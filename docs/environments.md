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
- IP: `161.104.36.83`
- SSH user: `ops`

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

Image tag policy:

- По умолчанию `les13`.
- Для reproducible deploy лучше передавать explicit immutable tag через GitHub Actions.

Ingress:

- `https://finguide.les13.tech/` -> `finguide-web`
- `https://finguide.les13.tech/finguide-api` -> `finguide-api`
- `https://finguide.les13.tech/auth` -> `keycloak`

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
- `finguide-web-secrets`
- `keycloak-secrets`

Значения secret'ов нельзя коммитить. Список обязательных keys надо дополнять здесь по мере стабилизации приложения.
