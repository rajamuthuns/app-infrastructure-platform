# AWS Credentials Setup Guide

This guide explains how to set up AWS credentials for your infrastructure deployment pipeline.

## 🎯 Overview

Your infrastructure needs AWS credentials to deploy resources across different environments. This guide covers multiple approaches from simple to enterprise-grade security.

## 🔐 Authentication Methods

### Method 1: IAM User with Access Keys (Simple)

**Best for**: Small teams, development environments, getting started quickly

#### Step 1: Create IAM User
```bash
# Using AWS CLI (if you have admin access)
aws iam create-user --user-name terraform-deployer

# Attach PowerUser policy (or create custom policy)
aws iam attach-user-policy \
    --user-name terraform-deployer \
    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

#### Step 2: Create Access Keys
```bash
# Create access key
aws iam create-access-key --user-name terraform-deployer

# Output will show:
# AccessKeyId: AKIA...
# SecretAccessKey: ...
```

#### Step 3: Add to GitHub Secrets
1. Go to your repository: `Settings` → `Secrets and variables` → `Actions`
2. Add these secrets:
   - `AWS_ACCESS_KEY_ID`: Your access key ID
   - `AWS_SECRET_ACCESS_KEY`: Your secret access key

### Method 2: Cross-Account Roles (Recommended)

**Best for**: Production environments, enterprise security, multiple AWS accounts

#### Step 1: Create Deployment Role in Each Account

Create this role in each AWS account (dev, staging, production):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::CENTRAL-ACCOUNT-ID:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "unique-external-id"
        }
      }
    }
  ]
}
```

#### Step 2: Create Central Deployment User
In your central/management account:

```bash
# Create user for GitHub Actions
aws iam create-user --user-name github-actions-deployer

# Create policy to assume cross-account roles
cat > assume-role-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        "arn:aws:iam::DEV-ACCOUNT-ID:role/TerraformDeploymentRole",
        "arn:aws:iam::STAGING-ACCOUNT-ID:role/TerraformDeploymentRole",
        "arn:aws:iam::PROD-ACCOUNT-ID:role/TerraformDeploymentRole"
      ]
    }
  ]
}
EOF

aws iam create-policy \
    --policy-name AssumeDeploymentRoles \
    --policy-document file://assume-role-policy.json

aws iam attach-user-policy \
    --user-name github-actions-deployer \
    --policy-arn arn:aws:iam::CENTRAL-ACCOUNT-ID:policy/AssumeDeploymentRoles
```

### Method 3: OIDC Provider (Most Secure)

**Best for**: Enterprise environments, no long-lived credentials

#### Step 1: Create OIDC Provider
```bash
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### Step 2: Create Role for GitHub Actions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR-ORG/YOUR-REPO:*"
        }
      }
    }
  ]
}
```

## 🔑 Required Permissions

### Minimum IAM Policy for Terraform

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudwatch:*",
        "logs:*",
        "iam:ListInstanceProfiles",
        "iam:PassRole",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetBucketEncryption",
        "s3:PutBucketEncryption",
        "s3:PutBucketPublicAccessBlock"
      ],
      "Resource": "arn:aws:s3:::terraform-state-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-lock-*"
    }
  ]
}
```

### Production-Ready Policy (More Restrictive)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags",
        "ec2:DescribeTags"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": ["us-east-1", "us-west-2"]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🏢 Enterprise Setup

### AWS Organizations Setup

If using AWS Organizations with multiple accounts:

#### Step 1: Create OrganizationAccountAccessRole
This role should exist in each member account (usually created automatically):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::MASTER-ACCOUNT-ID:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

#### Step 2: Update Backend Configuration
Your backend configurations already reference this role:

```hcl
# shared/backend-dev.hcl
role_arn = "arn:aws:iam::DEV-ACCOUNT-ID:role/OrganizationAccountAccessRole"

# shared/backend-staging.hcl  
role_arn = "arn:aws:iam::STAGING-ACCOUNT-ID:role/OrganizationAccountAccessRole"

# shared/backend-prod.hcl
role_arn = "arn:aws:iam::PROD-ACCOUNT-ID:role/OrganizationAccountAccessRole"
```

### Service Control Policies (SCPs)

Restrict what can be done in each account:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "ec2:TerminateInstances"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalTag/Department": "DevOps"
        }
      }
    }
  ]
}
```

## 🔒 Security Best Practices

### 1. Credential Rotation
```bash
# Rotate access keys every 90 days
aws iam update-access-key --access-key-id AKIA... --status Inactive
aws iam create-access-key --user-name terraform-deployer
# Update GitHub secrets with new keys
aws iam delete-access-key --access-key-id OLD-KEY-ID --user-name terraform-deployer
```

### 2. Least Privilege
- Start with minimal permissions
- Add permissions as needed
- Use resource-specific policies
- Implement condition-based access

### 3. Monitoring and Auditing
```bash
# Enable CloudTrail for all accounts
aws cloudtrail create-trail \
    --name terraform-deployment-trail \
    --s3-bucket-name cloudtrail-logs-bucket \
    --include-global-service-events \
    --is-multi-region-trail
```

### 4. Environment Isolation
- Use separate AWS accounts for each environment
- Implement network isolation
- Use different IAM policies per environment
- Monitor cross-environment access

## 🚨 Troubleshooting

### Common Issues

**Access Denied Errors**
```bash
# Check current identity
aws sts get-caller-identity

# Check assumed role
aws sts assume-role \
    --role-arn arn:aws:iam::ACCOUNT-ID:role/TerraformDeploymentRole \
    --role-session-name test-session
```

**Cross-Account Role Issues**
```bash
# Verify trust relationship
aws iam get-role --role-name TerraformDeploymentRole

# Test role assumption
aws sts assume-role \
    --role-arn arn:aws:iam::TARGET-ACCOUNT:role/TerraformDeploymentRole \
    --role-session-name github-actions-test
```

**GitHub Actions Authentication**
- Check secret names match exactly
- Verify secrets are set at repository level
- Ensure secrets don't contain extra spaces or characters

### Validation Commands

```bash
# Test AWS credentials
aws sts get-caller-identity

# Test S3 access (for Terraform state)
aws s3 ls s3://terraform-state-bucket-name

# Test EC2 permissions
aws ec2 describe-instances --max-items 1

# Test cross-account access
aws sts assume-role \
    --role-arn arn:aws:iam::TARGET-ACCOUNT:role/OrganizationAccountAccessRole \
    --role-session-name validation-test
```

## 📋 Setup Checklist

### For Each Environment:

- [ ] AWS account identified and accessible
- [ ] IAM user/role created with appropriate permissions
- [ ] Cross-account roles configured (if using multiple accounts)
- [ ] S3 bucket for Terraform state (will be created automatically)
- [ ] DynamoDB table for state locking (will be created automatically)
- [ ] GitHub secrets configured
- [ ] Backend configuration updated with correct account IDs

### Security Checklist:

- [ ] Least privilege permissions applied
- [ ] Access keys rotated regularly (if using)
- [ ] CloudTrail enabled for auditing
- [ ] MFA enabled on AWS accounts
- [ ] Service Control Policies applied (if using Organizations)
- [ ] Network access restricted appropriately

### Testing Checklist:

- [ ] Credentials work locally: `aws sts get-caller-identity`
- [ ] GitHub Actions can authenticate
- [ ] Terraform can initialize backend
- [ ] Terraform can plan/apply in dev environment
- [ ] Cross-account access works (if applicable)

---

**Need help with credentials setup? Contact your DevOps team or AWS administrator.**