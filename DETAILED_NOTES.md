# Detailed Notes on Project Setup

This document provides a detailed explanation of all the steps taken to set up the project, including commands executed, troubleshooting steps, and the reasoning behind each action.

## 1. Initial Setup

### Setting the AWS Account ID

First, I updated the AWS account ID in the necessary files to ensure all resources are created under the correct account.

```bash
# Update the AWS account ID in the AWS Load Balancer Controller service account
kubectl apply -f k8s/aws-load-balancer-controller-service-account.yaml
```

This command applies the AWS Load Balancer Controller service account configuration to the Kubernetes cluster. The service account is necessary for the AWS Load Balancer Controller to interact with AWS resources.

## 2. Setting up the EBS CSI Driver

The EBS CSI (Container Storage Interface) Driver is required to provision EBS volumes for Kubernetes persistent volumes.

```bash
# Install the EBS CSI Driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"
```

This command installs the EBS CSI Driver from the official Kubernetes SIGs repository. The driver enables Kubernetes to provision and manage EBS volumes.

### Checking the Status of the EBS CSI Driver

```bash
# Check if the EBS CSI Driver pods are running
kubectl get pods -n kube-system | grep ebs-csi
```

This command lists all pods in the kube-system namespace that have "ebs-csi" in their name. It helps verify that the EBS CSI Driver pods are running.

### Checking Persistent Volume Claims

```bash
# Check if the persistent volume claims are being provisioned
kubectl get pvc -n monitoring
```

This command lists all persistent volume claims in the monitoring namespace. It helps verify that the persistent volume claims are being created and provisioned.

### Troubleshooting EBS CSI Driver Permissions

When I noticed that the persistent volume claims were stuck in the Pending state, I checked the events for the PVC:

```bash
# Describe the PVC to see the events
kubectl describe pvc grafana -n monitoring
```

This command shows detailed information about the Grafana PVC, including events that might indicate why it's not being provisioned.

I discovered that the EBS CSI Driver didn't have the necessary permissions to create EBS volumes. To fix this, I created an IAM policy and attached it to the node group role:

```bash
# Create an IAM policy for the EBS CSI Driver
cat > ebs-csi-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume",
        "ec2:DeleteVolume",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:DescribeVolumes",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create the IAM policy
aws iam create-policy --policy-name EBS-CSI-Driver-Policy --policy-document file://ebs-csi-policy.json

# Get the ARN of the node group role
aws iam list-roles | grep main-eks-node-group

# Attach the policy to the node group role
aws iam attach-role-policy --role-name main-eks-node-group-20250427201850220000000001 --policy-arn arn:aws:iam::826783599335:policy/EBS-CSI-Driver-Policy
```

These commands create an IAM policy that allows the EBS CSI Driver to create, delete, attach, and detach EBS volumes, and then attach that policy to the node group role.

## 3. Setting up Monitoring with Prometheus and Grafana

### Initial Attempt with Persistent Volumes

Initially, I tried to set up Prometheus and Grafana with persistent volumes for data storage:

```bash
# Create values files for Prometheus and Grafana
cat > monitoring/prometheus-values.yaml << EOF
server:
  persistentVolume:
    size: 2Gi  # Reduced size for cost savings
    storageClass: gp2

  resources:
    limits:
      cpu: 200m  # Reduced for cost savings
      memory: 256Mi  # Reduced for cost savings
    requests:
      cpu: 50m  # Reduced for cost savings
      memory: 64Mi  # Reduced for cost savings

alertmanager:
  enabled: true
  persistentVolume:
    size: 1Gi  # Reduced size for cost savings
    storageClass: gp2

  resources:
    limits:
      cpu: 100m  # Reduced for cost savings
      memory: 128Mi  # Reduced for cost savings
    requests:
      cpu: 25m  # Reduced for cost savings
      memory: 32Mi  # Reduced for cost savings

  # Configure alertmanager to send alerts to Slack
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['alertname', 'job']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: 'slack'
      routes:
      - match:
          severity: critical
        receiver: 'slack'
    receivers:
    - name: 'slack'
      slack_configs:
      - api_url: '${SLACK_WEBHOOK_URL}'
        channel: '#alerts'
        send_resolved: true
        title: '{{ template "slack.default.title" . }}'
        text: '{{ template "slack.default.text" . }}'

nodeExporter:
  enabled: true

  resources:
    limits:
      cpu: 100m  # Reduced for cost savings
      memory: 30Mi  # Reduced for cost savings
    requests:
      cpu: 50m  # Reduced for cost savings
      memory: 20Mi  # Reduced for cost savings

pushgateway:
  enabled: false

kubeStateMetrics:
  enabled: true
EOF

cat > monitoring/grafana-values.yaml << EOF
adminPassword: admin

persistence:
  enabled: true
  size: 1Gi  # Reduced size for cost savings
  storageClass: gp2
  
resources:
  limits:
    cpu: 100m  # Reduced for cost savings
    memory: 128Mi  # Reduced for cost savings
  requests:
    cpu: 50m  # Reduced for cost savings
    memory: 64Mi  # Reduced for
