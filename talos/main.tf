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
    #modules used for longhorn
    "nvme_tcp",
    "vfio_pci",
    "uio_pci_generic"
  ]
  talos_extensions = [
    #extensions needed for longhorn
    "iscsi-tools",
    "util-linux-tools"
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
    namespaces = "manifests/namespaces.yaml"
    argocd = "manifests/argocd.yaml"
    metallb = "manifests/metallb.yaml"
    "cert-manager" = "manifests/cert_manager.yaml"
    ingress = "manifests/ingress.yaml"
  }
  config_templates = {
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