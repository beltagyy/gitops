# Staging Environment

Production-like environment for pre-release validation and testing.

## 🎯 Use Case

- Final validation before production
- Performance & load testing
- Integration testing
- Backup/restore procedures
- Disaster recovery drills

## ⚙️ Specifications

| Aspect | Value |
|--------|-------|
| **Nodes** | 3 (1 control plane + 2 workers) |
| **Network** | 10.198.142.0/24 |
| **CNI** | Cilium minimal |
| **Storage** | Longhorn (HA, replicated) |
| **Observability** | Full stack (Prometheus + Grafana + Loki) |
| **Management** | Headlamp, Portainer |
| **GitOps** | ArgoCD (optional) |

## 🚀 Deployment

Configure similar to dev but with HA storage:

```bash
cd talos/
cp ../envs/staging/terraform.tfvars .
vim terraform.tfvars

tofu apply
```

## 💾 Key Differences from Dev

### Storage: Longhorn (Replicated HA)

```hcl
# In main.tf, enable Longhorn:
longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
```

Longhorn provides:
- Cross-node replication (3x replicas)
- Automatic backups to S3/MinIO
- Volume snapshots
- HA across node failures

### Backup Strategy

```bash
# Configure Longhorn backups via UI:
# 1. Setup backup target (MinIO): s3://longhorn-backups@us-east-1/
# 2. Create recurring backup policy per volume
# 3. Test restore procedures

# Or via CLI:
kubectl patch -n longhorn-system \
  backingimage.longhorn.io/example \
  -p '{"spec":{"backupTargetURL":"s3://bucket@region/"}}'
```

### Enable ArgoCD (Optional)

```hcl
# Uncomment in main.tf:
argocd = "manifests/60-gitops/argocd/argocd.yaml"
"argocd-applications" = "manifests/60-gitops/argocd/argocd-applications.yaml"
```

Then define applications in Git:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: staging-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/you/gitops
    targetRevision: main
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## 📊 Pre-deployment Checklist

Before promoting to production:

- [ ] All services accessible
- [ ] Monitoring working (Prometheus, Grafana)
- [ ] Logs flowing (Loki)
- [ ] Longhorn backups running
- [ ] Load test passed
- [ ] Failover tested (kill a node)
- [ ] Backup restoration verified
- [ ] Security policies applied
- [ ] Documentation updated

## 🧪 Testing Procedures

### Health Check

```bash
# Nodes
kubectl get nodes -o wide

# Services
kubectl get svc -A

# Storage
kubectl get pvc -A
```

### Load Testing

```bash
# Simple load test
kubectl run -it --rm load-test \
  --image=busybox \
  --restart=Never \
  -- sh

# Inside container:
while true; do wget -q -O- http://my-app; done
```

### Failover Testing

```bash
# Reboot a worker node
talosctl --nodes 10.198.142.21 reboot

# Watch cluster recover
kubectl get pods -A --watch

# Verify storage volumes rebalance
kubectl get volumes -n longhorn-system
```

### Backup/Restore Test

```bash
# Create test volume
kubectl create pvc my-test --size 10Gi -n default

# Backup
# (Done via Longhorn UI or recurring jobs)

# Simulate data loss
# Delete and recreate PVC

# Restore from backup
# (Test restoration process)
```

## 🔍 Monitoring & Observability

### Check Cluster Health

```bash
# Prometheus targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Grafana dashboards
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Check storage health
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
```

### Common Queries

```promql
# Pod restart rate
rate(kube_pod_container_status_restarts_total[15m]) > 0

# Storage usage
kubelet_volume_stats_used_bytes

# Network latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

## 🚨 Known Issues & Workarounds

### Longhorn Manager Crashes

**Error**: `iscsiadm: No such file or directory`

**Solution**: Ensure iscsi-tools extension is in Talos schematic.

See [talos/UPGRADE_NOTES.md](../../talos/UPGRADE_NOTES.md)

### Network Latency

**Symptom**: Slow service-to-service communication

**Check**:
```bash
# Ping between pods
kubectl run -it debug --image=busybox -- sh
# ping <pod-ip>
```

## 🧹 Cleanup

```bash
# Graceful shutdown
cd talos/
tofu destroy

# Or just reset
kubectl delete all --all -A
```

## 📈 Scaling to Production

Once staging validation passes:

1. **Create prod environment**
   ```bash
   cp envs/staging/terraform.tfvars envs/prod/
   ```

2. **Adjust for production**
   - Increase replicas
   - Expand storage
   - Add DR site
   - Enable backup offsite

3. **Deploy prod**
   ```bash
   cd talos/
   cp envs/prod/terraform.tfvars .
   tofu apply
   ```

## 📚 More Info

- [Longhorn Documentation](https://longhorn.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Talos Upgrade Guide](../../talos/UPGRADE_NOTES.md)

---

Last updated: 2026-07-13
