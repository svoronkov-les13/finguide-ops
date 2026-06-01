# Disaster Recovery

## Goals

- Restore service after a failed deploy.
- Restore application state after data loss.
- Rebuild a Kubernetes node from documented steps.

## Backup Scope

Track these assets before production launch:

- Database dumps and retention policy.
- Keycloak realm export and client configuration.
- Kubernetes secrets backup procedure.
- Persistent volume backup procedure.
- GitHub Actions secrets inventory.

Secret values must not be committed to this repository.

## Recovery Order

1. Provision or repair Kubernetes node.
2. Restore cluster add-ons: ingress, cert-manager, storage, monitoring.
3. Restore namespaces and secrets.
4. Restore database and identity provider state.
5. Deploy FinGuide from `finguide-ops`.
6. Run health checks from `docs/runbook.md`.

## Drill Checklist

- [ ] Restore demo from backup into a clean namespace.
- [ ] Confirm API health endpoint.
- [ ] Confirm web can reach API.
- [ ] Confirm login flow.
- [ ] Confirm rollback procedure.
