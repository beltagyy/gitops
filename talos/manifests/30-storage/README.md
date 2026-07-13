# 30-Storage — Storage Backends & Volumes

This directory contains storage solution manifests. Choose one or combine for different workload types.

## 📦 Available Storage Solutions

### Longhorn (Distributed Block Storage) ⭐ Recommended
**Status**: ✅ Stable & tested with Cilium

Distributed, replicated block storage perfect for high-availability workloads.

**Use when**:
- Need HA across multiple nodes
- Running stateful apps (databases, message queues)
- Want automated backups
- Need cross-node volume migration

**Enable**:
```hcl
# In talos/main.tf
longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
```

**See**: `longhorn/README.md`

### OpenEBS (Local Persistent Volumes)
**Status**: ✅ High-performance

Local storage with minimal overhead, best for performance-critical workloads.

**Use when**:
- Need maximum performance
- Can tolerate loss of single node data
- Running local databases, caches
- Don't need cross-node HA

**Enable**:
```hcl
# In talos/main.tf
openebs = "manifests/30-storage/openebs/openebs.yaml"
```

**See**: `openebs/README.md`

### MinIO (S3-Compatible Object Storage)
**Status**: ✅ Production-ready

S3-compatible object storage for files, backups, archives.

**Use when**:
- Need object storage (files, images, etc)
- Want S3-compatible API
- Need backup target for Longhorn
- Running apps that use S3

**Enable**:
```hcl
# In talos/main.tf
minio = "manifests/30-storage/minio/minio.yaml"
```

**See**: `minio/README.md`

### Rook-Ceph (Distributed Storage)
**Status**: ⚠️ Complex, requires careful tuning

Enterprise distributed storage with advanced features.

**Use when**:
- Need advanced storage features
- Experienced with Ceph
- Have dedicated storage hardware

**Enable**:
```hcl
# In talos/main.tf
"rook-ceph-operator" = "manifests/30-storage/rook-ceph/rook-ceph-operator.yaml"
"rook-ceph-cluster" = "manifests/30-storage/rook-ceph/rook-ceph-cluster.yaml"
```

**See**: `rook-ceph/README.md`

## 🎯 Quick Decision Guide

| Need | Solution | Performance | HA | Setup |
|------|----------|-------------|----|----|
| General purpose | Longhorn | Good | ✅ | Easy |
| Max performance | OpenEBS | Excellent | ❌ | Easy |
| Object storage | MinIO | Good | ✅ | Easy |
| Enterprise | Rook-Ceph | Excellent | ✅ | Hard |

## 🚀 Common Scenarios

### Single Node Cluster
Use OpenEBS for local storage:
```hcl
openebs = "manifests/30-storage/openebs/openebs.yaml"
```

### Multi-Node HA Cluster (Recommended)
Use Longhorn for replicated volumes:
```hcl
longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
```

### Complete Storage Stack
Combine Longhorn + MinIO for flexibility:
```hcl
longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
minio = "manifests/30-storage/minio/minio.yaml"
```

## 📝 Storage Classes

Check available storage classes:
```bash
kubectl get storageclass
```

Example output:
```
NAME                      PROVISIONER
longhorn (default)        driver.longhorn.io
openebs-hostpath          openebs.io/local
rook-ceph-block           ceph.rook.io/block
```

## 💾 Using Storage

### Create Persistent Volume Claim (PVC)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

### Use in Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: my-app
    image: my-app:latest
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-app-data
```

## ⚙️ Operations

### Check Storage Health

```bash
# Longhorn
kubectl get volumes -n longhorn-system
kubectl get nodes -n longhorn-system

# OpenEBS
kubectl get pvc -A
kubectl get pv

# MinIO
kubectl get pods -n minio
kubectl port-forward -n minio svc/minio-console 9001:9001
```

### Backup Longhorn Volumes

Longhorn supports S3 backups (e.g., to MinIO):

1. Configure backup target in Longhorn UI
2. Set to: `s3://longhorn-backups@us-east-1/`
3. Configure recurring backups per volume

### Monitor Storage Usage

```bash
# Check PVC usage
kubectl get pvc -A

# Longhorn UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
# Visit http://localhost:8000

# Storage metrics in Prometheus/Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

## 🔗 Component Dependencies

```
30-storage/
├─ longhorn/       → Depends on: 10-networking, 00-namespaces
├─ openebs/        → Depends on: 10-networking, 00-namespaces
├─ minio/          → Depends on: 10-networking, 00-namespaces
└─ rook-ceph/      → Depends on: 10-networking, 00-namespaces, disk access
```

All storage solutions depend on:
- ✅ 00-namespaces deployed
- ✅ 10-networking (Cilium) working
- ✅ Sufficient disk space on nodes

## 🐛 Troubleshooting

### PVC Stuck in Pending

```bash
# Check storage class exists
kubectl get storageclass

# Check provisioner is running
kubectl get pods -A | grep -E "longhorn|openebs"

# Check PVC events
kubectl describe pvc <pvc-name> -n <namespace>
```

### Longhorn Manager Crashes

Error: `iscsiadm: No such file or directory`

**Solution**: Node needs iscsi-tools extension

```bash
# Check in talos/main.tf that iscsi-tools is in talos_extensions
talos_extensions = [
  "siderolabs/iscsi-tools",  # <- Must be present
  # ...
]
```

### Storage Performance Issues

```bash
# Check pod resource limits
kubectl describe pod <pod-name> -n <namespace>

# Monitor storage I/O
# Varies by storage backend (see component README)

# Check for pod evictions
kubectl get events -A --sort-by='.lastTimestamp'
```

## 📚 More Info

- [Longhorn Documentation](https://longhorn.io/docs/)
- [OpenEBS Documentation](https://openebs.io/docs/)
- [MinIO Documentation](https://docs.min.io/)
- [Rook Documentation](https://rook.io/docs/)
- [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

See individual component READMEs for detailed configuration and troubleshooting.
