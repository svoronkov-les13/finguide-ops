# Runbook

Удаление кубера. В начале tasks/main.yml
```yaml
- name: Uninstall k3s
  ansible.builtin.import_tasks: uninstall.yml
  tags: [never, uninstall]
```
И тогда запускать так:
```bash
  ansible-playbook bootstrap-kubernetes.yml --tags uninstall,all
```

## Генерация сикретов

```bash
# пароли БД — генерим и сразу кладём, без спецсимволов, чтобы не ломать connection strings
LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32 | gh secret set FINGUIDE_API_DB_PASSWORD
LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32 | gh secret set KEYCLOAK_DB_PASSWORD
LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32 | gh secret set KEYCLOAK_ADMIN_PASSWORD

# admin username — вводишь руками
gh secret set KEYCLOAK_ADMIN_USERNAME

# GHCR token
gh secret set GHCR_TOKEN
```

## Bootstrap Curie

После переустановки ОС у сервера меняется SSH host key. Если Ansible или SSH ругается на host key verification, обновить локальный `known_hosts`:

```bash
ssh-keygen -R 77.223.121.143
ssh-keyscan -H 77.223.121.143 >> ~/.ssh/known_hosts
ssh-keygen -R finguide.les13.tech
ssh-keyscan -H finguide.les13.tech >> ~/.ssh/known_hosts
```

Запускать из корня `finguide-ops`:

```bash
ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/bootstrap-kubernetes.yml
```

Playbook делает следующее:

- ставит k3s на `ops@finguide.les13.tech`;
- пишет `/etc/rancher/k3s/config.yaml`;
- отключает bundled Traefik и ServiceLB;
- ставит ingress-nginx через Helm;
- ставит cert-manager через Helm;
- создает `letsencrypt-prod` ClusterIssuer;
- копирует kubeconfig пользователю `ops`.

Проверка после bootstrap:

```bash
ssh ops@finguide.les13.tech 'sudo k3s kubectl get nodes -o wide'
ssh ops@finguide.les13.tech 'sudo k3s kubectl get pods -A'
```

## Ручной render overlays

```bash
kubectl kustomize k8s/overlays/dev
kubectl kustomize k8s/overlays/les13
kubectl kustomize k8s/platform/kubernetes-dashboard
```

## Kubernetes Dashboard

Dashboard ставится как platform add-on и не входит в `finguide` или `finguide-dev`.

Применить манифесты:

```bash
kubectl apply -k k8s/platform/kubernetes-dashboard
```

Проверить установку через k3s Helm controller:

```bash
kubectl -n kube-system get helmchart kubernetes-dashboard
kubectl -n kubernetes-dashboard get pods,svc
```

Получить token для входа:

```bash
kubectl -n kubernetes-dashboard create token kubernetes-dashboard-admin
```

Этот token дает `cluster-admin`; не сохранять его в git, chat logs или CI secrets без явной необходимости.

Открыть локальный доступ:

```bash
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
```

После этого открыть `https://localhost:8443/` и войти с token.

На Curie порт `8443` уже занят `ingress-nginx`, поэтому `https://finguide.les13.tech:8443/` не является Dashboard URL и может вернуть `400`. Если port-forward запускается прямо на Curie, использовать свободный локальный порт:

```bash
kubectl -n kubernetes-dashboard port-forward --address 127.0.0.1 svc/kubernetes-dashboard-kong-proxy 10443:443
curl -k https://127.0.0.1:10443/
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

Для GitHub Actions нужен environment secret:

- `KUBECONFIG_B64`: base64-encoded kubeconfig target cluster.
- `FINGUIDE_API_DB_PASSWORD`: пароль PostgreSQL для `finguide-api`.
- `KEYCLOAK_DB_PASSWORD`: пароль PostgreSQL для Keycloak.
- `KEYCLOAK_ADMIN_USERNAME`: bootstrap admin username Keycloak.
- `KEYCLOAK_ADMIN_PASSWORD`: bootstrap admin password Keycloak.
- `GHCR_USERNAME` / `GHCR_TOKEN`: опционально, если GHCR images остаются private.

Secret должен быть заведен в GitHub Environments, которые использует workflow:

- `dev` для `Deploy finguide-dev`;
- `les13` для `Deploy finguide`.

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

Для dev:

```bash
kubectl -n finguide-dev get pods
kubectl -n finguide-dev get ingress
kubectl -n finguide-dev get resourcequota
kubectl -n finguide-dev get certificate
curl -I https://finguide-dev.les13.tech/
curl -I https://finguide-dev.les13.tech/auth/
```

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

Перед rollback проверить совместимость database migrations и Keycloak state.
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
