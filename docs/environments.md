# Окружения

## Demo

Назначение:

- Проверять application deployments перед production.
- Обкатывать migrations, ingress rules и environment variables.
- Держать стабильный preview target.

Kubernetes namespace:

- `finguide-demo`

Overlay:

- `k8s/overlays/demo`

Image tag policy:

- Обычно `main`, `develop` или short SHA.
- Tag должен быть явным, чтобы деплой можно было воспроизвести.

## les13

Назначение:

- Запускать текущую цель FinGuide: `https://finguide.les13.tech`.
- Держать простую single-node инфраструктуру на уже существующем сервере.

Host:

- name: `curie`
- IP: `77.223.121.143`
- SSH user: `root`

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

- `https://finguide.les13.tech/` -> `finguide-web`
- `https://finguide.les13.tech/finguide-api` -> `finguide-api`
- `https://finguide.les13.tech/auth` -> `keycloak`

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

## Production

Назначение:

- Обслуживать real users.
- Использовать pinned release tags или immutable SHAs.

Kubernetes namespace:

- `finguide-prod`

Overlay:

- `k8s/overlays/prod`

Image tag policy:

- Release tag или immutable SHA.
- Не использовать mutable `latest`.

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
