pipeline {
    agent any

    environment {
        IMAGE_NAME = "mon-app"
        IMAGE_TAG  = "build-${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "📥 Récupération du code depuis GitHub..."
                checkout scm
            }
        }

        stage('Pull & Build Image Docker') {
            steps {
                echo "🐳 Build de l'image Docker..."
                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Scan Trivy') {
            steps {
                echo "🔍 Scan de sécurité avec Trivy..."
                sh """
                    trivy image \
                        --exit-code 0 \
                        --severity LOW,MEDIUM,HIGH,CRITICAL \
                        --timeout 10m \
                        --format csv \
                        --output trivy-report.csv \
                        ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/trivy-report.csv', allowEmptyArchive: true
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline terminé avec succès !"
        }
        failure {
            echo "❌ Pipeline échoué."
        }
        always {
            // Nettoyage des images locales (optionnel)
            sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
        }
    }
}
