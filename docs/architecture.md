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

The current target is a small Kubernetes distribution such as MicroK8s or k3s. The manifests are distribution-neutral. Ansible bootstrap tasks can be adjusted for the chosen distribution without changing app deployment contracts.

## Non-Goals

- No application `systemd` deployment.
- No Terraform until cloud resources or repeatable infrastructure provisioning require it.
- No secrets committed to git.
