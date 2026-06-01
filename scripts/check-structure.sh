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
  "k8s/base/finguide-api/service.yaml"
  "k8s/base/finguide-web/deployment.yaml"
  "k8s/base/finguide-web/service.yaml"
  "k8s/overlays/demo/kustomization.yaml"
  "k8s/overlays/prod/kustomization.yaml"
  "helm/finguide-api/Chart.yaml"
  "helm/finguide-api/values.yaml"
  "helm/finguide-web/Chart.yaml"
  "helm/finguide-web/values.yaml"
  "helm/finguide-stack/Chart.yaml"
  "helm/finguide-stack/values.yaml"
  "ansible/inventories/demo/hosts.ini"
  "ansible/inventories/prod/hosts.ini"
  "ansible/playbooks/bootstrap-kubernetes.yml"
  "ansible/roles/kubernetes-node/tasks/main.yml"
  ".github/workflows/deploy.yml"
)

missing=0
for path in "${required_paths[@]}"; do
  if [[ ! -e "$path" ]]; then
    echo "missing: $path"
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

echo "structure ok"
