# Runbook

## Bootstrap Curie

После переустановки ОС у сервера меняется SSH host key. Если Ansible или SSH ругается на host key verification, обновить локальный `known_hosts`:

```bash
ssh-keygen -R 77.223.121.143
ssh-keyscan -H 77.223.121.143 >> ~/.ssh/known_hosts
```

Запускать из корня `finguide-ops`:

```bash
ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/bootstrap-kubernetes.yml
```

Playbook делает следующее:

- ставит k3s на `root@77.223.121.143`;
- пишет `/etc/rancher/k3s/config.yaml`;
- отключает bundled Traefik и ServiceLB;
- ставит ingress-nginx через Helm;
- ставит cert-manager через Helm;
- создает `letsencrypt-prod` ClusterIssuer;
- копирует kubeconfig пользователю `root`.

Проверка после bootstrap:

```bash
ssh root@77.223.121.143 'k3s kubectl get nodes -o wide'
ssh root@77.223.121.143 'k3s kubectl get pods -A'
```

## Ручной render overlays

```bash
kubectl kustomize k8s/overlays/demo
kubectl kustomize k8s/overlays/dev
kubectl kustomize k8s/overlays/les13
kubectl kustomize k8s/overlays/prod
```

## Deploy через GitHub Actions

Для основных площадок использовать отдельные ручные workflows из этого репозитория:

- `Deploy finguide-dev` -> `k8s/overlays/dev`, namespace `finguide-dev`, host `finguide-dev.les13.tech`;
- `Deploy finguide` -> `k8s/overlays/les13`, namespace `finguide`, host `finguide.les13.tech`.

Оба workflow принимают:

- `api_image_tag`: tag API image в GHCR;
- `web_image_tag`: tag web image в GHCR.

Defaults:

- `Deploy finguide-dev`: `dev`;
- `Deploy finguide`: `les13`.

Workflow рендерит kustomize overlay, подменяет image tags, применяет результат в target cluster и ждет rollout `api`, `web` и соответствующего Keycloak.

Workflow `Deploy FinGuide Overlay` оставлен как общий fallback для `demo`, `dev`, `les13` и `prod`.

Для GitHub Actions нужен environment secret:

- `KUBECONFIG_B64`: base64-encoded kubeconfig target cluster.

Secret должен быть заведен в GitHub Environments, которые использует workflow:

- `dev` для `Deploy finguide-dev`;
- `les13` для `Deploy finguide`.

Если используется общий fallback workflow, такой же secret нужен в выбранном environment: `demo`, `dev`, `les13` или `prod`.

## Ручной deploy

Для `les13`:

```bash
OVERLAY=k8s/overlays/les13 \
NAMESPACE=finguide \
API_IMAGE_TAG=les13 \
WEB_IMAGE_TAG=les13 \
API_DEPLOYMENT=finguide-api \
WEB_DEPLOYMENT=finguide-web \
KEYCLOAK_DEPLOYMENT=keycloak \
bash scripts/deploy-kustomize-overlay.sh
```

Для `dev`:

```bash
OVERLAY=k8s/overlays/dev \
NAMESPACE=finguide-dev \
API_IMAGE_TAG=dev \
WEB_IMAGE_TAG=dev \
API_DEPLOYMENT=finguide-api-dev \
WEB_DEPLOYMENT=finguide-web-dev \
KEYCLOAK_DEPLOYMENT=keycloak-dev \
bash scripts/deploy-kustomize-overlay.sh
```

Для demo/prod использовать соответствующий overlay и namespace:

```bash
kubectl apply -k k8s/overlays/demo
kubectl apply -k k8s/overlays/prod
```

## Health checks

Для `les13`:

```bash
kubectl -n finguide get pods
kubectl -n finguide get ingress
kubectl -n finguide get certificate
kubectl -n finguide rollout status deployment/finguide-api
kubectl -n finguide rollout status deployment/finguide-web
```

Внешняя проверка:

```bash
curl -I https://finguide.les13.tech/
curl -I https://finguide.les13.tech/auth/
```

Для demo:

```bash
kubectl -n finguide-demo get pods
kubectl -n finguide-demo rollout status deployment/finguide-api-demo
kubectl -n finguide-demo rollout status deployment/finguide-web-demo
```

Для dev:

```bash
kubectl -n finguide-dev get pods
kubectl -n finguide-dev get ingress
kubectl -n finguide-dev get resourcequota
kubectl -n finguide-dev get certificate
curl -I https://finguide-dev.les13.tech/
curl -I https://finguide-dev.les13.tech/auth/
```

Для prod заменить namespace на `finguide-prod` и deployment names на `finguide-api-prod` / `finguide-web-prod`.

## Logs

Для `les13`:

```bash
kubectl -n finguide logs deployment/finguide-api --tail=100
kubectl -n finguide logs deployment/finguide-web --tail=100
kubectl -n finguide logs deployment/keycloak --tail=100
kubectl -n finguide logs deployment/keycloak-postgres --tail=100
```

Для `dev` заменить namespace на `finguide-dev`, а deployment names на `finguide-api-dev`, `finguide-web-dev`, `keycloak-dev`, `keycloak-postgres-dev`.

## Rollback

Для `les13`:

```bash
kubectl -n finguide rollout undo deployment/finguide-api
kubectl -n finguide rollout undo deployment/finguide-web
```

Перед rollback production проверить совместимость database migrations и Keycloak state.
Для dev допустимо чаще пересоздавать namespace целиком, если состояние не нужно сохранять.

## Restart

Для `les13`:

```bash
kubectl -n finguide rollout restart deployment/finguide-api
kubectl -n finguide rollout restart deployment/finguide-web
kubectl -n finguide rollout restart deployment/keycloak
```

## Быстрая диагностика ingress/TLS

```bash
kubectl -n ingress-nginx get pods
kubectl -n cert-manager get pods
kubectl -n finguide describe ingress finguide
kubectl -n finguide describe certificate finguide-les13-tls
kubectl -n finguide-dev describe ingress finguide-dev
kubectl -n finguide-dev describe certificate finguide-dev-les13-tls
kubectl get clusterissuer letsencrypt-prod
```
