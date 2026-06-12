# FinGuide Ops

Инфраструктура, деплой и эксплуатационная документация FinGuide.

Код продукта живет в отдельных репозиториях:

- `finguide-be` собирает и публикует образ API.
- `finguide-web` собирает и публикует образ web-приложения.
- `finguide-ops` хранит Kubernetes-манифесты, Helm-чарты, Ansible bootstrap, описание окружений и runbook'и.

## Рабочая модель

FinGuide разворачивается через Kubernetes. Прикладные сервисы не запускаются как отдельные `systemd` units. `systemd` может использоваться ниже уровнем для Kubernetes, runner'ов или host-сервисов, но `finguide-api` и `finguide-web` работают как Kubernetes workloads.

Образы публикуются в GitHub Container Registry:

- `ghcr.io/svoronkov-les13/finguide-api:<tag>`
- `ghcr.io/svoronkov-les13/finguide-web:<tag>`

Деплой запускается из этого репозитория через GitHub Actions. Для основных площадок есть отдельные ручные pipelines:

- `Deploy finguide-dev` раскатывает `k8s/overlays/dev` в namespace `finguide-dev`.
- `Deploy finguide` раскатывает `k8s/overlays/les13` в namespace `finguide`.

Заготовки `demo` и `prod` удалены. Сейчас поддерживаются только `dev` и `les13`.

## Документация и GitHub Pages

Этот репозиторий хранит operational docs в `docs/`, но отдельный GitHub Pages workflow здесь сейчас не настроен. Публичная MkDocs-документация проекта публикуется из `finguide-be`:

- https://svoronkov-les13.github.io/finguide-be/

При изменении Kubernetes manifests, deploy workflows, ingress, secrets или runbook'ов нужно обновлять документацию здесь и, если меняется внешний contract backend/frontend, синхронизировать страницы в `finguide-be`.

## Структура

```text
docs/                  Архитектура, окружения, runbook'и, восстановление
k8s/base/              Общие Kubernetes-ресурсы
k8s/overlays/dev/      Dev-контур finguide-dev.les13.tech
k8s/overlays/les13/    Single-node Curie для finguide.les13.tech
k8s/platform/          Cluster-level ресурсы: cert-manager issuers, Dashboard, Loki/Grafana
helm/                  Каркасы Helm-чартов для app и stack packaging
ansible/               Bootstrap Kubernetes nodes и host-level операции
terraform/             Заметки о Terraform boundary; сейчас cloud resources не управляются
scripts/               Локальные проверки и ops helpers
.github/workflows/     CI/CD workflows
```

## Быстрые проверки

Проверить структуру репозитория:

```bash
./scripts/check-structure.sh
```

Отрендерить Kubernetes overlay:

```bash
kubectl kustomize k8s/overlays/dev
kubectl kustomize k8s/overlays/les13
kubectl kustomize k8s/platform/kubernetes-dashboard
kubectl kustomize k8s/platform/loki-grafana
```

Проверить Ansible playbook:

```bash
ansible-playbook --syntax-check -i ansible/inventories/prod/hosts.ini ansible/playbooks/bootstrap-kubernetes.yml
```

## Текущая цель

Основная целевая площадка сейчас:

- host: `Curie`
- IP: `77.223.121.143`
- SSH user: `ops` для обычных операций, `root` только если нужен прямой break-glass доступ
- домен: `https://finguide.les13.tech`
- dev-домен: `https://finguide-dev.les13.tech`
- Kubernetes: single-node k3s
- ingress: ingress-nginx на host ports `80/443`
- TLS: cert-manager + Let's Encrypt
- storage: k3s local-path
- observability: Loki, Promtail и Grafana в отдельном namespace `loki-grafana`

Terraform сейчас не используется для установки k3s на Curie. Сервер уже существует, поэтому host bootstrap выполняется Ansible playbook'ом. Terraform стоит добавлять, когда репозиторий начнет управлять внешними ресурсами: VM, DNS, firewall/security groups, volumes или managed registry/secrets.

## Первый деплой

1. `finguide-be` и `finguide-web` публикуют образы в GHCR.
2. В `finguide-ops` запускается нужный deploy workflow и передаются image tags.
3. GitHub Actions рендерит overlay, подменяет tags и применяет манифесты в cluster.
4. Backend работает под context path `/finguide-api`, Keycloak под `/auth`, frontend под `/fg/` (`/` редиректит на `/fg/`).
5. Ansible используется только для bootstrap node и host-level операций.
