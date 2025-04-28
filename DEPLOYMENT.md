# Deployment Guide

This document provides detailed instructions for deploying the Hello World application on AWS EKS.

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

This will create:
- VPC
- EKS Cluster
- Node Group
- IAM Roles and Policies
- ECR Repository

## Step 4: Configure kubectl

```bash
aws eks update-kubeconfig --name hello-world-eks --region us-east-1
```

## Step 5: Build and Push the Docker Image

```bash
cd ../src
docker build -t hello-world .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
docker tag hello-world:latest YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/hello-world:latest
docker push YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/hello-world:latest
```

## Step 6: Deploy the Application

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

## Step 7: Deploy the AWS Load Balancer Controller

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

## Step 8: Deploy Prometheus and Grafana

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

# Get the Grafana password
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Get the Grafana URL
kubectl get svc grafana -n monitoring
```

## Step 9: Access the Application

```bash
# Get the application URL
kubectl get svc hello-world -n hello-world
```

## Step 10: Set Up CI/CD

1. Push the code to a GitHub repository
2. Set up the following secrets in your GitHub repository:
   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY
3. The CI/CD pipeline will automatically build, push, and deploy the application when you push to the main branch.

## Troubleshooting

### Pods are not starting

If pods are not starting, check the pod events:

```bash
kubectl describe pod <pod-name> -n <namespace>
```

### Services are not accessible

If services are not accessible, check the service and endpoints:

```bash
kubectl get svc <service-name> -n <namespace>
kubectl get endpoints <service-name> -n <namespace>
```

### Load Balancer is not provisioning

If the load balancer is not provisioning, check the AWS Load Balancer Controller logs:

```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Prometheus or Grafana is not working

If Prometheus or Grafana is not working, check the pod logs:

```bash
kubectl logs -n monitoring <pod-name>
```

## Cleanup

To clean up the resources, run:

```bash
# Delete the application
kubectl delete -f k8s/hpa.yaml
kubectl delete -f k8s/service.yaml
kubectl delete -f k8s/deployment-with-secrets.yaml
kubectl delete -f k8s/secrets.yaml
kubectl delete -f k8s/namespace.yaml

# Delete Prometheus and Grafana
helm uninstall grafana -n monitoring
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring

# Delete the AWS Load Balancer Controller
helm uninstall aws-load-balancer-controller -n kube-system
kubectl delete -f k8s/aws-load-balancer-controller-service-account.yaml

# Delete the infrastructure
cd terraform
terraform destroy -var="aws_account_id=YOUR_AWS_ACCOUNT_ID"
