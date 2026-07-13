locals {
  ## Main controlplane node, needed to bootstrap the talos cluster and deployments
  controlplane_address = var.bootstrap_node_address
  controlplane_url = "https://${local.controlplane_address}:6443"
  cluster_name = "${var.env}-${var.cluster_name}"
  ## Networking stuff
  nameservers = ["9.9.9.9","8.8.8.8", "8.8.4.4", "1.1.1.1"] # More dns because dns resolution fails randomly 
  gateway = "10.198.141.1" # I do not know who manages this network
  
  # Talos OS version for all nodes
  # Updated to v1.12.0 for iscsi-tools compatibility with Longhorn
  # Schematic: 53513e54bb39202f35694412577a6bc53d484744d35a126e5d42ef34785c0d83
  # This schematic includes: qemu-guest-agent, iscsi-tools, util-linux-tools
  talos_version = "1.12.0"

  # Kernel arguments for all nodes
  talos_extra_kernel_args = [
    "net.ifnames=0" # Ensures interface name is standard eth0 for consistency
  ]

  # Kernel modules required for storage and networking
  talos_kernel_modules = [
    # Storage modules
    "nvme_tcp",      # NVMe over TCP for remote storage
    "rbd",           # Ceph RADOS Block Device support
    # Networking modules
    "br_netfilter",  # Bridge netfilter for Cilium CNI
    "overlay"        # Overlay filesystem for container networking
  ]

  # Talos system extensions required for cluster functionality
  # These extensions are compiled into a schematic and must be present on ALL nodes
  # Changing these requires node upgrades with the new schematic
  talos_extensions = [
    # VM guest agent for better integration with Proxmox/hypervisor
    "siderolabs/qemu-guest-agent",

    # Longhorn distributed storage requirements (CRITICAL)
    # Without these, Longhorn manager will fail with "iscsiadm: No such file or directory"
    "siderolabs/iscsi-tools",      # iSCSI initiator for volume attachments
    "siderolabs/util-linux-tools"  # Utilities for disk management (nsenter, mount, etc.)
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
    # ============================================================
    # CORE INFRASTRUCTURE (Always required)
    # ============================================================
    # 00-namespaces: Creates all required namespaces
    namespaces = "manifests/00-namespaces/namespaces.yaml"

    # ============================================================
    # 10-NETWORKING: CNI, Ingress, Load Balancing (Always required)
    # ============================================================
    # Cilium CNI - Use cilium-minimal for most deployments
    cilium = "manifests/10-networking/cilium-minimal.yaml"

    # Traefik Ingress Routes
    # traefik-ingress = "manifests/10-networking/traefik-ingressroutes.yaml"

    # Gateway API (optional, for advanced routing)
    # "gateway-api-crds" = "manifests/10-networking/gateway-api-crds.yaml"

    # MetalLB Load Balancer (optional, Cilium L2 is simpler)
    # metallb = "manifests/70-loadbalancing/metallb.yaml"

    # ============================================================
    # 20-SECURITY: Certificates & Network Policies (Recommended)
    # ============================================================
    "cert-manager" = "manifests/20-security/cert_manager.yaml"

    # ============================================================
    # 30-STORAGE: Choose one or more storage backends (Optional)
    # ============================================================
    # Longhorn (distributed HA storage) - NOW WORKS WITH CILIUM!
    # See manifests/30-storage/longhorn/README.md for details
    # longhorn = "manifests/30-storage/longhorn/longhorn.yaml"

    # OpenEBS LocalPV (high-performance local storage)
    # See manifests/30-storage/openebs/README.md for details
    openebs = "manifests/30-storage/openebs/openebs.yaml"

    # Rook-Ceph (complex distributed storage)
    # See manifests/30-storage/rook-ceph/README.md for details
    # "rook-ceph-operator" = "manifests/30-storage/rook-ceph/rook-ceph-operator.yaml"
    # "rook-ceph-cluster" = "manifests/30-storage/rook-ceph/rook-ceph-cluster.yaml"

    # MinIO (S3-compatible object storage)
    # See manifests/30-storage/minio/README.md for details
    minio = "manifests/30-storage/minio/minio.yaml"

    # ============================================================
    # 40-OBSERVABILITY: Metrics, Logs, Dashboards (Optional)
    # ============================================================
    # Prometheus + Grafana (metrics collection and visualization)
    "prometheus-grafana" = "manifests/40-observability/prometheus/prometheus-grafana.yaml"

    # Loki (centralized logging)
    loki = "manifests/40-observability/loki/loki.yaml"

    # Grafana Dashboards for network observability
    "grafana-dashboard-hubble" = "manifests/40-observability/grafana/grafana-hubble-dashboard-configmap.yaml"

    # ============================================================
    # 50-MANAGEMENT: Web UIs for Cluster Management (Optional)
    # ============================================================
    # Headlamp - Kubernetes Dashboard
    headlamp = "manifests/50-management/headlamp/headlamp.yaml"

    # Portainer - Container Management UI
    portainer = "manifests/50-management/portainer/portainer.yaml"

    # ============================================================
    # 60-GITOPS: Continuous Delivery & CI/CD (Optional)
    # ============================================================
    # ArgoCD - GitOps continuous delivery
    # argocd = "manifests/60-gitops/argocd/argocd.yaml"
    # "argocd-applications" = "manifests/60-gitops/argocd/argocd-applications.yaml"

    # Jenkins - CI/CD automation
    # jenkins = "manifests/60-gitops/jenkins/jenkins.yaml"
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