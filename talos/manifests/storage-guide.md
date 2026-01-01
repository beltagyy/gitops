# Storage Class Selection Guide

## Available Storage Options

### 1. OpenEBS LocalPV (Already Installed)
- `openebs-hostpath` - Uses host path for storage
- `openebs-device` - Uses block devices

### 2. Longhorn (To be installed)
- `longhorn` - Replicated distributed storage

## When to Use Which Storage Class

### Use **openebs-hostpath** for:
```yaml
# High-performance database example
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
spec:
  storageClassName: openebs-hostpath
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
```
- PostgreSQL, MySQL, MongoDB (with app-level replication)
- Redis, Memcached
- Prometheus metrics storage
- Build caches (CI/CD)
- Logs and temporary data

**Why**: Maximum performance, direct disk I/O

### Use **longhorn** for:
```yaml
# High-availability application example
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wordpress-data
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```
- WordPress, Drupal, Ghost blogs
- GitLab
- MinIO (if not using native replication)
- Stateful apps that need to move between nodes
- Apps requiring backups and snapshots

**Why**: High availability, can survive node failures

## Default Storage Class

Set Longhorn as default for general use:
```bash
# Make Longhorn default
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Remove default from OpenEBS (if set)
kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

Or keep OpenEBS as default for performance:
```bash
# Make OpenEBS default
kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## Resource Allocation by Storage Type

### Recommended Node Labels:
```bash
# High-performance storage nodes (for OpenEBS)
kubectl label nodes preprod-worker-01 storage-type=high-performance

# Distributed storage nodes (for Longhorn - all workers)
kubectl label nodes preprod-worker-{01,02,03} storage-type=distributed
```

## Quick Reference Table

| Workload Type | Storage Class | Replicas | Performance | HA |
|---------------|---------------|----------|-------------|-----|
| PostgreSQL with streaming replication | openebs-hostpath | 3 | ⚡⚡⚡ | ✅ (app-level) |
| MySQL standalone | longhorn | 1 | ⚡⚡ | ✅ (storage-level) |
| Redis cluster | openebs-hostpath | 3 | ⚡⚡⚡ | ✅ (app-level) |
| Redis standalone | longhorn | 1 | ⚡⚡ | ✅ (storage-level) |
| WordPress | longhorn | 1 | ⚡⚡ | ✅ |
| Prometheus | openebs-hostpath | 1 | ⚡⚡⚡ | ⚠️ (can rebuild) |
| MinIO (3+ nodes) | openebs-hostpath | 4+ | ⚡⚡⚡ | ✅ (app-level) |
| MinIO (single) | longhorn | 1 | ⚡⚡ | ✅ (storage-level) |

## Example: Database with App-Level Replication

```yaml
---
apiVersion: v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  replicas: 3  # App provides HA
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      storageClassName: openebs-hostpath  # Fast local storage
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Gi
```

## Example: Single Instance Needing HA

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-data
spec:
  storageClassName: longhorn  # Storage provides HA
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
```

## Summary

**Keep both!** They complement each other:
- **OpenEBS**: Speed + App-level replication = Best performance
- **Longhorn**: Storage-level replication = Easy HA for single instances

Choose based on your workload requirements.
