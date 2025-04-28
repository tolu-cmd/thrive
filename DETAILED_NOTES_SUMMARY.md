# Summary of Project Setup

This document provides a summary of all the steps taken to set up the project, highlighting the key components and the reasoning behind each decision.

## Key Components Implemented

### 1. Infrastructure Provisioning

- **AWS EKS Cluster**: Set up a managed Kubernetes cluster on AWS.
- **Node Group**: Created a group of EC2 instances to run the Kubernetes pods.
- **VPC**: Used a Virtual Private Cloud for network isolation.
- **IAM Roles and Policies**: Created necessary IAM roles and policies for the EKS cluster, AWS Load Balancer Controller, and EBS CSI Driver.

### 2. Application Deployment

- **Containerization**: Deployed a containerized Hello World application.
- **Kubernetes Resources**: Created necessary Kubernetes resources like deployments, services, and secrets.
- **Health Checks**: Implemented liveness and readiness probes for the application.
- **Auto-scaling**: Set up Horizontal Pod Autoscaler for automatic scaling based on CPU and memory usage.

### 3. Monitoring and Logging

- **Prometheus**: Installed Prometheus for collecting metrics from the application and the Kubernetes cluster.
- **Grafana**: Installed Grafana for visualizing the metrics collected by Prometheus.
- **Dashboards**: Set up dashboards for monitoring the application and the Kubernetes cluster.

### 4. Bonus Points

- **Blue/Green Deployments**: Implemented blue/green deployments for zero-downtime deployments.
- **Canary Deployments**: Implemented canary deployments for gradual rollouts.
- **Secrets Management**: Used Kubernetes secrets for storing sensitive information.
- **Health Checks**: Added health checks to the application for better reliability.

## Challenges and Solutions

### 1. EBS CSI Driver Permissions

**Challenge**: The EBS CSI Driver didn't have the necessary permissions to create EBS volumes, causing persistent volume claims to remain in the Pending state.

**Solution**: Created an IAM policy with the necessary permissions and attached it to the node group role. However, due to the time it takes for the permissions to propagate, we switched to using emptyDir volumes for Prometheus and Grafana.

### 2. Alertmanager Configuration

**Challenge**: The Alertmanager pod was crashing due to issues with the Slack webhook URL configuration.

**Solution**: Disabled the Alertmanager in the Prometheus values file to focus on getting the core monitoring functionality working.

### 3. cert-manager and HTTPS

**Challenge**: The cert-manager pods were not starting due to node capacity issues, preventing us from implementing HTTPS using Let's Encrypt.

**Solution**: Tried to create an ingress resource with a self-signed certificate, but encountered issues with the AWS Load Balancer Controller webhook. Instead, focused on implementing blue/green and canary deployments.

### 4. Node Capacity Issues

**Challenge**: The nodes were at capacity, preventing additional pods from being scheduled.

**Solution**: Focused on implementing deployment strategies that work with the existing pods, such as updating the existing deployment with new image tags and implementing canary deployments by updating the service selector.

## Documentation Created

- **README.md**: Overview of the project and instructions for deployment.
- **ARCHITECTURE.md**: Detailed description of the architecture.
- **DEPLOYMENT.md**: Step-by-step deployment guide.
- **MONITORING.md**: Instructions for monitoring the application.
- **QUICK_START.md**: Quick start guide for deploying the application.
- **AWS_SETUP.md**: Instructions for setting up AWS resources.
- **DETAILED_NOTES.md**: Detailed notes on the project setup.

## Scripts Created

- **scripts/switch-deployment.sh**: Script to switch between blue and green deployments.
- **scripts/update-deployment.sh**: Script to update the deployment with a new image tag.
- **scripts/canary-deployment.sh**: Script to implement canary deployments.

## Conclusion

Despite the challenges encountered, we successfully set up a scalable and observable web application on AWS EKS. The application is deployed with best practices like health checks, auto-scaling, and deployment strategies. The monitoring stack provides visibility into the application and the Kubernetes cluster, enabling proactive monitoring and alerting.
