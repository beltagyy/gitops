# Talos + Cilium Elite Setup Guide

This guide walks you through setting up Talos with Cilium CNI and kube-proxy replacement, disabling the default Flannel CNI and kube-proxy.

## Prerequisites

- Talos CLI (`talosctl`) installed
- Helm installed
- kubectl configured
- Talos cluster nodes ready (control plane + worker nodes)

## Overview

By default, Talos ships with:
- **Flannel CNI** for networking
- **kube-proxy** for service load balancing

We're replacing these with:
- **Cilium CNI** with native routing and eBPF
- **Cilium kube-proxy replacement** using eBPF for better performance

## Configuration Files

- `talos-disable-cni-kube-proxy.yaml` - Patch to disable Flannel and kube-proxy
- `manifests/cilium-values.yaml` - Cilium Helm values
- `manifests/cilium.yaml` - Generated Cilium manifests

---

## Scenario 1: New Talos Cluster (Recommended)

### Step 1: Generate Talos Configuration with Patch

Generate machine configs with the CNI/kube-proxy disabled:

```bash
# Generate base configuration
talosctl gen config talos-cluster https://<control-plane-ip>:6443 \
  --config-patch @talos-disable-cni-kube-proxy.yaml

# This creates:
# - controlplane.yaml
# - worker.yaml
# - talosconfig
```

Or if you have existing base configs, patch them:

```bash
# Patch control plane config
talosctl machineconfig patch controlplane.yaml \
  --patch @talos-disable-cni-kube-proxy.yaml \
  -o controlplane-patched.yaml

# Patch worker config
talosctl machineconfig patch worker.yaml \
  --patch @talos-disable-cni-kube-proxy.yaml \
  -o worker-patched.yaml
```

### Step 2: Apply Configuration to Nodes

```bash
# Apply to control plane nodes
talosctl apply-config --insecure \
  --nodes <control-plane-ip> \
  --file controlplane-patched.yaml

# Apply to worker nodes
talosctl apply-config --insecure \
  --nodes <worker-ip> \
  --file worker-patched.yaml
```

### Step 3: Bootstrap Kubernetes

```bash
# Bootstrap etcd on first control plane node
talosctl bootstrap --nodes <control-plane-ip>

# Get kubeconfig
talosctl kubeconfig --nodes <control-plane-ip>
```

### Step 4: Verify Nodes (Will be NotReady - Expected!)

```bash
kubectl get nodes
# Nodes will be NotReady because there's no CNI yet
```

### Step 5: Install Cilium

```bash
# Install Cilium manifests
kubectl apply -f manifests/cilium.yaml

# Wait for Cilium to be ready
kubectl -n kube-system rollout status daemonset/cilium
kubectl -n kube-system rollout status deployment/cilium-operator
```

### Step 6: Verify Cluster

```bash
# Check nodes are now Ready
kubectl get nodes

# Check Cilium status
kubectl -n kube-system get pods -l k8s-app=cilium

# Install Cilium CLI for verification (optional)
cilium status
cilium connectivity test
```

---

## Scenario 2: Existing Talos Cluster (Migration)

⚠️ **WARNING**: This will cause temporary network disruption. Plan maintenance window.

### Step 1: Prepare Cilium Manifests

Ensure `manifests/cilium.yaml` is ready.

### Step 2: Apply Patch to Existing Cluster

```bash
# Get current control plane config
talosctl get machineconfig -n <control-plane-ip> -o yaml > current-controlplane.yaml

# Patch it
talosctl machineconfig patch current-controlplane.yaml \
  --patch @talos-disable-cni-kube-proxy.yaml \
  -o controlplane-patched.yaml

# Apply to control plane (one at a time for HA)
talosctl apply-config --nodes <control-plane-1> \
  --file controlplane-patched.yaml

# Wait for node to reboot and come back
talosctl health --nodes <control-plane-1>

# Repeat for other control plane nodes (if HA)
```

### Step 3: Apply to Worker Nodes

```bash
# Same process for workers
talosctl get machineconfig -n <worker-ip> -o yaml > current-worker.yaml

talosctl machineconfig patch current-worker.yaml \
  --patch @talos-disable-cni-kube-proxy.yaml \
  -o worker-patched.yaml

talosctl apply-config --nodes <worker-ip> \
  --file worker-patched.yaml
```

### Step 4: Deploy Cilium

```bash
# Nodes will be NotReady after reboot
kubectl apply -f manifests/cilium.yaml

# Wait for Cilium
kubectl -n kube-system rollout status daemonset/cilium
```

### Step 5: Verify Migration

```bash
# Check nodes
kubectl get nodes

# Check pods
kubectl get pods -A

# Verify no Flannel pods remain
kubectl get pods -n kube-system | grep flannel
# Should return nothing

# Verify kube-proxy is gone
kubectl get pods -n kube-system | grep kube-proxy
# Should return nothing

# Check Cilium status
cilium status
```

---

## Scenario 3: Using Terraform/IaC

If you're using Terraform or another IaC tool:

### Step 1: Add Patch to Machine Config Data Source

```hcl
# In your Terraform/Talos config
data "talos_machine_configuration" "controlplane" {
  cluster_name     = "talos-cluster"
  machine_type     = "controlplane"
  cluster_endpoint = "https://control-plane-ip:6443"

  # Add config patches
  config_patches = [
    file("${path.module}/talos-disable-cni-kube-proxy.yaml")
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = "talos-cluster"
  machine_type     = "worker"
  cluster_endpoint = "https://control-plane-ip:6443"

  config_patches = [
    file("${path.module}/talos-disable-cni-kube-proxy.yaml")
  ]
}
```

### Step 2: Apply Terraform

```bash
terraform plan
terraform apply
```

### Step 3: Deploy Cilium

```bash
kubectl apply -f manifests/cilium.yaml
```

---

## Verification Steps

### 1. Check Talos Configuration

Verify the patch was applied:

```bash
talosctl get machineconfig -n <node-ip> -o yaml | grep -A 5 "cni:"
# Should show: name: none

talosctl get machineconfig -n <node-ip> -o yaml | grep -A 3 "proxy:"
# Should show: disabled: true
```

### 2. Verify Cilium is Running

```bash
# Check Cilium pods
kubectl get pods -n kube-system -l k8s-app=cilium

# All should be Running:
# - cilium-xxxxx (DaemonSet - one per node)
# - cilium-operator-xxxxx (Deployment - 2 replicas)
# - hubble-relay-xxxxx (Deployment - 2 replicas)
# - hubble-ui-xxxxx (Deployment - 2 replicas)
```

### 3. Verify Kube-proxy Replacement

```bash
# Check Cilium status
kubectl exec -n kube-system ds/cilium -- cilium status | grep KubeProxyReplacement
# Should show: KubeProxyReplacement: True

# Verify no kube-proxy
kubectl get pods -n kube-system -l k8s-app=kube-proxy
# Should return: No resources found
```

### 4. Verify Networking

```bash
# Test pod-to-pod connectivity
kubectl run test-1 --image=nginx --restart=Never
kubectl run test-2 --image=busybox --restart=Never -- sleep 3600

# Get test-1 IP
TEST1_IP=$(kubectl get pod test-1 -o jsonpath='{.status.podIP}')

# Test connectivity from test-2 to test-1
kubectl exec test-2 -- wget -qO- http://$TEST1_IP

# Cleanup
kubectl delete pod test-1 test-2
```

### 5. Run Cilium Connectivity Test

```bash
# Install Cilium CLI if not already installed
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-darwin-arm64.tar.gz
sudo tar xzvfC cilium-darwin-arm64.tar.gz /usr/local/bin
rm cilium-darwin-arm64.tar.gz

# Run connectivity test (comprehensive!)
cilium connectivity test

# This will:
# - Deploy test pods
# - Test L3/L4 connectivity
# - Test L7 policies
# - Test encryption (WireGuard)
# - Test service routing
# - Cleanup after
```

---

## Troubleshooting

### Issue: Nodes Stuck in NotReady

**Cause**: Cilium not deployed or not running

**Solution**:
```bash
# Check Cilium pods
kubectl get pods -n kube-system -l k8s-app=cilium

# Check logs
kubectl logs -n kube-system -l k8s-app=cilium --tail=100

# Common issues:
# - Image pull errors (check internet connectivity)
# - Insufficient permissions (check RBAC)
# - Node not labeled correctly
```

### Issue: Pods Can't Communicate

**Cause**: Cilium not fully initialized

**Solution**:
```bash
# Restart Cilium pods
kubectl delete pods -n kube-system -l k8s-app=cilium

# Wait for them to come back
kubectl wait --for=condition=ready pod -n kube-system -l k8s-app=cilium --timeout=300s
```

### Issue: "Connection refused" to Services

**Cause**: Kube-proxy replacement not working

**Solution**:
```bash
# Verify kube-proxy replacement is enabled
kubectl exec -n kube-system ds/cilium -- cilium status | grep KubeProxyReplacement

# If False, check cilium-values.yaml:
# kubeProxyReplacement: true
# k8sServiceHost: "127.0.0.1"
# k8sServicePort: "7445"

# Regenerate manifests and reapply
```

### Issue: High CPU Usage

**Cause**: Debug mode enabled

**Solution**:
```bash
# Check if debug is enabled in cilium-values.yaml
# debug:
#   enabled: false  # Should be false for production

# If true, set to false, regenerate manifests, and reapply
```

### Issue: Cilium Pods CrashLoopBackOff

**Cause**: Conflicting network configuration

**Solution**:
```bash
# Check if Flannel is still running
kubectl get pods -n kube-system | grep flannel
# If found, delete:
kubectl delete -n kube-system ds/kube-flannel-ds

# Check if kube-proxy is running
kubectl get pods -n kube-system | grep kube-proxy
# If found, check if Talos patch was applied correctly

# Verify patch
talosctl get machineconfig -n <node-ip> -o yaml | grep "disabled: true"
```

---

## Post-Installation

### 1. Install Gateway API CRDs

```bash
kubectl apply -f manifests/gateway-api-crds.yaml
```

### 2. Configure BGP (if using)

Edit `manifests/cilium-bgp-config.yaml` with your BGP peer details:

```yaml
neighbors:
- peerAddress: "YOUR_ROUTER_IP/32"
  peerASN: YOUR_ASN
```

Then apply:
```bash
kubectl apply -f manifests/cilium-bgp-config.yaml
```

### 3. Deploy Hubble UI

Hubble UI is included in the Cilium manifests. Access it:

```bash
# Port-forward
kubectl port-forward -n kube-system svc/hubble-ui 12000:80

# Or configure ingress (update hostname in cilium-values.yaml)
```

### 4. Install Longhorn Storage

```bash
kubectl apply -f manifests/longhorn.yaml
kubectl apply -f manifests/longhorn-storage-classes.yaml
kubectl apply -f manifests/longhorn-recurring-jobs.yaml
```

### 5. Deploy Example Network Policies

```bash
kubectl apply -f manifests/cilium-network-policies-examples.yaml
```

---

## Additional Talos-Specific Considerations

### Persistent Storage for Longhorn

Ensure Talos nodes have disk space:
- Default: `/var/lib/longhorn/`
- Talos already has this path available
- Verify: `talosctl ls /var/lib/longhorn/ -n <node-ip>`

### System Extensions

Talos includes everything needed for Cilium and Longhorn:
- iSCSI support (for Longhorn)
- eBPF support (for Cilium)
- WireGuard kernel module (for Cilium encryption)

No additional extensions required!

### Firewall Rules

Talos firewall is permissive by default for Kubernetes traffic. If you've customized it, ensure:
- Port 4240: Cilium health checks
- Port 4244: Hubble server
- Port 4245: Hubble relay
- Port 8472: VXLAN (if using VXLAN instead of native routing)
- Port 51871: WireGuard

---

## Complete Deployment Order

1. ✅ **Disable Flannel/kube-proxy**: Apply `talos-disable-cni-kube-proxy.yaml`
2. ✅ **Bootstrap Talos**: `talosctl bootstrap`
3. ✅ **Deploy Cilium**: `kubectl apply -f manifests/cilium.yaml`
4. ✅ **Verify Networking**: `cilium connectivity test`
5. ✅ **Deploy Gateway API**: `kubectl apply -f manifests/gateway-api-crds.yaml`
6. ✅ **Deploy Longhorn**: `kubectl apply -f manifests/longhorn.yaml`
7. ✅ **Deploy Storage Classes**: `kubectl apply -f manifests/longhorn-storage-classes.yaml`
8. ✅ **Configure Monitoring**: Deploy Prometheus/Grafana dashboards
9. ✅ **Deploy Applications**: Start deploying your workloads!

---

## Quick Reference Commands

```bash
# Talos
talosctl health --nodes <node-ip>
talosctl dashboard --nodes <node-ip>
talosctl logs -f -n <node-ip> kubelet

# Cilium
cilium status
cilium connectivity test
kubectl exec -n kube-system ds/cilium -- cilium monitor

# Networking
kubectl get ciliumendpoints -A
kubectl get ciliumidentities
kubectl get ciliumnetworkpolicies -A

# Longhorn
kubectl get volumes -n longhorn-system
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
```

---

## Support & Resources

- [Talos Documentation](https://www.talos.dev/latest/)
- [Talos + Cilium Guide](https://www.talos.dev/latest/kubernetes-guides/network/deploying-cilium/)
- [Cilium Documentation](https://docs.cilium.io/)
- [Longhorn Documentation](https://longhorn.io/docs/)

**Congratulations!** You now have an elite Kubernetes cluster with:
- ✅ Talos immutable OS
- ✅ Cilium CNI with eBPF kube-proxy replacement
- ✅ WireGuard encryption
- ✅ Hubble observability
- ✅ BGP support
- ✅ Longhorn distributed storage
- ✅ Full monitoring stack
