.SHELLFLAGS = -e

# Variables
TERRAFORM_DIR := infrastucture/payment
ENVIRONMENTS_MAIN := infrastucture/environments-main
TERRAFORM := terraform

# Default target
.PHONY: all
all: help  ## Show this help message

.PHONY: help
help:  ## Show this help message
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?##"} \
	/^##@/ {print "\n" substr($$0, 5)} \
	/^[a-zA-Z0-9_-]+:.*?##/ {printf "  make %-20s - %s\n", $$1, $$2}' $(MAKEFILE_LIST)


# Terraform Environments Main
##@ Terraform Environments Main
.PHONY: init-env-main
init-env-main:  ## Terraform init for Environments Main
	terraform -chdir=$(ENVIRONMENTS_MAIN) init

.PHONY: plan-env-main
plan-env-main:  ## Terraform plan for Environments Main
	terraform -chdir=$(ENVIRONMENTS_MAIN) plan

.PHONY: apply-env-main
apply-env-main:  ## Terraform apply for Environments Main
	terraform -chdir=$(ENVIRONMENTS_MAIN) apply

.PHONY: destroy-env-main
destroy-env-main:  ## Terraform destroy for Environments Main
	terraform -chdir=$(ENVIRONMENTS_MAIN) destroy


# Terraform Payment
##@ Terraform payment
.PHONY: init-payments
init-payments:  ## Terraform init for Payment module
	terraform -chdir=$(TERRAFORM_DIR) init

.PHONY: plan-payments
plan-payments:  ## Terraform plan for Payment module
	terraform -chdir=$(TERRAFORM_DIR) plan

.PHONY: apply-payments
apply-payments:  ## Terraform apply for Payment module
	terraform -chdir=$(TERRAFORM_DIR) apply

.PHONY: destroy-payments
destroy-payments:  ## Terraform destroy for Payment module
	terraform -chdir=$(TERRAFORM_DIR) destroy


# Terraform
##@ Terraform
.PHONY: validate
validate:  ## Validate Terraform configuration (Payment module)
	terraform -chdir=$(TERRAFORM_DIR) validate

.PHONY: format
format:  ## Format Terraform files (Payment module)
	terraform -chdir=$(TERRAFORM_DIR) fmt -recursive


# Terraform
##@ Terraform
.PHONY: create
create: init-env-main init-payments  ## Create all: env-main & payment modules
	terraform -chdir=$(ENVIRONMENTS_MAIN) apply --auto-approve && \
	make store-pay-init && \
	make store-pay-fin && \
	terraform -chdir=$(TERRAFORM_DIR) apply --auto-approve


.PHONY: re-create
re-create: init-env-main init-payments  ## Create all: env-main & payment modules
	terraform -chdir=$(ENVIRONMENTS_MAIN) apply --auto-approve && \
	make deploy-pay-init && \
	make deploy-pay-fin && \
	terraform -chdir=$(TERRAFORM_DIR) apply --auto-approve

.PHONY: destroy-all
destroy-all: init-env-main init-payments  ## Destroy all: payment & env-main modules
	terraform -chdir=$(TERRAFORM_DIR) destroy --auto-approve && \
	terraform -chdir=$(ENVIRONMENTS_MAIN) destroy --auto-approve


# Apps
##@ Apps
.PHONY: store-pay-init
store-pay-init:  ## Store Payment app - init
	cd src/lambda-payments-initializer/ && make store-s3

.PHONY: store-pay-fin
store-pay-fin:  ## Store Payment app - fin
	cd src/lambda-payments-finalizer/ && make store-s3

.PHONY: deploy-pay-init
deploy-pay-init:  ## Deploy Payment app - init
	cd src/lambda-payments-initializer/ && make deploy-s3-using-docker

.PHONY: deploy-pay-fin
deploy-pay-fin:  ## Deploy Payment app - fin
	cd src/lambda-payments-finalizer/ && make deploy-s3-using-docker
