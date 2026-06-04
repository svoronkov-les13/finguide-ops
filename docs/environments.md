# Environments

## Demo

Purpose:

- Validate application deployments before production.
- Exercise migrations, ingress rules, and environment variables.
- Provide a stable preview target.

Kubernetes namespace:

- `finguide-demo`

Overlay:

- `k8s/overlays/demo`

Image tag policy:

- Usually `main`, `develop`, or a short SHA.
- Should be explicit for reproducibility.

## Production

Purpose:

- Serve real users.
- Prefer pinned release tags or immutable SHAs.

Kubernetes namespace:

- `finguide-prod`

Overlay:

- `k8s/overlays/prod`

Image tag policy:

- Release tag or immutable SHA.
- Avoid mutable `latest`.

## les13

Purpose:

- Run the current FinGuide target at `https://finguide.les13.tech`.
- Keep the deployment simple on a single existing server.

Host:

- `curie`, `161.104.36.83`
- SSH user: `ops`

Kubernetes:

- k3s single-node
- ingress-nginx on host network for ports 80 and 443
- cert-manager with `letsencrypt-prod`
- local-path storage

Kubernetes namespace:

- `finguide`

Overlay:

- `k8s/overlays/les13`

Image tag policy:

- `les13` by default, or an explicit immutable tag passed to the deploy workflow.

## Required Secret Names

These secrets are referenced by manifests but must be created outside git:

- `finguide-api-secrets`
- `finguide-web-secrets`
- `keycloak-secrets`

Document each key here as it becomes known. Do not commit secret values.
