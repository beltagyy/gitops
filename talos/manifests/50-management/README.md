# 50-Management — Management UIs & Tools

Web-based interfaces for cluster and container management.

## 📦 Components

### Portainer
**Directory**: `portainer/`

Container and Docker service management UI.

### Headlamp
**Directory**: `headlamp/`

Native Kubernetes dashboard.

### DNS
**Directory**: `dns/`

DNS administration tools.

## 🚀 Quick Start

Enable in talos/main.tf:

```hcl
portainer = "manifests/50-management/portainer/portainer.yaml"
headlamp = "manifests/50-management/headlamp/headlamp.yaml"
```

## 🔗 Access

Via Traefik ingress:
- Portainer: http://portainer.dev.dih.10.198.141.235.nip.io
- Headlamp: http://headlamp.dev.dih.10.198.141.235.nip.io

## 📚 See component directories for details
