# AWS Setup Guide

This document provides detailed instructions for setting up AWS resources for the Hello World application.

## Prerequisites

Before you begin, make sure you have the following:

- AWS Account
- AWS CLI installed and configured
- Terraform installed

## Step 1: Configure AWS CLI

```bash
aws configure
```

Enter your AWS Access Key ID, Secret Access Key, and default region.

## Step 2: Create an S3 Bucket for Terraform State

```bash
aws s3api create-bucket --bucket hello-world-terraform-state --region us-east-1
```

## Step 3: Enable Versioning on the S3 Bucket

```bash
aws s3api put-bucket-versioning --bucket hello-world-terraform-state --versioning-configuration Status=Enabled
```

## Step 4: Create a DynamoDB Table for Terraform State Locking

```bash
aws dynamodb create-table \
    --table-name hello-world-terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-east-1
```

## Step 5: Create an ECR Repository

```bash
aws ecr create-repository --repository-name hello-world --region us-east-1
```

## Step 6: Create an IAM User for CI/CD

```bash
aws iam create-user --user-name hello-world-cicd
```

## Step 7: Create an Access Key for the IAM User

```bash
aws iam create-access-key --user-name hello-world-cicd
```

Save the Access Key ID and Secret Access Key for later use.

## Step 8: Create an IAM Policy for the CI/CD User

Create a file named `cicd-policy.json` with the following content:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    }
  ]
}
```

```bash
aws iam create-policy --policy-name hello-world-cicd-policy --policy-document file://cicd-policy.json
```

## Step 9: Attach the Policy to the IAM User

```bash
aws iam attach-user-policy --user-name hello-world-cicd --policy-arn arn:aws:iam::YOUR_AWS_ACCOUNT_ID:policy/hello-world-cicd-policy
```

## Step 10: Update Terraform Variables

Update the `terraform/terraform.tfvars` file with your AWS account ID and other variables:

```hcl
aws_account_id = "YOUR_AWS_ACCOUNT_ID"
aws_region     = "us-east-1"
cluster_name   = "hello-world-eks"
```

## Step 11: Initialize Terraform

```bash
cd terraform
terraform init -backend-config="bucket=hello-world-terraform-state" -backend-config="key=terraform.tfstate" -backend-config="region=us-east-1" -backend-config="dynamodb_table=hello-world-terraform-state-lock"
```

## Step 12: Apply Terraform

```bash
terraform apply -var="aws_account_id=YOUR_AWS_ACCOUNT_ID"
```

## Step 13: Configure kubectl

```bash
aws eks update-kubeconfig --name hello-world-eks --region us-east-1
```

## Step 14: Set Up GitHub Secrets

If you're using GitHub Actions for CI/CD, set up the following secrets in your GitHub repository:

- AWS_ACCESS_KEY_ID: The Access Key ID of the CI/CD user
- AWS_SECRET_ACCESS_KEY: The Secret Access Key of the CI/CD user

## Step 15: Clean Up

When you're done with the application, clean up the AWS resources:

```bash
# Delete the Terraform-managed resources
cd terraform
terraform destroy -var="aws_account_id=YOUR_AWS_ACCOUNT_ID"

# Delete the ECR repository
aws ecr delete-repository --repository-name hello-world --force

# Delete the IAM user
aws iam detach-user-policy --user-name hello-world-cicd --policy-arn arn:aws:iam::YOUR_AWS_ACCOUNT_ID:policy/hello-world-cicd-policy
aws iam delete-policy --policy-arn arn:aws:iam::YOUR_AWS_ACCOUNT_ID:policy/hello-world-cicd-policy
aws iam delete-access-key --user-name hello-world-cicd --access-key-id YOUR_ACCESS_KEY_ID
aws iam delete-user --user-name hello-world-cicd

# Delete the DynamoDB table
aws dynamodb delete-table --table-name hello-world-terraform-state-lock

# Delete the S3 bucket
aws s3 rm s3://hello-world-terraform-state --recursive
aws s3api delete-bucket --bucket hello-world-terraform-state
```

## Troubleshooting

### Terraform Apply Fails

If Terraform apply fails, check the error message and fix the issue. Common issues include:

- Missing permissions
- Resource already exists
- Invalid configuration

### kubectl Cannot Connect to the Cluster

If kubectl cannot connect to the cluster, check the following:

- The cluster is running
- The kubeconfig is correctly configured
- The AWS credentials are correctly configured

### ECR Push Fails

If pushing to ECR fails, check the following:

- The repository exists
- The IAM user has the necessary permissions
- The Docker image is correctly tagged
