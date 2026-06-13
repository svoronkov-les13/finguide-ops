# Окружения

## les13

Назначение:

- Запускать текущую цель FinGuide: `https://finguide.les13.tech`.
- Держать простую single-node инфраструктуру на уже существующем сервере.

Host:

- name: `curie`
- IP: `77.223.121.143`
- SSH user: `ops` для стандартных операций; `root` только для break-glass/первичного восстановления

Kubernetes:

- single-node k3s;
- ingress-nginx на host network для ports `80` и `443`;
- cert-manager с `letsencrypt-prod`;
- local-path storage;
- bundled Traefik отключен;
- bundled ServiceLB отключен.

Kubernetes namespace:

- `finguide`

Overlay:

- `k8s/overlays/les13`

Deploy workflow:

- `Deploy finguide`

Image tag policy:

- По умолчанию `les13`.
- Для reproducible deploy лучше передавать explicit immutable tag через GitHub Actions.

Ingress:

- `https://finguide.les13.tech/` -> `finguide-web`, редирект на `/fg/`
- `https://finguide.les13.tech/fg/` -> `finguide-web`
- `https://finguide.les13.tech/finguide-api` -> `finguide-api`; backend context path тоже `/finguide-api`, ingress prefix не срезает
- `https://finguide.les13.tech/auth` -> `keycloak`

Runtime:

- API profile: `prod`
- API database: `jdbc:postgresql://finguide-api-postgres:5432/finguide`
- API schema owner/user: `finguide`
- API schema migrations: Liquibase из backend image
- Keycloak admin console: `https://finguide.les13.tech/auth/admin/master/console/`

## Dev

Назначение:

- Проверять новые сборки и auth-настройки на том же сервере Curie.
- Иметь отдельный Keycloak, realm и тестовых пользователей.
- Дать dev-контур, который можно пересоздать без риска для основного `les13`.

Host:

- name: `curie`
- IP: `77.223.121.143`
- DNS: `finguide-dev.les13.tech` должен указывать на тот же IP.

Kubernetes namespace:

- `finguide-dev`

Overlay:

- `k8s/overlays/dev`

Deploy workflow:

- `Deploy finguide-dev`

Image tag policy:

- По умолчанию `dev`.
- Для проверки конкретной сборки лучше передавать explicit immutable tag через GitHub Actions.

Ingress:

- `https://finguide-dev.les13.tech/` -> `finguide-web-dev`
- `https://finguide-dev.les13.tech/finguide-api` -> `finguide-api-dev`
- `https://finguide-dev.les13.tech/auth` -> `keycloak-dev`

Отдельный Keycloak:

- deployment: `keycloak-dev`
- postgres: `keycloak-postgres-dev`
- realm: `finguide-dev`
- issuer: `https://finguide-dev.les13.tech/auth/realms/finguide-dev`

Ограничения ресурсов:

- namespace quota: `requests.cpu=1`, `requests.memory=2Gi`, `limits.cpu=2`, `limits.memory=3Gi`
- api: `50m/192Mi` request, `300m/384Mi` limit
- web: `25m/64Mi` request, `150m/128Mi` limit
- keycloak: `150m/512Mi` request, `700m/1Gi` limit
- postgres: `50m/256Mi` request, `300m/512Mi` limit

`les13` не ограничен dev quota. Base manifest сейчас даёт `keycloak` `500m/1Gi` request и `2 CPU/3Gi` limit, потому что Keycloak 26 может делать Quarkus augmentation на старте и иначе уходить в OOMKilled. API base limit сейчас `2 CPU/1536Mi`, request `100m/512Mi`.

## Обязательные secrets

Эти secrets используются манифестами, но создаются вне git:

- `finguide-api-secrets`
  - `fg-api-db-password`
- `finguide-web-secrets`
- `keycloak-secrets`
  - `db-password`
  - `admin-username`
  - `admin-password`

Для `dev` используются такие же secret names, но в namespace `finguide-dev` и с отдельными dev-значениями.

Значения secret'ов нельзя коммитить. Список обязательных keys надо дополнять здесь по мере стабилизации приложения.

## Platform namespaces

Platform add-ons живут отдельно от application namespaces:

- `kubernetes-dashboard` — Kubernetes Dashboard и service account для token-login.
- `loki-grafana` — Loki, Promtail, Prometheus и Grafana для cluster logs и JVM/application metrics.
- `kube-system` — k3s `HelmChart` resources, которые управляют установкой platform add-ons.

Эти ресурсы не должны добавляться в overlays `k8s/overlays/*`, чтобы не смешивать cluster-level tooling с окружениями FinGuide.

## Удаленные заготовки

Заготовки окружений `demo` и `prod` удалены из репозитория. Сейчас поддерживаемые application overlays:

- `k8s/overlays/dev`
- `k8s/overlays/les13`
