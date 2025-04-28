# Architecture

This document describes the architecture of the Hello World application.

## Overview

The Hello World application is a simple web application that displays a "Hello World" message. It is deployed on AWS EKS with monitoring, CI/CD, and other DevOps best practices.

## Components

### Infrastructure

The infrastructure is provisioned using Terraform and consists of the following components:

- **VPC**: A Virtual Private Cloud that provides network isolation for the application.
- **EKS Cluster**: A managed Kubernetes cluster that runs the application.
- **Node Group**: A group of EC2 instances that run the Kubernetes pods.
- **IAM Roles and Policies**: IAM roles and policies that provide the necessary permissions for the EKS cluster and the AWS Load Balancer Controller.
- **ECR Repository**: A container registry that stores the Docker images.

### Application

The application is a simple Node.js web server that displays a "Hello World" message. It is containerized using Docker and deployed on the EKS cluster.

### Kubernetes Resources

The application is deployed using the following Kubernetes resources:

- **Namespace**: A namespace that isolates the application resources.
- **Deployment**: A deployment that manages the application pods.
- **Service**: A service that exposes the application to the internet.
- **HPA**: A Horizontal Pod Autoscaler that scales the application based on CPU and memory usage.
- **Secrets**: Kubernetes secrets that store sensitive information like API keys and database credentials.

### CI/CD

The CI/CD pipeline is implemented using GitHub Actions and consists of the following steps:

1. Build the Docker image
2. Push it to Amazon ECR
3. Deploy it to the Kubernetes cluster
4. Verify the deployment
5. Run tests

### Monitoring

The monitoring stack consists of the following components:

- **Prometheus**: A monitoring system that collects metrics from the application and the Kubernetes cluster.
- **Grafana**: A visualization tool that displays the metrics collected by Prometheus.

## Deployment Strategies

The application supports the following deployment strategies:

### Blue/Green Deployment

In a blue/green deployment, two identical environments (blue and green) are maintained. At any time, only one of the environments is live. When a new version of the application is deployed, it is deployed to the inactive environment. Once the deployment is verified, traffic is switched from the active environment to the inactive environment.

### Canary Deployment

In a canary deployment, a new version of the application is deployed alongside the existing version. A small percentage of traffic is routed to the new version. If the new version performs well, the percentage of traffic is gradually increased until all traffic is routed to the new version. If the new version does not perform well, traffic is routed back to the existing version.

## Security

The application implements the following security measures:

- **IAM Roles and Policies**: IAM roles and policies that provide the necessary permissions for the EKS cluster and the AWS Load Balancer Controller.
- **Kubernetes Secrets**: Kubernetes secrets that store sensitive information like API keys and database credentials.
- **Network Isolation**: The application is deployed in a VPC that provides network isolation.

## Scalability

The application is designed to be scalable and can handle increased load by:

- **Horizontal Pod Autoscaler**: The HPA scales the application based on CPU and memory usage.
- **Node Group Autoscaling**: The node group can be configured to automatically scale based on the number of pods.

## Reliability

The application is designed to be reliable and can recover from failures by:

- **Kubernetes Deployments**: Kubernetes deployments ensure that the desired number of pods are running at all times.
- **Liveness and Readiness Probes**: Liveness and readiness probes ensure that the application is healthy and ready to serve traffic.

## Monitoring and Alerting

The application is monitored using Prometheus and Grafana. Alerts are configured to notify the team when there are issues with the application.

## Diagram

```
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
|  GitHub Actions  |     |  Amazon ECR      |     |  Amazon EKS      |
|                  |     |                  |     |                  |
+--------+---------+     +--------+---------+     +--------+---------+
         |                        |                        |
         |                        |                        |
         v                        v                        v
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
|  CI/CD Pipeline  +---->+  Docker Images   +---->+  Kubernetes     |
|                  |     |                  |     |  Resources      |
+------------------+     +------------------+     +--------+---------+
                                                           |
                                                           |
                                                           v
                                                  +------------------+
                                                  |                  |
                                                  |  Prometheus &    |
                                                  |  Grafana         |
                                                  |                  |
                                                  +------------------+
