#!/usr/bin/env bash
set -euo pipefail

: "${NAMESPACE:?NAMESPACE is required}"
: "${FINGUIDE_API_DB_PASSWORD:?FINGUIDE_API_DB_PASSWORD is required}"
: "${KEYCLOAK_DB_PASSWORD:?KEYCLOAK_DB_PASSWORD is required}"
: "${KEYCLOAK_ADMIN_USERNAME:?KEYCLOAK_ADMIN_USERNAME is required}"
: "${KEYCLOAK_ADMIN_PASSWORD:?KEYCLOAK_ADMIN_PASSWORD is required}"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic finguide-api-secrets \
  --from-literal=fg-api-db-password="$FINGUIDE_API_DB_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic keycloak-secrets \
  --from-literal=db-password="$KEYCLOAK_DB_PASSWORD" \
  --from-literal=admin-username="$KEYCLOAK_ADMIN_USERNAME" \
  --from-literal=admin-password="$KEYCLOAK_ADMIN_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

if [[ -n "${GHCR_USERNAME:-}" && -n "${GHCR_TOKEN:-}" ]]; then
  kubectl -n "$NAMESPACE" create secret docker-registry ghcr-pull-secret \
    --docker-server=ghcr.io \
    --docker-username="$GHCR_USERNAME" \
    --docker-password="$GHCR_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl -n "$NAMESPACE" patch serviceaccount default \
    --type=merge \
    --patch='{"imagePullSecrets":[{"name":"ghcr-pull-secret"}]}'
fi
