# Runbook

## Deploy

Use the `Deploy FinGuide` workflow from this repository.

Inputs:

- `environment`: `demo`, `les13`, or `prod`
- `api_image_tag`: API image tag in GHCR
- `web_image_tag`: web image tag in GHCR

The workflow renders the selected kustomize overlay, updates image tags, and applies it to the target cluster.

## Manual Render

```bash
kubectl kustomize k8s/overlays/demo
kubectl kustomize k8s/overlays/les13
kubectl kustomize k8s/overlays/prod
```

## Bootstrap Curie

Run from this repository:

```bash
ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/bootstrap-kubernetes.yml
```

This installs k3s on `ops@161.104.36.83`, writes `/etc/rancher/k3s/config.yaml`, disables bundled Traefik and ServiceLB, installs ingress-nginx, installs cert-manager, and creates the `letsencrypt-prod` ClusterIssuer.

## Health Checks

```bash
kubectl -n finguide-demo get pods
kubectl -n finguide-demo rollout status deployment/finguide-api
kubectl -n finguide-demo rollout status deployment/finguide-web
```

For les13, use namespace `finguide` and deployments `finguide-api` / `finguide-web`. For production, replace `finguide-demo` with `finguide-prod`.

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
