# Local Development Environment (Kind)

Quick local cluster for development and testing using Kind (Kubernetes in Docker).

## 🎯 Use Case

- Testing GitOps workflows locally
- Rapid iteration without cloud resources
- Learning Kubernetes and GitOps
- CI/CD pipeline testing

## ⚙️ Specifications

| Aspect | Value |
|--------|-------|
| **Cluster Type** | Kind (Kubernetes in Docker) |
| **Nodes** | 1 (can scale to 3) |
| **CNI** | Cilium minimal |
| **Storage** | LocalPV (ephemeral) |
| **Network** | localhost |
| **Memory** | ~4GB recommended |
| **Disk** | ~20GB free |

## 🚀 Setup

See `../../scripts/kind-setup.sh` for automated setup.

Or manually:

```bash
# Install Kind
brew install kind  # macOS
# or use https://kind.sigs.k8s.io/docs/user/quick-start/

# Create cluster
kind create cluster --name gitops-local

# Verify
kubectl get nodes
```

## 📝 Configuration

### Minimal Stack (Fast)
```yaml
# In talos/main.tf or use envs/local/terraform.tfvars
components:
  - namespaces
  - cilium-minimal
  - cert-manager
```

### Full Stack (Complete Testing)
Add to minimal:
```yaml
  - openebs
  - prometheus-grafana
  - loki
  - headlamp
  - portainer
```

## 🔄 Workflow

### Deploy App

```bash
# Apply manifests
kubectl apply -f apps/my-app/

# Or use ArgoCD (if enabled)
argocd app create my-app --repo https://github.com/you/gitops --path apps/my-app
```

### Access Services

```bash
# Port-forward
kubectl port-forward svc/my-app 8080:80

# Or setup local ingress
# Edit /etc/hosts: 127.0.0.1 myapp.local
# Then: http://myapp.local
```

### Check Logs

```bash
# Pod logs
kubectl logs deploy/my-app

# Stream logs
kubectl logs -f deploy/my-app

# View in Grafana (if enabled)
kubectl port-forward svc/grafana 3000:3000
# http://localhost:3000
```

## ⏹️ Cleanup

```bash
# Delete cluster
kind delete cluster --name gitops-local

# Or just reset (keep Kind running)
kubectl delete all --all -A
```

## 💡 Tips

1. **Use small resource limits** — Local machine has limited resources
2. **Enable only needed components** — Faster startup
3. **Delete completed jobs** — Free up PVs
4. **Monitor memory usage** — `docker stats`
5. **Take snapshots before big changes** — Easy rollback

## 📚 More Info

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [LocalPV Documentation](https://openebs.io/docs/)
- [Local Storage Options](../../talos/manifests/30-storage/README.md)

---

Last updated: 2026-07-13
