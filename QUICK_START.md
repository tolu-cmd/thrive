# Quick Start Guide

This document provides a quick start guide for deploying the Hello World application on AWS EKS.

## Prerequisites

Before you begin, make sure you have the following tools installed:

- AWS CLI
- kubectl
- Terraform
- Docker
- Helm

## Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/hello-world.git
cd hello-world
```

## Step 2: Configure AWS Credentials

```bash
aws configure
```

Enter your AWS Access Key ID, Secret Access Key, and default region.

## Step 3: Deploy the Infrastructure

```bash
cd terraform
terraform init
terraform apply -var="aws_account_id=YOUR_AWS_ACCOUNT_ID"
```

## Step 4: Configure kubectl

```bash
aws eks update-kubeconfig --name hello-world-eks --region us-east-1
```

## Step 5: Deploy the Application

```bash
cd ..

# Create the namespace
kubectl apply -f k8s/namespace.yaml

# Create the secrets
kubectl apply -f k8s/secrets.yaml

# Deploy the application
kubectl apply -f k8s/deployment-with-secrets.yaml
kubectl apply -f k8s/service.yaml

# Deploy the HPA
kubectl apply -f k8s/hpa.yaml
```

## Step 6: Deploy the AWS Load Balancer Controller

```bash
# Create the IAM policy
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://terraform/iam_policy.json

# Create the service account
kubectl apply -f k8s/aws-load-balancer-controller-service-account.yaml

# Install the controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=hello-world-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

## Step 7: Deploy Prometheus and Grafana

```bash
# Create the monitoring namespace
kubectl create namespace monitoring

# Install Prometheus
cd monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus --namespace monitoring --values prometheus-values-emptydir.yaml

# Install Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana --namespace monitoring --values grafana-values-emptydir.yaml
```

## Step 8: Access the Application

```bash
# Get the application URL
kubectl get svc hello-world -n hello-world
```

## Step 9: Access Prometheus and Grafana

```bash
# Get the Prometheus URL
kubectl get svc prometheus-server -n monitoring

# Get the Grafana URL
kubectl get svc grafana -n monitoring

# Get the Grafana password
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

## Next Steps

For more detailed information, refer to the following documents:

- [Architecture](ARCHITECTURE.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Monitoring Guide](MONITORING.md)
