# Manifest Organization Plan

## Current Structure (Flat)
45 manifest files in `/talos/manifests/`

## Proposed Structure

```
talos/manifests/
├── README.md                          # Overview and dependency map
├── 00-namespaces/                     # Creates namespaces and basic resources
│   └── namespaces.yaml
├── 10-networking/                     # Networking layer
│   ├── README.md
│   ├── cilium-minimal.yaml
│   ├── cilium.yaml
│   ├── cilium-bgp-config.yaml
│   ├── cilium-ingressclass.yaml
│   ├── cilium-ingress-lb.yaml
│   ├── cilium-ingress-rbac.yaml
│   ├── cilium-l2-ippool.yaml
│   ├── cilium-loadbalancer-ippool.yaml
│   ├── cilium-network-policies-examples.yaml
│   ├── cilium-values-minimal.yaml
│   ├── cilium-values.yaml
│   ├── gateway-api-crds.yaml
│   ├── gateway-api-examples.yaml
│   └── traefik-ingressroutes.yaml
├── 20-security/                       # Security & certificates
│   ├── README.md
│   ├── cert-manager.yaml
│   └── cilium-network-policies/       # Network policies examples
│       └── cilium-network-policies-examples.yaml
├── 30-storage/                        # Storage backends
│   ├── README.md
│   ├── longhorn/
│   │   ├── longhorn.yaml
│   │   ├── longhorn-namespace.yaml
│   │   ├── longhorn-values-minimal.yaml
│   │   ├── longhorn-values.yaml
│   │   ├── longhorn-recurring-jobs.yaml
│   │   ├── longhorn-storage-classes.yaml
│   │   └── README.md
│   ├── openebs/
│   │   ├── openebs.yaml
│   │   └── README.md
│   ├── rook-ceph/
│   │   ├── rook-ceph-operator.yaml
│   │   ├── rook-ceph-operator-values.yaml
│   │   ├── rook-ceph-cluster.yaml
│   │   ├── rook-ceph-cluster-values.yaml
│   │   └── README.md
│   └── minio/
│       ├── minio.yaml
│       └── README.md
├── 40-observability/                  # Monitoring, logging, metrics
│   ├── README.md
│   ├── prometheus/
│   │   ├── prometheus-grafana.yaml
│   │   └── README.md
│   ├── grafana/
│   │   ├── grafana-hubble-dashboard-configmap.yaml
│   │   └── README.md
│   └── loki/
│       ├── loki.yaml
│       └── README.md
├── 50-management/                     # Management UIs & tools
│   ├── README.md
│   ├── portainer/
│   │   ├── portainer.yaml
│   │   ├── portainer-ingress.yaml
│   │   ├── portainer-traefik-ingress.yaml
│   │   └── README.md
│   ├── headlamp/
│   │   ├── headlamp.yaml
│   │   ├── headlamp-token.yaml
│   │   └── README.md
│   └── dns/
│       ├── dns_admin.yaml
│       └── README.md
├── 60-gitops/                         # GitOps & CI/CD (optional)
│   ├── README.md
│   ├── argocd/
│   │   ├── argocd.yaml
│   │   ├── argocd-applications.yaml
│   │   └── README.md
│   └── jenkins/
│       ├── jenkins.yaml
│       └── README.md
└── 70-loadbalancing/                  # Load balancing (optional)
    ├── README.md
    ├── metallb.yaml
    └── ui-loadbalancers.yaml
```

## Dependency Order

The numeric prefixes ensure deployment order:
1. **00-namespaces** - Must deploy first (creates namespaces)
2. **10-networking** - Core networking (Cilium CNI required)
3. **20-security** - Security & certificates
4. **30-storage** - Storage backends
5. **40-observability** - Monitoring
6. **50-management** - Management UIs
7. **60-gitops** - GitOps tools (optional)
8. **70-loadbalancing** - Load balancing (optional)

## Migration Steps

1. Create folder structure
2. Move files to appropriate folders
3. Create README.md in each folder
4. Update main.tf to use new paths
5. Create manifest dependency map
6. Test deployment with new structure

## Benefits

✅ Clear organization by function
✅ Easy to find related components
✅ Dependency order built-in
✅ Easier to enable/disable component groups
✅ Ready for environment-specific overrides (dev/staging/prod)
✅ Scales well as more components added

