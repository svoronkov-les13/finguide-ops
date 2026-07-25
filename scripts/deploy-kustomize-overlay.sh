#!/usr/bin/env bash
set -euo pipefail

: "${OVERLAY:?OVERLAY is required}"
: "${NAMESPACE:?NAMESPACE is required}"
: "${API_IMAGE_TAG:?API_IMAGE_TAG is required}"
: "${WEB_IMAGE_TAG:?WEB_IMAGE_TAG is required}"
: "${API_DEPLOYMENT:?API_DEPLOYMENT is required}"
: "${WEB_DEPLOYMENT:?WEB_DEPLOYMENT is required}"

KEYCLOAK_DEPLOYMENT="${KEYCLOAK_DEPLOYMENT:-}"
KEYCLOAK_REALM="${KEYCLOAK_REALM:-}"

validate_image_tag() {
  local name="$1"
  local value="$2"
  if [[ ! "$value" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]]; then
    echo "Invalid ${name}: ${value}" >&2
    exit 1
  fi
}

validate_image_tag "API_IMAGE_TAG" "$API_IMAGE_TAG"
validate_image_tag "WEB_IMAGE_TAG" "$WEB_IMAGE_TAG"

echo "Deploy overlay: ${OVERLAY}"
echo "Namespace: ${NAMESPACE}"
echo "API tag: ${API_IMAGE_TAG}"
echo "Web tag: ${WEB_IMAGE_TAG}"

kubectl kustomize "$OVERLAY" \
  | sed "s#ghcr.io/svoronkov-les13/finguide-api:[^[:space:]]*#ghcr.io/svoronkov-les13/finguide-api:${API_IMAGE_TAG}#g" \
  | sed "s#ghcr.io/svoronkov-les13/finguide-web:[^[:space:]]*#ghcr.io/svoronkov-les13/finguide-web:${WEB_IMAGE_TAG}#g" \
  | kubectl apply -f -

kubectl -n "$NAMESPACE" rollout restart deployment/"$API_DEPLOYMENT"
kubectl -n "$NAMESPACE" rollout restart deployment/"$WEB_DEPLOYMENT"

kubectl -n "$NAMESPACE" rollout status deployment/"$API_DEPLOYMENT" --timeout=180s
kubectl -n "$NAMESPACE" rollout status deployment/"$WEB_DEPLOYMENT" --timeout=180s

if [[ -n "$KEYCLOAK_DEPLOYMENT" ]]; then
  kubectl -n "$NAMESPACE" rollout restart deployment/"$KEYCLOAK_DEPLOYMENT"
  kubectl -n "$NAMESPACE" rollout status deployment/"$KEYCLOAK_DEPLOYMENT" --timeout=180s
  if [[ -n "$KEYCLOAK_REALM" ]]; then
    kubectl -n "$NAMESPACE" exec deployment/"$KEYCLOAK_DEPLOYMENT" -- sh -lc \
      '/opt/keycloak/bin/kcadm.sh config credentials --server http://127.0.0.1:8080/auth --realm master --user "$KC_BOOTSTRAP_ADMIN_USERNAME" --password "$KC_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null
       /opt/keycloak/bin/kcadm.sh update "realms/$1" -s loginTheme=finguide' \
      sh "$KEYCLOAK_REALM"
  fi
fi
