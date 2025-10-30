# Talos Kubernetes Cluster - Terraform Deployment

This Terraform configuration deploys a **production-ready Talos Kubernetes cluster** with a comprehensive set of pre-configured services including CNI, CSI, monitoring, logging, CI/CD, and storage solutions.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Components](#components)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Accessing Services](#accessing-services)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This deployment creates a fully-featured Kubernetes cluster on Talos OS with:

- **CNI**: Cilium for advanced networking and observability
- **CSI**: Longhorn for distributed persistent storage
- **Load Balancer**: MetalLB for bare-metal load balancing
- **Ingress**: NGINX Ingress Controller with TLS support
- **Certificate Management**: cert-manager with Let's Encrypt integration
- **GitOps**: ArgoCD for continuous delivery
- **Monitoring**: Prometheus & Grafana stack
- **Logging**: Loki with Promtail for log aggregation
- **CI/CD**: Jenkins with Kubernetes integration
- **Container Management**: Portainer CE
- **Object Storage**: MinIO distributed storage cluster

---

## 🏗️ Architecture

### Cluster Components

```
┌─────────────────────────────────────────────────────────────────┐
│                     Talos Kubernetes Cluster                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Networking Layer                                                │
│  ├── Cilium CNI (v1.16.5) - Pod networking & network policies  │
│  ├── MetalLB (v0.15.2) - Load balancer for bare metal          │
│  └── NGINX Ingress (v1.13.3) - Ingress controller              │
│                                                                  │
│  Storage Layer                                                   │
│  ├── Longhorn (v1.7.2) - Distributed block storage (CSI)       │
│  └── MinIO (2025-01-20) - S3-compatible object storage         │
│                                                                  │
│  Observability Stack                                             │
│  ├── Prometheus (v3.1.0) - Metrics collection                  │
│  ├── Grafana (v11.4.0) - Metrics visualization                 │
│  ├── Loki (v3.3.2) - Log aggregation                           │
│  └── Promtail (v3.3.2) - Log collection agent                  │
│                                                                  │
│  DevOps & Management                                             │
│  ├── ArgoCD (v3.1.8) - GitOps continuous delivery              │
│  ├── Jenkins (v2.479) - CI/CD automation                       │
│  ├── Portainer CE (v2.21.5) - Container management UI          │
│  └── cert-manager (v1.19.1) - Certificate management           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Node Architecture

- **Bootstrap Controlplane**: Initial cluster bootstrap node with all manifests
- **Additional Controlplanes**: High-availability control plane nodes
- **Worker Nodes**: Compute nodes for application workloads

---

## ✅ Prerequisites

### Required Tools

- **Terraform** >= 1.0
- **talosctl** - Talos CLI tool
- **kubectl** - Kubernetes CLI tool

### Network Requirements

- Static IP addresses for all nodes
- Network gateway accessible from all nodes
- DNS resolution configured
- IP range for MetalLB load balancer (default: 10.198.141.200-250)

### Hardware Requirements

**Minimum per node:**
- 4 CPU cores
- 8 GB RAM
- 100 GB disk space

**Recommended for production:**
- 8+ CPU cores
- 16+ GB RAM
- 500+ GB disk space (for storage nodes)

---

## 🚀 Components

### 1. Cilium CNI (v1.16.5)

**Purpose**: Container Network Interface for pod networking

**Features**:
- VXLAN tunneling for overlay networking
- Network policy enforcement
- Hubble for network observability
- L2 announcements support
- Bandwidth manager for QoS

**Namespace**: `kube-system`

### 2. Longhorn CSI (v1.7.2)

**Purpose**: Distributed block storage for Kubernetes

**Features**:
- 3-replica default for high availability
- Snapshot and backup support
- Volume expansion
- Storage over-provisioning
- Integration with MinIO for backups

**Namespace**: `longhorn-system`
**Storage Classes**:
- `longhorn` (default, ReclaimPolicy: Delete)
- `longhorn-retain` (ReclaimPolicy: Retain)

**Web UI**: Access via `http://longhorn-frontend.longhorn-system.svc.cluster.local`

### 3. MetalLB (v0.15.2)

**Purpose**: Load balancer for bare-metal Kubernetes

**Configuration**:
- IP Pool: 10.198.141.200-250 (customize in `argocd-applications.yaml`)
- L2 Advertisement mode

**Namespace**: `metallb-system`

### 4. NGINX Ingress Controller (v1.13.3)

**Purpose**: Ingress controller for HTTP/HTTPS traffic

**Features**:
- TLS termination
- Path-based routing
- Integration with cert-manager

**Namespace**: `ingress`

### 5. cert-manager (v1.19.1)

**Purpose**: Automatic TLS certificate management

**Features**:
- Let's Encrypt integration (production & staging)
- Automatic certificate renewal
- HTTP-01 challenge solver

**Namespace**: `cert-manager`
**Issuers**: `letsencrypt-prod`, `letsencrypt-staging`

**Usage**: Add annotation to Ingress:
```yaml
cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

### 6. ArgoCD (v3.1.8)

**Purpose**: GitOps continuous delivery

**Features**:
- Declarative GitOps CD
- Multi-cluster management
- RBAC & SSO support

**Namespace**: `argocd`
**Default Ingress**: `argocd.example.com`
**Initial Password**: Retrieved via:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 7. Prometheus & Grafana

**Prometheus (v3.1.0)**:
- Metrics retention: 30 days
- Storage: 50 GB (Longhorn PVC)
- Scrapes: Kubernetes API, nodes, pods, cadvisor, Longhorn

**Grafana (v11.4.0)**:
- Pre-configured Prometheus & Loki datasources
- Storage: 10 GB (Longhorn PVC)
- Default credentials: `admin/admin` (change after first login)

**Namespace**: `monitoring`
**Ingresses**:
- `prometheus.example.com`
- `grafana.example.com`

### 8. Loki & Promtail (v3.3.2)

**Purpose**: Log aggregation and collection

**Loki Features**:
- 31-day log retention
- 50 GB storage (Longhorn PVC)
- Integrated with Grafana

**Promtail Features**:
- DaemonSet on all nodes
- Automatic pod log collection
- CRI log parsing

**Namespace**: `logging`

### 9. Jenkins (v2.479)

**Purpose**: CI/CD automation server

**Features**:
- Kubernetes plugin pre-configured
- Dynamic agent provisioning
- Persistent storage: 50 GB (Longhorn PVC)
- Configuration as Code (JCasC)

**Namespace**: `jenkins`
**Ingress**: `jenkins.example.com`
**Initial Password**: Auto-generated, disable setup wizard via JCasC

### 10. Portainer CE (v2.21.5)

**Purpose**: Container management platform

**Features**:
- Kubernetes cluster management
- RBAC integration
- Multi-environment support
- Storage: 10 GB (Longhorn PVC)

**Namespace**: `portainer`
**Ingress**: `portainer.example.com`
**Ports**:
- 9443 (HTTPS UI)
- 9000 (HTTP UI)
- 8000 (Edge agent)

### 11. MinIO (RELEASE.2025-01-20)

**Purpose**: S3-compatible object storage

**Features**:
- 4-node distributed cluster
- Erasure coding (EC:2)
- 100 GB per node (400 GB total)
- Pre-created buckets: backups, longhorn-backups, loki-logs, prometheus-backups, jenkins-backups

**Namespace**: `minio`
**Credentials**: `admin / minio123456` (change in production!)
**Ingresses**:
- `minio-api.example.com` (S3 API)
- `minio-console.example.com` (Web UI)

---

## 🚀 Quick Start

### Step 1: Clone Repository

```bash
git clone <your-repo-url>
cd gitops/talos
```

### Step 2: Configure Variables

Copy and customize the example configuration:

```bash
cp example.terraform.tfvars terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
cluster_name = "production"
env = "prod"
bootstrap_node_address = "10.198.141.100"

nodes = {
  "controlplane-01" = {
    node_is_controlplane = true
    address = "10.198.141.101"
  }
  "controlplane-02" = {
    node_is_controlplane = true
    address = "10.198.141.102"
  }
  "worker-01" = {
    node_is_controlplane = false
    address = "10.198.141.103"
  }
  "worker-02" = {
    node_is_controlplane = false
    address = "10.198.141.104"
  }
}
```

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Review Plan

```bash
terraform plan
```

### Step 5: Deploy Cluster

```bash
terraform apply
```

This will:
1. Create Talos machine secrets
2. Configure all nodes with proper networking
3. Bootstrap the Kubernetes cluster
4. Deploy all components in order

### Step 6: Configure kubectl Access

```bash
# Get talosconfig
export TALOSCONFIG=$(pwd)/<env>.talosconfig

# Get kubeconfig
talosctl kubeconfig --nodes <bootstrap_node_address>

# Verify cluster
kubectl get nodes
kubectl get pods -A
```

---

## ⚙️ Configuration

### Customizing Domain Names

Update ingress hostnames in the manifest files:

**Files to modify**:
- `manifests/jenkins.yaml` - Change `jenkins.example.com`
- `manifests/portainer.yaml` - Change `portainer.example.com`
- `manifests/prometheus-grafana.yaml` - Change `grafana.example.com`, `prometheus.example.com`
- `manifests/minio.yaml` - Change `minio-api.example.com`, `minio-console.example.com`

### Customizing MetalLB IP Pool

Edit `manifests/argocd-applications.yaml`:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.198.141.200-10.198.141.250  # Change this range
```

### Customizing Storage Sizes

Edit PVC sizes in manifest files:
- **Longhorn**: `manifests/longhorn.yaml`
- **Jenkins**: `manifests/jenkins.yaml` (default: 50Gi)
- **Portainer**: `manifests/portainer.yaml` (default: 10Gi)
- **Prometheus**: `manifests/prometheus-grafana.yaml` (default: 50Gi)
- **Grafana**: `manifests/prometheus-grafana.yaml` (default: 10Gi)
- **Loki**: `manifests/loki.yaml` (default: 50Gi)
- **MinIO**: `manifests/minio.yaml` (default: 100Gi per node)

### Adding Custom Talos Extensions

Edit `main.tf`:

```hcl
talos_extensions = [
  "siderolabs/iscsi-tools",
  "siderolabs/util-linux-tools",
  "siderolabs/qemu-guest-agent",
  # Add more extensions from: https://github.com/siderolabs/extensions
]
```

### Per-Node Customization

Override defaults per node in `terraform.tfvars`:

```hcl
nodes = {
  "gpu-worker-01" = {
    node_is_controlplane = false
    address = "10.198.141.110"
    override_talos_extensions = ["siderolabs/nvidia-container-toolkit"]
    override_talos_kernel_modules = ["nvidia", "nvidia_uvm"]
  }
}
```

---

## 🔐 Accessing Services

### Default Credentials

| Service | Username | Password | Notes |
|---------|----------|----------|-------|
| Grafana | `admin` | `admin` | Change on first login |
| MinIO | `admin` | `minio123456` | **CHANGE IMMEDIATELY** |
| Portainer | - | Set on first login | - |
| Jenkins | - | Auto-configured via JCasC | No setup wizard |
| ArgoCD | `admin` | In secret (see below) | - |

**ArgoCD Password**:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### Service URLs

After configuring DNS or using local hosts file:

- **ArgoCD**: https://argocd.example.com
- **Grafana**: https://grafana.example.com
- **Prometheus**: https://prometheus.example.com
- **Jenkins**: https://jenkins.example.com
- **Portainer**: https://portainer.example.com
- **MinIO Console**: https://minio-console.example.com
- **MinIO API**: https://minio-api.example.com

### Port-Forward Access (No DNS)

```bash
# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# ArgoCD
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Jenkins
kubectl port-forward -n jenkins svc/jenkins 8080:8080

# Portainer
kubectl port-forward -n portainer svc/portainer 9443:9443

# MinIO Console
kubectl port-forward -n minio svc/minio-console 9001:9001

# Longhorn UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
```

---

## 🛠️ Customization

### Creating Bootstrap Manifests

To add new Helm charts as bootstrap manifests:

1. **Generate manifest from Helm chart**:
```bash
helm repo add <repo-name> <repo-url>
helm repo update
helm template <deployment-name> <repo/chart> -n <namespace> > manifests/<deployment-name>.yaml
```

2. **Add namespace** to `manifests/namespaces.yaml` (if needed)

3. **Update `main.tf`**:
```hcl
cluster_inline_manifests = {
  # ... existing manifests ...
  "<deployment-name>" = "manifests/<deployment-name>.yaml"
}
```

4. **Apply changes**:
```bash
terraform apply
```

### Upgrading Components

To upgrade a component:

1. Generate new manifest with updated version
2. Replace old manifest file
3. Apply: `terraform apply` (for bootstrap node) or update via ArgoCD

---

## 🐛 Troubleshooting

### Cluster Not Bootstrapping

```bash
# Check Talos service status
talosctl -n <bootstrap_node_address> services

# Check etcd health
talosctl -n <bootstrap_node_address> etcd members

# View logs
talosctl -n <bootstrap_node_address> logs kubelet
```

### Pods Not Starting

```bash
# Check node status
kubectl get nodes -o wide

# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check Cilium status
kubectl -n kube-system exec -it ds/cilium -- cilium status

# Check Longhorn status
kubectl -n longhorn-system get pods
```

### Storage Issues

```bash
# Check Longhorn volumes
kubectl -n longhorn-system get volumes

# Check PVCs
kubectl get pvc -A

# Access Longhorn UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
# Visit: http://localhost:8000
```

### Networking Issues

```bash
# Check Cilium connectivity
kubectl -n kube-system exec -it ds/cilium -- cilium connectivity test

# Check MetalLB speakers
kubectl -n metallb-system get pods

# Check IP address pools
kubectl -n metallb-system get ipaddresspool
```

### Certificate Issues

```bash
# Check cert-manager pods
kubectl -n cert-manager get pods

# Check certificate status
kubectl get certificate -A

# Check certificate requests
kubectl get certificaterequest -A

# View cert-manager logs
kubectl -n cert-manager logs deploy/cert-manager
```

---

## 📚 Additional Resources

- [Talos Documentation](https://www.talos.dev/docs/)
- [Cilium Documentation](https://docs.cilium.io/)
- [Longhorn Documentation](https://longhorn.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

## 🔒 Security Recommendations

1. **Change default passwords** immediately:
   - MinIO root credentials
   - Grafana admin password

2. **Configure proper TLS certificates**:
   - Update email in `argocd-applications.yaml` for Let's Encrypt
   - Use production certificates (not staging)

3. **Enable RBAC** for all services

4. **Use secrets management**:
   - Consider using Sealed Secrets or External Secrets Operator
   - Never commit secrets to Git

5. **Network Policies**:
   - Implement Cilium network policies for namespace isolation

6. **Regular Updates**:
   - Keep Talos OS updated
   - Update component versions regularly

---

## 📝 License

This configuration is provided as-is for use with Talos OS and Kubernetes.

---

## 🤝 Contributing

Contributions welcome! Please ensure all manifests are tested before submitting.

---

**Cluster Version**: Talos 1.11.2
**Kubernetes Version**: As per Talos 1.11.2 (v1.32+)
**Last Updated**: 2025-10-21
