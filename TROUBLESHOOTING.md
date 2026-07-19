# Troubleshooting & Runbooks

Quick reference for diagnosing and fixing common cluster issues.

---

## Cluster Won't Start

```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Check system pods
kubectl get pods -n kube-system

# Check events (last 5 min)
kubectl get events --sort-by=.metadata.creationTimestamp -A | tail -20
```

**Common causes:**
- Insufficient memory (need ~4GB for single node)
- Cilium not ready — wait 60s, check `kubectl -n kube-system rollout status daemonset/cilium`
- DNS issues — verify `kubectl -n kube-system get pods -l k8s-app=kube-dns`

---

## Cilium / Networking Issues

```bash
# Check Cilium status
cilium status

# Check Cilium pods
kubectl -n kube-system get pods -l k8s.kubernetes.io/manager=bugtool

# Restart Cilium
kubectl -n kube-system rollout restart daemonset/cilium

# Cilium connectivity test
cilium connectivity test
```

**Symptoms:** Pods can't reach each other, DNS resolution fails, services unreachable.

**Fix:**
1. Restart Cilium daemonset
2. Wait 60s for pods to reschedule
3. Re-test connectivity

---

## Longhorn / Storage Issues

```bash
# Check Longhorn status
kubectl -n longhorn-system get pods

# Check volumes
kubectl -n longhorn-system get volumes

# Force detach stuck volume
kubectl -n longhorn-system delete volume <volume-name>
```

**Symptoms:** PVCs stuck in Pending, pods can't mount volumes.

**Fix:**
1. Verify Longhorn manager is running
2. Check disk space on nodes (`df -h`)
3. Delete stuck volumes and let them recreate

---

## Ingress / Traefik Issues

```bash
# Check Traefik pods
kubectl -n traefik get pods

# Check ingress resources
kubectl get ingress -A

# Check Traefik logs
kubectl -n traefik logs deploy/traefik -f

# Test from inside cluster
kubectl run curl --image=curlimages/curl -it --rm -- curl -s http://<service-name>.<namespace>.svc.cluster.local
```

**Symptoms:** 502/504 errors, routes not working, TLS not terminating.

**Fix:**
1. Verify ingress class is `traefik`
2. Check service name/port match
3. Verify TLS secret exists

---

## Certificate / TLS Issues

```bash
# Check certificate status
kubectl get certificates -A
kubectl get certificaterequests -A

# Check cert-manager logs
kubectl -n cert-manager logs deploy/cert-manager

# Manually trigger renewal
kubectl delete certificate <name> -n <namespace>
```

**Symptoms:** TLS errors, certificates stuck in "Pending", browser shows invalid cert.

**Fix:**
1. Verify cert-manager is running
2. Check ClusterIssuer is Ready
3. Delete stuck CertificateRequest to force retry

---

## Port Forwarding

```bash
# Grafana
kubectl -n monitoring port-forward svc/grafana 3000:80

# Prometheus
kubectl -n monitoring port-forward svc/prometheus 9090:9090

# Any service
kubectl -n <namespace> port-forward svc/<service> <local-port>:<remote-port>
```

---

## Full Reset

```bash
# Nuclear option — delete everything
kubectl delete all --all -A
kubectl delete pvc --all -A
kubectl delete secrets --all -A

# Or just nuke the cluster
kind delete cluster --name gitops-local
```
