# Monitoring Guide

This document provides detailed instructions for monitoring the Hello World application using Prometheus and Grafana.

## Overview

The monitoring stack consists of the following components:

- **Prometheus**: A monitoring system that collects metrics from the application and the Kubernetes cluster.
- **Grafana**: A visualization tool that displays the metrics collected by Prometheus.

## Deployment

### Prerequisites

Before you begin, make sure you have the following tools installed:

- kubectl
- Helm

### Step 1: Create the Monitoring Namespace

```bash
kubectl create namespace monitoring
```

### Step 2: Install Prometheus

```bash
cd monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus --namespace monitoring --values prometheus-values-emptydir.yaml
```

### Step 3: Install Grafana

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana --namespace monitoring --values grafana-values-emptydir.yaml
```

### Step 4: Access Prometheus

```bash
# Get the Prometheus URL
kubectl get svc prometheus-server -n monitoring

# Port forward to access Prometheus locally
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```

Access Prometheus at http://localhost:9090

### Step 5: Access Grafana

```bash
# Get the Grafana URL
kubectl get svc grafana -n monitoring

# Get the Grafana password
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port forward to access Grafana locally
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

Access Grafana at http://localhost:3000

- Username: admin
- Password: (Get from the command above)

## Metrics

### Application Metrics

The application exposes the following metrics:

- **HTTP Request Count**: The number of HTTP requests received by the application.
- **HTTP Request Duration**: The duration of HTTP requests.
- **HTTP Request Size**: The size of HTTP requests.
- **HTTP Response Size**: The size of HTTP responses.

### Kubernetes Metrics

Prometheus collects the following Kubernetes metrics:

- **CPU Usage**: The CPU usage of the pods.
- **Memory Usage**: The memory usage of the pods.
- **Network I/O**: The network I/O of the pods.
- **Disk I/O**: The disk I/O of the pods.

## Dashboards

### Kubernetes Dashboards

The following Kubernetes dashboards are available in Grafana:

- **Kubernetes Cluster**: Provides an overview of the Kubernetes cluster.
- **Kubernetes Nodes**: Provides detailed information about the Kubernetes nodes.
- **Kubernetes Pods**: Provides detailed information about the Kubernetes pods.

### Application Dashboards

The following application dashboards are available in Grafana:

- **Hello World App**: Provides detailed information about the Hello World application.

## Alerting

### Prometheus Alerting

Prometheus is configured with the following alerting rules:

- **High CPU Usage**: Alerts when the CPU usage of a pod exceeds 80% for 5 minutes.
- **High Memory Usage**: Alerts when the memory usage of a pod exceeds 80% for 5 minutes.
- **Pod Restart**: Alerts when a pod restarts more than 5 times in 1 hour.
- **Pod Not Ready**: Alerts when a pod is not ready for more than 5 minutes.

### Grafana Alerting

Grafana is configured with the following alerting rules:

- **High HTTP Error Rate**: Alerts when the HTTP error rate exceeds 5% for 5 minutes.
- **High HTTP Latency**: Alerts when the HTTP latency exceeds 500ms for 5 minutes.

## Troubleshooting

### Prometheus is not collecting metrics

If Prometheus is not collecting metrics, check the Prometheus logs:

```bash
kubectl logs -n monitoring deployment/prometheus-server
```

### Grafana is not displaying metrics

If Grafana is not displaying metrics, check the Grafana logs:

```bash
kubectl logs -n monitoring deployment/grafana
```

### Alerting is not working

If alerting is not working, check the Alertmanager logs:

```bash
kubectl logs -n monitoring statefulset/prometheus-alertmanager
```

## Cleanup

To clean up the monitoring stack, run:

```bash
# Delete Grafana
helm uninstall grafana -n monitoring

# Delete Prometheus
helm uninstall prometheus -n monitoring

# Delete the monitoring namespace
kubectl delete namespace monitoring
