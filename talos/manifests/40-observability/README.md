# 40-Observability — Metrics, Logs & Visibility

This directory contains monitoring and observability stack components.

## 📦 Components

### Prometheus
**Directory**: `prometheus/`

Metrics collection and alerting.

**Provides**:
- Metrics scraping from all components
- 50GB default storage
- PromQL query language
- Alert rule engine

### Grafana
**Directory**: `grafana/`

Metrics and logs visualization dashboard.

**Provides**:
- Beautiful dashboards
- Multiple data sources (Prometheus, Loki)
- Alert notifications
- 10GB default storage

### Loki
**Directory**: `loki/`

Log aggregation and querying.

**Provides**:
- Centralized log storage
- Label-based indexing (lower cost than ELK)
- 50GB default storage
- Integration with Grafana

## 🚀 Quick Start

### Enable Observability Stack

```hcl
# In talos/main.tf
prometheus = "manifests/40-observability/prometheus/prometheus-grafana.yaml"
loki = "manifests/40-observability/loki/loki.yaml"
```

Apply:
```bash
cd talos/
tofu apply
```

### Access Grafana

```bash
# Via port-forward
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Or via Traefik
# http://grafana.dev.dih.10.198.141.235.nip.io
```

Default credentials: `admin` / `admin`

## 📊 Pre-configured Dashboards

- **Cluster Overview** — Node, pod, and resource metrics
- **Cilium Network** — Hubble network flows
- **Longhorn Storage** — Storage metrics (if enabled)

## 🔍 Common Queries

### Prometheus (PromQL)

```promql
# CPU usage per node
node_cpu_seconds_total

# Pod memory usage
container_memory_usage_bytes{namespace="default"}

# Requests per second
rate(http_requests_total[5m])

# Pod restarts
rate(kube_pod_container_status_restarts_total[15m]) > 0
```

### Loki (LogQL)

```loki
# All logs from namespace
{namespace="default"}

# Logs from specific pod
{namespace="longhorn-system", pod="longhorn-manager-xxxxx"}

# Error logs
{namespace="kube-system"} |= "error"

# Logs from last 1 hour
{namespace="monitoring"} | __error__ = ""
```

## ⚙️ Operations

### Check Prometheus Targets

```bash
# Port-forward
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Visit http://localhost:9090/targets
```

### View Pod Logs in Grafana

1. Open Grafana
2. Go to "Explore"
3. Select "Loki" data source
4. Query: `{namespace="<namespace>"}`

### Storage Usage

```bash
# Check storage PVCs
kubectl get pvc -A | grep monitoring

# Check actual usage
kubectl exec -n monitoring prometheus-0 -- du -sh /prometheus
```

### Alert Configuration

Create PrometheusRule:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: my-alerts
  namespace: monitoring
spec:
  groups:
    - name: my.rules
      interval: 30s
      rules:
        - alert: PodCrashing
          expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
          for: 5m
          annotations:
            summary: "Pod {{ $labels.pod }} restarting"
```

## 🎯 Best Practices

1. **Retention Policy** — Balance storage vs history
2. **Alert Rules** — Start conservative, tune over time
3. **Dashboards** — Create per-app dashboards
4. **Labels** — Consistent labeling for querying
5. **Storage** — Monitor PVC usage, expand as needed

## 🐛 Troubleshooting

### Prometheus Not Scraping

```bash
# Check Prometheus config
kubectl get cm -n monitoring prometheus-config

# Check targets
# Visit http://localhost:9090/targets (via port-forward)

# Check logs
kubectl logs -n monitoring prometheus-0
```

### Loki Logs Not Showing

```bash
# Check Loki pods
kubectl get pods -n monitoring -l app=loki

# Check Promtail (log collector)
kubectl get pods -n monitoring -l app=promtail

# Check logs
kubectl logs -n monitoring ds/loki-promtail
```

### Storage Full

```bash
# Check PVC
kubectl get pvc -n monitoring

# Reduce retention period
# Edit Prometheus/Loki resource settings

# Increase PVC size
kubectl patch pvc prometheus-db -n monitoring -p '{"spec":{"resources":{"requests":{"storage":"100Gi"}}}}'
```

## 🔗 Dependencies

Requires:
- ✅ 00-namespaces
- ✅ 10-networking (Cilium for ingress)
- ✅ 30-storage (PVC for metrics/logs)

Optional:
- cert-manager (for HTTPS)

## 📚 More Info

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)

See individual component directories for detailed configuration.
