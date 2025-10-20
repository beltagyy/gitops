variable "cluster_name" {
  description = "The name of the cluster created"
  type = string
  default = "cluster"
}
variable "env" {
  description = "The environemnt name(used to name the nodes)"
  type = string
}
variable "bootstrap_node_address" {
  description = "The bootstrap controlplane node ip address"
  type = string
}

variable "nodes" {
  description = "The node configs of the Talos Kubernetes Cluster"
  type = map(object({
    node_is_controlplane = bool
    address = string
    override_talos_extra_kernel_args = optional(list(string),null)
    override_talos_kernel_modules = optional(list(string),null)
    override_talos_extensions = optional(list(string),null)
  }))
}