# Контракт деплоя

## Репозитории приложения

`finguide-be` и `finguide-web` отвечают за:

- сборку Docker images;
- запуск application tests;
- публикацию images в GitHub Container Registry;
- поддержку `.env.example` и локальных deployment notes.

Они не отвечают за Kubernetes orchestration, host bootstrap и environment-level инфраструктуру.

## Ops-репозиторий

`finguide-ops` отвечает за:

- Kubernetes manifests и overlays;
- Helm packaging;
- GitHub Actions deployment workflows;
- Ansible bootstrap для Kubernetes node;
- operational docs и runbook'и.

## Имена образов

```text
ghcr.io/svoronkov-les13/finguide-api:<tag>
ghcr.io/svoronkov-les13/finguide-web:<tag>
```

Для production лучше использовать immutable tags: release tag или SHA. Для `les13` допустим tag `les13`, если он осознанно используется как текущий deploy target.
Для `dev` по умолчанию используется tag `dev`; для отладки конкретной сборки можно передавать short SHA через workflow inputs.

## GitHub Actions deploy contract

Основные ручные workflows:

- `Deploy finguide-dev`: деплоит `k8s/overlays/dev`, GitHub environment `dev`, namespace `finguide-dev`.
- `Deploy finguide`: деплоит `k8s/overlays/les13`, GitHub environment `les13`, namespace `finguide`.

Оба workflow принимают `api_image_tag` и `web_image_tag`, используют `scripts/deploy-kustomize-overlay.sh`, применяют манифесты через `kubectl` и ждут rollout application deployments и Keycloak.

Обязательный GitHub Actions secret в каждом target environment:

- `KUBECONFIG_B64`: kubeconfig target cluster в base64.

Workflow `Deploy FinGuide Overlay` используется как общий fallback для ручного деплоя любого overlay из списка `demo`, `dev`, `les13`, `prod`.

## Runtime configuration

Runtime configuration передается через Kubernetes ConfigMaps и Secrets.

ConfigMaps можно коммитить, если они не содержат secret values. Secrets создаются вне git:

- вручную через `kubectl`;
- через CI/CD secret store;
- через будущий secret manager, если он будет добавлен.

## Контракт окружения `les13`

Текущий deployment target:

- namespace: `finguide`
- overlay: `k8s/overlays/les13`
- domain: `finguide.les13.tech`
- ingress class: `nginx`
- TLS issuer: `letsencrypt-prod`

Обязательные secret names:

- `finguide-api-secrets` с key `fg-api-db-password`
- `finguide-web-secrets`
- `keycloak-secrets` с keys `db-password`, `admin-username`, `admin-password`

Secret values должны быть заведены до деплоя приложения.

## Контракт окружения `dev`

Dev deployment target:

- namespace: `finguide-dev`
- overlay: `k8s/overlays/dev`
- domain: `finguide-dev.les13.tech`
- ingress class: `nginx`
- TLS issuer: `letsencrypt-prod`
- Keycloak realm: `finguide-dev`

Dev использует отдельный Keycloak и отдельный PostgreSQL. Это позволяет свободно менять realm/client settings, redirect URI, roles и test users без риска для основного `les13`.

Обязательные secret names в namespace `finguide-dev`:

- `finguide-api-secrets` с key `fg-api-db-password`
- `finguide-web-secrets`
- `keycloak-secrets` с keys `db-password`, `admin-username`, `admin-password`

Имена такие же, как в `les13`, но namespace другой. Значения secret'ов должны быть dev-отдельными.
