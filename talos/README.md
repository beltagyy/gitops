# Talos Terraform Deployment
This terraform code is used to configure a talos node and deploy a kubernetes cluster on it then bootstrap essential kubernetes components.  

## Creating Bootstrap Manifests
We're creating the bootstrap manifests through helm. For a specific helm deployments we use the template function of helm, I would advice against using any helm chart that stores secrets inside of them, always prefer applications that automatically create their own temporary secrets on resource creation, avoid anything that could put the secret in the manifest.  
example of creating a manifest template:  
`helm template <helm_deployment_name> <repo/chart> -n <namespace> > manifests/<helm_deployment_name>.yaml`  
Afterwards, you'll need to add the `namespace` configuration to the `manifests/namespaces.yaml` for it to be created before the deployment of the rest of the applications, otherwise they might fail.  
Next, you'll have to edit the `cluster_inline_manifests` in the main terraform file's `bootstrap node` adding the  `helm_deployment_name` and location for it to take effect next time you apply terraform.  

## Terraform
In order to configure a talos node, you need to add the following to the `terraform.tfvars`

```yaml
nodes = {
    "nodename" = {
        node_is_controlplane = <true/false>
        address = "<node_address>"
        ### Optional overrides that will be applied instead of the default ones in the locals
        #### Source: https://docs.siderolabs.com/talos/v1.11/reference/kernel
        override_talos_extra_kernel_args
        #### Source: You can probably find the relevant modules for whatever deployment you're trying to put on the cluster.
        override_talos_kernel_modules
        #### Source: https://github.com/siderolabs/extensions
        override_talos_extensions = ["extension-1-name", "extension-2-name"]
    }
}
```


