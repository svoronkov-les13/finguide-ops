# Deployment Contract

## Application Repositories

`finguide-be` and `finguide-web` are responsible for:

- Building Docker images.
- Running application tests.
- Publishing images to GitHub Container Registry.
- Maintaining `.env.example` and app-local deployment notes.

They are not responsible for Kubernetes environment orchestration.

## Ops Repository

`finguide-ops` is responsible for:

- Kubernetes manifests and overlays.
- Helm chart packaging.
- GitHub Actions deployment workflow.
- Host bootstrap automation.
- Operational docs and runbooks.

## Image Names

```text
ghcr.io/svoronkov-les13/finguide-api:<tag>
ghcr.io/svoronkov-les13/finguide-web:<tag>
```

Tags should be immutable for production.

## Runtime Configuration

Runtime configuration is injected through Kubernetes ConfigMaps and Secrets. Secret values are managed outside git.
