# 00-Namespaces — Cluster Foundation

Creates Kubernetes namespaces used by other components.

## 📦 Namespaces Created

- `kube-system` — Core Kubernetes components
- `kube-public` — Public API endpoints
- `kube-node-lease` — Node heartbeat leases
- `default` — Default namespace for user workloads
- `traefik` — Traefik ingress controller
- `longhorn-system` — Longhorn storage
- `monitoring` — Prometheus, Grafana, Loki
- `portainer` — Portainer management UI
- `argocd` — ArgoCD GitOps
- `jenkins` — Jenkins CI/CD
- `minio` — MinIO object storage
- `logging` — Log aggregation

## 🚀 Deployment

Always deployed first — no dependencies.

```bash
tofu apply  # In main.tf, cluster_inline_manifests
```

## 📝 Add New Namespace

Edit `namespaces.yaml` and add:

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
  labels:
    name: my-app
```

## ✅ Verify

```bash
kubectl get namespaces
```

## 🔗 Next Steps

After namespaces are created, other components will deploy into them:
- 10-networking → traefik, kube-system
- 30-storage → longhorn-system, minio
- 40-observability → monitoring
- 50-management → portainer
- 60-gitops → argocd, jenkins
