# Talos Kubernetes Cluster - Production Deployment

This directory contains the **production Talos Kubernetes cluster** infrastructure-as-code using OpenTofu/Terraform, with a comprehensive stack of pre-configured services for networking, storage, monitoring, and management.

## Table of Contents

- [Overview](#overview)
- [Current Architecture](#current-architecture)
- [Directory Structure](#directory-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployed Services](#deployed-services)
- [Accessing Services](#accessing-services)
- [Storage Architecture](#storage-architecture)
- [Network Architecture](#network-architecture)
- [Upgrade Notes](#upgrade-notes)
- [Troubleshooting](#troubleshooting)
- [Additional Documentation](#additional-documentation)

---

## Overview

This Talos cluster deployment provides a **production-ready Kubernetes platform** with:

- **6-node cluster**: 3 control planes + 3 workers (highly available)
- **Talos OS v1.12.0** with critical extensions (iscsi-tools, qemu-guest-agent, util-linux-tools)
- **Cilium CNI** with L2 announcements and kube-proxy replacement
- **Multiple storage solutions**: OpenEBS (primary), Longhorn (distributed block storage)
- **Traefik ingress** with automatic service routing
- **Complete observability stack**: Prometheus, Grafana, Loki
- **GitOps-ready**: ArgoCD for continuous delivery
- **Management UIs**: Portainer, Headlamp, MinIO

**Environment**: `preprod`
**Cluster Name**: `preprod-cluster`
**Network**: `10.198.141.0/24`

---

## Current Architecture

### Cluster Nodes

```
┌─────────────────────────────────────────────────────────────────┐
│                   Talos v1.12.0 Kubernetes Cluster              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Control Plane (3 nodes)                                         │
│  ├── preprod-bootstrap-controlplane  10.198.141.73              │
│  ├── preprod-controlplane-01         10.198.141.71              │
│  └── preprod-controlplane-02         10.198.141.72              │
│                                                                  │
│  Worker Nodes (3 nodes)                                          │
│  ├── preprod-worker-01               10.198.141.74              │
│  ├── preprod-worker-02               10.198.141.75              │
│  └── preprod-worker-03               10.198.141.76              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Technology Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                         Application Layer                        │
├─────────────────────────────────────────────────────────────────┤
│  Management UIs                                                  │
│  ├── Portainer CE        - Container management                 │
│  ├── Headlamp            - Kubernetes dashboard                 │
│  └── MinIO Console       - Object storage UI                    │
│                                                                  │
│  Observability                                                   │
│  ├── Grafana             - Metrics & logs visualization         │
│  ├── Prometheus          - Metrics collection & alerting        │
│  └── Loki + Promtail     - Log aggregation                      │
│                                                                  │
│  GitOps & CI/CD (Optional)                                       │
│  ├── ArgoCD              - GitOps continuous delivery           │
│  ├── Jenkins             - CI/CD automation                     │
│  └── cert-manager        - TLS certificate management           │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                         Platform Layer                           │
├─────────────────────────────────────────────────────────────────┤
│  Ingress & Load Balancing                                        │
│  └── Traefik             - IngressRoute controller (10.198.141.235) │
│                                                                  │
│  Storage Solutions                                               │
│  ├── OpenEBS LocalPV     - Primary storage (local volumes)      │
│  └── Longhorn v1.7.2     - Distributed block storage (replicated) │
│                                                                  │
│  Networking                                                      │
│  └── Cilium v1.18        - CNI with L2 announcements            │
│                           - Native routing mode                  │
│                           - kube-proxy replacement               │
│                           - Hubble observability                 │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                      Talos OS v1.12.0                           │
├─────────────────────────────────────────────────────────────────┤
│  System Extensions (Schematic: 53513e54bb39202f35694412577a...)│
│  ├── qemu-guest-agent    - VM integration                       │
│  ├── iscsi-tools         - iSCSI for Longhorn (CRITICAL)        │
│  └── util-linux-tools    - Disk management utilities            │
│                                                                  │
│  Kernel Modules                                                  │
│  ├── nvme_tcp            - NVMe over TCP                        │
│  ├── rbd                 - Ceph RADOS block device              │
│  ├── br_netfilter        - Bridge netfilter for Cilium          │
│  └── overlay             - Overlay filesystem                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

```
.
├── manifests/                    # Kubernetes manifests for bootstrap
│   ├── CILIUM-ELITE-README.md   # Cilium advanced configuration guide
│   ├── LONGHORN-ELITE-README.md # Longhorn setup and tuning guide
│   ├── storage-guide.md         # Storage comparison and recommendations
│   │
│   ├── namespaces.yaml          # Cluster namespaces
│   ├── cilium-minimal.yaml      # Cilium CNI (core networking)
│   │
│   ├── openebs.yaml             # OpenEBS LocalPV (primary storage)
│   ├── longhorn.yaml            # Longhorn distributed storage
│   ├── longhorn-*.yaml          # Longhorn configuration files
│   │
│   ├── traefik-ingressroutes.yaml # Traefik IngressRoutes for all UIs
│   │
│   ├── cert_manager.yaml        # TLS certificate automation
│   ├── prometheus-grafana.yaml  # Monitoring stack
│   ├── loki.yaml                # Log aggregation
│   ├── grafana-hubble-dashboard-configmap.yaml
│   │
│   ├── portainer.yaml           # Container management UI
│   ├── headlamp.yaml            # Kubernetes dashboard
│   ├── minio.yaml               # S3-compatible object storage
│   │
│   ├── argocd.yaml              # GitOps CD (optional)
│   ├── argocd-applications.yaml # ArgoCD apps (optional)
│   └── jenkins.yaml             # CI/CD (optional)
│
├── templates/                    # Talos machine config templates
│   ├── disable_cni_kube_proxy.yaml      # Disable default CNI for Cilium
│   ├── network.yaml                      # Node network configuration
│   ├── allow_scheduling_on_controlplanes.yaml
│   └── longhorn-extensions.yaml
│
├── main.tf                       # Main Terraform configuration
├── variables.tf                  # Variable definitions
├── providers.tf                  # Terraform providers
├── terraform.tfvars              # Environment-specific values
│
├── preprod.talosconfig           # Talos CLI configuration
├── kubeconfig                    # Kubernetes CLI configuration
│
├── README.md                     # This file
├── UPGRADE_NOTES.md              # Talos v1.12.0 upgrade documentation
├── TALOS-CILIUM-SETUP.md         # Cilium setup guide
├── TERRAFORM-DEPLOYMENT.md       # Terraform deployment guide
└── CHEATSHEET.md                 # Quick reference commands
```

---

## Prerequisites

### Required Tools

- **OpenTofu/Terraform** >= 1.0
- **talosctl** - Talos OS CLI ([install](https://www.talos.dev/docs/latest/talos-guides/install/talosctl/))
- **kubectl** - Kubernetes CLI
- **helm** - Kubernetes package manager (optional, for manual installs)

### Install Tools (macOS)

```bash
# OpenTofu
brew install opentofu

# Talosctl
brew install siderolabs/tap/talosctl

# kubectl
brew install kubectl

# helm (optional)
brew install helm
```

### Infrastructure Requirements

- **Network**: Static IPs on same subnet with gateway access
- **DNS**: Internal DNS or nip.io for development
- **Hardware** (minimum per node):
  - 4 CPU cores
  - 8 GB RAM
  - 100 GB disk

---

## Quick Start

### 1. Clone Repository

```bash
git clone <repo-url>
cd gitops/talos
```

### 2. Configure Environment

Copy the example and customize:

```bash
cp example.terraform.tfvars terraform.tfvars
```

Edit `terraform.tfvars` with your node IPs and cluster name.

### 3. Deploy Cluster

```bash
# Initialize Terraform
tofu init

# Review changes
tofu plan

# Deploy cluster (nodes will bootstrap and install all services)
tofu apply

# This takes 5-10 minutes for full cluster initialization
```

### 4. Configure Access

```bash
# Set Talos config
export TALOSCONFIG=$(pwd)/preprod.talosconfig

# Get kubeconfig
talosctl kubeconfig --nodes 10.198.141.73

# Verify cluster
kubectl get nodes
kubectl get pods -A
```

### 5. Access Services

All services are available via Traefik ingress at `10.198.141.235`:

- **Portainer**: http://portainer.dev.dih.10.198.141.235.nip.io
- **Headlamp**: http://headlamp.dev.dih.10.198.141.235.nip.io
- **Longhorn UI**: http://longhorn.dev.dih.10.198.141.235.nip.io
- **MinIO Console**: http://minio.dev.dih.10.198.141.235.nip.io
- **Grafana**: http://grafana.dev.dih.10.198.141.235.nip.io

---

## Deployed Services

### Core Infrastructure

| Component | Version | Namespace | Purpose |
|-----------|---------|-----------|---------|
| Cilium CNI | v1.18.0 | kube-system | Pod networking, L2 announcements, kube-proxy replacement |
| Traefik | Latest | traefik | Ingress controller with IngressRoute CRDs |
| cert-manager | v1.19.1 | cert-manager | TLS certificate automation (Let's Encrypt) |

### Storage Solutions

| Component | Version | Namespace | Storage Class | Use Case |
|-----------|---------|-----------|---------------|----------|
| OpenEBS LocalPV | Latest | openebs | openebs-hostpath | Primary storage, local volumes, high performance |
| Longhorn | v1.7.2 | longhorn-system | longhorn, longhorn-retain | Distributed storage, replicated volumes, backups |

**Storage Decision Guide**:
- **OpenEBS**: Use for single-node workloads, databases requiring local SSD performance
- **Longhorn**: Use for replicated storage, cross-node failover, volume snapshots/backups

See `manifests/storage-guide.md` for detailed comparison.

### Observability Stack

| Component | Namespace | Purpose | Storage |
|-----------|-----------|---------|---------|
| Prometheus | monitoring | Metrics collection & alerting | 50 GB PVC |
| Grafana | monitoring | Metrics & logs visualization | 10 GB PVC |
| Loki | logging | Log aggregation | 50 GB PVC |
| Promtail | logging | Log collection agent (DaemonSet) | - |

**Pre-configured**:
- Prometheus datasource in Grafana
- Loki datasource in Grafana
- Hubble network observability dashboard
- 30-day metrics retention

### Management UIs

| Service | Namespace | Purpose | Credentials |
|---------|-----------|---------|-------------|
| Portainer CE | portainer | Container management platform | Set on first login |
| Headlamp | headlamp | Kubernetes dashboard | Token-based auth |
| Longhorn UI | longhorn-system | Storage management | No auth (internal) |
| MinIO Console | minio | Object storage UI | admin / minio123456 |

### Object Storage

**MinIO** (namespace: `minio`):
- **S3-compatible** object storage
- **4-node distributed** setup with erasure coding
- **Pre-created buckets**: backups, longhorn-backups, loki-logs, prometheus-backups
- **Credentials**: `admin / minio123456` (CHANGE IN PRODUCTION!)

### GitOps & CI/CD (Optional)

These are defined in manifests but **commented out** in `main.tf`:

- **ArgoCD**: GitOps continuous delivery
- **Jenkins**: CI/CD automation server

Uncomment in `main.tf` to enable.

---

## Accessing Services

### Service URLs (via Traefik Ingress)

All services use **nip.io** for DNS-free access:

```bash
# Management UIs
Portainer:      http://portainer.dev.dih.10.198.141.235.nip.io
Headlamp:       http://headlamp.dev.dih.10.198.141.235.nip.io
Longhorn UI:    http://longhorn.dev.dih.10.198.141.235.nip.io
MinIO Console:  http://minio.dev.dih.10.198.141.235.nip.io

# Monitoring
Grafana:        http://grafana.dev.dih.10.198.141.235.nip.io
```

**Note**: Traefik LoadBalancer IP: `10.198.141.235`

### Port-Forward Access (Alternative)

```bash
# Portainer (HTTPS)
kubectl port-forward -n portainer svc/portainer 9443:9443
# Access: https://localhost:9443

# Headlamp
kubectl port-forward -n headlamp svc/headlamp 8080:80
# Access: http://localhost:8080

# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Access: http://localhost:3000

# Longhorn UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
# Access: http://localhost:8000

# MinIO Console
kubectl port-forward -n minio svc/minio-console 9001:9001
# Access: http://localhost:9001
```

### Default Credentials

| Service | Username | Password | Notes |
|---------|----------|----------|-------|
| Grafana | `admin` | `admin` | Change on first login |
| MinIO | `admin` | `minio123456` | **CHANGE IMMEDIATELY** |
| Portainer | - | Set on first access | Create admin account |
| Headlamp | - | Token-based | Use ServiceAccount token |

**Grafana** (change password on first login):
```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Visit http://localhost:3000, login admin/admin, set new password
```

**Headlamp** (get access token):
```bash
kubectl get secret -n headlamp headlamp-token -o jsonpath='{.data.token}' | base64 -d
```

---

## Storage Architecture

### OpenEBS LocalPV (Primary)

- **Type**: Local path provisioner
- **Storage Class**: `openebs-hostpath`
- **Replicas**: No replication (data stays on single node)
- **Performance**: Maximum performance (direct local disk access)
- **Use Cases**:
  - High-performance databases (PostgreSQL, MySQL)
  - Single-node stateful apps
  - Temporary/cache storage
  - Build artifacts

### Longhorn v1.7.2 (Distributed)

- **Type**: Distributed block storage
- **Storage Classes**:
  - `longhorn` (default, ReclaimPolicy: Delete)
  - `longhorn-retain` (ReclaimPolicy: Retain)
- **Replicas**: 3 (configurable per volume)
- **Features**:
  - Cross-node replication
  - Volume snapshots and backups
  - Disaster recovery to S3 (MinIO)
  - Live volume expansion
- **Use Cases**:
  - Critical data requiring replication
  - Cross-node pod mobility
  - Backup/restore requirements
  - Prometheus/Grafana/Loki data

**Longhorn requires iscsi-tools extension** - see [UPGRADE_NOTES.md](UPGRADE_NOTES.md)

### Storage Capacity

Monitor storage usage:

```bash
# OpenEBS volumes
kubectl get pvc -A | grep openebs

# Longhorn volumes and health
kubectl get volumes -n longhorn-system
kubectl get pods -n longhorn-system -l app=longhorn-manager

# Access Longhorn UI for detailed stats
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
```

---

## Network Architecture

### Cilium CNI Configuration

**Mode**: Native routing with L2 announcements
**Features Enabled**:
- kube-proxy replacement (eBPF-based)
- L2 announcements for LoadBalancer services
- Hubble network observability
- Bandwidth manager for QoS
- VXLAN tunneling disabled (native routing)

**Network Policies**: Cilium supports advanced network policies (see `manifests/cilium-network-policies-examples.yaml`)

### Traefik Ingress

**LoadBalancer IP**: `10.198.141.235`
**Entry Points**:
- `web` (port 80)
- `websecure` (port 443)

**IngressRoute Configuration**: All service routes defined in `manifests/traefik-ingressroutes.yaml`

**TLS**: Currently using HTTP, cert-manager available for HTTPS (see cert-manager section)

### Networking Commands

```bash
# Check Cilium status
kubectl -n kube-system exec -it ds/cilium -- cilium status

# Check Cilium connectivity
kubectl -n kube-system exec -it ds/cilium -- cilium connectivity test

# View Hubble flows (network traffic)
kubectl port-forward -n kube-system svc/hubble-relay 4245:80
hubble observe --server localhost:4245

# Check Traefik routes
kubectl get ingressroute -A

# Check LoadBalancer IPs
kubectl get svc -A | grep LoadBalancer
```

---

## Upgrade Notes

### Talos v1.12.0 Upgrade

The cluster has been upgraded to **Talos v1.12.0** with critical extensions for Longhorn compatibility.

**Key Changes**:
- Talos version: v1.11.2 → v1.12.0
- **iscsi-tools extension**: Required for Longhorn iSCSI volumes
- **Schematic ID**: `53513e54bb39202f35694412577a6bc53d484744d35a126e5d42ef34785c0d83`

**Current Status**:
- ✅ **Upgraded nodes**: preprod-worker-01, preprod-bootstrap-controlplane
- ⏳ **Pending nodes**: preprod-controlplane-01, preprod-controlplane-02, preprod-worker-02, preprod-worker-03

**To complete the upgrade**:

```bash
# Review changes
tofu plan

# Apply to remaining nodes (rolling upgrade, one node at a time)
tofu apply

# Verify all nodes have extensions
export TALOSCONFIG=preprod.talosconfig
talosctl --nodes 10.198.141.71,10.198.141.72,10.198.141.74,10.198.141.75 get extensions
```

**See [UPGRADE_NOTES.md](UPGRADE_NOTES.md) for detailed upgrade documentation.**

---

## Troubleshooting

### Common Issues

#### 1. Pods Stuck in Pending

```bash
# Check node resources
kubectl top nodes

# Check PVC status
kubectl get pvc -A

# Check events
kubectl get events -A --sort-by='.lastTimestamp'
```

#### 2. Storage Issues

```bash
# Check Longhorn health
kubectl get pods -n longhorn-system
kubectl get volumes -n longhorn-system

# Check for iscsi-tools extension
export TALOSCONFIG=preprod.talosconfig
talosctl --nodes <node-ip> get extensions

# Longhorn manager logs
kubectl logs -n longhorn-system -l app=longhorn-manager --tail=50
```

#### 3. Networking Issues

```bash
# Check Cilium pods
kubectl get pods -n kube-system -l k8s-app=cilium

# Cilium status
kubectl -n kube-system exec -it ds/cilium -- cilium status

# Check Traefik
kubectl get pods -n traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik
```

#### 4. Ingress Not Working

```bash
# Verify Traefik is running
kubectl get svc -n traefik traefik

# Check IngressRoutes
kubectl get ingressroute -A

# Test Traefik directly
curl -v http://10.198.141.235

# Check specific route
curl -v -H "Host: portainer.dev.dih.10.198.141.235.nip.io" http://10.198.141.235
```

#### 5. Node Reboot / Extension Lost

If a node loses extensions after reboot:

```bash
# Check current extensions
talosctl --nodes <node-ip> get extensions

# Manually upgrade with correct schematic
talosctl --nodes <node-ip> upgrade \
  --image factory.talos.dev/installer/53513e54bb39202f35694412577a6bc53d484744d35a126e5d42ef34785c0d83:v1.12.0

# Then apply Terraform to make permanent
tofu apply
```

### Useful Commands

```bash
# Cluster health overview
kubectl get nodes
kubectl get pods -A | grep -v Running

# Talos node health
export TALOSCONFIG=preprod.talosconfig
talosctl --nodes 10.198.141.73 health

# etcd health
talosctl --nodes 10.198.141.73 etcd members

# Node logs
talosctl --nodes <node-ip> logs kubelet
talosctl --nodes <node-ip> logs containerd

# Restart a crashed pod
kubectl delete pod <pod-name> -n <namespace>
```

---

## Additional Documentation

### In This Directory

- **[UPGRADE_NOTES.md](UPGRADE_NOTES.md)** - Talos v1.12.0 upgrade with iscsi-tools
- **[TALOS-CILIUM-SETUP.md](TALOS-CILIUM-SETUP.md)** - Cilium CNI setup and configuration
- **[TERRAFORM-DEPLOYMENT.md](TERRAFORM-DEPLOYMENT.md)** - Terraform deployment guide
- **[CHEATSHEET.md](CHEATSHEET.md)** - Quick reference commands

### In Manifests Directory

- **[manifests/CILIUM-ELITE-README.md](manifests/CILIUM-ELITE-README.md)** - Advanced Cilium features
- **[manifests/LONGHORN-ELITE-README.md](manifests/LONGHORN-ELITE-README.md)** - Longhorn advanced setup
- **[manifests/storage-guide.md](manifests/storage-guide.md)** - Storage solution comparison

### External Resources

- [Talos Documentation](https://www.talos.dev/docs/)
- [Cilium Documentation](https://docs.cilium.io/)
- [Longhorn Documentation](https://longhorn.io/docs/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [OpenEBS Documentation](https://openebs.io/docs/)

---

## Configuration Customization

### Adding New Services

To deploy additional services via bootstrap:

1. **Generate manifest**:
```bash
helm repo add <repo> <url>
helm template <name> <chart> -n <namespace> > manifests/<name>.yaml
```

2. **Add to main.tf**:
```hcl
cluster_inline_manifests = {
  # ... existing ...
  "<name>" = "manifests/<name>.yaml"
}
```

3. **Apply**:
```bash
tofu apply
```

### Customizing Node Configuration

Per-node overrides in `terraform.tfvars`:

```hcl
nodes = {
  "special-worker" = {
    node_is_controlplane = false
    address = "10.198.141.100"
    override_talos_extensions = ["siderolabs/nvidia-container-toolkit"]
    override_talos_kernel_modules = ["nvidia", "nvidia_uvm"]
  }
}
```

### Updating Component Versions

1. Regenerate manifest with new version
2. Replace old manifest file
3. Run `tofu apply` (bootstrap node) or manually apply

**Example - Upgrading Longhorn**:
```bash
helm repo update
helm template longhorn longhorn/longhorn --namespace longhorn-system \
  --version 1.8.0 > manifests/longhorn.yaml
tofu apply
```

---

## Security Recommendations

1. **Change default passwords immediately**:
   - MinIO: `admin / minio123456`
   - Grafana: `admin / admin`

2. **Enable TLS for production**:
   - Configure cert-manager with Let's Encrypt
   - Update IngressRoutes with TLS configuration

3. **Implement network policies**:
   - Use Cilium NetworkPolicies for namespace isolation
   - See `manifests/cilium-network-policies-examples.yaml`

4. **Secure storage**:
   - Enable Longhorn backup to MinIO with encryption
   - Use `longhorn-retain` storage class for critical data

5. **Regular updates**:
   - Monitor Talos OS releases
   - Update component versions quarterly
   - Test in preprod before production

6. **RBAC**:
   - Review and restrict ServiceAccount permissions
   - Use dedicated namespaces for tenant isolation

---

## Cluster Specifications

- **Talos OS Version**: v1.12.0
- **Kubernetes Version**: v1.32+ (as per Talos v1.12.0)
- **Schematic ID**: 53513e54bb39202f35694412577a6bc53d484744d35a126e5d42ef34785c0d83
- **CNI**: Cilium v1.18.0
- **Primary Storage**: OpenEBS LocalPV
- **Distributed Storage**: Longhorn v1.7.2
- **Ingress**: Traefik (latest)
- **Last Updated**: 2026-01-02

---

## Support & Contributing

For issues or questions:
- Check troubleshooting section above
- Review additional documentation in this directory
- Consult official Talos/Kubernetes documentation

Contributions welcome - test thoroughly before submitting changes.

---

**Deployed with**: OpenTofu/Terraform
**Managed by**: GitOps repository
