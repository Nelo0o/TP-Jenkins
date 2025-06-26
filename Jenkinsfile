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
                    docker build -t ${DOCKER_IMAGE_BACKEND}:${APP_VERSION} ./backend
                    docker build -t ${DOCKER_IMAGE_FRONTEND}:${APP_VERSION} ./frontend
                    
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
                        sh """
                        echo ${GITHUB_TOKEN} | docker login ${DOCKER_REGISTRY} -u ${GITHUB_USER} --password-stdin
                        
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
                withCredentials([usernamePassword(credentialsId: 'github-credentials', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                    sh """
                    git config user.email "leon.gallet@gmail.com"
                    git config user.name "Léon"
                    
                    git tag -a v${APP_VERSION} -m "Version ${APP_VERSION} automatiquement taguée par Jenkins"
                    git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${GITHUB_USER}/jenkins-exo.git --tags
                    """
                }
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
