# AWS Credentials Setup Guide

Complete guide for setting up AWS credentials for infrastructure deployment.

## 🎯 Overview

Your infrastructure needs AWS credentials to deploy resources across different environments (dev, staging, production).

## 🔐 Authentication Methods

### Method 1: IAM User with Access Keys (Simple)

**Best for**: Small teams, development environments, getting started quickly

#### Step 1: Create IAM User
```bash
# Create IAM user
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
        "Federated": "arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:YOUR-ORG/YOUR-REPO:*"
        }
      }
    }
  ]
}
```

#### Step 2: Attach Permissions Policy
```bash
# Attach PowerUser policy to the role
aws iam attach-role-policy \
    --role-name GitHubActionsDeploymentRole \
    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

#### Step 3: Configure GitHub Workflow
Update your workflow to use OIDC:

```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::ACCOUNT-ID:role/GitHubActionsDeploymentRole
    aws-region: us-east-1
```

### Method 3: AWS SSO/Identity Center (Enterprise)

**Best for**: Large organizations with centralized identity management

#### Step 1: Configure Permission Sets
1. Create permission sets in AWS SSO for each environment
2. Assign appropriate policies (PowerUser, custom policies)
3. Assign users/groups to permission sets

#### Step 2: Use AWS CLI with SSO
```bash
# Configure SSO profile
aws configure sso

# Use in workflows with temporary credentials
aws sts get-caller-identity --profile your-sso-profile
```

## 🔒 Security Best Practices

### Principle of Least Privilege
- Use custom IAM policies instead of PowerUser when possible
- Separate roles for different environments
- Regular credential rotation

### Custom Policy Example
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elbv2:*",
        "iam:PassRole",
        "s3:*",
        "cloudformation:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### Credential Rotation
```bash
# Rotate access keys regularly
aws iam create-access-key --user-name terraform-deployer
# Update GitHub secrets
aws iam delete-access-key --user-name terraform-deployer --access-key-id OLD-KEY
```

## 🧪 Testing Credentials

### Verify Access
```bash
# Test AWS access
aws sts get-caller-identity

# Test specific permissions
aws ec2 describe-regions
aws s3 ls
```

### GitHub Actions Testing
```yaml
- name: Test AWS Access
  run: |
    aws sts get-caller-identity
    aws ec2 describe-regions --region us-east-1
```

## 🆘 Troubleshooting

### Common Issues

**Access Denied Errors**
- Check IAM policies attached to user/role
- Verify account ID in trust relationships
- Ensure credentials are correctly set in GitHub secrets

**OIDC Provider Issues**
- Verify OIDC provider exists in AWS account
- Check trust relationship conditions
- Ensure repository path matches exactly

**Credential Expiration**
- Rotate access keys regularly
- Monitor AWS CloudTrail for authentication failures
- Set up alerts for credential usage

### Debug Commands
```bash
# Check current identity
aws sts get-caller-identity

# List attached policies
aws iam list-attached-user-policies --user-name terraform-deployer

# Test assume role
aws sts assume-role --role-arn arn:aws:iam::ACCOUNT:role/ROLE --role-session-name test
```

---

**Security Note**: Never commit AWS credentials to version control. Always use GitHub secrets or environment variables.