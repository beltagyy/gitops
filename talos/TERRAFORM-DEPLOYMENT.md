# Terraform Deployment Guide - Elite Talos + Cilium + Longhorn

This guide explains how to deploy your elite Kubernetes stack using Terraform with Talos inline manifests.

## What Changed

### Files Added/Modified

1. **templates/disable_cni_kube_proxy.yaml** - New template to disable Flannel and kube-proxy
2. **main.tf** - Updated with:
   - CNI/kube-proxy disable template
   - Elite Cilium manifests
   - Longhorn storage classes and recurring jobs
   - Gateway API CRDs
   - Headlamp dashboard
   - Grafana dashboards for Hubble and Longhorn

### New Inline Manifests Deployed

The following manifests are now automatically deployed via Talos inline manifests:

#### Networking (Deployed First)
- ✅ `cilium.yaml` - Elite Cilium CNI (native routing, WireGuard, Hubble, BGP, kube-proxy replacement)
- ✅ `gateway-api-crds.yaml` - Gateway API v1.2.1 CRDs

#### Storage
- ✅ `longhorn.yaml` - Longhorn distributed storage
- ✅ `longhorn-storage-classes.yaml` - 7 performance-tuned storage classes
- ✅ `longhorn-recurring-jobs.yaml` - Automated snapshots and backups

#### Dashboards & Monitoring
- ✅ `headlamp.yaml` - Kubernetes dashboard
- ✅ `grafana-hubble-dashboard-configmap.yaml` - Hubble flow visualization
- ✅ `grafana-dashboard-longhorn.yaml` - Longhorn storage metrics

## Architecture

```
Talos Bootstrap Node
├── Config Templates (Applied to all nodes)
│   ├── disable_cni_kube_proxy.yaml ← Disables Flannel & kube-proxy
│   ├── network.yaml                ← Node networking
│   └── allow_scheduling_on_controlplanes.yaml
│
└── Cluster Inline Manifests (Applied at cluster bootstrap)
    ├── 1. namespaces.yaml          ← Create namespaces first
    ├── 2. cilium.yaml              ← CNI MUST BE FIRST!
    ├── 3. gateway-api-crds.yaml    ← Gateway API support
    ├── 4. metallb.yaml             ← Load balancer
    ├── 5. ingress.yaml             ← Ingress controller
    ├── 6. cert-manager.yaml        ← Certificate management
    ├── 7. longhorn.yaml            ← Storage CSI
    ├── 8. longhorn-storage-classes.yaml
    ├── 9. longhorn-recurring-jobs.yaml
    ├── 10. headlamp.yaml           ← Dashboard
    ├── 11. argocd.yaml             ← GitOps
    ├── 12. prometheus-grafana.yaml ← Monitoring
    ├── 13. loki.yaml               ← Logging
    ├── 14. grafana dashboards      ← Dashboards
    └── ... (other apps)
```

## Deployment Order (Automated)

Talos inline manifests are applied in the order they're defined in `cluster_inline_manifests`. The critical order is:

1. **Namespaces** - Create all required namespaces
2. **Cilium CNI** - Networking MUST be first, nodes won't be Ready without it
3. **Gateway API** - Required by Cilium ingress controller
4. **Everything else** - Can deploy in any order after CNI is ready

## How It Works

### Config Templates

Applied to each node's machine configuration:

```yaml
# templates/disable_cni_kube_proxy.yaml
cluster:
  network:
    cni:
      name: none        # No Flannel
  proxy:
    disabled: true      # No kube-proxy
```

This is merged into the Talos machine config for both control plane and worker nodes.

### Inline Manifests

Deployed automatically during cluster bootstrap:

```hcl
cluster_inline_manifests = {
  cilium = "manifests/cilium.yaml"
  # ... more manifests
}
```

Talos will:
1. Read each manifest file
2. Apply them to the cluster in order
3. Wait for bootstrap to complete

## Prerequisites

1. **Terraform** - v1.0+
2. **Talos** - v1.11.2 (specified in main.tf)
3. **Generated Manifests** - All manifests in `manifests/` directory
4. **Network Configuration** - Update `terraform.tfvars` with your network settings

## Deployment Steps

### Step 1: Review Configuration

Check your `terraform.tfvars`:

```hcl
env                     = "prod"
cluster_name            = "kubernetes"
bootstrap_node_address  = "10.198.141.10"  # Your control plane IP

nodes = {
  "worker-1" = {
    address              = "10.198.141.11"
    node_is_controlplane = false
    # ... other settings
  }
  # ... more nodes
}
```

### Step 2: Initialize Terraform

```bash
cd /Users/melbeltagy/Downloads/gitops/talos

terraform init
```

### Step 3: Review Plan

```bash
terraform plan
```

Look for:
- ✅ Talos machine configs with CNI disabled
- ✅ Inline manifests for Cilium, Longhorn, etc.
- ✅ Config templates applied to all nodes

### Step 4: Apply Configuration

```bash
terraform apply
```

This will:
1. Generate Talos machine configs with CNI/kube-proxy disabled
2. Apply configs to all nodes
3. Bootstrap the cluster
4. Deploy all inline manifests automatically

### Step 5: Wait for Bootstrap

```bash
# Watch bootstrap progress
talosctl -n <bootstrap-node-ip> --talosconfig prod.talosconfig dmesg -f

# Or use dashboard
talosctl -n <bootstrap-node-ip> --talosconfig prod.talosconfig dashboard
```

### Step 6: Get Kubeconfig

Terraform should output this, but if not:

```bash
talosctl -n <bootstrap-node-ip> --talosconfig prod.talosconfig kubeconfig .
export KUBECONFIG=$(pwd)/kubeconfig
```

### Step 7: Verify Deployment

```bash
# Check nodes (should be Ready)
kubectl get nodes

# Check Cilium
kubectl get pods -n kube-system -l k8s-app=cilium

# Check Longhorn
kubectl get pods -n longhorn-system

# Check all manifests deployed
kubectl get pods -A
```

## Verification Checklist

### ✅ Talos Configuration

```bash
# Verify CNI is disabled
talosctl -n <node-ip> --talosconfig prod.talosconfig get machineconfig -o yaml | grep "name: none"

# Verify kube-proxy is disabled
talosctl -n <node-ip> --talosconfig prod.talosconfig get machineconfig -o yaml | grep "disabled: true"
```

### ✅ Cilium

```bash
# Check Cilium status
kubectl exec -n kube-system ds/cilium -- cilium status

# Verify kube-proxy replacement
kubectl exec -n kube-system ds/cilium -- cilium status | grep KubeProxyReplacement
# Should show: KubeProxyReplacement: True

# Check all Cilium components
kubectl get pods -n kube-system | grep cilium
# Expected:
# - cilium-xxxxx (DaemonSet - one per node)
# - cilium-operator-xxxxx (2 replicas)
# - hubble-relay-xxxxx (2 replicas)
# - hubble-ui-xxxxx (2 replicas)
```

### ✅ Longhorn

```bash
# Check Longhorn pods
kubectl get pods -n longhorn-system

# Check storage classes
kubectl get storageclass
# Expected: 7 storage classes (high-performance, high-availability, balanced, etc.)

# Check recurring jobs
kubectl get recurringjobs -n longhorn-system
# Expected: snapshot-hourly, snapshot-daily, backup-daily, etc.
```

### ✅ Gateway API

```bash
# Check Gateway API CRDs
kubectl get crd | grep gateway
# Expected: gatewayclasses, gateways, httproutes, etc.
```

### ✅ Headlamp

```bash
# Check Headlamp
kubectl get pods -n headlamp

# Port-forward to access
kubectl port-forward -n headlamp svc/headlamp 8080:80
# Open: http://localhost:8080
```

### ✅ Grafana Dashboards

```bash
# Check dashboards are deployed
kubectl get configmap -n monitoring | grep dashboard
# Expected: grafana-dashboard-hubble, grafana-dashboard-longhorn
```

## Updating the Cluster

### Update Manifests

1. **Regenerate manifests** (e.g., new Cilium version):
   ```bash
   cd manifests/
   helm template cilium cilium/cilium --version 1.17.1 \
     --namespace kube-system \
     --values cilium-values.yaml > cilium.yaml
   ```

2. **Apply via Terraform**:
   ```bash
   terraform apply
   ```

   Talos will update the inline manifests automatically.

### Add New Nodes

1. **Update `terraform.tfvars`**:
   ```hcl
   nodes = {
     # ... existing nodes
     "worker-3" = {
       address              = "10.198.141.13"
       node_is_controlplane = false
       # ...
     }
   }
   ```

2. **Apply**:
   ```bash
   terraform apply
   ```

The new node will get the same config templates (CNI disabled, etc.).

### Remove Nodes

1. **Update `terraform.tfvars`** - Remove node entry
2. **Apply**:
   ```bash
   terraform apply
   ```

## Troubleshooting

### Issue: Nodes Not Becoming Ready

**Symptom**: Nodes stay in `NotReady` state

**Cause**: Cilium not deployed or not running

**Solution**:
```bash
# Check Cilium pods
kubectl get pods -n kube-system -l k8s-app=cilium

# Check logs
kubectl logs -n kube-system -l k8s-app=cilium --tail=100

# Verify manifest is in inline manifests
talosctl -n <node-ip> --talosconfig prod.talosconfig get manifests
```

### Issue: Manifest Not Applied

**Symptom**: Expected resources not created

**Cause**: Manifest not in inline manifests or has errors

**Solution**:
```bash
# Check inline manifests on node
talosctl -n <node-ip> --talosconfig prod.talosconfig get manifests

# Check for errors
kubectl get events -A --sort-by='.lastTimestamp'

# Manually apply to test
kubectl apply -f manifests/<manifest-name>.yaml
```

### Issue: Terraform Apply Fails

**Symptom**: Terraform errors during apply

**Cause**: Various (network, syntax, resource conflicts)

**Solution**:
```bash
# Check Terraform state
terraform state list

# Validate configuration
terraform validate

# Check for syntax errors in manifests
kubectl apply --dry-run=client -f manifests/

# If stuck, force unlock (use with caution!)
terraform force-unlock <lock-id>
```

### Issue: Old Flannel Still Running

**Symptom**: Flannel pods still exist

**Cause**: Template not applied correctly

**Solution**:
```bash
# Check if template is applied
talosctl -n <node-ip> --talosconfig prod.talosconfig get machineconfig -o yaml | grep cni

# If "name: flannel", template not applied. Re-run:
terraform apply -replace="module.bootstrap-node.talos_machine_configuration_apply.this"
```

## Advanced Configuration

### Customize Cilium

Edit `manifests/cilium-values.yaml` and regenerate:

```bash
helm template cilium cilium/cilium --version 1.17.0 \
  --namespace kube-system \
  --values manifests/cilium-values.yaml > manifests/cilium.yaml

terraform apply
```

### Customize Longhorn

Edit `manifests/longhorn-values.yaml` and regenerate:

```bash
helm template longhorn longhorn/longhorn --version 1.7.2 \
  --namespace longhorn-system \
  --values manifests/longhorn-values.yaml > manifests/longhorn.yaml

terraform apply
```

### Add New Inline Manifests

1. **Create manifest** in `manifests/`
2. **Add to `main.tf`**:
   ```hcl
   cluster_inline_manifests = {
     # ... existing
     "my-new-app" = "manifests/my-new-app.yaml"
   }
   ```
3. **Apply**:
   ```bash
   terraform apply
   ```

### Change Deployment Order

Manifests are applied in the order defined in the map. To change order, reorder in `main.tf`:

```hcl
cluster_inline_manifests = {
  namespaces = "manifests/namespaces.yaml"
  cilium = "manifests/cilium.yaml"      # Must be first!
  # ... everything else
}
```

## Infrastructure as Code Benefits

### ✅ Declarative

All configuration in Git. No manual `kubectl apply`.

### ✅ Reproducible

Same Terraform config = identical clusters.

### ✅ Version Controlled

Git history tracks all changes.

### ✅ Automated

CI/CD can deploy changes automatically.

### ✅ Disaster Recovery

Rebuild entire cluster from code:
```bash
terraform destroy
terraform apply
```

## CI/CD Integration

### GitLab CI Example

```yaml
deploy:
  stage: deploy
  script:
    - terraform init
    - terraform plan
    - terraform apply -auto-approve
  only:
    - main
```

### GitHub Actions Example

```yaml
- name: Terraform Apply
  run: |
    terraform init
    terraform apply -auto-approve
```

## Best Practices

1. **Always run `terraform plan`** before `apply`
2. **Keep manifests in Git** - Version control everything
3. **Test manifest changes** with `kubectl apply --dry-run=client` first
4. **Backup Terraform state** - Use remote backend (S3, etc.)
5. **Use workspaces** for multiple environments (dev, staging, prod)
6. **Pin versions** - Talos, Cilium, Longhorn versions in code
7. **Document changes** - Comment complex configurations

## Remote State Backend (Recommended)

For production, use remote state:

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "talos/terraform.tfstate"
    region = "us-east-1"
  }
}
```

Or use Terraform Cloud, GitLab, etc.

## Summary

Your Terraform configuration now:
- ✅ Disables Flannel and kube-proxy automatically
- ✅ Deploys elite Cilium with all features
- ✅ Deploys Longhorn with 7 storage classes
- ✅ Configures automated snapshots and backups
- ✅ Deploys Headlamp dashboard
- ✅ Configures Grafana dashboards
- ✅ Everything is declarative and version controlled

Next steps:
1. Run `terraform plan` to review changes
2. Run `terraform apply` to deploy
3. Verify with the checklist above
4. Enjoy your elite Kubernetes cluster!

---

**Questions?** Check the other guides:
- **CILIUM-ELITE-README.md** - Cilium features and usage
- **LONGHORN-ELITE-README.md** - Storage configuration
- **TALOS-CILIUM-SETUP.md** - Manual setup guide
