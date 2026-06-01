# FinGuide Ops

Infrastructure, deployment, and runbooks for FinGuide.

Product code stays in the application repositories:

- `finguide-be` builds and publishes the API image.
- `finguide-web` builds and publishes the web image.
- `finguide-ops` owns Kubernetes manifests, Helm charts, node bootstrap, environment documentation, and operational procedures.

## Operating Model

FinGuide is Kubernetes-first. Application services are not deployed through app-level `systemd` units. `systemd` may exist underneath Kubernetes, runners, or host services, but FinGuide API and web workloads run as Kubernetes workloads.

Images are published to GitHub Container Registry:

- `ghcr.io/svoronkov-les13/finguide-api:<tag>`
- `ghcr.io/svoronkov-les13/finguide-web:<tag>`

Deployments are driven from this repository through GitHub Actions.

## Layout

```text
docs/                  Architecture, environments, runbooks, recovery
k8s/base/              Shared Kubernetes resources
k8s/overlays/demo/     Demo environment customization
k8s/overlays/prod/     Production environment customization
helm/                  Helm chart skeletons for app and stack packaging
ansible/               Host bootstrap for Kubernetes nodes
scripts/               Local validation and operations helpers
.github/workflows/     CI/CD workflows
```

## Quick Checks

Run the repository structure check:

```bash
./scripts/check-structure.sh
```

Render the demo overlay when `kubectl` includes kustomize support:

```bash
kubectl kustomize k8s/overlays/demo
```

## First Deploy Shape

1. `finguide-be` and `finguide-web` publish images to GHCR.
2. This repository updates Kubernetes image tags.
3. GitHub Actions deploys `k8s/overlays/demo` or `k8s/overlays/prod`.
4. Ansible is used only for node bootstrap and host-level operations.
