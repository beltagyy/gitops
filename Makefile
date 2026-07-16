.PHONY: help init plan apply destroy fmt validate kubeconfig status ping apps-deploy apps-diff

TALOS_DIR := talos

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ─── Terraform ───────────────────────────────────────────────

init: ## Initialize Terraform
	cd $(TALOS_DIR) && terraform init

plan: ## Preview infrastructure changes
	cd $(TALOS_DIR) && terraform plan

apply: ## Apply infrastructure changes
	cd $(TALOS_DIR) && terraform apply

destroy: ## Destroy infrastructure (DANGER)
	cd $(TALOS_DIR) && terraform destroy

fmt: ## Format Terraform files
	cd $(TALOS_DIR) && terraform fmt -recursive

validate: ## Validate Terraform configuration
	cd $(TALOS_DIR) && terraform validate

# ─── Kubernetes ──────────────────────────────────────────────

kubeconfig: ## Fetch kubeconfig from Talos
	cd $(TALOS_DIR) && talosctl kubeconfig .

status: ## Show cluster status
	kubectl get nodes -o wide
	@echo ""
	kubectl get pods -A

ping: ## Test cluster connectivity
	kubectl cluster-info
	kubectl get cs

# ─── Applications ────────────────────────────────────────────

apps-deploy: ## Deploy all applications via kubectl
	kubectl apply -R -f apps/

apps-diff: ## Show what would change in app deployments
	kubectl diff -R -f apps/

# ─── Utilities ───────────────────────────────────────────────

dashboard: ## Open Kubernetes dashboard
	@echo "Opening Headlamp dashboard..."
	@echo "URL: https://headlamp.local"

portainer: ## Open Portainer dashboard
	@echo "Opening Portainer..."
	@echo "URL: https://portainer.local"

certs: ## Check certificate status
	kubectl get certificates -A
	kubectl get certificaterequests -A

