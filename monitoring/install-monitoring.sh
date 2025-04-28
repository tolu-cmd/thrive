#!/bin/bash
set -e

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus
echo "Installing Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --set alertmanager.config.receivers[0].slack_configs[0].api_url=${SLACK_WEBHOOK_URL:-https://hooks.slack.com/services/your/webhook/url}

# Install Grafana
echo "Installing Grafana..."
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --values grafana-values.yaml

# Wait for Grafana to be ready
echo "Waiting for Grafana to be ready..."
kubectl rollout status deployment/grafana -n monitoring

# Get Grafana URL
echo "Grafana URL:"
kubectl get svc grafana -n monitoring -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"
echo ""

# Get Grafana admin password
echo "Grafana admin password: admin"

# Get Prometheus URL
echo "Prometheus URL:"
kubectl get svc prometheus-server -n monitoring -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"
echo ""

echo "Monitoring stack installed successfully!"
