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
  -> finguide-ops GitHub Actions deploy workflow
  -> Kubernetes overlay
  -> target namespace
```

Для текущей площадки `les13` целевой namespace: `finguide`.
Для dev-контура целевой namespace: `finguide-dev`.
Для них заведены отдельные ручные workflows: `Deploy finguide` и `Deploy finguide-dev`.

## Runtime-компоненты

- `finguide-api`: backend API Deployment и Service.
- `finguide-api-postgres`: PostgreSQL 16 для backend данных FinGuide.
- `finguide-web`: frontend Deployment и Service.
- `keycloak`: identity provider для `les13`.
- `keycloak-postgres`: PostgreSQL для Keycloak на single-node площадке.
- `keycloak-dev`: отдельный identity provider для `finguide-dev.les13.tech`.
- `keycloak-postgres-dev`: отдельный PostgreSQL для dev Keycloak.
- `finguide-stack`: umbrella Helm chart для установки app-компонентов вместе.
- `ingress-nginx`: входящий HTTP/HTTPS traffic.
- `cert-manager`: выпуск TLS-сертификатов Let's Encrypt.
- `kubernetes-dashboard`: cluster-level dashboard в отдельном namespace `kubernetes-dashboard`.

## Kubernetes distribution

Текущая цель для `finguide.les13.tech` — single-node k3s на Curie (`77.223.121.143`).

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

- `https://finguide.les13.tech/` -> `finguide-web`, редирект на `/fg/`
- `https://finguide.les13.tech/fg/` -> `finguide-web`
- `https://finguide.les13.tech/finguide-api` -> `finguide-api`
- `https://finguide.les13.tech/auth` -> `keycloak`

Для `dev` внешний вход отдельный, на том же IP:

- `https://finguide-dev.les13.tech/` -> `finguide-web-dev`
- `https://finguide-dev.les13.tech/finguide-api` -> `finguide-api-dev`
- `https://finguide-dev.les13.tech/auth` -> `keycloak-dev`

Dev-контур живет в отдельном namespace `finguide-dev`, имеет отдельный Keycloak realm `finguide-dev`, отдельный Keycloak/Postgres и ограничен `ResourceQuota`/`LimitRange`.

Ingress не делает rewrite для `/finguide-api`: Spring Boot backend сам запущен с `server.servlet.context-path=/finguide-api`, поэтому probes, Swagger и API endpoints тоже живут под этим prefix. Если когда-либо переносить prefix stripping в ingress, API path надо вынести в отдельный Ingress resource, потому что annotation `nginx.ingress.kubernetes.io/rewrite-target` применяется ко всему объекту и может сломать `/auth` или `/`.

NodePort для публичного доступа не используется. Наружу должны быть открыты только `22`, `80`, `443`; `6443` нужен только для администрирования и CI/CD.

## Platform add-ons

Platform-манифесты лежат отдельно от application overlays и не устанавливаются в `finguide*` namespaces.

- `k8s/platform/cert-manager`: cluster issuer для TLS.
- `k8s/platform/kubernetes-dashboard`: k3s `HelmChart`, который ставит Kubernetes Dashboard в namespace `kubernetes-dashboard`.

Kubernetes Dashboard не имеет публичного ingress в git-манифестах. Доступ предполагается через `kubectl port-forward` и token отдельного service account.

## Secrets

Secret values не коммитятся в git. В манифестах допускаются только имена secret'ов и ссылки на keys.

Keycloak admin console для `les13` доступен по:

- `https://finguide.les13.tech/auth/admin/master/console/`

Admin username/password лежат в Kubernetes Secret `keycloak-secrets` keys `admin-username` и `admin-password`. Не переносить реальные значения в git, README, issues или Pages.

## Terraform boundary

Terraform сейчас не участвует в bootstrap k3s на Curie. Причина простая: Curie уже существует как сервер, а установка packages/k3s/Helm add-ons является host configuration, которую в этом репозитории делает Ansible.

Terraform надо добавить, когда появятся ресурсы, которыми нужно владеть декларативно через provider:

- создание или пересоздание cloud VM;
- DNS records `finguide.les13.tech` / `finguide-dev.les13.tech`;
- firewall/security group rules;
- external volumes, object storage, registry или managed secrets.

Если такой provider появится, Terraform должен создать/обновить инфраструктурные ресурсы, а затем передать inventory outputs в Ansible bootstrap.

## Не цели

- Не разворачивать application services через `systemd`.
- Не устанавливать k3s через Terraform remote-exec поверх уже существующего Curie.
- Не хранить секреты в репозитории.
