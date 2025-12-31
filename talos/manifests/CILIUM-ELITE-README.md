# Cilium Elite Configuration

This directory contains an elite-level Cilium CNI configuration with advanced networking, security, and observability features for your Talos Kubernetes cluster.

## Features Enabled

### Core Networking
- **Native Routing Mode**: Direct routing without tunneling overhead for maximum performance
- **Kube-proxy Replacement**: eBPF-based service load balancing replacing kube-proxy
- **Session Affinity**: Consistent routing for stateful applications
- **Socket-level Load Balancing**: Fast datapath bypassing netfilter
- **BPF Masquerading**: Efficient NAT using eBPF

### Security
- **WireGuard Encryption**: Zero-trust pod-to-pod encryption with strict mode
- **Network Policies**: L3/L4 and L7 network policies with protocol-aware filtering
- **Identity-based Security**: Cryptographic identity for all workloads
- **DNS-aware Policies**: FQDN-based egress policies

### Service Mesh Features
- **Envoy Integration**: L7 proxy for HTTP/gRPC traffic management
- **Traffic Management**: Canary deployments, circuit breaking, retries
- **No Sidecars**: Mesh features without per-pod sidecar overhead

### Observability (Hubble)
- **Hubble UI**: Web-based network flow visualization
- **Hubble Relay**: Cluster-wide flow aggregation
- **Flow Metrics**: DNS, TCP, HTTP/2, drops, ICMP metrics
- **Prometheus Integration**: Full metrics export with ServiceMonitors
- **Grafana Dashboards**: Pre-built dashboards for network observability
- **OpenTelemetry**: Distributed tracing support

### Advanced Routing
- **BGP Control Plane**: Advertise pod CIDRs and LoadBalancer IPs
- **L2 Announcements**: ARP/NDP announcements for LoadBalancer services
- **Egress Gateway**: Stable source IPs for egress traffic
- **Local Redirect Policy**: Traffic redirection for service mesh patterns

### Ingress & Gateway API
- **Built-in Ingress Controller**: Envoy-based Ingress with L7 load balancing
- **Gateway API Support**: Next-generation ingress with HTTPRoute, GRPCRoute, TLSRoute

### Performance Optimizations
- **Bandwidth Manager**: TCP BBR congestion control
- **eBPF Host Routing**: Bypass iptables for faster routing
- **Endpoint Routes**: Direct pod routing
- **Large BPF Maps**: Increased connection tracking limits (524K TCP, 262K any)

## File Structure

```
manifests/
├── cilium-values.yaml                      # Helm values for elite configuration
├── cilium.yaml                             # Generated Cilium manifests (2774 lines)
├── cilium-bgp-config.yaml                  # BGP peering and LoadBalancer IP pool configs
├── cilium-network-policies-examples.yaml   # Example L3/L4/L7 network policies
├── gateway-api-crds.yaml                   # Gateway API v1.2.1 CRDs
├── gateway-api-examples.yaml               # Example Gateway API resources
├── headlamp.yaml                           # Headlamp Kubernetes dashboard
└── CILIUM-ELITE-README.md                  # This file
```

## Installation Order

1. **Install Cilium CRDs and Core** (if not already installed by Talos):
   ```bash
   kubectl apply -f cilium.yaml
   ```

2. **Wait for Cilium to be ready**:
   ```bash
   kubectl -n kube-system rollout status daemonset/cilium
   kubectl -n kube-system rollout status deployment/cilium-operator
   ```

3. **Install Gateway API CRDs**:
   ```bash
   kubectl apply -f gateway-api-crds.yaml
   ```

4. **Configure BGP (if using BGP)**:
   - Edit `cilium-bgp-config.yaml` with your BGP peer IPs and ASN numbers
   - Edit the LoadBalancer IP pool range
   ```bash
   kubectl apply -f cilium-bgp-config.yaml
   ```

5. **Install Headlamp Dashboard** (optional):
   ```bash
   kubectl apply -f headlamp.yaml
   ```

6. **Apply Example Policies** (for testing):
   ```bash
   kubectl apply -f cilium-network-policies-examples.yaml
   kubectl apply -f gateway-api-examples.yaml
   ```

## Verification

### Check Cilium Status
```bash
# Install Cilium CLI (if not already installed)
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-darwin-arm64.tar.gz
sudo tar xzvfC cilium-darwin-arm64.tar.gz /usr/local/bin
rm cilium-darwin-arm64.tar.gz

# Check connectivity
cilium connectivity test

# Check status
cilium status --wait
```

### Verify Hubble
```bash
# Port-forward Hubble UI
kubectl port-forward -n kube-system svc/hubble-ui 12000:80

# Open in browser
open http://localhost:12000
```

### Verify Kube-proxy Replacement
```bash
# Should show kube-proxy replacement is enabled
cilium status | grep KubeProxyReplacement
```

### Check BGP Status
```bash
# View BGP peering status
kubectl get ciliumbgppeeringpolicies
kubectl get ciliumloadbalancerippools
```

## Configuration Customization

### Update BGP Configuration

Edit `cilium-bgp-config.yaml`:
```yaml
neighbors:
- peerAddress: "YOUR_ROUTER_IP/32"
  peerASN: YOUR_ASN
```

Edit LoadBalancer IP pool:
```yaml
blocks:
- start: "YOUR_IP_RANGE_START"
  stop: "YOUR_IP_RANGE_END"
```

### Update Ingress Hostnames

For Hubble UI (`cilium-values.yaml`):
```yaml
hubble:
  ui:
    ingress:
      hosts:
        - "hubble.yourdomain.com"
```

For Headlamp (`headlamp.yaml`):
```yaml
spec:
  rules:
  - host: headlamp.yourdomain.com
```

### Adjust Resource Limits

Edit resource requests/limits in `cilium-values.yaml`:
```yaml
resources:
  limits:
    cpu: 4000m      # Adjust based on node capacity
    memory: 4Gi
  requests:
    cpu: 400m
    memory: 512Mi
```

## Advanced Features Usage

### L7 Network Policy

See `cilium-network-policies-examples.yaml` for examples of:
- HTTP method and path filtering
- gRPC service filtering
- DNS-based egress policies
- Kafka protocol filtering

### Egress Gateway

To use egress gateway for stable source IPs:
1. Label nodes that will act as egress gateways:
   ```bash
   kubectl label node <node-name> egress-gateway=true
   ```

2. Apply egress gateway policy (see `cilium-network-policies-examples.yaml`)

### Service Mesh with Envoy

Cilium provides service mesh features without sidecars:
- L7 load balancing
- Traffic splitting for canary deployments
- Circuit breaking and retries
- mTLS between services

### Gateway API Routing

Use Gateway API for advanced routing:
- Canary deployments with traffic weights
- Header-based routing
- gRPC method routing
- Cross-namespace routing with ReferenceGrant

See `gateway-api-examples.yaml` for examples.

## Monitoring & Observability

### Prometheus Metrics

ServiceMonitors are automatically created for:
- `cilium-agent` - CNI agent metrics
- `cilium-operator` - Operator metrics
- `cilium-envoy` - Envoy proxy metrics
- `hubble` - Network flow metrics

### Grafana Dashboards

Import pre-built dashboards:
1. Cilium Metrics
2. Cilium Operator
3. Hubble - Network Overview
4. Hubble - L7 HTTP Metrics
5. Hubble - DNS Metrics

### Hubble Flow Logs

View network flows in real-time:
```bash
# Install Hubble CLI
HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-darwin-arm64.tar.gz
sudo tar xzvfC hubble-darwin-arm64.tar.gz /usr/local/bin
rm hubble-darwin-arm64.tar.gz

# Port-forward to Hubble Relay
cilium hubble port-forward &

# Watch flows
hubble observe --follow

# Filter by namespace
hubble observe --namespace demo-app

# Filter by L7 protocol
hubble observe --protocol http

# Filter drops
hubble observe --verdict DROPPED
```

### Loki Integration

To send Hubble flows to Loki for long-term storage:

1. Install Loki stack (if not already installed)
2. Configure Hubble to export flows:
```yaml
hubble:
  export:
    dynamic:
      enabled: true
    static:
      enabled: true
      filePath: /var/run/cilium/hubble/events.log
```

3. Create Promtail config to scrape Hubble logs

## Troubleshooting

### Cilium Agent Logs
```bash
kubectl -n kube-system logs -l k8s-app=cilium --tail=100
```

### Hubble Logs
```bash
kubectl -n kube-system logs -l k8s-app=hubble-relay --tail=100
kubectl -n kube-system logs -l k8s-app=hubble-ui --tail=100
```

### Network Policy Debugging
```bash
# Check endpoint status
kubectl get ciliumendpoints -A

# Check identity
kubectl get ciliumidentities

# Check network policies
kubectl get ciliumnetworkpolicies -A
```

### BGP Debugging
```bash
# Check BGP status
kubectl exec -n kube-system ds/cilium -- cilium bgp routes

# Check IP pools
kubectl get ciliumloadbalancerippools
```

## Security Considerations

1. **WireGuard Encryption**: All pod-to-pod traffic is encrypted with WireGuard
2. **Strict Mode**: Enabled to prevent fallback to unencrypted communication
3. **Network Policies**: Default deny policies are recommended (see examples)
4. **Identity-based Security**: All workloads have cryptographic identities
5. **RBAC**: Headlamp has cluster-admin (adjust for production)

## Performance Tuning

### For High-Throughput Workloads
- Increase BPF map sizes in `cilium-values.yaml`:
  ```yaml
  bpf:
    ctTcpMax: 1048576  # 1M connections
    ctAnyMax: 524288   # 512K connections
  ```

### For Low-Latency Workloads
- Enable BBR congestion control (already enabled)
- Use native routing mode (already enabled)
- Enable endpoint routes (already enabled)

### For Large Clusters
- Increase operator replicas
- Tune monitor aggregation
- Consider disabling debug logging

## Integration with Existing Services

### Traefik Integration
Cilium and Traefik can work together:
- Cilium provides CNI and network policies
- Traefik provides Ingress controller
- Use Gateway API for unified configuration

### Prometheus/Grafana Integration
All ServiceMonitors are configured with label:
```yaml
labels:
  prometheus: kube-prometheus
```

Ensure your Prometheus Operator is configured to discover these.

### Cert-Manager Integration
Ingress resources are configured for cert-manager:
```yaml
annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

## Additional Resources

- [Cilium Documentation](https://docs.cilium.io/)
- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [Hubble Documentation](https://docs.cilium.io/en/stable/gettingstarted/hubble/)
- [Cilium Network Policy Editor](https://editor.cilium.io/)
- [Cilium BGP Documentation](https://docs.cilium.io/en/stable/network/bgp-control-plane/)

## Support

For issues or questions:
- Cilium Slack: https://slack.cilium.io/
- GitHub Issues: https://github.com/cilium/cilium/issues
- Documentation: https://docs.cilium.io/

---

**Note**: This is an elite configuration with many advanced features. Test thoroughly in a development environment before deploying to production.
