# Terraform

Terraform пока не используется для установки k3s на Curie.

Текущая модель:

- существующий сервер Curie доступен по `ops@finguide.les13.tech`;
- host bootstrap, установка k3s, ingress-nginx и cert-manager выполняются Ansible playbook'ом `ansible/playbooks/bootstrap-kubernetes.yml`;
- Kubernetes workloads применяются через Kustomize overlays и GitHub Actions.

Terraform стоит добавить сюда, когда появится provider-managed infrastructure:

- cloud VM;
- DNS records;
- firewall/security group rules;
- external volumes/object storage;
- managed secrets или registry resources.

Граница ответственности:

- Terraform создает или обновляет внешние инфраструктурные ресурсы.
- Ansible конфигурирует уже созданный host.
- Kustomize/GitHub Actions деплоят приложения в Kubernetes.

Не используем Terraform `remote-exec` для установки k3s на уже существующий сервер: это хуже Ansible по идемпотентности, диагностике и повторному запуску.
