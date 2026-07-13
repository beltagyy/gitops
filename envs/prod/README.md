# Production Environment

High-availability Kubernetes cluster for production workloads.

## 🎯 Requirements

- **Cluster Size**: 6+ nodes (3 control planes, 3+ workers)
- **Storage**: Replicated, backed up
- **Monitoring**: Full observability stack
- **Disaster Recovery**: Backup strategy, failover plan
- **Security**: Network policies, RBAC, secret management
- **GitOps**: ArgoCD for consistent deployments

## ⚙️ Specifications

| Aspect | Value |
|--------|-------|
| **Nodes** | 6+ (3+ control planes, 3+ workers) |
| **Network** | 10.198.143.0/24 |
| **CNI** | Cilium with network policies |
| **Storage** | Longhorn (3x HA replication) + MinIO backups |
| **Observability** | Prometheus + Grafana + Loki + Alerts |
| **Management** | Headlamp, Portainer |
| **GitOps** | ArgoCD (mandatory) |
| **Security** | Network policies, RBAC, pod security |
| **Backup** | Automated daily to S3/MinIO |

## 🚀 Pre-Deployment Checklist

### Infrastructure

- [ ] 6+ nodes provisioned with Talos OS
- [ ] Network configured (10.198.143.0/24)
- [ ] DNS configured for production domain
- [ ] TLS certificates ready (or Let's Encrypt)
- [ ] Backup storage (S3 or MinIO) ready
- [ ] Monitoring/alerting system provisioned

### Configuration

- [ ] All terraform.tfvars reviewed for production values
- [ ] Node addresses verified
- [ ] Storage class replicas set to 3
- [ ] Resource limits set appropriately
- [ ] Network policies enabled
- [ ] RBAC policies configured

### Security

- [ ] Change default passwords (Grafana, Portainer)
- [ ] Enable TLS for all services
- [ ] Configure network policies
- [ ] Setup secret management
- [ ] Enable audit logging
- [ ] Review RBAC permissions

## 🚀 Deployment

### 1. Final Review

```bash
# Check everything one more time
cd talos/
cp envs/prod/terraform.tfvars .
tofu plan -out=prod_plan

# REVIEW THE PLAN VERY CAREFULLY!
less prod_plan
```

### 2. Backup Existing State (if upgrading)

```bash
# Backup current Kubernetes state
kubectl get all -A -o yaml > prod_backup_$(date +%Y%m%d).yaml

# Backup Terraform state
cp terraform.tfstate terraform.tfstate.backup
```

### 3. Deploy

```bash
# Apply with approval
tofu apply prod_plan
```

### 4. Verify Deployment

```bash
# Check nodes
kubectl get nodes -o wide

# Check all pods
kubectl get pods -A

# Check services
kubectl get svc -A

# Check storage
kubectl get pvc -A
```

## 📊 Configuration

### Storage: Longhorn with Replicas=3

```hcl
# In main.tf, ensure Longhorn manifests include:
# longhorn-storage-classes.yaml
# Sets replicas: 3 for all volumes
```

### Network Policies: Deny by Default

```bash
# Apply strict network policies
kubectl apply -f manifests/20-security/network-policies/

# Test connectivity
kubectl run -it --rm test --image=busybox -- sh
# This should be blocked unless explicitly allowed
```

### GitOps: ArgoCD

```hcl
# Mandatory in production:
argocd = "manifests/60-gitops/argocd/argocd.yaml"
"argocd-applications" = "manifests/60-gitops/argocd/argocd-applications.yaml"
```

All application deployments go through Git:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prod-app
  namespace: argocd
spec:
  project: prod
  source:
    repoURL: https://github.com/you/gitops
    targetRevision: main  # Use Git tags for releases
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true      # Remove deleted items
      selfHeal: true   # Sync on Git changes
    syncOptions:
      - CreateNamespace=true
```

### Monitoring & Alerting

```bash
# Setup alerts for critical issues
kubectl apply -f manifests/40-observability/
```

Create PrometheusRule for critical alerts:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: production-alerts
  namespace: monitoring
spec:
  groups:
    - name: prod.rules
      interval: 30s
      rules:
        # Node down
        - alert: NodeDown
          expr: up{job="node-exporter"} == 0
          for: 5m
          annotations:
            summary: "Node {{ $labels.node }} is down"

        # Pod crashing
        - alert: PodCrashing
          expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
          for: 5m
          annotations:
            summary: "Pod {{ $labels.pod }} restarting in {{ $labels.namespace }}"

        # Storage full
        - alert: StorageAlmostFull
          expr: kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes > 0.9
          for: 10m
          annotations:
            summary: "Storage {{ $labels.persistentvolumeclaim }} almost full"
```

### Backup Strategy

```bash
# Configure Longhorn backups

# 1. Setup backup target via UI:
#    Target: s3://prod-backups@us-east-1/
#    Credentials: Set via Kubernetes Secret

# 2. Create recurring backup job:
#    Schedule: Daily at 2 AM UTC
#    Retention: Keep 30 days

# 3. Verify backups
kubectl get backupvolumes -n longhorn-system
```

## 🔄 Operations

### Monitoring Dashboard

```bash
# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
# https://grafana.prod.example.com/
```

### Check Cluster Health

```bash
# Node status
kubectl get nodes -o wide

# Pod status
kubectl get pods -A | grep -v Running

# Storage health
kubectl get volumes -n longhorn-system
kubectl get backupvolumes -n longhorn-system

# Recent events
kubectl get events -A --sort-by='.lastTimestamp' | tail -50
```

### Deploy New Application

```bash
# 1. Create app in Git
mkdir -p apps/my-prod-app
# ... add manifests ...
git push

# 2. Create ArgoCD Application
kubectl apply -f - << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-prod-app
  namespace: argocd
spec:
  project: prod
  source:
    repoURL: https://github.com/you/gitops
    targetRevision: main
    path: apps/my-prod-app
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# 3. Monitor deployment
argocd app watch my-prod-app
```

### Scale Deployment

```bash
# Edit via ArgoCD (recommended)
# Or manually:
kubectl patch deployment my-app \
  -p '{"spec":{"replicas":5}}'
```

## 🚨 Disaster Recovery

### Backup Testing (Monthly)

```bash
# 1. Take snapshot of cluster state
kubectl get all -A -o yaml > prod_state_$(date +%Y%m%d).yaml

# 2. Test restore to staging
# (Use staging environment for this)

# 3. Verify data integrity
```

### Node Failure Recovery

```bash
# If a node goes down:
# Longhorn automatically rebalances replicas

kubectl get volumes -n longhorn-system
# Should show replication_required: 0 after recovery
```

### Cluster Recovery

```bash
# Emergency access to control plane
talosctl --nodes 10.198.143.20 kubeconfig > prod_kubeconfig

# etcd snapshot (backup)
talosctl --nodes 10.198.143.20 etcd snapshot etcd-snapshot.db

# Restore from snapshot
talosctl --nodes 10.198.143.20 reset --graceful=false
```

## 🔐 Security Hardening

### Network Policies

```bash
# Apply strict network policies
kubectl apply -f manifests/20-security/network-policies/

# Verify enforcement
# Check that traffic between pods is restricted as expected
```

### RBAC

```bash
# Create service accounts per app
kubectl create serviceaccount my-app -n production

# Bind minimal permissions
kubectl create clusterrole my-app-reader --verb=get,list --resource=pods
kubectl create clusterrolebinding my-app-read \
  --clusterrole=my-app-reader \
  --serviceaccount=production:my-app
```

### Pod Security Standards

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  runAsUser:
    rule: MustRunAsNonRoot
  fsGroup:
    rule: MustRunAs
    ranges:
      - min: 1000
        max: 65535
```

## 📞 Incident Response

### Common Issues

**Pod Stuck in CrashLoopBackOff**
```bash
kubectl logs -n <namespace> <pod-name> --tail=50
kubectl describe pod <pod-name> -n <namespace>
```

**Storage Unavailable**
```bash
kubectl get pvc -a
kubectl describe pvc <pvc-name> -n <namespace>
kubectl get volumes -n longhorn-system
```

**Ingress Not Working**
```bash
kubectl get ingressroute -a
kubectl logs -n traefik deploy/traefik
```

### Escalation Path

1. **Critical**: Page on-call engineer
2. **High**: Create incident ticket
3. **Medium**: Add to sprint planning
4. **Low**: Note for improvement

## 📚 Documentation

See also:
- [Talos Documentation](https://www.talos.dev/docs/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/)
- [Longhorn Operations](https://longhorn.io/docs/latest/best-practices/)

## 🔗 Runbooks

- [Backup & Restore](../../docs/RUNBOOKS.md#backupmd)
- [Node Replacement](../../docs/RUNBOOKS.md#node-replacement)
- [Emergency Access](../../docs/RUNBOOKS.md#emergency-access)
- [Cluster Upgrade](../../docs/RUNBOOKS.md#cluster-upgrade)

---

Last updated: 2026-07-13

**Contact**: devops@example.com | Slack: #infrastructure
