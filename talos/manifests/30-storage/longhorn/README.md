# Longhorn Storage — Distributed HA Block Storage

Distributed, replicated block storage for high-availability workloads.

## ✅ Status: NOW WORKS WITH CILIUM!

Previously disabled due to kube-proxy incompatibility with Cilium.
**This is now fixed!** Longhorn works perfectly with Cilium minimal and full configs.

See [UPGRADE_NOTES.md](../../UPGRADE_NOTES.md) for Talos extension requirements.

## 🚀 Quick Enable

```hcl
# In talos/main.tf, uncomment:
longhorn = "manifests/30-storage/longhorn/longhorn.yaml"

# Deploy:
tofu apply
```

## 📋 Files in This Directory

- `longhorn.yaml` — Main Longhorn operator and components
- `longhorn-namespace.yaml` — Longhorn namespace
- `longhorn-values-minimal.yaml` — Minimal Helm values
- `longhorn-values.yaml` — Full Helm values
- `longhorn-storage-classes.yaml` — Storage class definitions (3x replication)
- `longhorn-recurring-jobs.yaml` — Snapshot and backup schedules
- `longhorn-grafana-dashboard.yaml` — Monitoring dashboard

## ✅ Prerequisites

### Talos Extensions

Nodes **MUST** have iscsi-tools extension:

```bash
# Check node extensions
talosctl --nodes <node-ip> get extensions

# Should see:
# - siderolabs/iscsi-tools
# - siderolabs/util-linux-tools
```

If missing: Upgrade Talos with correct schematic
```bash
# See talos/UPGRADE_NOTES.md for details
```

### Network

- Cilium must be deployed (it is by default)
- Network connectivity between nodes required
- Sufficient disk space on each node

## 🎯 What It Provides

- **3x Replication**: Each volume replicated across 3 nodes
- **HA**: Volume survives single node failure
- **Cross-node Migration**: Volumes can move between nodes
- **Snapshots**: Point-in-time copies
- **Backups**: Automatic S3/MinIO backups
- **CLI & UI**: Management console
- **Monitoring**: Metrics for Prometheus/Grafana

## 🔧 Storage Classes

```yaml
# Created automatically:
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "3"  # 3 copies
```

### Create PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-volume
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

## 📊 Monitoring

### Access Longhorn UI

```bash
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
# http://localhost:8000
```

### Grafana Dashboard

Dashboard pre-configured showing:
- Volume health
- Replica status
- Backup history
- Usage metrics

## 💾 Backup Strategy

Configure automatic backups to MinIO:

```bash
# Via Longhorn UI:
# 1. Settings → Backup
# 2. Backup Target: s3://longhorn-backups@us-east-1/
# 3. Create recurring backup: Daily at 2 AM
# 4. Retention: 30 days
```

### Test Backup

```bash
# Create test volume
kubectl create pvc test --size 5Gi

# Add test file
kubectl run -it test --image=busybox -- sh
# cp /etc/hostname /mnt/test/

# Backup
# (Via UI or recurring job)

# Verify restore
# Longhorn UI → Backups → Restore
```

## 🧪 Verification

```bash
# Check Longhorn running
kubectl get pods -n longhorn-system

# Check volumes
kubectl get volumes -n longhorn-system

# Check storage class
kubectl get sc longhorn

# Check replicas (should be 3)
kubectl get volumes -n longhorn-system -o jsonpath='{.items[0].status.replicas}'
```

## 🚨 Troubleshooting

### Longhorn Manager Crashes

**Error**: `iscsiadm: No such file or directory`

**Solution**: Missing iscsi-tools extension on node

```bash
# Check extension
talosctl --nodes <ip> get extensions | grep iscsi

# If missing, upgrade Talos with correct schematic
# See talos/UPGRADE_NOTES.md
```

### PVC Stuck in Pending

```bash
# Check Longhorn manager
kubectl logs -n longhorn-system deploy/longhorn-manager

# Check provisioner
kubectl logs -n longhorn-system deploy/longhorn-provisioner

# Describe PVC
kubectl describe pvc <name>
```

### Replication Degraded

```bash
# Check volume status
kubectl get volumes -n longhorn-system -o wide

# Check replicas
kubectl get replicas -n longhorn-system

# View Longhorn UI for detailed status
```

## 📚 More Info

- [Longhorn Docs](https://longhorn.io/docs/)
- [Storage Classes](https://longhorn.io/docs/latest/advanced-resource-management/storage-class/)
- [Backups](https://longhorn.io/docs/latest/snapshots-and-backups/backup-and-restoration/)
- [High Availability](https://longhorn.io/docs/latest/high-availability/)

---

See [30-storage/README.md](../README.md) for storage options comparison.
