# Disaster Recovery

## Цели

- Восстановить сервис после неудачного деплоя.
- Восстановить состояние приложения после потери данных.
- Пересобрать Kubernetes node по документированным шагам.

## Что нужно бэкапить

До production launch надо зафиксировать процедуры для:

- database dumps и retention policy;
- Keycloak realm export и client configuration;
- Kubernetes secrets backup;
- persistent volumes backup;
- GitHub Actions secrets inventory.

Secret values нельзя коммитить в этот репозиторий.

## Восстановление Curie/k3s

1. Проверить доступ к host:

```bash
ssh root@77.223.121.143
```

2. Проверить текущего bootstrap-пользователя. После переустановки ОС используется `root`; если позже вернется `ops`, обновить `ansible/inventories/prod/hosts.ini` и `k3s_kubeconfig_*` в group vars.

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
2. Восстановить cluster add-ons: ingress-nginx, cert-manager, storage.
3. Восстановить namespaces и secrets.
4. Восстановить database и identity provider state.
5. Задеплоить FinGuide из `finguide-ops`.
6. Выполнить health checks из `docs/runbook.md`.

## Drill checklist

- [ ] Восстановить demo или les13 в чистый namespace/cluster.
- [ ] Проверить API health endpoint.
- [ ] Проверить, что web ходит в API.
- [ ] Проверить login flow через Keycloak.
- [ ] Проверить rollback procedure.
