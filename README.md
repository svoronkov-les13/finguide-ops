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

Деплой запускается из этого репозитория через GitHub Actions.

## Структура

```text
docs/                  Архитектура, окружения, runbook'и, восстановление
k8s/base/              Общие Kubernetes-ресурсы
k8s/overlays/demo/     Demo-окружение
k8s/overlays/les13/    Single-node Curie для finguide.les13.tech
k8s/overlays/prod/     Production-окружение
k8s/platform/          Cluster-level ресурсы, например cert-manager issuers
helm/                  Каркасы Helm-чартов для app и stack packaging
ansible/               Bootstrap Kubernetes nodes и host-level операции
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
kubectl kustomize k8s/overlays/demo
kubectl kustomize k8s/overlays/les13
kubectl kustomize k8s/overlays/prod
```

Проверить Ansible playbook:

```bash
ansible-playbook --syntax-check -i ansible/inventories/prod/hosts.ini ansible/playbooks/bootstrap-kubernetes.yml
```

## Текущая цель

Основная целевая площадка сейчас:

- host: `Curie`
- IP: `161.104.36.83`
- SSH user: `ops`
- домен: `https://finguide.les13.tech`
- Kubernetes: single-node k3s
- ingress: ingress-nginx на host ports `80/443`
- TLS: cert-manager + Let's Encrypt
- storage: k3s local-path

## Первый деплой

1. `finguide-be` и `finguide-web` публикуют образы в GHCR.
2. Этот репозиторий выбирает Kubernetes overlay и image tags.
3. GitHub Actions деплоит `k8s/overlays/les13`, `demo` или `prod`.
4. Ansible используется только для bootstrap node и host-level операций.
