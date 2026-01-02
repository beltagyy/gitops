# GitOps Infrastructure Repository

**Production-ready Kubernetes infrastructure managed with GitOps principles.**

This repository contains the complete infrastructure-as-code for deploying and managing a **Talos Kubernetes cluster** with a comprehensive platform stack including networking, storage, observability, CI/CD, and application management.

---

## Repository Overview

```
gitops/
├── talos/                    # Main infrastructure - Talos Kubernetes cluster
│   ├── manifests/           # Kubernetes manifests for all platform components
│   ├── templates/           # Talos machine configuration templates
│   ├── main.tf              # Terraform infrastructure definition
│   ├── README.md            # Comprehensive cluster documentation
│   └── UPGRADE_NOTES.md     # Talos v1.12.0 upgrade guide
│
├── apps/                     # Application deployments (managed by GitOps)
│   └── nginx/               # Example application
│
├── DEPLOYMENT_GUIDE.md       # Quick deployment guide
├── README.md                 # This file
├── Jenkinsfile              # CI/CD pipeline definition
└── deployment.yaml          # Generic deployment template
```

---

## Quick Navigation

### Core Documentation

| Document | Description |
|----------|-------------|
| **[talos/README.md](talos/README.md)** | Complete Talos cluster documentation - START HERE |
| **[talos/UPGRADE_NOTES.md](talos/UPGRADE_NOTES.md)** | Talos v1.12.0 upgrade guide with iscsi-tools |
| **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** | Quick deployment overview |
| **[talos/TALOS-CILIUM-SETUP.md](talos/TALOS-CILIUM-SETUP.md)** | Cilium CNI setup guide |
| **[talos/TERRAFORM-DEPLOYMENT.md](talos/TERRAFORM-DEPLOYMENT.md)** | Terraform deployment details |
| **[talos/CHEATSHEET.md](talos/CHEATSHEET.md)** | Quick command reference |

### Component-Specific Guides

| Guide | Topic |
|-------|-------|
| **[talos/manifests/CILIUM-ELITE-README.md](talos/manifests/CILIUM-ELITE-README.md)** | Advanced Cilium networking |
| **[talos/manifests/LONGHORN-ELITE-README.md](talos/manifests/LONGHORN-ELITE-README.md)** | Longhorn storage deep dive |
| **[talos/manifests/storage-guide.md](talos/manifests/storage-guide.md)** | Storage solution comparison |

---

## Infrastructure Stack

### Current Deployment: Preprod Environment

**Cluster**: `preprod-cluster` (6 nodes: 3 control planes + 3 workers)
**Talos OS**: v1.12.0
**Kubernetes**: v1.32+
**Network**: 10.198.141.0/24

### Platform Components

#### Networking Layer
- **Cilium CNI v1.18** - eBPF-based networking with kube-proxy replacement
- **Traefik Ingress** - HTTP/HTTPS routing with IngressRoute CRDs
- **L2 Announcements** - LoadBalancer service announcements via Cilium

#### Storage Layer
- **OpenEBS LocalPV** - Primary local storage for high-performance workloads
- **Longhorn v1.7.2** - Distributed block storage with 3-replica HA
- **MinIO** - S3-compatible object storage (4-node cluster, 400GB)

#### Observability Stack
- **Prometheus** - Metrics collection and alerting (50GB storage)
- **Grafana** - Metrics and logs visualization (10GB storage)
- **Loki + Promtail** - Log aggregation and collection (50GB storage)
- **Hubble** - Cilium network observability

#### Management & Operations
- **Portainer CE** - Container management web UI
- **Headlamp** - Kubernetes dashboard
- **cert-manager** - Automatic TLS certificate management

#### CI/CD & GitOps (Optional)
- **ArgoCD** - GitOps continuous delivery (commented out in config)
- **Jenkins** - CI/CD automation (commented out in config)

---

## Quick Start

### Prerequisites

**Tools Required**:
- OpenTofu/Terraform >= 1.0
- talosctl (Talos CLI)
- kubectl (Kubernetes CLI)
- helm (optional, for manual chart deployments)

**Install on macOS**:
```bash
brew install opentofu kubectl helm
brew install siderolabs/tap/talosctl
```

### Deploy the Cluster

1. **Clone Repository**:
```bash
git clone <repo-url>
cd gitops/talos
```

2. **Configure Environment**:
```bash
cp example.terraform.tfvars terraform.tfvars
# Edit terraform.tfvars with your node IPs
```

3. **Deploy Infrastructure**:
```bash
tofu init
tofu plan
tofu apply  # Takes 5-10 minutes
```

4. **Configure Access**:
```bash
export TALOSCONFIG=$(pwd)/preprod.talosconfig
talosctl kubeconfig --nodes 10.198.141.73
kubectl get nodes
```

**For detailed deployment instructions, see [talos/README.md](talos/README.md)**

---

## Accessing Services

### Management UIs (via Traefik Ingress)

All services are accessible via **Traefik LoadBalancer** at `10.198.141.235`:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Portainer** | http://portainer.dev.dih.10.198.141.235.nip.io | Set on first login |
| **Headlamp** | http://headlamp.dev.dih.10.198.141.235.nip.io | Token-based |
| **Longhorn UI** | http://longhorn.dev.dih.10.198.141.235.nip.io | No auth (internal) |
| **MinIO Console** | http://minio.dev.dih.10.198.141.235.nip.io | admin / minio123456 |
| **Grafana** | http://grafana.dev.dih.10.198.141.235.nip.io | admin / admin |

**Note**: All services use **nip.io** for DNS-free access in development environments.

### Port-Forward Access (Alternative)

```bash
# Grafana (monitoring)
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Access: http://localhost:3000

# Portainer (container management)
kubectl port-forward -n portainer svc/portainer 9443:9443
# Access: https://localhost:9443

# MinIO (object storage)
kubectl port-forward -n minio svc/minio-console 9001:9001
# Access: http://localhost:9001

# Longhorn (storage management)
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
# Access: http://localhost:8000
```

---

## Repository Structure

### /talos/ - Main Infrastructure

The **heart of this repository** - contains all infrastructure-as-code for the Talos Kubernetes cluster.

**Key files**:
- `main.tf` - Terraform configuration with all nodes and bootstrap manifests
- `variables.tf` - Input variable definitions
- `terraform.tfvars` - Environment-specific values (node IPs, cluster config)
- `manifests/` - 50+ Kubernetes manifests for platform components
- `templates/` - Talos machine configuration templates

**Documentation**:
- Comprehensive README with architecture, deployment, troubleshooting
- UPGRADE_NOTES for Talos version upgrades
- Component-specific guides in manifests/ directory

**See [talos/README.md](talos/README.md) for complete documentation.**

### /apps/ - Application Deployments

Application manifests managed via GitOps (e.g., ArgoCD).

**Current apps**:
- `nginx/` - Example NGINX deployment

**Structure**:
```
apps/
└── <app-name>/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    └── configmap.yaml
```

### Root Configuration Files

| File | Purpose |
|------|---------|
| `deployment.yaml` | Generic Kubernetes deployment template |
| `service.yaml` | Generic Kubernetes service template |
| `Jenkinsfile` | CI/CD pipeline definition |
| `sonar-project.properties` | SonarQube code quality config |
| `preprod.talosconfig` | Talos CLI configuration (symlinked from talos/) |

---

## Infrastructure Management

### Terraform Workflow

**Initial Deployment**:
```bash
cd talos/
tofu init
tofu plan -out=tfplan
tofu apply tfplan
```

**Updates**:
```bash
# Edit main.tf or manifests
tofu plan
tofu apply
```

**Destroy** (caution - deletes everything):
```bash
tofu destroy
```

### Talos Operations

**Node Management**:
```bash
export TALOSCONFIG=talos/preprod.talosconfig

# Check node health
talosctl --nodes 10.198.141.73 health

# Get node status
talosctl --nodes 10.198.141.73,10.198.141.74,10.198.141.75 get nodestatus

# View node logs
talosctl --nodes <node-ip> logs kubelet

# Reboot a node
talosctl --nodes <node-ip> reboot
```

**Cluster Bootstrap**:
```bash
# Get kubeconfig (run from talos/ directory)
talosctl kubeconfig --nodes 10.198.141.73

# Bootstrap cluster (only needed once)
talosctl bootstrap --nodes 10.198.141.73
```

### Kubernetes Operations

**Cluster Health**:
```bash
# Node status
kubectl get nodes -o wide

# All pods across namespaces
kubectl get pods -A

# Check core components
kubectl get pods -n kube-system
kubectl get pods -n longhorn-system
kubectl get pods -n monitoring
```

**Storage Management**:
```bash
# Check storage classes
kubectl get sc

# View persistent volume claims
kubectl get pvc -A

# Longhorn volumes
kubectl get volumes -n longhorn-system

# OpenEBS volumes
kubectl get pvc -A | grep openebs
```

---

## GitOps Workflow

### Adding New Applications

1. **Create application directory**:
```bash
mkdir -p apps/my-app
```

2. **Add Kubernetes manifests**:
```bash
cat > apps/my-app/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:latest
        ports:
        - containerPort: 8080
EOF
```

3. **Apply manually** (or use ArgoCD):
```bash
kubectl apply -f apps/my-app/
```

### Using ArgoCD (when enabled)

1. **Uncomment ArgoCD** in `talos/main.tf`:
```hcl
cluster_inline_manifests = {
  # ...
  argocd = "manifests/argocd.yaml"
  "argocd-applications" = "manifests/argocd-applications.yaml"
}
```

2. **Apply Terraform changes**:
```bash
cd talos/
tofu apply
```

3. **Access ArgoCD UI**:
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
# Get password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

4. **Create ArgoCD Application**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_ORG/gitops.git
    targetRevision: main
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## Monitoring & Observability

### Grafana Dashboards

**Access Grafana**:
```bash
# Port-forward
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Or visit: http://grafana.dev.dih.10.198.141.235.nip.io
```

**Pre-configured Datasources**:
- Prometheus: `http://prometheus.monitoring.svc.cluster.local:9090`
- Loki: `http://loki.logging.svc.cluster.local:3100`

**Pre-loaded Dashboards**:
- Hubble Network Observability (Cilium network flows)

### Viewing Logs

**Via Grafana** (Loki datasource):
```
# All logs from namespace
{namespace="default"}

# Logs from specific pod
{namespace="longhorn-system", pod="longhorn-manager-xxxxx"}

# Filter by log level
{namespace="kube-system"} |= "error"
```

**Via kubectl**:
```bash
# Pod logs
kubectl logs -n <namespace> <pod-name>

# Follow logs
kubectl logs -n <namespace> <pod-name> -f

# Previous container logs (after crash)
kubectl logs -n <namespace> <pod-name> --previous
```

### Metrics & Alerts

**Prometheus Targets**:
```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Visit: http://localhost:9090/targets
```

**Query Metrics**:
```promql
# Node CPU usage
node_cpu_seconds_total

# Pod memory usage
container_memory_usage_bytes{namespace="longhorn-system"}

# Longhorn volume health
longhorn_volume_actual_size_bytes
```

---

## Troubleshooting

### Common Issues

#### Pods Stuck in Pending

**Check**:
```bash
kubectl get pvc -A  # Check if PVCs are bound
kubectl describe pod <pod-name> -n <namespace>
kubectl get events -A --sort-by='.lastTimestamp'
```

**Solution**: Usually storage-related (Longhorn not ready or insufficient capacity)

#### Longhorn Manager Crashes

**Symptom**: `longhorn-manager` pods in CrashLoopBackOff
**Error**: `iscsiadm: No such file or directory`

**Solution**: Node missing iscsi-tools extension
```bash
# Check extensions
talosctl --nodes <node-ip> get extensions

# Upgrade node with correct schematic
talosctl --nodes <node-ip> upgrade \
  --image factory.talos.dev/installer/53513e54bb39202f35694412577a6bc53d484744d35a126e5d42ef34785c0d83:v1.12.0
```

**See [talos/UPGRADE_NOTES.md](talos/UPGRADE_NOTES.md) for details.**

#### Networking Issues

**Check Cilium**:
```bash
kubectl -n kube-system get pods -l k8s-app=cilium
kubectl -n kube-system exec -it ds/cilium -- cilium status
```

**Check Traefik**:
```bash
kubectl get pods -n traefik
kubectl get svc -n traefik
kubectl get ingressroute -A
```

#### Ingress Not Working

**Test Traefik**:
```bash
# Check if Traefik has external IP
kubectl get svc -n traefik traefik

# Test direct connection
curl -v http://10.198.141.235

# Test specific route
curl -v -H "Host: portainer.dev.dih.10.198.141.235.nip.io" http://10.198.141.235
```

### Getting Help

1. **Check documentation**:
   - [talos/README.md](talos/README.md) - Comprehensive troubleshooting section
   - [talos/CHEATSHEET.md](talos/CHEATSHEET.md) - Quick command reference

2. **View cluster events**:
```bash
kubectl get events -A --sort-by='.lastTimestamp' | tail -20
```

3. **Check component logs**:
```bash
# Cilium
kubectl logs -n kube-system -l k8s-app=cilium --tail=50

# Longhorn
kubectl logs -n longhorn-system -l app=longhorn-manager --tail=50

# Traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik --tail=50
```

---

## Security Considerations

### Change Default Passwords

**Critical - Change immediately**:

| Service | Default | Location |
|---------|---------|----------|
| MinIO | admin / minio123456 | `talos/manifests/minio.yaml` |
| Grafana | admin / admin | Login page after first access |

### Enable TLS

**cert-manager** is installed and ready for Let's Encrypt certificates.

To enable HTTPS:
1. Configure DNS for your domain
2. Update `talos/manifests/traefik-ingressroutes.yaml` with TLS configuration
3. Apply changes: `kubectl apply -f talos/manifests/traefik-ingressroutes.yaml`

### Network Policies

Cilium supports advanced **network policies** for namespace isolation.

**Example**: See `talos/manifests/cilium-network-policies-examples.yaml`

### RBAC

Review and restrict ServiceAccount permissions for production deployments.

---

## Maintenance

### Regular Tasks

**Weekly**:
- Monitor disk usage: `kubectl get pvc -A` and Longhorn UI
- Check pod health: `kubectl get pods -A | grep -v Running`
- Review Grafana dashboards for anomalies

**Monthly**:
- Review and rotate credentials
- Check for component updates
- Review Prometheus alerts

**Quarterly**:
- Update Talos OS version (see UPGRADE_NOTES.md)
- Update component versions (Cilium, Longhorn, etc.)
- Test backup/restore procedures

### Backup Strategy

**Longhorn Volumes**:
- Configure recurring snapshots in Longhorn UI
- Set backup target to MinIO (S3): `s3://longhorn-backups@us-east-1/`

**etcd (Talos)**:
```bash
# etcd snapshot (via Talos)
talosctl --nodes 10.198.141.73 etcd snapshot etcd-snapshot.db
```

**Terraform State**:
- State stored locally in `talos/terraform.tfstate`
- **Backup regularly** or use remote backend (S3, etc.)

---

## Contributing

### Adding New Components

1. **Generate manifest**:
```bash
helm repo add <repo> <url>
helm template <name> <chart> -n <namespace> > talos/manifests/<name>.yaml
```

2. **Add to bootstrap** in `talos/main.tf`:
```hcl
cluster_inline_manifests = {
  # ...
  "<name>" = "manifests/<name>.yaml"
}
```

3. **Document** in this README and `talos/README.md`

4. **Test deployment**:
```bash
cd talos/
tofu plan
tofu apply
kubectl get pods -n <namespace>
```

### Repository Guidelines

- Keep secrets out of Git (use Kubernetes Secrets or external secret management)
- Test changes in preprod before production
- Document all significant changes
- Use meaningful commit messages
- Update relevant README files

---

## Cluster Specifications

| Specification | Value |
|--------------|-------|
| **Talos OS** | v1.12.0 |
| **Kubernetes** | v1.32+ (bundled with Talos) |
| **Schematic ID** | 53513e54bb39202f35694412577a6bc53d484744d35a126e5d42ef34785c0d83 |
| **CNI** | Cilium v1.18.0 (native routing, kube-proxy replacement) |
| **Primary Storage** | OpenEBS LocalPV |
| **Distributed Storage** | Longhorn v1.7.2 (3-replica HA) |
| **Ingress** | Traefik (latest) |
| **LoadBalancer IP** | 10.198.141.235 |
| **Control Planes** | 3 nodes |
| **Workers** | 3 nodes |
| **Environment** | preprod |

---

## Technology Stack

### Infrastructure
- **IaC**: OpenTofu/Terraform
- **OS**: Talos Linux (immutable, API-driven)
- **Orchestration**: Kubernetes

### Networking
- **CNI**: Cilium (eBPF, native routing)
- **Ingress**: Traefik
- **Service Mesh**: (Optional, Cilium can provide)

### Storage
- **Block Storage**: Longhorn (distributed, replicated)
- **Local Storage**: OpenEBS LocalPV
- **Object Storage**: MinIO (S3-compatible)

### Observability
- **Metrics**: Prometheus + Grafana
- **Logs**: Loki + Promtail
- **Network**: Hubble (Cilium)

### Management
- **UI**: Portainer, Headlamp
- **GitOps**: ArgoCD (optional)
- **CI/CD**: Jenkins (optional)
- **Certificates**: cert-manager

---

## External Resources

### Official Documentation

- **Talos**: https://www.talos.dev/docs/
- **Kubernetes**: https://kubernetes.io/docs/
- **Cilium**: https://docs.cilium.io/
- **Longhorn**: https://longhorn.io/docs/
- **Traefik**: https://doc.traefik.io/traefik/
- **OpenEBS**: https://openebs.io/docs/
- **Prometheus**: https://prometheus.io/docs/
- **Grafana**: https://grafana.com/docs/
- **Loki**: https://grafana.com/docs/loki/

### Community

- Talos: https://github.com/siderolabs/talos
- Cilium Slack: https://cilium.io/slack
- CNCF Slack: https://slack.cncf.io/

---

## License

This repository is managed internally. All components deployed use their respective open-source licenses.

---

## Summary

This GitOps repository provides a **complete, production-ready Kubernetes platform** built on Talos OS with:

- ✅ High-availability 6-node cluster (3 control planes, 3 workers)
- ✅ Advanced networking with Cilium CNI and eBPF
- ✅ Dual storage solutions (local + distributed with HA)
- ✅ Complete observability stack (metrics, logs, network)
- ✅ Management UIs for all components
- ✅ GitOps-ready with ArgoCD support
- ✅ Comprehensive documentation

**Get Started**: See [talos/README.md](talos/README.md) for complete deployment guide.

**Last Updated**: 2026-01-02

---

**Questions or Issues?** Check [talos/README.md](talos/README.md) for comprehensive documentation and troubleshooting.
