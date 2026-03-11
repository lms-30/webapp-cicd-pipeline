pipeline {
    agent any
    environment {
        IMAGE_NAME    = "mon-app"
        IMAGE_TAG     = "build-${BUILD_NUMBER}"
        REPORT_DIR    = "reports"
        REPORT_FILE   = "trivy-report.csv"
    }
    stages {
        stage('Checkout') {
            steps {
                echo "📥 Récupération du code depuis GitHub..."
                checkout scm
            }
        }

        stage('Build Image Docker Compose') {
            steps {
                echo "🐳 Build avec Docker Compose..."
                sh """
                    docker compose build
                    docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Scan Trivy') {
            steps {
                echo "🔍 Scan de sécurité avec Trivy..."
                sh """
                    mkdir -p ${REPORT_DIR}
                    trivy image \
                        --exit-code 0 \
                        --severity LOW,MEDIUM,HIGH,CRITICAL \
                        --timeout 10m \
                        --format template \
                        --template "@contrib/csv.tpl"
                        --output ${REPORT_DIR}/${REPORT_FILE} \
                        ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: "${REPORT_DIR}/${REPORT_FILE}", allowEmptyArchive: true
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
            sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
        }
    }
}
