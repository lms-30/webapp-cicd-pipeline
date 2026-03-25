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
                docker compose build --no-cache
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

                trivy image \
                --scanners vuln \
                --severity LOW,MEDIUM,HIGH,CRITICAL \
                --timeout 15m \
                --format template \
                --template "@templates/csv.tpl" \
                --output reports/trivy-report-raw.csv \
                ${IMAGE_NAME}:latest
                '''
            }
        }
        stage('Sort Vulnerabilities by Severity') {
            steps {
                echo '📋 Tri des vulnérabilités par ordre décroissant de sévérité...'
                sh '''
                python3 - <<'EOF'
import csv
import sys

# Ordre de priorité décroissant
SEVERITY_ORDER = {
    "CRITICAL": 1,
    "HIGH":     2,
    "MEDIUM":   3,
    "LOW":      4,
    "UNKNOWN":  5
}

input_file  = "reports/trivy-report-raw.csv"
output_file = "reports/trivy-report.csv"

try:
    with open(input_file, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames

        if not fieldnames:
            print("⚠️  Fichier CSV vide ou sans en-tête.")
            sys.exit(0)

        # Détection automatique de la colonne Severity
        severity_col = next(
            (col for col in fieldnames if "severity" in col.lower()),
            None
        )

        if not severity_col:
            print("⚠️  Colonne 'Severity' introuvable. Colonnes disponibles :", fieldnames)
            sys.exit(1)

        rows = list(reader)

    # Tri par sévérité décroissante, puis par VulnerabilityID pour l'ordre alphabétique
    vuln_col = next(
        (col for col in fieldnames if "vulnerabilityid" in col.lower() or "id" in col.lower()),
        None
    )

    rows.sort(key=lambda r: (
        SEVERITY_ORDER.get(r[severity_col].strip().upper(), 99),
        r.get(vuln_col, "") if vuln_col else ""
    ))

    with open(output_file, "w", newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    # Résumé dans les logs Jenkins
    from collections import Counter
    counts = Counter(r[severity_col].strip().upper() for r in rows)
    print("\\n===== Résumé des vulnérabilités =====")
    for level in ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"]:
        if counts.get(level, 0) > 0:
            print(f"  {level:<10}: {counts[level]}")
    print(f"  {'TOTAL':<10}: {sum(counts.values())}")
    print("=====================================\\n")
    print(f"✅ Rapport trié sauvegardé dans : {output_file}")

except FileNotFoundError:
    print(f"❌ Fichier introuvable : {input_file}")
    sys.exit(1)
EOF
                '''
            }
        }
        stage('Archive Report') {
            steps {
                echo '📊 Archivage du rapport Trivy trié...'
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
