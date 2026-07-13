# Kubernetes Manifests Organization

This directory contains all Kubernetes manifests for the cluster, organized by functional component groups with built-in dependency ordering.

## 📋 Directory Structure & Deployment Order

Manifests are organized with numeric prefixes that indicate deployment order:

| Order | Directory | Purpose | Required | Status |
|-------|-----------|---------|----------|--------|
| **1** | `00-namespaces/` | Create namespaces and basic resources | ✅ Yes | Core |
| **2** | `10-networking/` | Cilium CNI, Traefik ingress, networking | ✅ Yes | Core |
| **3** | `20-security/` | Certificate management, network policies | ✅ Yes | Core |
| **4** | `30-storage/` | Storage backends (Longhorn, MinIO, OpenEBS, etc) | ⚠️ Optional | Experimental |
| **5** | `40-observability/` | Prometheus, Grafana, Loki monitoring | ⚠️ Optional | Experimental |
| **6** | `50-management/` | Portainer, Headlamp, DNS management | ⚠️ Optional | Experimental |
| **7** | `60-gitops/` | ArgoCD, Jenkins CI/CD | ⚠️ Optional | Experimental |
| **8** | `70-loadbalancing/` | MetalLB, load balancer IPs | ⚠️ Optional | Experimental |

## 🔧 Component Groups

### 00-namespaces/ — Cluster Foundation
**Deploys**: Kubernetes namespaces

**Files**:
- `namespaces.yaml` - Creates all required namespaces

**Dependencies**: None (deploys first)

**Enable/Disable**: Always enabled in `main.tf`

---

### 10-networking/ — Network Infrastructure
**Deploys**: Cilium CNI, Traefik ingress controller, networking policies

**Files**:
- `cilium-minimal.yaml` - Minimal Cilium setup (eBPF, kube-proxy replacement)
- `cilium.yaml` - Full Cilium with advanced features
- `cilium-bgp-config.yaml` - BGP configuration
- `cilium-l2-ippool.yaml` - L2 announcement IP pool
- `cilium-loadbalancer-ippool.yaml` - LoadBalancer IP pool
- `cilium-ingressclass.yaml` - Cilium ingress class
- `cilium-ingress-lb.yaml` - Cilium as ingress LoadBalancer
- `cilium-ingress-rbac.yaml` - RBAC for Cilium ingress
- `cilium-values-minimal.yaml` - Minimal Cilium Helm values
- `cilium-values.yaml` - Full Cilium Helm values
- `gateway-api-crds.yaml` - Kubernetes Gateway API CRDs
- `gateway-api-examples.yaml` - Gateway API examples
- `traefik-ingressroutes.yaml` - Traefik ingress routes and services
- `ingress.yaml` - Generic ingress resources

**Dependencies**: None (deploys after namespaces)

**Enable/Disable**: Always enabled in `main.tf` (core functionality)

**Key Points**:
- Cilium replaces kube-proxy by default
- Use `cilium-minimal.yaml` for quick setup
- Use `cilium.yaml` for advanced features (Hubble, network policies)
- Traefik provides HTTP/HTTPS load balancing

---

### 20-security/ — Security & Certificates
**Deploys**: cert-manager for TLS certificates, network policy examples

**Files**:
- `cert-manager.yaml` - Certificate management
- `network-policies/cilium-network-policies-examples.yaml` - Network policy examples

**Dependencies**: `10-networking/` (Cilium must be ready)

**Enable/Disable**: 
```hcl
# In main.tf cluster_inline_manifests:
"cert-manager" = "manifests/20-security/cert_manager.yaml"
```

**Key Points**:
- cert-manager enables automatic TLS certificate generation
- Use Let's Encrypt for public domains
- Network policies restrict traffic between pods

---

### 30-storage/ — Storage Backends
**Deploys**: Multiple storage solutions (choose one or combine)

#### Longhorn (Distributed Block Storage)
**Files**: `longhorn/*`
- `longhorn.yaml` - Longhorn operator and components
- `longhorn-namespace.yaml` - Longhorn namespace
- `longhorn-values-minimal.yaml` - Minimal Helm values
- `longhorn-values.yaml` - Full Helm values
- `longhorn-recurring-jobs.yaml` - Snapshot/backup schedules
- `longhorn-storage-classes.yaml` - Storage class definitions
- `longhorn-grafana-dashboard.yaml` - Grafana monitoring dashboard

**Status**: ✅ Working with Cilium

#### OpenEBS (Local Persistent Volumes)
**Files**: `openebs/`
- `openebs.yaml` - OpenEBS operator

**Status**: ✅ High-performance local storage

#### Rook-Ceph (Distributed Storage)
**Files**: `rook-ceph/*`
- `rook-ceph-operator.yaml` - Ceph operator
- `rook-ceph-operator-values.yaml` - Operator Helm values
- `rook-ceph-cluster.yaml` - Ceph cluster
- `rook-ceph-cluster-values.yaml` - Cluster Helm values

**Status**: ⚠️ Complex setup, requires careful configuration

#### MinIO (S3-Compatible Object Storage)
**Files**: `minio/`
- `minio.yaml` - MinIO server and console

**Status**: ✅ Good for backups and object storage

**Dependencies**: `10-networking/` and `00-namespaces/`

**Enable/Disable**:
```hcl
# In main.tf cluster_inline_manifests, uncomment:
longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
# or
openebs = "manifests/30-storage/openebs/openebs.yaml"
# or both
```

**Key Points**:
- Choose storage backend based on workload
- Longhorn recommended for HA distributed storage
- OpenEBS for high-performance local storage
- Can mix storage classes for different workloads

---

### 40-observability/ — Monitoring & Logging
**Deploys**: Prometheus metrics, Grafana dashboards, Loki logs

#### Prometheus
**Files**: `prometheus/`
- `prometheus-grafana.yaml` - Prometheus and Grafana

#### Grafana
**Files**: `grafana/`
- `grafana-hubble-dashboard-configmap.yaml` - Cilium network observability dashboard

#### Loki
**Files**: `loki/`
- `loki.yaml` - Log aggregation

**Dependencies**: `10-networking/` (for ingress)

**Enable/Disable**:
```hcl
# In main.tf cluster_inline_manifests:
prometheus = "manifests/40-observability/prometheus/prometheus-grafana.yaml"
loki = "manifests/40-observability/loki/loki.yaml"
```

**Key Points**:
- Prometheus scrapes metrics from all components
- Grafana visualizes metrics and logs
- Loki aggregates logs from all pods
- Hubble provides network flow visibility

---

### 50-management/ — Management UIs
**Deploys**: Web UIs for cluster and container management

#### Portainer
**Files**: `portainer/*`
- `portainer.yaml` - Portainer container management UI
- `portainer-ingress.yaml` - Ingress (alternative)
- `portainer-traefik-ingress.yaml` - Traefik-specific ingress

#### Headlamp
**Files**: `headlamp/*`
- `headlamp.yaml` - Kubernetes dashboard
- `headlamp-token.yaml` - Token setup

#### DNS
**Files**: `dns/`
- `dns_admin.yaml` - DNS administration tools

**Dependencies**: `10-networking/` (for ingress)

**Enable/Disable**:
```hcl
# In main.tf cluster_inline_manifests:
portainer = "manifests/50-management/portainer/portainer.yaml"
headlamp = "manifests/50-management/headlamp/headlamp.yaml"
```

**Key Points**:
- Portainer manages containers and Docker services
- Headlamp provides native Kubernetes dashboard
- Both accessible via Traefik ingress

---

### 60-gitops/ — GitOps & CI/CD
**Deploys**: ArgoCD for GitOps, Jenkins for CI/CD (optional)

#### ArgoCD
**Files**: `argocd/*`
- `argocd.yaml` - ArgoCD server and components
- `argocd-applications.yaml` - Application definitions

**Status**: ✅ Recommended for production GitOps

#### Jenkins
**Files**: `jenkins/`
- `jenkins.yaml` - Jenkins CI/CD server

**Status**: ⚠️ Optional CI/CD

**Dependencies**: `10-networking/`, `20-security/`, `30-storage/`

**Enable/Disable**:
```hcl
# In main.tf cluster_inline_manifests:
argocd = "manifests/60-gitops/argocd/argocd.yaml"
"argocd-applications" = "manifests/60-gitops/argocd/argocd-applications.yaml"
# and/or
jenkins = "manifests/60-gitops/jenkins/jenkins.yaml"
```

**Key Points**:
- ArgoCD continuously syncs Git state to cluster
- Applications defined in Git are source of truth
- Enables GitOps workflow

---

### 70-loadbalancing/ — Load Balancing
**Deploys**: MetalLB for on-premises LoadBalancer support

**Files**:
- `metallb.yaml` - MetalLB operator and controller
- `ui-loadbalancers.yaml` - LoadBalancer service definitions

**Status**: ⚠️ Optional (Cilium L2 announcements are primary)

**Dependencies**: `10-networking/`

**Enable/Disable**:
```hcl
# In main.tf cluster_inline_manifests:
# metallb = "manifests/70-loadbalancing/metallb.yaml"
# "ui-loadbalancers" = "manifests/70-loadbalancing/ui-loadbalancers.yaml"
```

**Key Points**:
- MetalLB provides LoadBalancer service support
- Cilium L2 announcements are simpler alternative
- Choose one or the other, not both

---

## 🚀 Deployment Workflow

### Standard Deployment (main.tf)

Edit `talos/main.tf` and add components to `cluster_inline_manifests`:

```hcl
cluster_inline_manifests = {
  # Core (always)
  namespaces = "manifests/00-namespaces/namespaces.yaml"
  cilium = "manifests/10-networking/cilium-minimal.yaml"
  "cert-manager" = "manifests/20-security/cert_manager.yaml"
  
  # Storage (optional)
  longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
  
  # Observability (optional)
  prometheus = "manifests/40-observability/prometheus/prometheus-grafana.yaml"
  loki = "manifests/40-observability/loki/loki.yaml"
  
  # Management (optional)
  portainer = "manifests/50-management/portainer/portainer.yaml"
  headlamp = "manifests/50-management/headlamp/headlamp.yaml"
}
```

Then deploy:
```bash
cd talos/
tofu plan
tofu apply
```

### Manual Deployment

Apply specific manifests:
```bash
# Deploy all storage components
kubectl apply -f manifests/30-storage/longhorn/
kubectl apply -f manifests/30-storage/minio/

# Or use kustomize (if available)
kubectl apply -k manifests/30-storage/longhorn/
```

---

## 📊 Component Dependencies

```
00-namespaces
    ↓
10-networking (Cilium + Traefik)
    ├─ 20-security (cert-manager, network policies)
    │   ├─ 30-storage (Longhorn, MinIO, etc)
    │   │   └─ 40-observability (Prometheus, Loki)
    │   │       └─ 50-management (Portainer, Headlamp)
    │   │           └─ 60-gitops (ArgoCD, Jenkins)
    │   └─ 50-management (Portainer, Headlamp)
    └─ 70-loadbalancing (MetalLB)
```

**Key Dependencies**:
- Networking (10-*) must deploy before anything else
- Storage (30-*) depends on networking
- Observability (40-*) depends on storage
- Management (50-*) depends on networking
- GitOps (60-*) depends on all core components

---

## ✅ Common Operations

### Enable a Component

1. Check the component's README in its directory
2. Uncomment the line in `main.tf` `cluster_inline_manifests`
3. Run `tofu plan` to verify
4. Run `tofu apply` to deploy

Example - Enable Longhorn:
```hcl
# In talos/main.tf
longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
```

### Disable a Component

Comment out the line in `main.tf`:
```hcl
# longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
```

### Add New Manifest

1. Create appropriate subdirectory if needed
2. Add manifest file
3. Update relevant component README
4. Add to `main.tf` if deploying via Terraform

### View What's Deployed

```bash
# See all deployed manifests
kubectl get all -A

# Check specific component
kubectl get pods -n longhorn-system
kubectl get pods -n monitoring
```

---

## 🔍 Troubleshooting

### Pods Stuck in Pending

```bash
# Check events
kubectl get events -A --sort-by='.lastTimestamp'

# Check storage
kubectl get pvc -A
kubectl get storageclass

# Check logs
kubectl logs -n <namespace> <pod-name>
```

### Component Not Starting

1. Check namespace exists: `kubectl get ns`
2. Check pod logs: `kubectl logs -n <namespace> <pod-name>`
3. Check resource requests: `kubectl describe pod -n <namespace> <pod-name>`
4. Check manifests are valid: `kubectl apply -f <manifest.yaml> --dry-run=client`

### Ingress Not Working

```bash
# Check Traefik
kubectl get pods -n traefik
kubectl get svc -n traefik

# Check IngressRoutes
kubectl get ingressroute -A
```

---

## 📚 Component-Specific Guides

See README.md in each component directory for detailed:
- Configuration options
- Troubleshooting
- Performance tuning
- Backup/restore procedures

---

## 📝 Version Information

- Talos OS: v1.12.0
- Kubernetes: v1.32+
- Cilium: v1.18.0
- Longhorn: v1.7.2
- Prometheus: Latest (Kube-Prometheus-Stack)
- Grafana: Latest

Last updated: 2026-07-13
