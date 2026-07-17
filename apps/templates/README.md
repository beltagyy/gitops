# App Deployment Templates

Reusable Kubernetes manifests for deploying applications to the cluster.

## Quick Start

```bash
# Create a new app from template
./create-app.sh myapp default myregistry/myapp:v1

# Deploy it
kubectl apply -R -f apps/myapp/

# Or deploy all apps
make apps-deploy
```

## Template Files

| File | Description |
|------|-------------|
| `deployment.yaml` | Deployment with health checks, resource limits |
| `service.yaml` | ClusterIP service |
| `ingress.yaml` | Traefik ingress with TLS |

## What's Included

- **Health checks:** liveness + readiness probes on `/health`
- **Resource limits:** CPU/memory requests and limits
- **Labels:** `managed-by: gitops` for filtering
- **TLS:** cert-manager integration via Traefik

## Adding a New App

1. Run `./create-app.sh <name> <namespace> <image>`
2. Edit the generated manifests
3. Commit and push
4. ArgoCD syncs automatically (if configured)
