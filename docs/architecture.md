# Архитектура

## Зона ответственности

`finguide-ops` отвечает за инфраструктурную границу FinGuide:

- Kubernetes manifests и environment overlays.
- Helm-чарты для повторяемой упаковки приложения.
- GitHub Actions workflows для деплоя.
- Bootstrap хостов через Ansible.
- Документацию по деплою, rollback, health checks, backup и disaster recovery.

Репозитории приложения отвечают за исходный код, тесты, Dockerfile'ы и публикацию образов.

## Поток деплоя

```text
finguide-be / finguide-web
  -> build Docker image
  -> push to GHCR
  -> finguide-ops GitHub Actions deploy
  -> Kubernetes overlay
  -> target namespace
```

Для текущей площадки `les13` целевой namespace: `finguide`.

## Runtime-компоненты

- `finguide-api`: backend API Deployment и Service.
- `finguide-web`: frontend Deployment и Service.
- `keycloak`: identity provider для `les13`.
- `keycloak-postgres`: PostgreSQL для Keycloak на single-node площадке.
- `finguide-stack`: umbrella Helm chart для установки app-компонентов вместе.
- `ingress-nginx`: входящий HTTP/HTTPS traffic.
- `cert-manager`: выпуск TLS-сертификатов Let's Encrypt.

## Kubernetes distribution

Текущая цель для `finguide.les13.tech` — single-node k3s на Curie (`161.104.36.83`).

k3s запускается с такими принципами:

- bundled Traefik отключен;
- bundled ServiceLB отключен;
- local-path storage оставлен как простой storage для одной ноды;
- ingress-nginx слушает host ports `80` и `443`;
- cert-manager выпускает сертификаты через `letsencrypt-prod`;
- Kubernetes API доступен на `6443`, но его надо ограничивать firewall'ом по trusted IP.

Приложение остается на стандартных Kubernetes-ресурсах. Overlay выбирает hostname, image tags, ingress и replicas.

## Сети и ingress

Для `les13` внешний вход один:

- `https://finguide.les13.tech/` -> `finguide-web`
- `https://finguide.les13.tech/finguide-api` -> `finguide-api`
- `https://finguide.les13.tech/auth` -> `keycloak`

NodePort для публичного доступа не используется. Наружу должны быть открыты только `22`, `80`, `443`; `6443` нужен только для администрирования и CI/CD.

## Secrets

Secret values не коммитятся в git. В манифестах допускаются только имена secret'ов и ссылки на keys.

## Не цели

- Не разворачивать application services через `systemd`.
- Не добавлять Terraform, пока нет cloud resources или repeatable provisioning поверх уже существующего Curie.
- Не хранить секреты в репозитории.
