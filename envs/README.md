# Environment Configurations

This directory contains environment-specific configurations for different deployment targets.

## 📋 Directory Structure

```
envs/
├── local/          # Local development (Kind cluster)
├── dev/            # Development environment
├── staging/        # Staging environment
├── prod/           # Production environment
└── README.md       # This file
```

## 🎯 Environment Overview

| Environment | Use Case | Network | Nodes | Storage | Observability |
|-------------|----------|---------|-------|---------|--------------|
| **local** | Testing, learning | localhost | 1 (Kind) | LocalPV | Basic |
| **dev** | Development & experimentation | 10.198.141.0/24 | 3 | OpenEBS | Full stack |
| **staging** | Pre-production testing | 10.198.142.0/24 | 3 | Longhorn HA | Full stack |
| **prod** | Production workloads | 10.198.143.0/24 | 6+ | Longhorn HA | Full stack |

## 🚀 Quick Start

### Deploy to an Environment

```bash
# Copy environment config
cd talos/
cp ../envs/dev/terraform.tfvars .

# Review and customize
vim terraform.tfvars

# Deploy
tofu plan
tofu apply
```

### Switch Environments

```bash
# Save current environment
cp talos/terraform.tfvars envs/dev/terraform.tfvars

# Load different environment
cp envs/staging/terraform.tfvars talos/

# Deploy
cd talos/
tofu apply
```

## 📝 Environment Files

Each environment directory contains:

### terraform.tfvars
Environment-specific Terraform variables:
- Cluster name and environment name
- Node IP addresses
- Network configuration
- Component enablement flags

### values-overrides/ (Optional)
Component-specific configuration overrides:
- Storage class settings
- Resource limits
- Replica counts
- Feature flags

### README.md
Environment-specific documentation:
- Setup prerequisites
- Deployment instructions
- Access information
- Troubleshooting

## 🔧 Configuration Management

### Using environment-specific variables

Edit `talos/variables.tf` to accept environment variable:

```hcl
variable "env" {
  description = "Environment name (local, dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["local", "dev", "staging", "prod"], var.env)
    error_message = "Environment must be local, dev, staging, or prod."
  }
}
```

Then in `terraform.tfvars`:

```hcl
env = "dev"
cluster_name = "k8s-cluster"
# ... other settings
```

### Component Enablement by Environment

```hcl
# In main.tf
cluster_inline_manifests = merge(
  # Always deploy
  {
    namespaces = "manifests/00-namespaces/namespaces.yaml"
    cilium = "manifests/10-networking/cilium-minimal.yaml"
    "cert-manager" = "manifests/20-security/cert_manager.yaml"
  },
  # Environment-specific
  var.env == "prod" ? {
    longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
    "prometheus-grafana" = "manifests/40-observability/prometheus/prometheus-grafana.yaml"
    loki = "manifests/40-observability/loki/loki.yaml"
    argocd = "manifests/60-gitops/argocd/argocd.yaml"
  } : {},
  var.env == "staging" ? {
    longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
  } : {},
  var.env == "dev" ? {
    openebs = "manifests/30-storage/openebs/openebs.yaml"
  } : {}
)
```

## 📚 Environment-Specific Guides

### Local Development (Kind)
See `local/README.md`
- Fast local testing
- Single-node cluster
- Minimal resources

### Development
See `dev/README.md`
- Team experimentation
- New feature testing
- Component evaluation

### Staging
See `staging/README.md`
- Pre-production validation
- Performance testing
- Integration testing

### Production
See `prod/README.md`
- HA configuration
- Backup strategy
- Monitoring & alerting
- Disaster recovery

## 🔄 Promotion Workflow

Typical development workflow:

```
Feature Branch
    ↓
local (Kind cluster)  ← Rapid iteration
    ↓
dev                   ← Team integration
    ↓
staging               ← Production validation
    ↓
prod                  ← Live deployment
```

### Example: Deploying a New Application

1. **Local**: Test app manifest locally
   ```bash
   cd envs/local
   kustomize build . | kubectl apply -f -
   ```

2. **Dev**: Deploy to dev cluster
   ```bash
   cd envs/dev
   kustomize build . | kubectl apply -f -
   ```

3. **Staging**: Validate in staging
   ```bash
   cd envs/staging
   kustomize build . | kubectl apply -f -
   ```

4. **Prod**: Deploy to production
   ```bash
   cd envs/prod
   kustomize build . | kubectl apply -f -
   ```

## 🎨 Configuration Patterns

### Using Kustomize for Component Configuration

Create `envs/dev/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: default

commonLabels:
  environment: dev

resources:
  - ../../talos/manifests/30-storage/longhorn/

patchesStrategicMerge:
  - longhorn-patch.yaml

configMapGenerator:
  - name: env-config
    literals:
      - ENVIRONMENT=dev
      - LOG_LEVEL=DEBUG
```

### Environment-Specific Patches

Create `envs/dev/longhorn-patch.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: longhorn-manager
spec:
  replicas: 1  # Single replica for dev
  template:
    spec:
      containers:
        - name: longhorn-manager
          resources:
            limits:
              memory: 256Mi
```

## 📊 Comparing Environments

```bash
# Show differences between environments
diff envs/dev/terraform.tfvars envs/prod/terraform.tfvars

# Dry-run deployment to staging
cd talos/
cp ../envs/staging/terraform.tfvars .
tofu plan -out=staging_plan
# Review carefully before apply
```

## 🔒 Secrets Management

Environment-sensitive values (passwords, API keys):

**Option 1: Use Kubernetes Secrets**
```bash
kubectl create secret generic my-secret \
  --from-literal=key=value \
  -n <namespace>
```

**Option 2: Use External Secrets Operator**
See manifests documentation for integration.

**Option 3: Use Git with sops encryption**
```bash
# Encrypt secrets
sops envs/dev/secrets.yaml

# Decrypt when needed
sops -d envs/dev/secrets.yaml
```

## ✅ Validation

Check environment configuration before deployment:

```bash
# Validate terraform
cd talos/
tofu validate

# Check manifests
kubectl apply -f manifests/ --dry-run=client

# Lint YAML
yamllint envs/*/
```

## 🚨 Important Notes

1. **Environment Isolation**: Keep environments separate to prevent crosstalk
2. **State Management**: Terraform state should be per-environment
3. **Backup State**: Regular backups of terraform.tfstate
4. **Version Pinning**: Pin component versions per environment
5. **Documentation**: Keep environment-specific docs up-to-date

## 🔗 See Also

- [Terraform Documentation](https://www.terraform.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [ArgoCD Multi-Environment](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)

---

Last updated: 2026-07-13
