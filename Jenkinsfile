pipeline {
    agent any

    environment {
        IMAGE_NAME = "mon-app"
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo '📥 Récupération du code depuis GitHub...'
                checkout scm
            }
        }

        stage('Build Image Docker Compose') {
            steps {
                echo '🐳 Build avec Docker Compose...'
                sh '''
                docker compose build
                docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Scan Trivy') {
            steps {
                echo '🔍 Scan de sécurité avec Trivy...'
                sh '''
                mkdir -p reports
                mkdir -p templates

                wget https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/csv.tpl -O templates/csv.tpl

                trivy image \
                --scanners vuln \
                --exit-code 0 \
                --severity LOW,MEDIUM,HIGH,CRITICAL \
                --timeout 10m \
                --format template \
                --template "@templates/csv.tpl" \
                --output reports/trivy-report.csv \
                ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Archive Report') {
            steps {
                echo '📊 Archivage du rapport Trivy...'
                archiveArtifacts artifacts: 'reports/trivy-report.csv', fingerprint: true
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline terminé avec succès.'
        }

        failure {
            echo '❌ Pipeline échoué.'
        }

        always {
            sh '''
            docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true
            '''
        }
    }
}
