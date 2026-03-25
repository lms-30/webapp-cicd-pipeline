pipeline {
    agent any
    environment {
        IMAGE_NAME = "mon-app"
        IMAGE_TAG  = "build-${BUILD_NUMBER}"
    }
    stages {
        stage('Checkout') {
            steps {
                echo '📥 Code récupéré automatiquement par Jenkins via SCM.'
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
from collections import Counter

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
        raw_fieldnames = reader.fieldnames

        if not raw_fieldnames:
            print("⚠️  Fichier CSV vide ou sans en-tête.")
            sys.exit(0)

        # Supprimer les colonnes sans nom (None, "", "  ")
        fieldnames = [col for col in raw_fieldnames if col and col.strip()]

        rows = []
        for row in reader:
            # Nettoyer chaque ligne : garder uniquement les clés valides
            clean_row = {k: v for k, v in row.items() if k and k.strip()}
            rows.append(clean_row)

    # Détection automatique de la colonne Severity
    severity_col = next(
        (col for col in fieldnames if "severity" in col.lower()), None
    )
    if not severity_col:
        print("⚠️  Colonne Severity introuvable. Colonnes disponibles :", fieldnames)
        sys.exit(1)

    # Détection automatique de la colonne VulnerabilityID
    vuln_col = next(
        (col for col in fieldnames
         if "vulnerabilityid" in col.lower() or col.lower() == "id"),
        None
    )

    # Tri décroissant par sévérité, puis par ID pour les ex-aequo
    rows.sort(key=lambda r: (
        SEVERITY_ORDER.get(r.get(severity_col, "").strip().upper(), 99),
        r.get(vuln_col, "") if vuln_col else ""
    ))

    with open(output_file, "w", newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(
            f,
            fieldnames=fieldnames,
            extrasaction='ignore'
        )
        writer.writeheader()
        writer.writerows(rows)

    # Résumé dans les logs Jenkins
    counts = Counter(r.get(severity_col, "").strip().upper() for r in rows)
    print("\\n===== Résumé des vulnérabilités =====")
    for level in ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"]:
        if counts.get(level, 0) > 0:
            print(f"  {level:<10}: {counts[level]}")
    print(f"  {'TOTAL':<10}: {sum(counts.values())}")
    print("=====================================\\n")
    print(f"✅ Rapport trié sauvegardé : {output_file}")

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
        stage('Export Report to Host') {
            steps {
                echo '💾 Export du rapport vers le dossier partagé hôte...'
                sh '''
                SHARED_DIR="/var/jenkins_home/exports"
                mkdir -p $SHARED_DIR

                TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
                EXPORT_NAME="trivy-report_${TIMESTAMP}_build-${BUILD_NUMBER}.csv"

                cp reports/trivy-report.csv $SHARED_DIR/$EXPORT_NAME

                echo ""
                echo "✅ Rapport exporté avec succès !"
                echo "   📄 Fichier  : $SHARED_DIR/$EXPORT_NAME"
                echo "   📦 Taille   : $(du -h $SHARED_DIR/$EXPORT_NAME | cut -f1)"
                echo "   🗂️  Historique des exports :"
                ls -lht $SHARED_DIR/
                '''
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
            docker rmi ${IMAGE_NAME}:latest || true
            '''
        }
    }
}
