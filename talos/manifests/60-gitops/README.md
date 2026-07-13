# 60-GitOps — Continuous Delivery & CI/CD

GitOps and CI/CD tools for automated deployment workflows.

## 📦 Components

### ArgoCD
**Directory**: `argocd/`

GitOps continuous delivery - syncs Git state to cluster.

**Use for**: Automated app deployments from Git

### Jenkins
**Directory**: `jenkins/`

CI/CD automation and build pipelines.

**Use for**: Build, test, and release automation

## 🚀 Quick Start

Enable in talos/main.tf:

```hcl
argocd = "manifests/60-gitops/argocd/argocd.yaml"
"argocd-applications" = "manifests/60-gitops/argocd/argocd-applications.yaml"
# and/or
# jenkins = "manifests/60-gitops/jenkins/jenkins.yaml"
```

## 📚 See component directories for details
