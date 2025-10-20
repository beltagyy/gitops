## Cluster Specific Configs
### These are used to name the cluster "env-cluster_name" which will be "example-cluster" and it's nodes "test-node_name"
cluster_name = "cluster"
env = "example"

## Bootstrap Controlplane specific configs
bootstrap_node_address = "10.198.141.100"

## Node Configs
nodes = {
  ### The object name is used as the node name, it is appended to the environment "test-controlplane-01"
  "controlplane-01" = {
    node_is_controlplane = true
    address = "10.198.141.101"
  }
  "controlplane-02" = {
    node_is_controlplane = true
    address = "10.198.141.102"
  }
  "worker-01" = {
    node_is_controlplane = false
    address = "10.198.141.103"
  }
  "worker-02" = {
    node_is_controlplane = false
    address = "10.198.141.104"
  }
}