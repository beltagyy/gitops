# Talos Kubernetes Cluster - Command Cheatsheet

Quick reference for common operations on your Talos cluster.

---

## 🔧 Cluster Management

### Terraform Operations

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply configuration
terraform apply

# Destroy cluster (careful!)
terraform destroy

# Show current state
terraform show

# Format Terraform files
terraform fmt
```

### Talos Operations

```bash
# Set Talos config
export TALOSCONFIG=$(pwd)/<env>.talosconfig

# Get cluster health
talosctl health --nodes <node-ip>

# Check Talos services
talosctl services --nodes <node-ip>

# View logs
talosctl logs kubelet --nodes <node-ip>
talosctl logs etcd --nodes <node-ip>

# Get kubeconfig
talosctl kubeconfig --nodes <bootstrap-ip>

# Reboot node
talosctl reboot --nodes <node-ip>

# Upgrade Talos
talosctl upgrade --image ghcr.io/siderolabs/installer:v1.11.2 --nodes <node-ip>

# Edit machine config
talosctl edit machineconfig --nodes <node-ip>

# Dashboard
talosctl dashboard --nodes <node-ip>

# etcd operations
talosctl etcd members --nodes <controlplane-ip>
talosctl etcd status --nodes <controlplane-ip>
```

---

## ☸️ Kubernetes Operations

### Cluster Info

```bash
# Get cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes -o wide

# Describe node
kubectl describe node <node-name>

# Get all resources
kubectl get all -A

# Get events
kubectl get events -A --sort-by='.lastTimestamp'

# Check API server
kubectl get --raw /healthz
```

### Pod Management

```bash
# Get all pods
kubectl get pods -A

# Watch pods
kubectl get pods -A -w

# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Get pod logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> -f  # Follow
kubectl logs <pod-name> -n <namespace> --previous  # Previous instance

# Execute command in pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Port forward
kubectl port-forward <pod-name> -n <namespace> <local-port>:<remote-port>

# Delete pod
kubectl delete pod <pod-name> -n <namespace>
```

---

## 🌐 Networking

### Cilium

```bash
# Get Cilium status
kubectl -n kube-system exec -it ds/cilium -- cilium status

# Cilium connectivity test
kubectl -n kube-system exec -it ds/cilium -- cilium connectivity test

# Check Cilium endpoints
kubectl -n kube-system exec -it ds/cilium -- cilium endpoint list

# Monitor network traffic
kubectl -n kube-system exec -it ds/cilium -- cilium monitor

# Check Hubble status
kubectl -n kube-system exec -it ds/cilium -- cilium hubble status
```

### MetalLB

```bash
# Get MetalLB pods
kubectl -n metallb-system get pods

# Get IP pools
kubectl -n metallb-system get ipaddresspool

# Get L2 advertisements
kubectl -n metallb-system get l2advertisement

# Check speaker logs
kubectl -n metallb-system logs daemonset/speaker
```

### Ingress

```bash
# Get ingresses
kubectl get ingress -A

# Describe ingress
kubectl describe ingress <ingress-name> -n <namespace>

# Get NGINX controller logs
kubectl -n ingress logs deploy/ingress-nginx-controller

# Get NGINX config
kubectl -n ingress exec deploy/ingress-nginx-controller -- cat /etc/nginx/nginx.conf
```

---

## 💾 Storage

### Longhorn

```bash
# Get Longhorn pods
kubectl -n longhorn-system get pods

# Get volumes
kubectl -n longhorn-system get volumes

# Get engines
kubectl -n longhorn-system get engines

# Get replicas
kubectl -n longhorn-system get replicas

# Access Longhorn UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
# Open: http://localhost:8000

# Get storage classes
kubectl get sc

# Get PVCs
kubectl get pvc -A

# Get PVs
kubectl get pv

# Describe PVC
kubectl describe pvc <pvc-name> -n <namespace>
```

### MinIO

```bash
# Get MinIO pods
kubectl -n minio get pods

# Access MinIO console
kubectl port-forward -n minio svc/minio-console 9001:9001
# Open: http://localhost:9001

# Get MinIO credentials
kubectl -n minio get secret minio-credentials -o jsonpath='{.data.rootUser}' | base64 -d
kubectl -n minio get secret minio-credentials -o jsonpath='{.data.rootPassword}' | base64 -d

# Check MinIO logs
kubectl -n minio logs statefulset/minio

# MinIO client (mc) operations via pod
kubectl -n minio exec -it minio-0 -- mc admin info local
kubectl -n minio exec -it minio-0 -- mc ls local/
```

---

## 📊 Monitoring & Logging

### Prometheus

```bash
# Get Prometheus pods
kubectl -n monitoring get pods -l app=prometheus

# Access Prometheus UI
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Open: http://localhost:9090

# Check Prometheus config
kubectl -n monitoring get configmap prometheus-config -o yaml

# Query Prometheus
kubectl -n monitoring exec -it statefulset/prometheus -- promtool query instant http://localhost:9090 'up'

# Check targets
# Open Prometheus UI -> Status -> Targets
```

### Grafana

```bash
# Get Grafana pod
kubectl -n monitoring get pods -l app=grafana

# Access Grafana UI
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Open: http://localhost:3000 (admin/admin)

# Get Grafana logs
kubectl -n monitoring logs deploy/grafana

# Reset admin password
kubectl -n monitoring exec -it deploy/grafana -- grafana-cli admin reset-admin-password newpassword
```

### Loki & Promtail

```bash
# Get Loki pod
kubectl -n logging get pods -l app=loki

# Get Promtail pods
kubectl -n logging get pods -l app=promtail

# Check Loki logs
kubectl -n logging logs statefulset/loki

# Query Loki (via LogQL)
kubectl -n logging exec -it statefulset/loki -- wget -qO- 'http://localhost:3100/loki/api/v1/query?query={namespace="default"}'

# Check Promtail status
kubectl -n logging logs daemonset/promtail
```

---

## 🚀 CI/CD

### Jenkins

```bash
# Get Jenkins pod
kubectl -n jenkins get pods

# Access Jenkins UI
kubectl port-forward -n jenkins svc/jenkins 8080:8080
# Open: http://localhost:8080

# Get Jenkins logs
kubectl -n jenkins logs statefulset/jenkins

# Get Jenkins home directory
kubectl -n jenkins exec -it statefulset/jenkins -- ls -la /var/jenkins_home

# Restart Jenkins
kubectl -n jenkins rollout restart statefulset/jenkins
```

### ArgoCD

```bash
# Get ArgoCD pods
kubectl -n argocd get pods

# Access ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:443
# Open: https://localhost:8080

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# ArgoCD CLI login
argocd login localhost:8080 --insecure

# List applications
argocd app list

# Sync application
argocd app sync <app-name>

# Get application details
argocd app get <app-name>

# Create application
argocd app create <app-name> --repo <repo-url> --path <path> --dest-server https://kubernetes.default.svc --dest-namespace <namespace>
```

---

## 🐳 Container Management

### Portainer

```bash
# Get Portainer pod
kubectl -n portainer get pods

# Access Portainer UI
kubectl port-forward -n portainer svc/portainer 9443:9443
# Open: https://localhost:9443

# Get Portainer logs
kubectl -n portainer logs deploy/portainer
```

---

## 🔐 Security

### Certificates (cert-manager)

```bash
# Get cert-manager pods
kubectl -n cert-manager get pods

# Get certificates
kubectl get certificate -A

# Get certificate requests
kubectl get certificaterequest -A

# Get cluster issuers
kubectl get clusterissuer

# Describe certificate
kubectl describe certificate <cert-name> -n <namespace>

# Check cert-manager logs
kubectl -n cert-manager logs deploy/cert-manager

# Manually trigger certificate renewal
kubectl delete certificaterequest <cert-request-name> -n <namespace>
```

### Secrets

```bash
# List secrets
kubectl get secrets -A

# Get secret
kubectl get secret <secret-name> -n <namespace> -o yaml

# Decode secret
kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data.<key>}' | base64 -d

# Create generic secret
kubectl create secret generic <secret-name> --from-literal=<key>=<value> -n <namespace>

# Create TLS secret
kubectl create secret tls <secret-name> --cert=<cert-file> --key=<key-file> -n <namespace>
```

---

## 🔍 Debugging

### Common Debug Commands

```bash
# Run debug pod
kubectl run debug --image=nicolaka/netshoot -it --rm -- /bin/bash

# DNS debugging
kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/agnhost:2.39 -it --rm -- /bin/bash
# Inside pod: nslookup kubernetes.default

# Check resource usage
kubectl top nodes
kubectl top pods -A

# Get resource quotas
kubectl get resourcequota -A

# Get limit ranges
kubectl get limitrange -A

# Describe namespace
kubectl describe namespace <namespace>

# Check API resources
kubectl api-resources

# Explain resource
kubectl explain pod.spec.containers

# Dry run
kubectl apply -f <file> --dry-run=client -o yaml
kubectl apply -f <file> --dry-run=server -o yaml
```

### Network Debugging

```bash
# Test connectivity from pod
kubectl run netshoot --image=nicolaka/netshoot -it --rm -- /bin/bash
# Inside: ping <service>, curl <url>, nslookup <domain>

# Check service endpoints
kubectl get endpoints -A

# Check network policies
kubectl get networkpolicies -A

# Describe service
kubectl describe service <service-name> -n <namespace>
```

---

## 📦 Backup & Restore

### etcd Backup (via Talos)

```bash
# Create etcd snapshot
talosctl -n <controlplane-ip> etcd snapshot /tmp/etcd.snapshot

# Get snapshot from node
talosctl -n <controlplane-ip> read /tmp/etcd.snapshot > etcd-backup.snapshot
```

### Longhorn Backups

```bash
# Create snapshot (via Longhorn UI or CRD)
kubectl apply -f - <<EOF
apiVersion: longhorn.io/v1beta2
kind: Snapshot
metadata:
  name: backup-$(date +%Y%m%d-%H%M%S)
  namespace: longhorn-system
spec:
  volume: <volume-name>
EOF

# List backups
kubectl -n longhorn-system get backups

# Restore from backup (via Longhorn UI or Volume spec)
```

---

## 🧹 Cleanup

### Resource Cleanup

```bash
# Delete all resources in namespace
kubectl delete all --all -n <namespace>

# Delete namespace
kubectl delete namespace <namespace>

# Delete pod forcefully
kubectl delete pod <pod-name> -n <namespace> --grace-period=0 --force

# Clean up completed jobs
kubectl delete jobs --field-selector status.successful=1 -A

# Clean up evicted pods
kubectl get pods -A | grep Evicted | awk '{print $2, $1}' | xargs -n 2 kubectl delete pod -n

# Clean up failed pods
kubectl delete pods --field-selector status.phase=Failed -A
```

### Storage Cleanup

```bash
# Delete PVC
kubectl delete pvc <pvc-name> -n <namespace>

# Delete unused PVs
kubectl get pv | grep Released | awk '{print $1}' | xargs kubectl delete pv
```

---

## 📈 Scaling

### Scale Deployments

```bash
# Scale deployment
kubectl scale deployment <deployment-name> --replicas=<count> -n <namespace>

# Autoscale deployment
kubectl autoscale deployment <deployment-name> --min=<min> --max=<max> --cpu-percent=<percent> -n <namespace>

# Get HPA
kubectl get hpa -A
```

### StatefulSet Operations

```bash
# Scale StatefulSet
kubectl scale statefulset <statefulset-name> --replicas=<count> -n <namespace>

# Delete StatefulSet (keep pods)
kubectl delete statefulset <statefulset-name> --cascade=orphan -n <namespace>
```

---

## 🔄 Updates & Rollouts

### Rolling Updates

```bash
# Update image
kubectl set image deployment/<deployment-name> <container-name>=<new-image> -n <namespace>

# Rollout status
kubectl rollout status deployment/<deployment-name> -n <namespace>

# Rollout history
kubectl rollout history deployment/<deployment-name> -n <namespace>

# Rollback
kubectl rollout undo deployment/<deployment-name> -n <namespace>

# Rollback to specific revision
kubectl rollout undo deployment/<deployment-name> --to-revision=<revision> -n <namespace>

# Restart deployment
kubectl rollout restart deployment/<deployment-name> -n <namespace>

# Pause rollout
kubectl rollout pause deployment/<deployment-name> -n <namespace>

# Resume rollout
kubectl rollout resume deployment/<deployment-name> -n <namespace>
```

---

## 💡 Useful Aliases

Add these to your `.bashrc` or `.zshrc`:

```bash
# Kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kgn='kubectl get nodes'
alias kgs='kubectl get svc'
alias kgi='kubectl get ingress'
alias kd='kubectl describe'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias ke='kubectl exec -it'
alias kpf='kubectl port-forward'
alias kgc='kubectl get certificate -A'
alias kgpvc='kubectl get pvc -A'

# Talos aliases
alias t='talosctl'
alias tl='talosctl logs'
alias ts='talosctl services'
alias th='talosctl health'

# Context switching
alias kctx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'
```

---

## 🆘 Emergency Commands

### Cluster Issues

```bash
# Force delete stuck namespace
kubectl get namespace <namespace> -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/<namespace>/finalize" -f -

# Force delete stuck pod
kubectl delete pod <pod-name> -n <namespace> --grace-period=0 --force

# Drain node (for maintenance)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Uncordon node
kubectl uncordon <node-name>

# Cordon node (mark unschedulable)
kubectl cordon <node-name>

# Check component health
kubectl get componentstatuses
```

---

## 📝 Quick Reference URLs

After port-forwarding, access services at:

| Service | Command | URL |
|---------|---------|-----|
| Grafana | `kubectl port-forward -n monitoring svc/grafana 3000:3000` | http://localhost:3000 |
| Prometheus | `kubectl port-forward -n monitoring svc/prometheus 9090:9090` | http://localhost:9090 |
| ArgoCD | `kubectl port-forward -n argocd svc/argocd-server 8080:443` | https://localhost:8080 |
| Jenkins | `kubectl port-forward -n jenkins svc/jenkins 8080:8080` | http://localhost:8080 |
| Portainer | `kubectl port-forward -n portainer svc/portainer 9443:9443` | https://localhost:9443 |
| MinIO Console | `kubectl port-forward -n minio svc/minio-console 9001:9001` | http://localhost:9001 |
| Longhorn UI | `kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80` | http://localhost:8000 |

---

**Save this file for quick reference!** 📋
