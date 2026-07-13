# Component Status & Enable/Disable Guide

Clear documentation on each component, why some are disabled, and how to enable them.

## 📊 Component Matrix

| Component | Status | Enabled by Default | Environment | To Enable | Notes |
|-----------|--------|-------------------|-----------|-----------|-------|
| **Cilium CNI** | ✅ Stable | Yes | All | Always enabled | Uses minimal config by default |
| **cert-manager** | ✅ Stable | Yes | All | Always enabled | Required for TLS |
| **OpenEBS** | ✅ Stable | Yes | dev/local | Uncomment in main.tf | High-perf local storage |
| **Longhorn** | ✅ Stable | No | staging/prod | Uncomment in main.tf | **NOW WORKS WITH CILIUM** |
| **MinIO** | ✅ Stable | Yes | All | Already enabled | S3-compatible storage |
| **Prometheus** | ✅ Stable | Yes | dev/staging/prod | Already enabled | Metrics collection |
| **Grafana** | ✅ Stable | Yes | dev/staging/prod | Already enabled | Visualization |
| **Loki** | ✅ Stable | Yes | dev/staging/prod | Already enabled | Centralized logging |
| **Headlamp** | ✅ Stable | Yes | All | Already enabled | Kubernetes dashboard |
| **Portainer** | ✅ Stable | Yes | All | Already enabled | Container management |
| **ArgoCD** | ✅ Stable | No | prod/staging | Uncomment in main.tf | **RECOMMENDED for prod** |
| **Jenkins** | ⚠️ Optional | No | All | Uncomment in main.tf | Optional CI/CD |
| **MetalLB** | ⚠️ Optional | No | All | Uncomment in main.tf | Cilium L2 is simpler |
| **Rook-Ceph** | ⚠️ Complex | No | All | Uncomment in main.tf | Requires careful setup |
| **Gateway API** | ⚠️ Optional | No | All | Uncomment in main.tf | Advanced ingress only |

---

## 🟢 Enabled Components

These are already enabled in the default configuration.

### Cilium CNI (Networking)

**Status**: ✅ Production-ready

```yaml
# Location: manifests/10-networking/cilium-minimal.yaml
# Enabled in: main.tf (line 83)

cilium = "manifests/10-networking/cilium-minimal.yaml"
```

**What it does**:
- Container networking (CNI)
- Replaces kube-proxy for better performance
- Network policies
- Service mesh capabilities
- Hubble network observability

**Why this config**:
- Uses "minimal" for lower resource usage
- Production tested
- Works with all storage backends

**To use advanced Cilium features**:
Replace `cilium-minimal.yaml` with `cilium.yaml`

```hcl
# In main.tf
cilium = "manifests/10-networking/cilium.yaml"
```

### cert-manager (TLS Certificates)

**Status**: ✅ Production-ready

```yaml
# Location: manifests/20-security/cert_manager.yaml
# Enabled in: main.tf (line 93)

"cert-manager" = "manifests/20-security/cert_manager.yaml"
```

**What it does**:
- Automatic TLS certificate generation
- Let's Encrypt integration
- Certificate renewal
- Multiple domain support

**Why always enabled**:
- Needed for HTTPS
- Lightweight
- Essential for production

### OpenEBS LocalPV (Storage)

**Status**: ✅ Production-ready

```yaml
# Location: manifests/30-storage/openebs/openebs.yaml
# Enabled in: main.tf (line 103)

"openebs" = "manifests/30-storage/openebs/openebs.yaml"
```

**What it does**:
- Local persistent volumes
- High performance
- Each node has its own storage

**When to use**:
- Single-node clusters
- Maximum performance workloads
- Local data (ok if node fails)

**When to replace**:
- Multi-node HA cluster → use Longhorn
- Need cross-node replication → use Longhorn

### Observability Stack

**Status**: ✅ Production-ready

```yaml
# Prometheus: Line 113
"prometheus-grafana" = "manifests/40-observability/prometheus/prometheus-grafana.yaml"

# Loki: Line 114
loki = "manifests/40-observability/loki/loki.yaml"

# Grafana dashboard: Line 117
"grafana-dashboard-hubble" = "manifests/40-observability/grafana/grafana-hubble-dashboard-configmap.yaml"
```

**What it does**:
- Prometheus: Metrics collection (50GB)
- Grafana: Visualization dashboard
- Loki: Centralized logging (50GB)
- Hubble: Network flow visualization

**Access**:
```bash
# Via Traefik
http://grafana.dev.dih.10.198.141.235.nip.io  (admin/admin)

# Via port-forward
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

### Management UIs

**Status**: ✅ Production-ready

```yaml
# Headlamp: Line 106
headlamp = "manifests/50-management/headlamp/headlamp.yaml"

# Portainer: Line 122
portainer = "manifests/50-management/portainer/portainer.yaml"
```

**Headlamp** (Kubernetes Dashboard):
- Web-based Kubernetes dashboard
- Pod/service/deployment management
- Access: Token-based

**Portainer** (Container Management):
- Docker/container management UI
- Stack management
- Access: Web UI with login

### MinIO (Object Storage)

**Status**: ✅ Production-ready

```yaml
# Location: manifests/30-storage/minio/minio.yaml
# Enabled in: main.tf (line 125)

minio = "manifests/30-storage/minio/minio.yaml"
```

**What it does**:
- S3-compatible object storage
- 4-node cluster with 400GB default
- Console UI for management
- Perfect backup target for Longhorn

**Default credentials**:
- User: `admin`
- Password: `minio123456`  (⚠️ **CHANGE IN PRODUCTION!**)

---

## 🟡 Disabled Components (Can be Enabled)

These are commented out and must be explicitly enabled. Here's why and how.

### Longhorn (Distributed Storage)

**Status**: ✅ Stable & **NOW WORKS WITH CILIUM!**

```yaml
# Location: manifests/30-storage/longhorn/longhorn.yaml
# Currently: COMMENTED OUT in main.tf (line 100)

# longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
```

**Why was it disabled**:
- ⚠️ OLD NOTE: "Incompatible with Cilium kube-proxy replacement"
- ✅ **THIS IS NOW FIXED!** Longhorn works perfectly with Cilium
- See: [talos/UPGRADE_NOTES.md](talos/UPGRADE_NOTES.md) for details

**What it does**:
- Distributed block storage
- 3x replication across nodes (HA)
- Automatic backups to S3/MinIO
- Cross-node volume migration
- Snapshots and cloning

**When to enable**:
- ✅ Multi-node clusters (3+ nodes)
- ✅ Production environments
- ✅ Need HA and backup
- ✅ Running stateful apps (databases, message queues)

**How to enable**:

```hcl
# In talos/main.tf, find line ~100 and change from:
# longhorn = "manifests/30-storage/longhorn/longhorn.yaml"

# To:
longhorn = "manifests/30-storage/longhorn/longhorn.yaml"

# Then:
cd talos/
tofu plan
tofu apply
```

**Prerequisites**:
- ✅ Cilium must be deployed (it is)
- ✅ Talos nodes must have iscsi-tools extension
  - Check: `talosctl --nodes <ip> get extensions | grep iscsi`
  - If missing: Upgrade Talos with correct schematic (see UPGRADE_NOTES.md)

**Storage class setup**:
```yaml
# Longhorn creates storage class automatically:
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "3"  # 3x replication
  staleReplicaTimeout: "2880"  # 2 days
```

### ArgoCD (GitOps)

**Status**: ✅ Stable

```yaml
# Location: manifests/60-gitops/argocd/argocd.yaml
# Currently: COMMENTED OUT in main.tf (lines 109-110)

# argocd = "manifests/60-gitops/argocd/argocd.yaml"
# "argocd-applications" = "manifests/60-gitops/argocd/argocd-applications.yaml"
```

**Why it's disabled**:
- Optional component (not needed for basic cluster)
- Should be explicitly enabled for GitOps workflow

**What it does**:
- GitOps continuous delivery
- Automatically syncs Git state to cluster
- Application definitions stored in Git
- Automatic rollback to last known good
- Multi-environment support

**When to enable**:
- ✅ Production deployments (recommended)
- ✅ Team workflows (Git as source of truth)
- ✅ Automated deployments
- ❌ Simple testing (skip for local dev)

**How to enable**:

```hcl
# In talos/main.tf, uncomment lines ~109-110:
argocd = "manifests/60-gitops/argocd/argocd.yaml"
"argocd-applications" = "manifests/60-gitops/argocd/argocd-applications.yaml"

# Then:
cd talos/
tofu apply
```

**First access**:
```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port-forward to ArgoCD server
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Access: https://localhost:8080
# User: admin
# Password: (from above)
```

**Define applications**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/you/gitops.git
    targetRevision: main
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true      # Remove deleted resources
      selfHeal: true   # Auto-sync on changes
```

### Jenkins (CI/CD)

**Status**: ⚠️ Optional

```yaml
# Location: manifests/60-gitops/jenkins/jenkins.yaml
# Currently: COMMENTED OUT in main.tf (line 121)

# jenkins = "manifests/60-gitops/jenkins/jenkins.yaml"
```

**When to enable**:
- Need custom build pipelines
- CI/CD automation beyond Git push
- Optional (ArgoCD handles most deployment needs)

**How to enable**:
```hcl
# In talos/main.tf, uncomment line ~121:
jenkins = "manifests/60-gitops/jenkins/jenkins.yaml"

tofu apply
```

---

## 🔴 Complex Components (Requires Careful Setup)

### Rook-Ceph (Enterprise Distributed Storage)

**Status**: ⚠️ Complex, requires expertise

```yaml
# Location: manifests/30-storage/rook-ceph/
# Currently: COMMENTED OUT in main.tf (lines 96-97)

# "rook-ceph-operator" = "manifests/30-storage/rook-ceph/rook-ceph-operator.yaml"
# "rook-ceph-cluster" = "manifests/30-storage/rook-ceph/rook-ceph-cluster.yaml"
```

**Why it's disabled**:
- Complex setup and tuning
- Requires dedicated hardware
- Can have PVC binding issues
- Needs expertise to troubleshoot

**When to use**:
- Enterprise requirements
- Advanced storage features needed
- Experienced with Ceph
- Not recommended for learning

**To enable** (only if you need it):
```hcl
"rook-ceph-operator" = "manifests/30-storage/rook-ceph/rook-ceph-operator.yaml"
"rook-ceph-cluster" = "manifests/30-storage/rook-ceph/rook-ceph-cluster.yaml"
```

### MetalLB (Load Balancer)

**Status**: ⚠️ Optional (Cilium L2 is simpler)

```yaml
# Location: manifests/70-loadbalancing/metallb.yaml
# Currently: COMMENTED OUT in main.tf (line 89)

# metallb = "manifests/70-loadbalancing/metallb.yaml"
```

**Why it's disabled**:
- Cilium L2 announcements are simpler
- Overlaps with Cilium functionality
- MetalLB useful only in specific setups

**When to use MetalLB**:
- BGP load balancing needed
- Layer 3 requirements
- Cilium L2 insufficient

**Use Cilium L2 instead**:
```yaml
# Enabled by default in cilium-l2-ippool.yaml
# Simpler than MetalLB for most use cases
```

### Gateway API (Advanced Ingress)

**Status**: ⚠️ Optional

```yaml
# Location: manifests/10-networking/gateway-api-crds.yaml
# Currently: COMMENTED OUT in main.tf (line 86)

# "gateway-api-crds" = "manifests/10-networking/gateway-api-crds.yaml"
```

**When to use**:
- Complex routing requirements
- Multiple ingress controllers
- Advanced traffic management
- Not needed for basic setup

---

## ✅ Quick Decision Guide

### "I want Longhorn (HA storage)"

1. Verify prerequisites:
   ```bash
   talosctl --nodes <ip> get extensions | grep iscsi-tools
   ```

2. Enable in main.tf:
   ```hcl
   longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
   ```

3. Deploy:
   ```bash
   cd talos/
   tofu apply
   ```

4. Verify:
   ```bash
   kubectl get pods -n longhorn-system
   kubectl get volumes -n longhorn-system
   ```

### "I want GitOps with ArgoCD"

1. Enable in main.tf:
   ```hcl
   argocd = "manifests/60-gitops/argocd/argocd.yaml"
   "argocd-applications" = "manifests/60-gitops/argocd/argocd-applications.yaml"
   ```

2. Deploy:
   ```bash
   tofu apply
   ```

3. Get initial password:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret \
     -o jsonpath="{.data.password}" | base64 -d
   ```

4. Define applications in Git

### "I'm learning/testing"

Keep defaults:
- ✅ Cilium (networking)
- ✅ cert-manager (TLS)
- ✅ OpenEBS (storage)
- ✅ Observability stack
- ✅ Management UIs

Don't enable:
- ❌ Longhorn (use OpenEBS for testing)
- ❌ ArgoCD (not needed yet)
- ❌ Rook-Ceph (too complex)
- ❌ MetalLB (Cilium L2 is fine)

---

## 🐛 Troubleshooting

### Component Won't Start

1. Check if enabled in main.tf:
   ```bash
   grep "component-name" talos/main.tf
   ```

2. Check for syntax errors:
   ```bash
   cd talos/
   tofu validate
   ```

3. Check pod status:
   ```bash
   kubectl get pods -n <namespace>
   kubectl logs -n <namespace> <pod-name>
   ```

### Component Conflicts

**Longhorn + MetalLB**: OK to have both

**MetalLB + Cilium L2**: Choose one:
- Default is Cilium L2 (in cilium-l2-ippool.yaml)
- Disable Cilium L2 if using MetalLB

### Storage Class Issues

```bash
# Check available storage classes
kubectl get storageclass

# Verify default storage class
kubectl get storageclass --show-default

# Change default
kubectl patch storageclass longhorn \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

---

## 📚 Related Documentation

- [Longhorn Documentation](https://longhorn.io/docs/)
- [Rook-Ceph Documentation](https://rook.io/docs/rook/latest/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [MetalLB Documentation](https://metallb.universe.tf/)
- [Cilium Documentation](https://docs.cilium.io/)

---

Last updated: 2026-07-13
