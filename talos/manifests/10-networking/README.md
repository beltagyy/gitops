# 10-Networking — CNI, Ingress & Load Balancing

This directory contains network infrastructure components.

## 📦 Components

### Cilium CNI
**Files**: `cilium-minimal.yaml`, `cilium.yaml`, `cilium-*.yaml`, `cilium-values*.yaml`

Cilium provides:
- eBPF-based networking (performance)
- Kube-proxy replacement (simpler, faster)
- Network policies
- Service mesh capabilities
- Hubble network observability

**Choose one**:
- `cilium-minimal.yaml` — Recommended for most deployments (lower resource usage)
- `cilium.yaml` — Full features including Hubble and advanced networking

### Traefik Ingress
**Files**: `traefik-ingressroutes.yaml`, `ingress.yaml`

Traefik provides:
- HTTP/HTTPS routing
- Service discovery
- Auto-reload configuration
- Native Kubernetes integration

### Gateway API (Optional)
**Files**: `gateway-api-crds.yaml`, `gateway-api-examples.yaml`

Advanced ingress API for complex routing scenarios.

### LoadBalancer IPs
**Files**: `cilium-l2-ippool.yaml`, `cilium-loadbalancer-ippool.yaml`, `cilium-ingress-lb.yaml`

Configure IP ranges for LoadBalancer services.

## 🚀 Quick Start

### Deploy Minimal Networking Stack

```bash
cd talos/

# Edit main.tf - ensure this is enabled:
# cluster_inline_manifests = {
#   namespaces = "manifests/00-namespaces/namespaces.yaml"
#   cilium = "manifests/10-networking/cilium-minimal.yaml"
# }

tofu apply
```

### Verify Cilium is Running

```bash
# Check Cilium pods
kubectl get pods -n kube-system -l k8s-app=cilium

# Check Cilium status
kubectl -n kube-system exec -it ds/cilium -- cilium status
```

### Access Services via Traefik

Services with LoadBalancer type get an external IP:

```bash
# Find Traefik IP
kubectl get svc -n traefik

# Access service
curl http://<traefik-ip>
```

## 🔧 Configuration

### Change Cilium IP Pool

Edit `cilium-l2-ippool.yaml`:
```yaml
spec:
  cidrs:
  - cidr: "10.198.141.0/24"  # Your network range
  disabled: false
```

### Add Traefik Routes

Add to `traefik-ingressroutes.yaml`:
```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: my-service
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`myservice.example.com`)
      kind: Rule
      services:
        - name: my-service
          port: 80
```

## 📊 Common Operations

### Verify Network Connectivity

```bash
# Check node connectivity
kubectl get nodes -o wide

# Check pod network
kubectl get pods -A -o wide

# Test pod-to-pod connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# ping <pod-ip>
```

### Troubleshoot Traefik

```bash
# Check Traefik pods
kubectl get pods -n traefik

# View Traefik logs
kubectl logs -n traefik deploy/traefik

# Check ingress routes
kubectl get ingressroute -A
kubectl describe ingressroute <name> -n <namespace>
```

### Network Policies

Apply examples from `cilium-network-policies-examples.yaml`:

```bash
kubectl apply -f 20-security/network-policies/cilium-network-policies-examples.yaml
```

## 🎯 Best Practices

1. **Use `cilium-minimal.yaml` first** — Easier to debug
2. **Test network policies before enabling** — Can block traffic
3. **Monitor Traefik logs** — Quick diagnosis of routing issues
4. **Use nip.io for dev DNS** — No DNS setup needed
5. **Check IP pool capacity** — Ensure enough IPs for services

## 🔗 More Info

- [Cilium Documentation](https://docs.cilium.io/)
- [Traefik Documentation](https://doc.traefik.io/)
- [Kubernetes Networking](https://kubernetes.io/docs/concepts/services-networking/)
