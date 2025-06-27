pipeline {
    agent any
    
    tools {
        nodejs 'NodeJS'
    }
    
    environment {
        APP_VERSION = "1.0.${BUILD_NUMBER}"
        DOCKER_REGISTRY = "ghcr.io"
        GITHUB_USER = credentials('github-user')
        GITHUB_USER_LOWERCASE = "${GITHUB_USER.toLowerCase()}"
        DOCKER_IMAGE_BACKEND = "${DOCKER_REGISTRY}/${GITHUB_USER_LOWERCASE}/jenkins-exo-backend"
        DOCKER_IMAGE_FRONTEND = "${DOCKER_REGISTRY}/${GITHUB_USER_LOWERCASE}/jenkins-exo-frontend"
        
        DEPLOY_CREDENTIALS = credentials('vps-deploy-credentials')
        DEPLOY_HOST = credentials('vps-host')
        DEPLOY_DIR = "/opt/jenkins-exo"
        SSH_CREDENTIALS_ID = "vps-ssh-key"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Installation des dépendances') {
            steps {
                sh '''
                npm ci
                
                cd backend
                npm ci
                cd ..
                
                cd frontend
                npm ci
                cd ..
                '''
            }
        }
        
        stage('Exécution des tests') {
            steps {
                sh '''
                npx jest
                '''
            }
        }
        
        stage('Build') {
            steps {
                sh '''
                echo "Backend Express: pas de compilation nécessaire"
                
                cd frontend
                npm run build
                '''
            }
        }
        
        stage('Construction des images Docker') {
            steps {
                script {
                    sh """
                    docker build -t ${DOCKER_IMAGE_BACKEND}:${APP_VERSION} -f ./backend/Dockerfile.prod ./backend
                    docker build -t ${DOCKER_IMAGE_FRONTEND}:${APP_VERSION} -f ./frontend/Dockerfile.prod ./frontend
                    
                    docker tag ${DOCKER_IMAGE_BACKEND}:${APP_VERSION} ${DOCKER_IMAGE_BACKEND}:latest
                    docker tag ${DOCKER_IMAGE_FRONTEND}:${APP_VERSION} ${DOCKER_IMAGE_FRONTEND}:latest
                    """
                }
            }
        }
        
        stage('Publication des images Docker') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                        sh '''
                            set +x
                            echo $GITHUB_TOKEN | docker login $DOCKER_REGISTRY -u $GITHUB_USER_LOWERCASE --password-stdin
                            set -x
                        '''
                        sh """
                            docker push ${DOCKER_IMAGE_BACKEND}:${APP_VERSION}
                            docker push ${DOCKER_IMAGE_FRONTEND}:${APP_VERSION}
                            docker push ${DOCKER_IMAGE_BACKEND}:latest
                            docker push ${DOCKER_IMAGE_FRONTEND}:latest
                        """
                    }
                }
            }
        }
        
        stage('Tag du repository') {
            steps {
                sh """
                    git config user.email "leon.gallet@gmail.com"
                    git config user.name "Léon"
                    
                    git tag -a v${APP_VERSION} -m "Version ${APP_VERSION} automatiquement taguée par Jenkins"
                """
                
                withCredentials([usernamePassword(credentialsId: 'github-credentials', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                    sh '''
                        set +x
                        git push https://$GIT_USERNAME:$GIT_PASSWORD@github.com/$GITHUB_USER_LOWERCASE/jenkins-exo.git --tags
                        set -x
                    '''
                }
            }
        }
        
        stage('Création du package de déploiement') {
            steps {
                sh """
                    chmod +x scripts/create_deployment_package.sh
                    ./scripts/create_deployment_package.sh "${APP_VERSION}" "${DOCKER_IMAGE_BACKEND}" "${DOCKER_IMAGE_FRONTEND}"
                """
                
                archiveArtifacts artifacts: "jenkins-exo-deploy-*.tar.gz", fingerprint: true
            }
        }
        
        stage('Déploiement sur environnement de dev') {
            steps {
                sh "mkdir -p deploy-temp"
                
                sh "cp jenkins-exo-deploy-*.tar.gz deploy-temp/"
                
                // Récupérer la valeur de DEPLOY_HOST à partir des credentials
                withCredentials([
                    string(credentialsId: 'vps-host', variable: 'VPS_HOST')
                ]) {
                withEnv(["DEPLOY_USER=${DEPLOY_CREDENTIALS_USR}", "DEPLOY_PASSWORD=${DEPLOY_CREDENTIALS_PSW}", "DEPLOY_HOST=${VPS_HOST}"]) {
                    sh "apt-get update && apt-get install -y sshpass || true"
                    
                    writeFile file: 'deploy-temp/deploy-script.sh', text: """
                        #!/bin/bash
                        set -e
                        
                        export SSHPASS=\"${DEPLOY_PASSWORD}\"
                        
                        echo "🔄 Création du répertoire de déploiement sur le VPS..."
                        sshpass -e ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "mkdir -p ${DEPLOY_DIR}"
                        
                        echo "📦 Copie du package de déploiement vers le VPS..."
                        sshpass -e scp -o StrictHostKeyChecking=no deploy-temp/jenkins-exo-deploy-*.tar.gz ${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_DIR}/
                        
                        echo "🚀 Exécution du script de déploiement sur le VPS..."
                        sshpass -e ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "cd ${DEPLOY_DIR} && \
                            tar -xzf jenkins-exo-deploy-*.tar.gz && \
                            cd jenkins-exo-deploy-* && \
                            chmod +x deploy.sh && \
                            ./deploy.sh"
                    """
                    
                    sh "chmod +x deploy-temp/deploy-script.sh"
                    sh "./deploy-temp/deploy-script.sh"
                }
                }
                
                echo "🚀 Application déployée avec succès sur https://${DEPLOY_HOST}"
            }
        }
    }
    
    post {
        always {
            sh """
            docker system prune -f
            docker logout ${DOCKER_REGISTRY} || true
            """
            cleanWs()
        }
        success {
            echo "🚀 Pipeline exécuté avec succès! Images publiées: ${DOCKER_IMAGE_BACKEND}:${APP_VERSION} et ${DOCKER_IMAGE_FRONTEND}:${APP_VERSION}"
        }
        failure {
            echo "❌ Échec du pipeline. Vérifiez les logs pour plus de détails."
        }
    }
}
