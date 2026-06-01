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

## Required Secret Names

These secrets are referenced by manifests but must be created outside git:

- `finguide-api-secrets`
- `finguide-web-secrets`

Document each key here as it becomes known. Do not commit secret values.
