pipeline {
    agent any
    
    tools {
        nodejs 'NodeJS'
    }
    
    stages {
        stage('Install Dependencies') {
            steps {
                sh '''
                cd backend
                npm ci
                cd ../frontend
                npm ci
                cd ..
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
        
        stage('Verify Nginx Config') {
            steps {
                sh '''
                cd nginx
                # Évite que ce soit un dossier (cas où Docker l'aurait transformé en dossier)
                [ -d default.conf ] && rm -rf default.conf
                
                # Vérifie l'existence réelle du fichier
                if [ ! -f default.conf ]; then
                  echo "Fichier nginx/default.conf manquant !"
                  exit 1
                fi
                cd ..
                '''
            }
        }
        
        stage('Build & Deploy') {
            steps {
                script {
                    def projectName = "jenkins-exo_${BUILD_NUMBER}".toLowerCase().replaceAll('[^a-z0-9]', '-')
                    
                    sh """
                    export COMPOSE_PROJECT_NAME=${projectName}
                    docker compose -p ${projectName} up --build --abort-on-container-exit --exit-code-from backend
                    """
                }
            }
        }
    }
    
    post {
        always {
            script {
                def projectName = "jenkins-exo_${BUILD_NUMBER}".toLowerCase().replaceAll('[^a-z0-9]', '-')
                sh "docker compose -p ${projectName} down -v || true"
            }
            cleanWs()
        }
    }
}
