# Environment Management Guide

How to work with multiple environments (local, dev, staging, prod).

## 🎯 Quick Reference

### Switch to an Environment

```bash
cd talos/
cp ../envs/<environment>/terraform.tfvars .
tofu plan
tofu apply
```

### Supported Environments

| Env | Location | Use Case | Nodes |
|-----|----------|----------|-------|
| **local** | Your machine | Learning, testing | 1 (Kind) |
| **dev** | 10.198.141.0/24 | Team development | 3 |
| **staging** | 10.198.142.0/24 | Pre-prod validation | 3 |
| **prod** | 10.198.143.0/24 | Production workloads | 6+ |

## 🚀 Typical Workflow

### 1. Develop Locally

```bash
# Setup local Kind cluster
scripts/kind-setup.sh

# Test manifest changes
kubectl apply -f manifests/

# Iterate until working
```

### 2. Deploy to Dev

```bash
cd talos/
cp ../envs/dev/terraform.tfvars .
vim terraform.tfvars  # Adjust IPs if needed

tofu plan
tofu apply

# Access services
kubectl get svc -A
```

### 3. Validate in Staging

```bash
# Copy current state
cp talos/terraform.tfvars envs/dev/terraform.tfvars

# Switch to staging
cp envs/staging/terraform.tfvars talos/

cd talos/
tofu apply  # Deploys to staging

# Run tests
./tests/integration_tests.sh
```

### 4. Promote to Production

```bash
# Final review
cd talos/
cp envs/prod/terraform.tfvars .
tofu plan -out=prod_plan

# Review very carefully!
less prod_plan

# Deploy
tofu apply prod_plan
```

## 📝 Configuration Details

### Environment-Specific Values

Each environment customizes:

**terraform.tfvars**:
- Cluster name
- Node IP addresses
- Number of nodes
- Environment tag

**main.tf** (optional):
- Component enablement
- Resource limits
- Replica counts
- Backup strategies

### Example: Enabling Features per Environment

```hcl
# In talos/main.tf

cluster_inline_manifests = merge(
  # Always deploy
  {
    namespaces = "manifests/00-namespaces/namespaces.yaml"
    cilium = "manifests/10-networking/cilium-minimal.yaml"
  },
  # Production only
  var.env == "prod" ? {
    longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
    argocd = "manifests/60-gitops/argocd/argocd.yaml"
  } : {},
  # Staging and prod
  contains(["staging", "prod"], var.env) ? {
    "prometheus-grafana" = "manifests/40-observability/prometheus/prometheus-grafana.yaml"
  } : {}
)
```

## 🔄 Managing State

### Terraform State Files

Each environment should have separate state:

```bash
# For dev
tofu init -backend-config="path=terraform_dev.tfstate"

# For prod
tofu init -backend-config="path=terraform_prod.tfstate"

# Or use remote backend
tofu init -backend-config="bucket=my-org-terraform" \
          -backend-config="key=prod/terraform.tfstate"
```

### Backing Up State

```bash
# Before any major changes
cp talos/terraform.tfstate talos/terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)

# After successful deployment
git add talos/terraform.tfstate  # If tracking (risky!)
# Better: Store in S3 or similar
```

## 🧪 Testing Changes

### Dry Run

```bash
cd talos/
tofu plan -out=test.tfplan

# Review the plan
less test.tfplan

# Don't apply, just verify output
```

### Sandbox Environment

Use dev/staging for testing:

```bash
# Make changes to manifests
vim talos/manifests/30-storage/longhorn/README.md

cd talos/
cp envs/dev/terraform.tfvars .
tofu apply

# Test in dev first
kubectl get pods -n longhorn-system

# If good, promote to staging
```

## 🔀 Promotion Pipeline

### From Dev to Staging

```bash
# 1. Ensure dev is working
cd talos/
cp envs/dev/terraform.tfvars .
tofu apply

# 2. Run tests
kubectl run test --image=busybox -- sh

# 3. Save current manifests
git add -A && git commit -m "tested in dev"

# 4. Switch to staging
cp envs/staging/terraform.tfvars .
tofu apply

# 5. Verify staging
kubectl get nodes
```

### From Staging to Production

```bash
# CRITICAL: Never skip validation!

# 1. Comprehensive staging validation
cd talos/
cp envs/staging/terraform.tfvars .

# Run all tests
./tests/smoke_tests.sh
./tests/ha_tests.sh
./tests/backup_tests.sh

# 2. Get approval (if in team)
# (Manual step - create PR, get review)

# 3. Deploy to prod
cp envs/prod/terraform.tfvars .
tofu plan -out=prod.tfplan

# Review extremely carefully
less prod.tfplan

tofu apply prod.tfplan

# 4. Monitor closely
kubectl get pods -A --watch
```

## 🔧 Common Tasks

### Scale a Cluster

```bash
# Add more workers to dev
vim envs/dev/terraform.tfvars
# Add more entries to nodes {}

cp envs/dev/terraform.tfvars talos/
cd talos/
tofu apply
```

### Change Storage Backend

```bash
# Example: Switch from OpenEBS to Longhorn in staging

# 1. In main.tf, change manifests for staging
# 2. Update terraform.tfvars: env = "staging"
# 3. Test in dev first
# 4. Then in staging

tofu plan
# Review changes

tofu apply
```

### Update Component Version

```bash
# Example: Upgrade Cilium

# 1. Update manifest: talos/manifests/10-networking/cilium.yaml
# 2. Test in dev
# 3. Validate in staging
# 4. Deploy to prod

cd talos/
cp envs/dev/terraform.tfvars .
tofu plan  # Should show Cilium update

tofu apply
```

## 🚨 Troubleshooting

### Wrong Environment Deployed

```bash
# Check what you're about to deploy
cat talos/terraform.tfvars | grep env

# Make sure it's correct before apply!
tofu plan
```

### State Corruption

```bash
# If terraform state gets corrupted

# 1. Restore from backup
cp terraform.tfstate.backup terraform.tfstate

# 2. Or manually refresh state
tofu refresh

# 3. Check what state thinks vs reality
tofu state list
```

### Lost Configuration

```bash
# If you lose an environment config

# 1. Check git history
git log --oneline -- envs/

# 2. Restore from git
git checkout HEAD~5 -- envs/dev/terraform.tfvars

# 3. Or recreate from template
cp envs/dev/terraform.tfvars.backup envs/dev/terraform.tfvars
```

## 📚 Best Practices

1. **Always use `tofu plan` first**
   ```bash
   tofu plan -out=tfplan
   # Review plan carefully
   tofu apply tfplan
   ```

2. **Test in lower environments first**
   - local → dev → staging → prod

3. **Save state before major changes**
   ```bash
   cp terraform.tfstate terraform.tfstate.backup
   ```

4. **Document environment-specific settings**
   ```bash
   # In environment README
   echo "Note: Uses Longhorn HA with 3 replicas" >> envs/prod/README.md
   ```

5. **Use tags for releases**
   ```bash
   git tag -a prod-v1.0.0 -m "Production release v1.0.0"
   git push origin prod-v1.0.0
   ```

6. **Automate with CI/CD**
   - Git push → dev deploys automatically
   - Manual approval → staging deploys
   - Manual approval → prod deploys

## 🔗 Related Documentation

- [Terraform Documentation](https://www.terraform.io/docs/language/)
- [Talos Deployment](./talos/README.md)
- [Manifests Organization](./talos/manifests/README.md)
- [Local Development](./envs/local/README.md)

---

Last updated: 2026-07-13
