# Quick Reference Guide

Fast answers to common questions.

## ❓ Common Questions

### "How do I enable Longhorn?"

```bash
cd talos/
# Edit main.tf line ~100, uncomment:
# longhorn = "manifests/30-storage/longhorn/longhorn.yaml"

tofu apply
```

See: [COMPONENT_STATUS.md](COMPONENT_STATUS.md#longhorn-distributed-storage)

### "How do I use ArgoCD for GitOps?"

```bash
cd talos/
# Edit main.tf lines ~109-110, uncomment:
# argocd = "manifests/60-gitops/argocd/argocd.yaml"
# "argocd-applications" = "manifests/60-gitops/argocd/argocd-applications.yaml"

tofu apply

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

See: [COMPONENT_STATUS.md](COMPONENT_STATUS.md#argocd-gitops)

### "How do I deploy a new app?"

```bash
# 1. Create app manifest
mkdir -p apps/my-app
cat > apps/my-app/deployment.yaml << 'EOF'
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

# 2. Deploy
kubectl apply -f apps/my-app/

# Or with ArgoCD (if enabled)
kubectl apply -f - << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/you/gitops
    targetRevision: main
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

### "How do I switch environments?"

```bash
cd talos/

# From dev to staging
cp ../envs/staging/terraform.tfvars .
tofu plan
tofu apply

# From staging to prod
cp ../envs/prod/terraform.tfvars .
tofu plan  # REVIEW CAREFULLY
tofu apply
```

See: [ENVIRONMENT_MANAGEMENT.md](ENVIRONMENT_MANAGEMENT.md)

### "How do I add persistent storage to a pod?"

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-data
spec:
  storageClassName: longhorn  # or openebs
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: my-app
    image: nginx:latest
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-data
```

### "How do I check cluster health?"

```bash
# Nodes
kubectl get nodes

# All pods
kubectl get pods -A

# Storage
kubectl get pvc -A

# Events
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Services
kubectl get svc -A
```

### "How do I access Grafana?"

```bash
# Option 1: Port-forward
kubectl port-forward -n monitoring svc/grafana 3000:3000
# http://localhost:3000 (admin/admin)

# Option 2: Via Traefik
# http://grafana.dev.dih.10.198.141.235.nip.io (admin/admin)
```

### "How do I view logs?"

```bash
# Latest pod logs
kubectl logs <pod-name> -n <namespace>

# Stream logs
kubectl logs -f <pod-name> -n <namespace>

# Previous container logs (after crash)
kubectl logs <pod-name> -n <namespace> --previous

# Logs in Grafana (via Loki)
# Explore → Loki → {namespace="<ns>"}
```

### "How do I execute a command in a pod?"

```bash
# Execute command
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Or with sh
kubectl exec -it <pod-name> -n <namespace> -- sh
```

### "How do I scale a deployment?"

```bash
kubectl scale deploy <deployment-name> --replicas=3 -n <namespace>

# Or edit deployment
kubectl edit deploy <deployment-name> -n <namespace>
# Change replicas: 3
```

### "How do I delete a component?"

Option 1: Comment out in main.tf
```hcl
# longhorn = "manifests/30-storage/longhorn/longhorn.yaml"
tofu apply
```

Option 2: Direct kubectl
```bash
kubectl delete -f manifests/30-storage/longhorn/
```

## 📋 Component Paths

```
talos/manifests/
├── 00-namespaces/      # Namespaces
├── 10-networking/      # Cilium, Traefik
├── 20-security/        # cert-manager, network policies
├── 30-storage/         # Longhorn, OpenEBS, MinIO
├── 40-observability/   # Prometheus, Grafana, Loki
├── 50-management/      # Portainer, Headlamp
├── 60-gitops/          # ArgoCD, Jenkins
└── 70-loadbalancing/   # MetalLB
```

See: [talos/manifests/README.md](talos/manifests/README.md)

## 🚀 Common Commands

```bash
# Deploy cluster
cd talos/
tofu apply

# Get kubeconfig
talosctl kubeconfig --nodes <control-plane-ip>

# Check cluster
kubectl get nodes
kubectl get pods -A

# Port-forward service
kubectl port-forward svc/<service> 8080:80 -n <namespace>

# View logs
kubectl logs deploy/<deployment> -n <namespace>

# Exec into pod
kubectl exec -it pod/<pod> -n <namespace> -- sh

# Check storage
kubectl get pvc -A
kubectl get storageclass

# Check network
kubectl get ingressroute -A
kubectl get svc -A

# Monitor
kubectl top nodes
kubectl top pods -A

# Get status of component
kubectl get pods -n <namespace>
kubectl describe pod <pod> -n <namespace>
```

## 🔗 Key Documentation

| Topic | File |
|-------|------|
| Main README | [README.md](README.md) |
| Component Status | [COMPONENT_STATUS.md](COMPONENT_STATUS.md) |
| Environments | [ENVIRONMENT_MANAGEMENT.md](ENVIRONMENT_MANAGEMENT.md) |
| Manifests Org | [talos/manifests/README.md](talos/manifests/README.md) |
| Talos Setup | [talos/README.md](talos/README.md) |
| Local Dev | [envs/local/README.md](envs/local/README.md) |
| Dev Env | [envs/dev/README.md](envs/dev/README.md) |
| Staging Env | [envs/staging/README.md](envs/staging/README.md) |
| Prod Env | [envs/prod/README.md](envs/prod/README.md) |

## 🆘 Troubleshooting Quick Lookup

| Problem | Check |
|---------|-------|
| Pods not starting | `kubectl get events -A` |
| Storage full | `kubectl get pvc -A` |
| Network issues | `kubectl logs -n kube-system -l k8s-app=cilium` |
| Ingress not working | `kubectl get ingressroute -a` |
| Component missing | [COMPONENT_STATUS.md](COMPONENT_STATUS.md) |
| Node down | `kubectl get nodes` |
| Longhorn crashes | See [30-storage/longhorn/README.md](talos/manifests/30-storage/longhorn/README.md) |

## 💡 Pro Tips

1. **Use `tofu plan` before apply**
   ```bash
   tofu plan -out=tfplan
   # Review carefully!
   tofu apply tfplan
   ```

2. **Save state before major changes**
   ```bash
   cp terraform.tfstate terraform.tfstate.backup
   ```

3. **Port-forward for quick access**
   ```bash
   kubectl port-forward svc/<name> 8080:80 -n <ns>
   ```

4. **Watch deployments**
   ```bash
   kubectl get pods -A --watch
   ```

5. **Get logs in real-time**
   ```bash
   kubectl logs -f deploy/<name> -n <ns>
   ```

---

**More help**: Check the relevant documentation file above or open an issue!

Last updated: 2026-07-13
