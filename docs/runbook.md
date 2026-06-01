# Runbook

## Deploy

Use the `Deploy FinGuide` workflow from this repository.

Inputs:

- `environment`: `demo` or `prod`
- `api_image_tag`: API image tag in GHCR
- `web_image_tag`: web image tag in GHCR

The workflow renders the selected kustomize overlay, updates image tags, and applies it to the target cluster.

## Manual Render

```bash
kubectl kustomize k8s/overlays/demo
kubectl kustomize k8s/overlays/prod
```

## Health Checks

```bash
kubectl -n finguide-demo get pods
kubectl -n finguide-demo rollout status deployment/finguide-api
kubectl -n finguide-demo rollout status deployment/finguide-web
```

For production, replace `finguide-demo` with `finguide-prod`.

## Logs

```bash
kubectl -n finguide-demo logs deployment/finguide-api --tail=100
kubectl -n finguide-demo logs deployment/finguide-web --tail=100
```

## Rollback

```bash
kubectl -n finguide-demo rollout undo deployment/finguide-api
kubectl -n finguide-demo rollout undo deployment/finguide-web
```

For production, verify impact and database compatibility before rollback.

## Restart

```bash
kubectl -n finguide-demo rollout restart deployment/finguide-api
kubectl -n finguide-demo rollout restart deployment/finguide-web
```
