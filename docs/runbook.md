# Runbook

## Bootstrap Curie

Запускать из корня `finguide-ops`:

```bash
ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/bootstrap-kubernetes.yml
```

Playbook делает следующее:

- ставит k3s на `ops@161.104.36.83`;
- пишет `/etc/rancher/k3s/config.yaml`;
- отключает bundled Traefik и ServiceLB;
- ставит ingress-nginx через Helm;
- ставит cert-manager через Helm;
- создает `letsencrypt-prod` ClusterIssuer;
- копирует kubeconfig пользователю `ops`.

Проверка после bootstrap:

```bash
ssh curie 'sudo k3s kubectl get nodes -o wide'
ssh curie 'sudo k3s kubectl get pods -A'
```

## Ручной render overlays

```bash
kubectl kustomize k8s/overlays/demo
kubectl kustomize k8s/overlays/dev
kubectl kustomize k8s/overlays/les13
kubectl kustomize k8s/overlays/prod
```

## Deploy через GitHub Actions

Использовать workflow `Deploy FinGuide` из этого репозитория.

Inputs:

- `environment`: `demo`, `dev`, `les13` или `prod`;
- `api_image_tag`: tag API image в GHCR;
- `web_image_tag`: tag web image в GHCR.

Workflow рендерит выбранный kustomize overlay, подменяет image tags и применяет результат в target cluster.

Для GitHub Actions нужен secret:

- `KUBECONFIG_B64`: base64-encoded kubeconfig target cluster.

## Ручной deploy

Для `les13`:

```bash
kubectl apply -k k8s/overlays/les13
kubectl -n finguide rollout status deployment/finguide-api --timeout=180s
kubectl -n finguide rollout status deployment/finguide-web --timeout=180s
kubectl -n finguide rollout status deployment/keycloak --timeout=180s
```

Для `dev`:

```bash
kubectl apply -k k8s/overlays/dev
kubectl -n finguide-dev rollout status deployment/finguide-api-dev --timeout=180s
kubectl -n finguide-dev rollout status deployment/finguide-web-dev --timeout=180s
kubectl -n finguide-dev rollout status deployment/keycloak-dev --timeout=180s
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
