# Development Environment

Multi-node Kubernetes cluster for team development and experimentation.

## 🎯 Use Case

- Team development workflows
- Testing new features
- Component evaluation
- Integration testing
- Safe experimentation

## ⚙️ Specifications

| Aspect | Value |
|--------|-------|
| **Nodes** | 3 (1 control plane + 2 workers) |
| **Network** | 10.198.141.0/24 |
| **CNI** | Cilium minimal |
| **Storage** | OpenEBS LocalPV |
| **Observability** | Prometheus + Grafana + Loki |
| **Management** | Headlamp, Portainer |
| **Access** | Traefik Ingress + nip.io DNS |

## 🚀 Deployment

### 1. Get Node IPs

Assign IP addresses to 3 nodes:
```
Node 1 (Control): 10.198.141.20  # bootstrap node
Node 2 (Worker):  10.198.141.21
Node 3 (Worker):  10.198.141.22
```

### 2. Configure terraform.tfvars

```bash
cd talos/
cp ../envs/dev/terraform.tfvars .
vim terraform.tfvars
```

Example:
```hcl
env = "dev"
cluster_name = "k8s-dev"
bootstrap_node_address = "10.198.141.20"

nodes = {
  worker-1 = {
    address = "10.198.141.21"
    node_is_controlplane = false
  }
  worker-2 = {
    address = "10.198.141.22"
    node_is_controlplane = false
  }
}
```

### 3. Deploy

```bash
tofu plan
tofu apply  # Takes 5-10 minutes
```

### 4. Access Cluster

```bash
# Get kubeconfig
talosctl kubeconfig --nodes 10.198.141.20

# Verify
kubectl get nodes
```

## 🌐 Access Services

All accessible via Traefik at `10.198.141.235`:

| Service | URL | Credentials |
|---------|-----|-------------|
| Headlamp | headlamp.dev.dih.10.198.141.235.nip.io | Token-based |
| Portainer | portainer.dev.dih.10.198.141.235.nip.io | Set on first access |
| Grafana | grafana.dev.dih.10.198.141.235.nip.io | admin / admin |

Or port-forward:
```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
kubectl port-forward -n portainer svc/portainer 9443:9443
```

## 💾 Components Enabled

✅ Core:
- Cilium CNI (minimal)
- cert-manager
- OpenEBS storage

✅ Observability:
- Prometheus (50GB)
- Grafana
- Loki

✅ Management:
- Headlamp (Kubernetes dashboard)
- Portainer (container management)

❌ Optional (disabled):
- Longhorn (use OpenEBS for local perf)
- ArgoCD (enable in main.tf if needed)
- Jenkins (enable in main.tf if needed)

## 📝 Managing Applications

### Deploy New App

```bash
# Create manifest
mkdir -p apps/my-app
cat > apps/my-app/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
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
        image: nginx:latest
        ports:
        - containerPort: 80
EOF

# Deploy
kubectl apply -f apps/my-app/
```

### Scale App

```bash
kubectl scale deploy/my-app --replicas=3
```

### View Logs

```bash
# Stream logs
kubectl logs -f deploy/my-app

# View in Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Then Explore → Loki → {app="my-app"}
```

## 🔧 Troubleshooting

### Cluster Not Starting

```bash
# Check node health
talosctl --nodes 10.198.141.20 health

# Check node logs
talosctl --nodes 10.198.141.20 logs kubelet | tail -50
```

### Pods Stuck in Pending

```bash
# Check storage
kubectl get pvc -A
kubectl get storageclass

# Check events
kubectl get events -A --sort-by='.lastTimestamp' | tail -20
```

### Network Issues

```bash
# Check Cilium
kubectl get pods -n kube-system -l k8s-app=cilium

# Verify connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# ping <pod-ip>
```

## 📊 Monitoring

### Check Node Health

```bash
kubectl get nodes -o wide
```

### Monitor Pod Deployment

```bash
kubectl get pods -A --watch
```

### View Prometheus Targets

```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# http://localhost:9090/targets
```

## 🧹 Cleanup

### Delete Everything

```bash
cd talos/
tofu destroy
```

### Keep Cluster, Reset Apps

```bash
kubectl delete all --all -A
```

### Check Storage Before Destroy

```bash
# Backup any important data
kubectl get pvc -A
```

## 🎯 Next Steps

1. Deploy test applications
2. Enable ArgoCD for GitOps workflows
3. Test backup/restore procedures
4. Evaluate different storage backends
5. Load test cluster

## 📚 More Info

- [Talos Documentation](https://www.talos.dev/docs/)
- [Cilium Documentation](https://docs.cilium.io/)
- [OpenEBS Documentation](https://openebs.io/docs/)

---

Last updated: 2026-07-13
