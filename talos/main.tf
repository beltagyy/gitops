locals {
  ## Main controlplane node, needed to bootstrap the talos cluster and deployments
  controlplane_address = var.bootstrap_node_address
  controlplane_url = "https://${local.controlplane_address}:6443"
  cluster_name = "${var.env}-${var.cluster_name}"
  ## Networking stuff
  nameservers = ["9.9.9.9","8.8.8.8", "8.8.4.4", "1.1.1.1"] # More dns because dns resolution fails randomly 
  gateway = "10.198.141.1" # I do not know who manages this network
  
  #DO NOT CHANGE, it'll break the nodes
  talos_version = "1.11.2"
  
  talos_extra_kernel_args = [
    "net.ifnames=0" #ensures interface name is standard eth0
  ]
  talos_kernel_modules = [
    #modules used for rook-ceph and storage
    "nvme_tcp",
    "rbd",           # for Ceph RBD
    "br_netfilter",  # for Cilium CNI
    "overlay"        # for container networking
  ]
  talos_extensions = [
    #extensions needed for rook-ceph and storage
    # Additional useful extensions
    "siderolabs/qemu-guest-agent"
  ]
}
## Secrets
resource "talos_machine_secrets" "this" {}

resource "talos_machine_bootstrap" "this" {
  depends_on = [ module.bootstrap-node ]
  node = local.controlplane_address
  client_configuration = talos_machine_secrets.this.client_configuration
}

## file configs
data "talos_client_configuration" "this" {
  cluster_name = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints = [
    local.controlplane_address
  ]
}

## Main Controlplane node, used for bootstrapping the cluster and automatically installing / configuring the core apps
module "bootstrap-node" {
  source = "git::https://github.com/axolotlite/terraform-modules.git//modules/misc/talos_node"
  #Talos configs
  node_is_controlplane = true
  node_address = local.controlplane_address
  cluster_name = local.cluster_name
  talos_version = local.talos_version
  client_configuration = talos_machine_secrets.this.client_configuration
  machine_secrets = talos_machine_secrets.this.machine_secrets
  is_image_secureboot = false
  talos_extra_kernel_args = local.talos_extra_kernel_args
  talos_kernel_modules = local.talos_kernel_modules
  talos_extensions = local.talos_extensions
  cluster_endpoint = local.controlplane_url
  cluster_inline_manifests = {
    # Core Infrastructure
    namespaces = "manifests/namespaces.yaml"

    # Networking - CNI must be deployed FIRST before anything else
    # Minimal Cilium with native routing and kube-proxy replacement
    cilium = "manifests/cilium-minimal.yaml"

    # Gateway API - Required for advanced ingress with Cilium
    #"gateway-api-crds" = "manifests/gateway-api-crds.yaml"

    # Load Balancer & Ingress
   # metallb = "manifests/metallb.yaml"
    #ingress = "manifests/ingress.yaml"

    # Certificate Management
    "cert-manager" = "manifests/cert_manager.yaml"

    # Storage - COMMENTED OUT (Rook-Ceph - complex setup, PVC binding issues)
    # "rook-ceph-operator" = "manifests/rook-ceph-operator.yaml"
    # "rook-ceph-cluster" = "manifests/rook-ceph-cluster.yaml"

    # Storage - COMMENTED OUT (Longhorn - incompatible with Cilium kube-proxy replacement)
    # longhorn = "manifests/longhorn.yaml"

    # Storage - OpenEBS LocalPV (simple, production-ready, Cilium-compatible)
    "openebs" = "manifests/openebs.yaml"

    # Kubernetes Dashboard
    headlamp = "manifests/headlamp.yaml"

    # GitOps
    # argocd = "manifests/argocd.yaml"
    # "argocd-applications" = "manifests/argocd-applications.yaml"

    # Monitoring & Logging
    "prometheus-grafana" = "manifests/prometheus-grafana.yaml"
    loki = "manifests/loki.yaml"

    # Grafana Dashboards for Cilium and Ceph
    "grafana-dashboard-hubble" = "manifests/grafana-hubble-dashboard-configmap.yaml"
    # "grafana-dashboard-ceph" = "manifests/ceph-grafana-dashboard.yaml"  # TODO: Add Ceph dashboard

    # CI/CD & Management
    # jenkins = "manifests/jenkins.yaml"
    portainer = "manifests/portainer.yaml"

    # Object Storage
    minio = "manifests/minio.yaml"
  }
  config_templates = {
    # Disable Flannel CNI and kube-proxy for Cilium
    "templates/disable_cni_kube_proxy.yaml" = {}

    "templates/network.yaml" = {
      node_name = "${var.env}-bootstrap-controlplane"
      nameservers = local.nameservers
      addresses = ["${local.controlplane_address}/24"]
      gateway = local.gateway
    }
  }
}

module "nodes" {
  for_each = var.nodes
  source = "git::https://github.com/axolotlite/terraform-modules.git//modules/misc/talos_node"
  #Talos configs
  node_is_controlplane = each.value.node_is_controlplane
  node_address = each.value.address
  cluster_name = local.cluster_name
  talos_version = local.talos_version
  client_configuration = talos_machine_secrets.this.client_configuration
  machine_secrets = talos_machine_secrets.this.machine_secrets
  is_image_secureboot = false
  talos_extra_kernel_args = each.value.override_talos_extra_kernel_args == null ? local.talos_extra_kernel_args : each.value.override_talos_extra_kernel_args
  talos_kernel_modules = each.value.override_talos_kernel_modules == null ? local.talos_kernel_modules : each.value.override_talos_kernel_modules
  talos_extensions = each.value.override_talos_extensions == null ? local.talos_extensions : each.value.override_talos_extensions
  cluster_endpoint = local.controlplane_url
  config_templates = {
    # Disable Flannel CNI and kube-proxy for Cilium
    "templates/disable_cni_kube_proxy.yaml" = {}

    "templates/allow_scheduling_on_controlplanes.yaml" = {}
    "templates/network.yaml" = {
      node_name = "${var.env}-${each.key}"
      nameservers = local.nameservers
      addresses = ["${each.value.address}/24"]
      gateway = local.gateway
    }
  }
}

### local files
resource "local_file" "talosconfig" {
  content = data.talos_client_configuration.this.talos_config
  filename = "${path.module}/${var.env}.talosconfig"
}