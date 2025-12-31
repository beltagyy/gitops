# Longhorn Elite Storage Configuration

This directory contains an elite-level Longhorn distributed block storage configuration with advanced features for high availability, performance optimization, automated backups, and comprehensive monitoring.

## Features Enabled

### Core Storage
- **Distributed Block Storage**: Replicated across multiple nodes for HA
- **Dynamic Provisioning**: Automatic PV provisioning via CSI
- **Volume Expansion**: Online volume expansion without downtime
- **Snapshot Support**: CSI snapshots and volume clones
- **Data Locality**: Optional data locality for database workloads

### High Availability
- **Multiple Replicas**: 1-3 replicas per storage class
- **Fast Replica Rebuild**: Accelerated rebuild after node failures
- **Auto-Balance**: Automatic replica distribution across nodes
- **Zone/Disk Anti-Affinity**: Replicas distributed across zones and disks
- **Auto-Salvage**: Automatic recovery from failures

### Backup & Disaster Recovery
- **Automated Snapshots**: Hourly, daily, weekly, monthly schedules
- **Local Backups**: Store backups locally or on NFS
- **S3 Backups**: Optional S3-compatible backup targets (MinIO, AWS S3)
- **Snapshot Retention**: Configurable retention policies
- **Volume Cloning**: Clone volumes for dev/test
- **Cross-Cluster DR**: Backup and restore across clusters

### Performance Optimization
- **SSD/NVMe Support**: Disk selectors for high-performance storage
- **Data Locality**: Reduce network latency for databases
- **Fast Rebuild**: Quick replica reconstruction
- **Concurrent Limits**: Tuned for maximum throughput
- **Filesystem Trim**: Automatic space reclamation

### Monitoring & Observability
- **Prometheus Metrics**: Full metrics export with ServiceMonitor
- **Grafana Dashboard**: Pre-built dashboard for IOPS, latency, capacity
- **Built-in UI**: Web-based management interface
- **Volume Health Monitoring**: Real-time health status
- **Capacity Planning**: Storage usage and trends

## File Structure

```
manifests/
├── longhorn-values.yaml                    # Helm values for elite configuration
├── longhorn.yaml                           # Generated Longhorn manifests (5408 lines)
├── longhorn-storage-classes.yaml           # 7 storage class profiles
├── longhorn-recurring-jobs.yaml            # Automated snapshot/backup jobs
├── longhorn-grafana-dashboard.yaml         # Grafana dashboard ConfigMap
└── LONGHORN-ELITE-README.md                # This file
```

## Storage Class Profiles

### 1. High Performance (`longhorn-high-performance`)
- **Replicas**: 1
- **Data Locality**: Enabled
- **Disk**: SSD/NVMe only
- **Best For**: Databases (PostgreSQL, MySQL), Redis, high-IOPS apps
- **Snapshots**: Hourly

### 2. High Availability (`longhorn-high-availability`) ⭐ Default
- **Replicas**: 3
- **Data Locality**: Disabled
- **Anti-Affinity**: Zone + Disk
- **Reclaim Policy**: Retain
- **Best For**: Critical production workloads, stateful services
- **Snapshots**: Daily + Weekly backups

### 3. Balanced (`longhorn-balanced`)
- **Replicas**: 2
- **Anti-Affinity**: Soft
- **Best For**: General applications, web servers
- **Snapshots**: Daily

### 4. Cost Optimized (`longhorn-cost-optimized`)
- **Replicas**: 1
- **Data Locality**: Enabled
- **Best For**: Dev/test, ephemeral data, CI/CD
- **Snapshots**: None

### 5. Database Optimized (`longhorn-database`)
- **Replicas**: 3
- **Data Locality**: Enabled
- **Disk**: SSD/NVMe only
- **Node Selector**: `workload=database`
- **Volume Binding**: WaitForFirstConsumer
- **Reclaim Policy**: Retain
- **Best For**: PostgreSQL, MySQL, MongoDB, Cassandra
- **Snapshots**: Hourly + Daily backups

### 6. Fast Rebuild (`longhorn-fast-rebuild`)
- **Replicas**: 2
- **Fast Rebuild**: Enabled
- **Best For**: Stateful apps, message queues
- **Snapshots**: Daily

### 7. Snapshot Optimized (`longhorn-snapshot-optimized`)
- **Replicas**: 2
- **Best For**: Development, testing, versioning
- **Snapshots**: Hourly + Daily

## Installation

### Prerequisites

1. **Talos Kubernetes Cluster**: Running and healthy
2. **Storage**: Each node should have:
   - Disk space for Longhorn (recommend 100GB+ per node)
   - Path `/var/lib/longhorn` available
3. **iSCSI Support**: Already included in Talos
4. **Helm**: Installed on your machine

### Installation Steps

#### 1. Install Longhorn

```bash
kubectl apply -f manifests/longhorn.yaml
```

Wait for Longhorn to be ready:
```bash
kubectl -n longhorn-system rollout status deployment/longhorn-driver-deployer
kubectl -n longhorn-system rollout status deployment/longhorn-ui
```

#### 2. Apply Storage Classes

```bash
kubectl apply -f manifests/longhorn-storage-classes.yaml
```

Verify storage classes:
```bash
kubectl get storageclass
```

#### 3. Configure Recurring Jobs

```bash
kubectl apply -f manifests/longhorn-recurring-jobs.yaml
```

Verify recurring jobs:
```bash
kubectl get recurringjobs -n longhorn-system
```

#### 4. Install Grafana Dashboard (optional)

```bash
kubectl apply -f manifests/longhorn-grafana-dashboard.yaml
```

#### 5. Access Longhorn UI

Port-forward the UI:
```bash
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
```

Or configure ingress (update hostname in `longhorn-values.yaml`):
```yaml
ingress:
  enabled: true
  host: longhorn.yourdomain.com
```

Open: http://localhost:8080 or https://longhorn.yourdomain.com

## Configuration

### Configure Backup Target

#### Option 1: Local NFS Backup

1. Set up NFS server or use existing one
2. Update Longhorn settings:

```bash
kubectl -n longhorn-system edit settings.longhorn.io backup-target
```

Set value to:
```
nfs://nfs-server.example.com:/longhorn-backups
```

#### Option 2: S3-Compatible Backup (MinIO, AWS S3)

1. Create S3 credentials secret:

```bash
kubectl create secret generic s3-backup-secret \
  -n longhorn-system \
  --from-literal=AWS_ACCESS_KEY_ID=your-access-key \
  --from-literal=AWS_SECRET_ACCESS_KEY=your-secret-key \
  --from-literal=AWS_ENDPOINTS=https://s3.amazonaws.com \
  --from-literal=AWS_REGION=us-east-1
```

2. Update backup target:

```bash
kubectl -n longhorn-system edit settings.longhorn.io backup-target
```

Set value to:
```
s3://bucket-name@region/path
```

3. Set backup target credential secret:

```bash
kubectl -n longhorn-system edit settings.longhorn.io backup-target-credential-secret
```

Set value to: `s3-backup-secret`

### Label Nodes for Database Workloads

If using `longhorn-database` storage class:

```bash
kubectl label node <node-name> workload=database
```

### Label Disks for High Performance

For SSD/NVMe disks:

```bash
# In Longhorn UI, go to Node → Edit Node and Disks
# Add tags: ssd, nvme to appropriate disks
```

Or via CLI (requires Longhorn API access).

## Usage Examples

### Create PVC with High Availability

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
  namespace: production
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn-high-availability
  resources:
    requests:
      storage: 50Gi
```

### Create PVC for Database

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: databases
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn-database
  resources:
    requests:
      storage: 100Gi
```

### Manual Snapshot

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: my-snapshot
  namespace: production
spec:
  volumeSnapshotClassName: longhorn-snapshot-class
  source:
    persistentVolumeClaimName: my-app-data
```

### Restore from Snapshot

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-data
  namespace: production
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn-high-availability
  dataSource:
    name: my-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  resources:
    requests:
      storage: 50Gi
```

### Clone Volume

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloned-volume
  namespace: development
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn-cost-optimized
  dataSource:
    name: my-app-data
    kind: PersistentVolumeClaim
  resources:
    requests:
      storage: 50Gi
```

## Monitoring

### Prometheus Metrics

ServiceMonitor is automatically created at:
```
longhorn-system/longhorn-prometheus-servicemonitor
```

Key metrics:
- `longhorn_volume_actual_size_bytes` - Volume size
- `longhorn_volume_read_iops` - Read IOPS
- `longhorn_volume_write_iops` - Write IOPS
- `longhorn_volume_read_throughput` - Read throughput
- `longhorn_volume_write_throughput` - Write throughput
- `longhorn_volume_read_latency` - Read latency
- `longhorn_volume_write_latency` - Write latency
- `longhorn_node_storage_usage_bytes` - Node storage usage
- `longhorn_volume_robustness` - Volume health

### Grafana Dashboard

Import the dashboard from `longhorn-grafana-dashboard.yaml` or access:
- Volume metrics (size, IOPS, throughput, latency)
- Node storage usage
- Volume health status
- Capacity planning

### Longhorn UI

Access comprehensive monitoring:
```bash
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
```

Features:
- Volume management
- Snapshot management
- Backup management
- Node and disk management
- Event logs
- System settings

## Backup and Restore

### Automated Backups

Backups run automatically via RecurringJobs:
- **Daily**: 1 AM, retain 7 backups
- **Weekly**: Sunday 4 AM, retain 4 backups
- **Monthly**: 1st of month 5 AM, retain 12 backups

### Manual Backup

Via Longhorn UI:
1. Go to Volume
2. Click "Create Backup"
3. Backup is stored in configured backup target

Via CLI:
```bash
kubectl -n longhorn-system create -f - <<EOF
apiVersion: longhorn.io/v1beta2
kind: Backup
metadata:
  name: manual-backup
spec:
  snapshotName: <snapshot-name>
  labels:
    backup-type: manual
EOF
```

### Restore from Backup

Via Longhorn UI:
1. Go to Backup
2. Select backup
3. Click "Restore"
4. Create new PVC or restore to existing

### Cross-Cluster Disaster Recovery

1. **Source Cluster**: Configure backup target (S3/NFS)
2. **Destination Cluster**: Configure same backup target
3. **Restore**: Backups will appear in destination cluster
4. **Create Volume**: Restore from backup in destination cluster

## Recurring Jobs Schedules

| Job | Schedule | Type | Retention | Purpose |
|-----|----------|------|-----------|---------|
| snapshot-hourly | Every hour | Snapshot | 24 | High-frequency snapshots |
| snapshot-daily | 2 AM daily | Snapshot | 7 | Daily snapshots |
| snapshot-weekly | Sunday 3 AM | Snapshot | 4 | Weekly snapshots |
| backup-daily | 1 AM daily | Backup | 7 | Daily backups |
| backup-weekly | Sunday 4 AM | Backup | 4 | Weekly backups |
| backup-monthly | 1st 5 AM | Backup | 12 | Monthly backups |
| snapshot-cleanup | 6 AM daily | Cleanup | N/A | Remove old snapshots |
| filesystem-trim | Saturday 2 AM | Trim | N/A | Reclaim space |

## Maintenance

### Check Volume Health

```bash
kubectl get volumes -n longhorn-system
```

### Check Node Status

```bash
kubectl get nodes.longhorn.io -n longhorn-system
```

### Clean Up Snapshots

Automatic via `snapshot-cleanup` recurring job, or manual:
```bash
# In Longhorn UI: Volume → Snapshots → Delete
```

### Upgrade Longhorn

1. Backup all volumes
2. Update `longhorn-values.yaml` with new version
3. Regenerate manifests:
   ```bash
   helm template longhorn longhorn/longhorn \
     --namespace longhorn-system \
     --version <new-version> \
     --values manifests/longhorn-values.yaml \
     > manifests/longhorn.yaml
   ```
4. Apply:
   ```bash
   kubectl apply -f manifests/longhorn.yaml
   ```

### Troubleshooting

#### Volume Won't Attach

Check:
- Node has available disk space
- iSCSI is working on node
- Instance manager pods are running

```bash
kubectl get pods -n longhorn-system | grep instance-manager
kubectl logs -n longhorn-system <instance-manager-pod>
```

#### Slow Performance

- Check disk I/O on nodes
- Verify replica count (more replicas = more overhead)
- Use `longhorn-high-performance` storage class
- Enable data locality
- Use SSD/NVMe disks

#### Backup Failing

- Verify backup target is accessible
- Check credentials (for S3)
- Check logs:
  ```bash
  kubectl logs -n longhorn-system -l app=longhorn-manager
  ```

#### Out of Space

- Delete old snapshots
- Delete unused volumes
- Increase disk size on nodes
- Add more nodes

## Performance Tuning

### For Databases

Use `longhorn-database` storage class with:
- 3 replicas for HA
- Data locality enabled
- SSD/NVMe disks
- Dedicated nodes with `workload=database` label

### For High IOPS Workloads

Use `longhorn-high-performance` with:
- 1 replica
- Data locality enabled
- NVMe disks
- Fast rebuild disabled (less overhead)

### For Cost Optimization

Use `longhorn-cost-optimized` with:
- 1 replica
- No automatic snapshots
- Manual snapshots as needed

## Security Considerations

1. **Encryption at Rest**: Use encrypted disks/volumes at infrastructure level
2. **Backup Encryption**: S3 backups can use server-side encryption
3. **RBAC**: Longhorn respects Kubernetes RBAC
4. **Network Policies**: Can apply network policies to longhorn-system namespace
5. **Secrets**: Backup credentials stored in Kubernetes secrets

## Integration

### With Velero

Longhorn works with Velero for full cluster backups:
```bash
velero install \
  --use-volume-snapshots \
  --snapshot-location-config region=default
```

Velero will use Longhorn CSI snapshots automatically.

### With ArgoCD

All manifests are GitOps-ready:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: longhorn
spec:
  source:
    path: manifests
    targetRevision: main
  destination:
    namespace: longhorn-system
```

### With Prometheus/Grafana

ServiceMonitor already configured. Ensure Prometheus Operator is running:
```bash
kubectl get servicemonitors -n longhorn-system
```

## Additional Resources

- [Longhorn Documentation](https://longhorn.io/docs/)
- [Longhorn Best Practices](https://longhorn.io/docs/latest/best-practices/)
- [Longhorn GitHub](https://github.com/longhorn/longhorn)
- [Longhorn Slack](https://cloud-native.slack.com/messages/longhorn)

## Quick Reference

### Common Commands

```bash
# List volumes
kubectl get volumes -n longhorn-system

# List recurring jobs
kubectl get recurringjobs -n longhorn-system

# Check storage classes
kubectl get sc

# Port-forward UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80

# View manager logs
kubectl logs -n longhorn-system -l app=longhorn-manager

# Check node status
kubectl get nodes.longhorn.io -n longhorn-system

# List backups
kubectl get backups -n longhorn-system
```

---

**Note**: This is an elite configuration optimized for production use. Test thoroughly in development before deploying to production.
