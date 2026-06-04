# Architecture

## Responsibilities

`finguide-ops` owns the infrastructure boundary for FinGuide:

- Kubernetes manifests and environment overlays.
- Helm chart skeletons for repeatable packaging.
- GitHub Actions deployment workflows.
- Host bootstrap through Ansible.
- Operational documentation for deploy, rollback, health checks, backups, and disaster recovery.

Application repositories own source code, tests, Dockerfiles, and image publishing.

## Deployment Flow

```text
finguide-be / finguide-web
  -> build Docker image
  -> push to GHCR
  -> finguide-ops GitHub Actions deploy
  -> Kubernetes overlay
  -> demo or prod namespace
```

## Runtime Components

- `finguide-api`: backend API deployment and service.
- `finguide-web`: frontend deployment and service.
- `finguide-stack`: umbrella Helm chart for installing both app components together.
- Ingress, certificates, storage, database, and identity provider integration are environment-level concerns documented here before automation is added.

## Kubernetes Distribution

The current target for `finguide.les13.tech` is single-node k3s on Curie (`161.104.36.83`). k3s runs with bundled Traefik and ServiceLB disabled, local-path storage enabled, ingress-nginx bound to host ports 80/443, and cert-manager issuing Let's Encrypt certificates.

The application manifests remain standard Kubernetes resources. Environment overlays decide hostnames, image tags, ingress, and replica counts.

## Non-Goals

- No application `systemd` deployment.
- No Terraform until cloud resources or repeatable infrastructure provisioning require it; Curie already exists, so Ansible owns node bootstrap for now.
- No secrets committed to git.
