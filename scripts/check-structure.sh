#!/usr/bin/env bash
set -euo pipefail

required_paths=(
  "README.md"
  "docs/architecture.md"
  "docs/environments.md"
  "docs/runbook.md"
  "docs/disaster-recovery.md"
  "docs/deployment-contract.md"
  "k8s/base/kustomization.yaml"
  "k8s/base/namespace.yaml"
  "k8s/base/finguide-api/deployment.yaml"
  "k8s/base/finguide-api/postgres.yaml"
  "k8s/base/finguide-api/pvc.yaml"
  "k8s/base/finguide-api/service.yaml"
  "k8s/base/finguide-web/deployment.yaml"
  "k8s/base/finguide-web/service.yaml"
  "k8s/base/keycloak/deployment.yaml"
  "k8s/base/keycloak/kustomization.yaml"
  "k8s/base/keycloak/postgres.yaml"
  "k8s/base/keycloak/service.yaml"
  "images/keycloak/Dockerfile"
  "images/keycloak/themes/finguide/login/theme.properties"
  "images/keycloak/themes/finguide/login/template.ftl"
  "images/keycloak/themes/finguide/login/resources/css/finguide.css"
  "k8s/overlays/dev/kustomization.yaml"
  "k8s/overlays/dev/configmap.yaml"
  "k8s/overlays/dev/ingress.yaml"
  "k8s/overlays/dev/keycloak-realm.yaml"
  "k8s/overlays/dev/quota.yaml"
  "k8s/overlays/dev/patches/finguide-api-resources.yaml"
  "k8s/overlays/dev/patches/finguide-web-resources.yaml"
  "k8s/overlays/dev/patches/keycloak-dev.yaml"
  "k8s/overlays/dev/patches/keycloak-postgres-dev.yaml"
  "k8s/overlays/dev/patches/keycloak-postgres-pvc.yaml"
  "k8s/overlays/les13/kustomization.yaml"
  "k8s/overlays/les13/configmap.yaml"
  "k8s/overlays/les13/ingress.yaml"
  "k8s/overlays/les13/keycloak-realm.yaml"
  "k8s/platform/cert-manager/clusterissuer-letsencrypt-prod.yaml"
  "k8s/platform/kubernetes-dashboard/admin-user.yaml"
  "k8s/platform/kubernetes-dashboard/helmchart.yaml"
  "k8s/platform/kubernetes-dashboard/kustomization.yaml"
  "k8s/platform/kubernetes-dashboard/namespace.yaml"
  "helm/finguide-api/Chart.yaml"
  "helm/finguide-api/values.yaml"
  "helm/finguide-web/Chart.yaml"
  "helm/finguide-web/values.yaml"
  "helm/finguide-stack/Chart.yaml"
  "helm/finguide-stack/values.yaml"
  "ansible/inventories/prod/hosts.ini"
  "ansible/inventories/prod/group_vars/kubernetes_nodes.yml"
  "ansible.cfg"
  "ansible/playbooks/bootstrap-kubernetes.yml"
  "ansible/roles/kubernetes-node/handlers/main.yml"
  "ansible/roles/kubernetes-node/tasks/main.yml"
  "ansible/roles/kubernetes-node/templates/k3s-config.yaml.j2"
  "scripts/deploy-kustomize-overlay.sh"
  "scripts/apply-runtime-secrets.sh"
  ".github/workflows/deploy.yml"
  ".github/workflows/deploy-finguide.yml"
  ".github/workflows/deploy-finguide-dev.yml"
  ".github/workflows/build-keycloak.yml"
)

missing=0
for path in "${required_paths[@]}"; do
  if [[ ! -e "$path" ]]; then
    echo "missing: $path"
    missing=1
  fi
done

if [[ -f "k8s/base/keycloak/deployment.yaml" ]] && ! grep -q "ghcr.io/svoronkov-les13/finguide-keycloak" "k8s/base/keycloak/deployment.yaml"; then
  echo "missing: keycloak deployment does not use FinGuide Keycloak image"
  missing=1
fi

for realm in "k8s/overlays/dev/keycloak-realm.yaml" "k8s/overlays/les13/keycloak-realm.yaml"; do
  if [[ -f "$realm" ]] && ! grep -q '"loginTheme": "finguide"' "$realm"; then
    echo "missing: $realm does not set loginTheme=finguide"
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

echo "structure ok"
