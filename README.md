# Hello World Application

This repository contains a simple Hello World application deployed on AWS EKS with monitoring, CI/CD, and other DevOps best practices.

## Architecture

The application is deployed on AWS EKS with the following components:

- **AWS EKS**: Managed Kubernetes service for running the application
- **AWS ECR**: Container registry for storing Docker images
- **AWS Load Balancer Controller**: For exposing the application to the internet
- **Prometheus & Grafana**: For monitoring and alerting
- **GitHub Actions**: For CI/CD

## Prerequisites

- AWS CLI
- kubectl
- Terraform
- Docker
- Helm

## Deployment Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/hello-world.git
cd hello-world
```

### 2. Configure AWS Credentials

```bash
aws configure
```

Enter your AWS Access Key ID, Secret Access Key, and default region.

### 3. Deploy the Infrastructure

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

### 4. Configure kubectl

```bash
aws eks update-kubeconfig --name hello-world-eks --region us-east-1
```

### 5. Deploy the Application

```bash
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

### 6. Deploy the AWS Load Balancer Controller

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

### 7. Deploy Prometheus and Grafana

```bash
# Create the monitoring namespace
kubectl create namespace monitoring

# Install Prometheus
cd monitoring
helm install prometheus prometheus-community/prometheus --namespace monitoring --values prometheus-values-emptydir.yaml

# Install Grafana
helm install grafana grafana/grafana --namespace monitoring --values grafana-values-emptydir.yaml

# Get the Grafana password
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Get the Grafana URL
kubectl get svc grafana -n monitoring
```

### 8. Access the Application

```bash
# Get the application URL
kubectl get svc hello-world -n hello-world
```

## Blue/Green Deployments

To perform a blue/green deployment:

```bash
# Deploy the blue version
kubectl apply -f k8s/blue-deployment.yaml
kubectl apply -f k8s/blue-service.yaml

# Deploy the green version
kubectl apply -f k8s/green-deployment.yaml
kubectl apply -f k8s/green-service.yaml

# Switch between blue and green
./scripts/switch-deployment.sh blue
./scripts/switch-deployment.sh green
```

## Canary Deployments

To perform a canary deployment:

```bash
# Deploy a canary version
./scripts/canary-deployment.sh v2

# If the canary is successful, update the main deployment
./scripts/update-deployment.sh v2

# Delete the canary deployment
kubectl delete deployment hello-world-canary -n hello-world
```

## Monitoring

### Prometheus

Access Prometheus at: http://ae9030e500cc648f78e825f4372fbccc-2050249566.us-east-1.elb.amazonaws.com/query

```

```

### Grafana

Access Grafana at:http://a51f0e494f1f741b2ae34c30901d4f1c-191398344.us-east-1.elb.amazonaws.com/d/os6Bh8Omk/kubernetes-cluster?orgId=1&from=now-30m&to=now&timezone=browser&refresh=30s

```
http://<grafana-service-url>

```

- Username: admin
- Password: (Get from the command above)

## CI/CD Pipeline

The CI/CD pipeline is configured in `.github/workflows/ci-cd.yaml`. It performs the following steps:

1. Build the Docker image
2. Push it to Amazon ECR
3. Deploy it to the Kubernetes cluster
4. Verify the deployment
5. Run tests

To use the CI/CD pipeline, you need to set up the following secrets in your GitHub repository:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

## Tradeoffs and Decisions

- **EKS vs. ECS**: We chose EKS for better Kubernetes compatibility and ecosystem.
- **Prometheus vs. CloudWatch**: We chose Prometheus for better customization and Grafana integration.
- **emptyDir vs. PersistentVolumes**: We used emptyDir for simplicity, but in a production environment, you would want to use PersistentVolumes.
- **Blue/Green vs. Canary**: We implemented both for flexibility.

## License

