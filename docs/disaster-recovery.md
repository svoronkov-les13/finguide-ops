# Disaster Recovery

## Цели

- Восстановить сервис после неудачного деплоя.
- Восстановить состояние приложения после потери данных.
- Пересобрать Kubernetes node по документированным шагам.

## Что нужно бэкапить

До публичного запуска надо зафиксировать процедуры для:

- database dumps и retention policy;
- Keycloak realm export и client configuration;
- Kubernetes secrets backup;
- persistent volumes backup;
- решение по backup observability PVC: `loki-grafana` хранит диагностические логи, но не является source of truth для приложения;
- GitHub Actions secrets inventory.

Secret values нельзя коммитить в этот репозиторий.

## Восстановление Curie/k3s

1. Проверить доступ к host:

```bash
ssh ops@finguide.les13.tech
```

2. Проверить текущего bootstrap-пользователя. Штатный пользователь для host-level операций — `ops` с passwordless sudo.

3. Запустить bootstrap из `finguide-ops`:

```bash
ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/bootstrap-kubernetes.yml
```

4. Проверить node и system namespaces:

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

5. Восстановить secrets:

```bash
kubectl -n finguide get secrets
```

Если secret'ов нет, создать `finguide-api-secrets`, `finguide-web-secrets`, `keycloak-secrets` из внешнего хранилища.

6. Восстановить persistent data:

- `finguide-api-data`
- `finguide-api-postgres-data`
- `keycloak-postgres-data`

7. Применить overlay:

```bash
kubectl apply -k k8s/overlays/les13
```

8. Проверить rollout и внешний доступ по `docs/runbook.md`.

## Восстановление dev-контура

Dev-контур считается менее ценным, чем основной `les13`. Если нет специальных причин сохранять данные, быстрее пересоздать его:

```bash
kubectl delete namespace finguide-dev
kubectl apply -k k8s/overlays/dev
```

После пересоздания заново завести dev secrets в namespace `finguide-dev` и проверить `https://finguide-dev.les13.tech`.

## Общий порядок восстановления

1. Починить или заново подготовить Kubernetes node.
2. Восстановить cluster add-ons: ingress-nginx, cert-manager, storage, Dashboard и observability.
3. Восстановить namespaces и secrets.
4. Восстановить database и identity provider state.
5. Задеплоить FinGuide из `finguide-ops`.
6. Выполнить health checks из `docs/runbook.md`.

Platform add-ons из git:

```bash
kubectl apply -k k8s/platform/kubernetes-dashboard
kubectl apply -k k8s/platform/loki-grafana
```

Loki logs можно не восстанавливать, если задача — вернуть приложение в работу. Восстанавливать PVC `loki-grafana` имеет смысл только если нужны старые диагностические логи для расследования.

## Drill checklist

- [ ] Восстановить `les13` в чистый namespace/cluster.
- [ ] Проверить API health endpoint.
- [ ] Проверить, что web ходит в API.
- [ ] Проверить login flow через Keycloak.
- [ ] Проверить rollback procedure.
