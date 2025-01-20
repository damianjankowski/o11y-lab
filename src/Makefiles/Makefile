SHELL := /bin/bash

# .env
# -----------------------------------------------------------------------------
ifneq (,$(wildcard ./.env))
    $(info .env file loaded)
    include .env
    export
else
    $(info .env not exists)
endif

# Variables
# -----------------------------------------------------------------------------
PYTHON := python3
PIP := pip3
AWS := aws
MAIN_FILE := $(MAIN_FILE)
REQUIREMENTS := requirements.txt
REQUIREMENTS_DEV := requirements-dev.txt
LOCUST_FILE := locustfile.py
LOCUST_PORT := $(LOCUST_PORT)

PREFIX := $(PREFIX)
PROJECT := $(notdir $(CURDIR))
PROJECT_NAME := $(if $(PROJECT_NAME),$(PROJECT_NAME),$(PREFIX)-$(PROJECT))

AWS_LAMBDA_FUNCTION_NAME := $(PROJECT_NAME)
DEPLOYMENT_PACKAGE_ZIP := $(AWS_LAMBDA_FUNCTION_NAME).zip
AWS_FUNCTION_DOCKER_IMAGE_NAME := $(PROJECT_NAME)

DEPENDENCIES_DIRECTORY = package

AWS_REGION ?= $(AWS_REGION)
AWS_ACCOUNT_ID ?= $(AWS_ACCOUNT_ID)
BUCKET_NAME = $(PREFIX)-s3-bucket
AWS_ECR_REPO := $(PREFIX)
DATE_TAG := $(shell date +%Y%m%d)
TAGS := latest $(DATE_TAG)

.DEFAULT_GOAL := all

# General
# -----------------------------------------------------------------------------
##@ General

.PHONY: help
help:  ## Show this help message
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?##"} \
	/^##@/ {print "\n" substr($$0, 5)} \
	/^[a-zA-Z0-9_-]+:.*?##/ {printf "  make %-20s - %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: all
all:  ## Display the help message for all targets
	@make help

# Setup
# -----------------------------------------------------------------------------
##@ Setup

.PHONY: install
install:  ## Install dependencies from requirements.txt
	$(PIP) install -r $(REQUIREMENTS)

.PHONY: install-dev
install-dev:  ## Install development dependencies from requirements-dev.txt
	$(PIP) install -r $(REQUIREMENTS_DEV)

# Development
# -----------------------------------------------------------------------------
##@ Development

.PHONY: locust
locust:  ## Run Locust for performance testing
	$(PYTHON) -m locust -f test_perf/$(LOCUST_FILE) --web-port $(LOCUST_PORT)

.PHONY: clean
clean:  ## Remove temporary files, caches, and build artifacts
	@echo "Cleaning up temporary files and caches..."
	find . -type f -name '*.pyc' -delete
	find . -type d -name '__pycache__' -delete
	rm -rf .pytest_cache $(DEPLOYMENT_PACKAGE_ZIP) $(DEPENDENCIES_DIRECTORY)
	[ -f Dockerfile ] && rm Dockerfile || true

# Deployment
# -----------------------------------------------------------------------------
##@ Deployment

.PHONY: package
package: clean ## Create a deployment package for AWS Lambda
	@echo "Creating deployment package..."
	mkdir -p $(DEPENDENCIES_DIRECTORY)
	$(PIP) install --target $(DEPENDENCIES_DIRECTORY) -r $(REQUIREMENTS)
	cd $(DEPENDENCIES_DIRECTORY) && zip -r ../$(DEPLOYMENT_PACKAGE_ZIP) .
	zip $(DEPLOYMENT_PACKAGE_ZIP) $(MAIN_FILE)
	@echo "Deployment package $(DEPLOYMENT_PACKAGE_ZIP) created."
	[ -f Dockerfile ] && rm Dockerfile

.PHONY: build-on-docker
build-on-docker: clean ## Create a deployment package for AWS Lambda
	@echo $(PROJECT_NAME)
	@echo "Creating deployment package..."
	mkdir -p $(DEPENDENCIES_DIRECTORY)
	[ ! -f Dockerfile ] && cp ../Dockerfiles/Dockerfile Dockerfile
	docker build -t lambda-build .
	docker create --name lambda-build-container lambda-build
	docker cp lambda-build-container:/out/. ./package
	docker rm lambda-build-container
	cd $(DEPENDENCIES_DIRECTORY) && zip -r ../$(DEPLOYMENT_PACKAGE_ZIP) .
	zip $(DEPLOYMENT_PACKAGE_ZIP) $(MAIN_FILE)
	@echo "Deployment package $(DEPLOYMENT_PACKAGE_ZIP) created."
	rm Dockerfile
	@echo "Dockerfile removed."

.PHONY: store-s3
store-s3: build-on-docker  ## Upload the Lambda function code to S3 and deploy it
	$(AWS) s3 cp $(DEPLOYMENT_PACKAGE_ZIP) s3://$(BUCKET_NAME)/$(DEPLOYMENT_PACKAGE_ZIP)

.PHONY: deploy-s3-using-docker
deploy-s3-using-docker: store-s3  ## Upload the Lambda function code to S3 and deploy it
	$(AWS) lambda update-function-code --function-name $(AWS_LAMBDA_FUNCTION_NAME) --s3-bucket $(BUCKET_NAME) --s3-key $(DEPLOYMENT_PACKAGE_ZIP) --no-cli-pager

.PHONY: deploy-s3
deploy-s3: package  ## Upload the Lambda function code to S3 and deploy it
	$(AWS) s3 cp $(DEPLOYMENT_PACKAGE_ZIP) s3://$(BUCKET_NAME)/$(DEPLOYMENT_PACKAGE_ZIP)
	$(AWS) lambda update-function-code --function-name $(AWS_LAMBDA_FUNCTION_NAME) --s3-bucket $(BUCKET_NAME) --s3-key $(DEPLOYMENT_PACKAGE_ZIP)

.PHONY: deploy
deploy: package ## Deploy the Lambda function to AWS
	$(AWS) lambda update-function-code --function-name $(AWS_LAMBDA_FUNCTION_NAME) --zip-file fileb://$(DEPLOYMENT_PACKAGE_ZIP) --region $(AWS_REGION)

# Docker
# -----------------------------------------------------------------------------
##@ Docker

.PHONY: push
push:  ## Build and push Docker image to AWS ECR
	$(AWS) ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
	docker build --platform linux/amd64 -t $(AWS_FUNCTION_DOCKER_IMAGE_NAME):latest .
	@for tag in $(TAGS); do \
		docker tag $(AWS_FUNCTION_DOCKER_IMAGE_NAME):latest $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(AWS_ECR_REPO):$$tag; \
		docker push $(AWS_ACCOUNT_ID).dkr.ecr.$$(AWS_REGION).amazonaws.com/$(AWS_ECR_REPO):$$tag; \
	done

.PHONY: clean-images
clean-images:  ## Remove Docker images locally
	@for tag in $(TAGS); do \
		docker rmi $(AWS_FUNCTION_DOCKER_IMAGE_NAME):$$tag || true; \
		docker rmi $(AWS_ACCOUNT_ID).dkr.ecr.$$(AWS_REGION).amazonaws.com/$(AWS_ECR_REPO):$$tag || true; \
	done

.PHONY: list-images
list-images:  ## List Docker images in AWS ECR
	$(AWS) ecr list-images --repository-name $(AWS_ECR_REPO) --query 'imageIds[*]' --output json

# Lambda Locally
# -----------------------------------------------------------------------------
##@ Lambda Locally

.PHONY: sam-build
sam-build:  ## Build the Lambda function using SAM
	sam build

.PHONY: invoke
invoke:  ## Invoke the Lambda function locally using SAM
	sam local invoke function --event test_data/event.json
