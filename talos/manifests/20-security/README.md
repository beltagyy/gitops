# 20-Security — Certificates & Network Policies

This directory contains security-related configurations.

## 📦 Components

### cert-manager
**File**: `cert_manager.yaml`

Automated TLS certificate management using Let's Encrypt.

**Use for**:
- Automatic HTTPS certificate generation
- Certificate renewal
- Multiple domain support

**Example: Auto-HTTPS for Traefik IngressRoute**

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: my-service
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`myservice.example.com`)
      kind: Rule
      services:
        - name: my-service
          port: 80
  tls:
    certResolver: letsencrypt
```

### Network Policies
**Directory**: `network-policies/`

Examples for restricting pod-to-pod traffic.

**Use for**:
- Least-privilege networking
- Namespace isolation
- Application security

**Example: Deny All by Default**

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: deny-all
spec:
  description: "Deny all traffic by default"
  endpointSelector: {}
  policyTypes:
    - Ingress
    - Egress
  egress:
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
```

## 🚀 Quick Start

### Enable cert-manager

```hcl
# In talos/main.tf
"cert-manager" = "manifests/20-security/cert_manager.yaml"
```

Apply:
```bash
cd talos/
tofu apply
```

### Verify cert-manager

```bash
kubectl get pods -n cert-manager
kubectl get certificates -A
```

### Enable Network Policies

```bash
kubectl apply -f network-policies/
```

## 🔧 Configuration

### Let's Encrypt Certificate

Create a Certificate resource:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-cert
  namespace: default
spec:
  secretName: my-cert-tls
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
  dnsNames:
    - myservice.example.com
    - www.myservice.example.com
```

### Network Policy: Allow Specific Traffic

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-http
spec:
  endpointSelector:
    matchLabels:
      app: web
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: frontend
      toPorts:
        - ports:
            - port: "80"
              protocol: TCP
```

## 📊 Operations

### Check Certificates

```bash
# List all certificates
kubectl get cert -A

# Check specific cert status
kubectl describe cert <cert-name> -n <namespace>

# View cert details
kubectl get secret <secret-name> -n <namespace> -o yaml
```

### Test Network Policies

```bash
# Apply policy
kubectl apply -f network-policies/policy.yaml

# Test connectivity
kubectl run -it --rm test --image=busybox --restart=Never -- sh
# ping <target-pod>
```

### Troubleshoot Certificate Issues

```bash
# Check cert-manager logs
kubectl logs -n cert-manager deploy/cert-manager

# Check issuer status
kubectl get issuer -A
kubectl describe issuer <issuer-name> -n <namespace>

# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>
```

## 🎯 Best Practices

1. **Always use cert-manager for HTTPS** — Automatic renewal
2. **Start with `deny-all` policy** — Add exceptions as needed
3. **Test policies in dev first** — Can break applications
4. **Monitor certificate expiry** — Set up alerts
5. **Use network policies per app** — Easier to manage

## 🔗 Dependencies

Requires:
- ✅ 00-namespaces
- ✅ 10-networking (Cilium for network policies)

## 🐛 Troubleshooting

### Certificate Not Issuing

```bash
# Check cert-manager running
kubectl get pods -n cert-manager

# Check ClusterIssuer
kubectl get clusterissuer

# View cert logs
kubectl logs -n cert-manager deploy/cert-manager -f
```

### Network Policy Blocks Everything

1. Check policy syntax
2. Verify labels match
3. Test with permissive policy first
4. Check pod labels: `kubectl get pods --show-labels`

## 📚 More Info

- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Cilium Network Policies](https://docs.cilium.io/en/stable/security/policy/)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
