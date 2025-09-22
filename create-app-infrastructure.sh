#!/bin/bash

# App Team Infrastructure Wrapper
# Creates complete infrastructure setup for application teams

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to validate prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed. Please install it first."
        echo "Visit: https://cli.github.com/"
        exit 1
    fi
    
    # Check if gh is authenticated
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated. Please run 'gh auth login' first."
        exit 1
    fi
    
    # Check if git is configured
    if ! git config user.name &> /dev/null || ! git config user.email &> /dev/null; then
        print_error "Git is not configured. Please set user.name and user.email."
        exit 1
    fi
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_warning "Terraform is not installed. The generated project will need Terraform to deploy."
    fi
    
    print_success "Prerequisites check completed"
}

# Function to collect user input
collect_input() {
    print_header "App Team Infrastructure Setup"
    echo "This script will create a complete infrastructure setup for your application team."
    echo ""
    
    # App name
    while true; do
        read -p "Enter your app name (e.g., 'my-web-app'): " APP_NAME
        if [[ "$APP_NAME" =~ ^[a-z0-9-]+$ ]]; then
            break
        else
            print_error "App name must contain only lowercase letters, numbers, and hyphens"
        fi
    done
    
    # GitHub organization
    read -p "Enter GitHub organization (leave empty for personal account): " GITHUB_ORG
    if [ -z "$GITHUB_ORG" ]; then
        GITHUB_ORG=$(gh api user --jq .login)
    fi
    
    # Repository name
    REPO_NAME="${APP_NAME}-infrastructure"
    read -p "Repository name [$REPO_NAME]: " input
    REPO_NAME=${input:-$REPO_NAME}
    
    # AWS Account IDs
    echo ""
    print_status "Enter AWS Account IDs for each environment:"
    read -p "Development Account ID: " DEV_ACCOUNT_ID
    read -p "Staging Account ID: " STAGING_ACCOUNT_ID
    read -p "Production Account ID: " PROD_ACCOUNT_ID
    
    # Team members for approvals
    echo ""
    print_status "Enter team members for approvals (GitHub usernames):"
    read -p "Staging approvers (comma-separated): " STAGING_APPROVERS
    read -p "Production approvers (comma-separated): " PROD_APPROVERS
    
    # Confirmation
    echo ""
    print_header "Configuration Summary"
    echo "App Name: $APP_NAME"
    echo "GitHub Org: $GITHUB_ORG"
    echo "Repository: $REPO_NAME"
    echo "Dev Account: $DEV_ACCOUNT_ID"
    echo "Staging Account: $STAGING_ACCOUNT_ID"
    echo "Production Account: $PROD_ACCOUNT_ID"
    echo "Staging Approvers: $STAGING_APPROVERS"
    echo "Production Approvers: $PROD_APPROVERS"
    echo ""
    
    read -p "Continue with this configuration? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "Setup cancelled"
        exit 0
    fi
}

# Function to create GitHub repository
create_github_repo() {
    print_status "Creating GitHub repository: $GITHUB_ORG/$REPO_NAME"
    
    # Check if repository already exists
    if gh repo view "$GITHUB_ORG/$REPO_NAME" &> /dev/null; then
        print_error "Repository $GITHUB_ORG/$REPO_NAME already exists"
        read -p "Do you want to continue with the existing repository? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            exit 1
        fi
        REPO_EXISTS=true
    else
        # Create repository
        gh repo create "$GITHUB_ORG/$REPO_NAME" \
            --description "Infrastructure as Code for $APP_NAME" \
            --private \
            --clone
        
        cd "$REPO_NAME"
        REPO_EXISTS=false
        print_success "Repository created and cloned"
    fi
}

# Function to copy base files
copy_base_files() {
    print_status "Setting up project structure..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    BASE_DIR="$(dirname "$SCRIPT_DIR")"
    
    # Copy main Terraform files
    cp "$BASE_DIR/main.tf" .
    cp "$BASE_DIR/variables.tf" .
    cp "$BASE_DIR/outputs.tf" .
    cp "$BASE_DIR/backend.tf" .
    
    # Copy configuration files
    mkdir -p config
    cp "$BASE_DIR/config/"*.json config/
    
    # Copy shared backend configurations
    mkdir -p shared
    cp "$BASE_DIR/shared/"*.hcl shared/
    
    # Copy scripts
    mkdir -p scripts
    cp "$BASE_DIR/scripts/"*.sh scripts/
    chmod +x scripts/*.sh
    
    # Copy GitHub workflows
    mkdir -p .github/workflows
    cp -r "$BASE_DIR/.github/workflows/"* .github/workflows/
    
    # Copy documentation
    mkdir -p docs
    cp "$BASE_DIR/docs/"*.md docs/
    
    # Copy other files
    cp "$BASE_DIR/Makefile" .
    cp "$BASE_DIR/deploy.sh" .
    chmod +x deploy.sh
    cp "$BASE_DIR/.gitignore" .
    
    print_success "Base files copied"
}

# Function to create empty tfvars and userdata directories with examples
create_empty_directories() {
    print_status "Creating tfvars and userdata directories with examples..."
    
    # Create tfvars directory with examples
    mkdir -p tfvars
    
    # Create tfvars README
    cat > tfvars/README.md << 'EOF'
# Terraform Variables Configuration

This directory contains environment-specific configuration files for your infrastructure.

## 📋 Required Files

You need to create the following files with your specific configurations:

- `dev-terraform.tfvars` - Development environment configuration
- `stg-terraform.tfvars` - Staging environment configuration  
- `prod-terraform.tfvars` - Production environment configuration

## 🚀 Getting Started

1. Copy the example files and remove the `.example` extension
2. Update the values according to your requirements
3. Commit the files to your repository
4. Push to dev branch to trigger deployment

## 🔒 Security Note

These files may contain sensitive information. Ensure your repository is private and follow your organization's security guidelines.

## 📖 Configuration Guide

See the main README.md and SETUP.md files for detailed configuration instructions.
EOF

    # Create example tfvars files
    cat > tfvars/dev-terraform.tfvars.example << EOF
# Development Environment Configuration
project_name = "$APP_NAME"
environment = "dev"
account_id = "$DEV_ACCOUNT_ID"
aws_region = "us-east-1"

# GitLab configuration for private modules
gitlab_org = "your-gitlab-org"

# Base modules configuration
base_modules = {
  ec2 = {
    repository = "ec2-base-module"
    version    = "main"
  }
  alb = {
    repository = "alb-base-module"
    version    = "main"
  }
}

# ALB Configuration
alb_spec = {
  web-alb = {
    vpc_name = "dev-vpc"
    http_enabled = true
    https_enabled = false
    name = "web-alb"
  }
}

# EC2 Configuration
ec2_spec = {
  "web-server" = {
    enable_alb_integration = true
    alb_name = "web-alb"
    instance_type = "t3.micro"
    vpc_name = "dev-vpc"
    subnet_name = "dev-public-subnet-1"
    ami_name = "amzn2-ami-hvm-*-x86_64-gp2"
    os_type = "linux"
    root_volume_size = 20
    key_name = "your-key-pair"
  }
}
EOF

    cat > tfvars/stg-terraform.tfvars.example << EOF
# Staging Environment Configuration
project_name = "$APP_NAME"
environment = "staging"
account_id = "$STAGING_ACCOUNT_ID"
aws_region = "us-east-1"

# GitLab configuration for private modules
gitlab_org = "your-gitlab-org"

# Base modules configuration
base_modules = {
  ec2 = {
    repository = "ec2-base-module"
    version    = "main"
  }
  alb = {
    repository = "alb-base-module"
    version    = "main"
  }
}

# ALB Configuration
alb_spec = {
  web-alb = {
    vpc_name = "staging-vpc"
    http_enabled = true
    https_enabled = false
    name = "web-alb"
  }
}

# EC2 Configuration
ec2_spec = {
  "web-server" = {
    enable_alb_integration = true
    alb_name = "web-alb"
    instance_type = "t3.small"
    vpc_name = "staging-vpc"
    subnet_name = "staging-public-subnet-1"
    ami_name = "amzn2-ami-hvm-*-x86_64-gp2"
    os_type = "linux"
    root_volume_size = 30
    key_name = "your-key-pair"
  }
}
EOF

    cat > tfvars/prod-terraform.tfvars.example << EOF
# Production Environment Configuration
project_name = "$APP_NAME"
environment = "prod"
account_id = "$PROD_ACCOUNT_ID"
aws_region = "us-east-1"

# GitLab configuration for private modules
gitlab_org = "your-gitlab-org"

# Base modules configuration
base_modules = {
  ec2 = {
    repository = "ec2-base-module"
    version    = "main"
  }
  alb = {
    repository = "alb-base-module"
    version    = "main"
  }
}

# ALB Configuration
alb_spec = {
  web-alb = {
    vpc_name = "prod-vpc"
    http_enabled = false
    https_enabled = true
    name = "web-alb"
    # certificate_arn = "arn:aws:acm:us-east-1:account:certificate/cert-id"
  }
}

# EC2 Configuration - Multiple instances for production
ec2_spec = {
  "web-server-1" = {
    enable_alb_integration = true
    alb_name = "web-alb"
    instance_type = "t3.medium"
    vpc_name = "prod-vpc"
    subnet_name = "prod-public-subnet-1"
    ami_name = "amzn2-ami-hvm-*-x86_64-gp2"
    os_type = "linux"
    root_volume_size = 50
    key_name = "your-key-pair"
  },
  "web-server-2" = {
    enable_alb_integration = true
    alb_name = "web-alb"
    instance_type = "t3.medium"
    vpc_name = "prod-vpc"
    subnet_name = "prod-public-subnet-2"
    ami_name = "amzn2-ami-hvm-*-x86_64-gp2"
    os_type = "linux"
    root_volume_size = 50
    key_name = "your-key-pair"
  }
}
EOF

    # Create userdata directory with examples
    mkdir -p userdata
    
    # Create userdata README
    cat > userdata/README.md << 'EOF'
# User Data Scripts

This directory contains server initialization scripts that run when your EC2 instances start.

## 📋 Required Files

You need to create the following files based on your operating system requirements:

- `userdata-linux.sh` - Linux server initialization script
- `userdata-windows.ps1` - Windows server initialization script (if needed)

## 🚀 Getting Started

1. Copy the example files and remove the `.example` extension
2. Customize the scripts for your application requirements
3. Test the scripts in development environment first
4. Commit the files to your repository

## 🔒 Security Note

These scripts run with root/administrator privileges. Follow security best practices:
- Don't hardcode secrets or passwords
- Use AWS Systems Manager Parameter Store or Secrets Manager for sensitive data
- Validate and sanitize any external inputs

## 📖 Script Guide

See the main README.md and SETUP.md files for detailed scripting instructions.
EOF

    # Create example userdata files
    cat > userdata/userdata-linux.sh.example << 'EOF'
#!/bin/bash

# Linux Server Initialization Script
# This script runs when your EC2 instance starts

# Variables passed from Terraform
ENVIRONMENT="${environment}"
HOSTNAME="${hostname}"
OS_TYPE="${os_type}"

# Set hostname
hostnamectl set-hostname "$HOSTNAME"

# Update system
yum update -y

# Install basic packages
yum install -y \
    curl \
    wget \
    unzip \
    git \
    htop \
    awscli

# Install Docker (example)
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install your application
# Example: Download and run your application
# wget https://your-app-releases.com/latest.tar.gz
# tar -xzf latest.tar.gz
# ./install.sh

# Configure application for environment
case "$ENVIRONMENT" in
    "dev")
        echo "Configuring for development environment"
        # Development-specific configuration
        ;;
    "staging")
        echo "Configuring for staging environment"
        # Staging-specific configuration
        ;;
    "prod")
        echo "Configuring for production environment"
        # Production-specific configuration
        ;;
esac

# Start your application service
# systemctl start your-app
# systemctl enable your-app

# Log completion
echo "User data script completed for $HOSTNAME in $ENVIRONMENT environment" >> /var/log/userdata.log
EOF

    cat > userdata/userdata-windows.ps1.example << 'EOF'
# Windows Server Initialization Script
# This script runs when your EC2 instance starts

# Variables passed from Terraform
$Environment = "${environment}"
$Hostname = "${hostname}"
$OSType = "${os_type}"

# Set hostname
Rename-Computer -NewName $Hostname -Force

# Install Chocolatey package manager
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install basic packages
choco install -y git
choco install -y awscli
choco install -y 7zip

# Install IIS (example web server)
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole, IIS-WebServer, IIS-CommonHttpFeatures, IIS-HttpErrors, IIS-HttpLogging, IIS-RequestFiltering, IIS-StaticContent

# Install your application
# Example: Download and install your application
# Invoke-WebRequest -Uri "https://your-app-releases.com/latest.msi" -OutFile "C:\temp\app.msi"
# Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\app.msi /quiet'

# Configure application for environment
switch ($Environment) {
    "dev" {
        Write-Host "Configuring for development environment"
        # Development-specific configuration
    }
    "staging" {
        Write-Host "Configuring for staging environment"
        # Staging-specific configuration
    }
    "prod" {
        Write-Host "Configuring for production environment"
        # Production-specific configuration
    }
}

# Start your application service
# Start-Service -Name "YourAppService"
# Set-Service -Name "YourAppService" -StartupType Automatic

# Log completion
Add-Content -Path "C:\temp\userdata.log" -Value "User data script completed for $Hostname in $Environment environment"
EOF

    print_success "Empty directories created with examples"
}

# Function to update configuration files
update_configurations() {
    print_status "Updating configuration files..."
    
    # Update AWS accounts configuration
    cat > config/aws-accounts.json << EOF
{
  "dev": {
    "account_id": "$DEV_ACCOUNT_ID",
    "role_name": "OrganizationAccountAccessRole"
  },
  "staging": {
    "account_id": "$STAGING_ACCOUNT_ID",
    "role_name": "OrganizationAccountAccessRole"
  },
  "production": {
    "account_id": "$PROD_ACCOUNT_ID",
    "role_name": "OrganizationAccountAccessRole"
  }
}
EOF

    # Update backend configurations with account IDs
    sed -i.bak "s/REPLACE_WITH_DEV_ACCOUNT_ID/$DEV_ACCOUNT_ID/g" shared/backend-dev.hcl
    sed -i.bak "s/REPLACE_WITH_STAGING_ACCOUNT_ID/$STAGING_ACCOUNT_ID/g" shared/backend-staging.hcl
    sed -i.bak "s/REPLACE_WITH_PRODUCTION_ACCOUNT_ID/$PROD_ACCOUNT_ID/g" shared/backend-prod.hcl
    
    # Clean up backup files
    rm -f shared/*.bak
    
    print_success "Configuration files updated"
}

# Function to create app-specific README
create_app_readme() {
    print_status "Creating app-specific README..."
    
    cat > README.md << EOF
# $APP_NAME Infrastructure

Infrastructure as Code for $APP_NAME using Terraform and GitOps workflow.

## 🏗️ Architecture

This repository uses the Terraform Infrastructure Orchestrator pattern to manage infrastructure across multiple environments (dev, staging, production) with GitOps workflow.

### Environments
- **Development**: Account ID $DEV_ACCOUNT_ID
- **Staging**: Account ID $STAGING_ACCOUNT_ID  
- **Production**: Account ID $PROD_ACCOUNT_ID

## 🚀 Quick Start

### 1. Configure Your Infrastructure

Create your environment-specific configuration files:

\`\`\`bash
# Copy example files and customize
cp tfvars/dev-terraform.tfvars.example tfvars/dev-terraform.tfvars
cp tfvars/stg-terraform.tfvars.example tfvars/stg-terraform.tfvars
cp tfvars/prod-terraform.tfvars.example tfvars/prod-terraform.tfvars

# Edit each file with your specific requirements
nano tfvars/dev-terraform.tfvars
nano tfvars/stg-terraform.tfvars
nano tfvars/prod-terraform.tfvars
\`\`\`

### 2. Add User Data Scripts

Create your server initialization scripts:

\`\`\`bash
# Copy example files and customize
cp userdata/userdata-linux.sh.example userdata/userdata-linux.sh
# cp userdata/userdata-windows.ps1.example userdata/userdata-windows.ps1  # If needed

# Edit scripts for your application
nano userdata/userdata-linux.sh
\`\`\`

### 3. Set Up AWS Credentials

Configure GitHub repository secrets (see SETUP.md for details):
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- PRIVATE_REPO_TOKEN (for private modules)

### 4. Deploy with GitOps

\`\`\`bash
# Add all your configurations
git add .
git commit -m "feat: initial infrastructure configuration"
git push origin dev

# GitOps workflow will automatically:
# 1. Deploy to dev environment
# 2. Create PR to staging (requires approval)
# 3. Create PR to production (requires approval)
\`\`\`

## 🌍 Environments and Approvals

- **Dev**: Auto-deploys on push to dev branch
- **Staging**: Requires approval from: $STAGING_APPROVERS
- **Production**: Requires approval from: $PROD_APPROVERS

## 📁 Project Structure

\`\`\`
$REPO_NAME/
├── README.md                          # This file
├── SETUP.md                           # Detailed setup instructions
├── main.tf                            # Infrastructure orchestration
├── variables.tf                       # Variable definitions
├── outputs.tf                         # Output definitions
├── backend.tf                         # Backend configuration
├── tfvars/                            # Environment configurations
│   ├── dev-terraform.tfvars           # Development config
│   ├── stg-terraform.tfvars           # Staging config
│   └── prod-terraform.tfvars          # Production config
├── userdata/                          # Server initialization scripts
│   ├── userdata-linux.sh              # Linux initialization
│   └── userdata-windows.ps1           # Windows initialization
├── .github/workflows/                 # GitOps CI/CD pipelines
├── config/                            # Environment configurations
├── shared/                            # Backend configurations
├── scripts/                           # Utility scripts
└── docs/                              # Documentation
\`\`\`

## 🛠️ Local Development

\`\`\`bash
# Plan changes for development
./deploy.sh dev plan

# Apply changes to development
./deploy.sh dev apply

# Plan changes for staging
./deploy.sh staging plan
\`\`\`

## 📖 Documentation

- [SETUP.md](SETUP.md) - Detailed setup instructions
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Architecture details
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues

## 🆘 Support

For questions or issues:
1. Check the SETUP.md file
2. Review documentation in docs/ folder
3. Contact the DevOps team
4. Create an issue in this repository

---

Generated by App Team Infrastructure Wrapper
EOF

    print_success "App-specific README created"
}

# Function to create setup instructions
create_setup_instructions() {
    print_status "Creating setup instructions..."
    
    cat > SETUP.md << 'EOF'
# Setup Instructions

This guide will help you complete the setup of your infrastructure repository.

## 🎯 Overview

Your infrastructure repository has been created with the following structure:
- ✅ Base Terraform files copied
- ✅ GitOps workflow configured
- ✅ GitHub environments set up
- ⚠️ **Action Required**: Configure tfvars and userdata
- ⚠️ **Action Required**: Set up AWS credentials

## 📋 Required Actions

### 1. Configure Infrastructure (tfvars)

Create your environment-specific configuration files:

```bash
# Copy example files
cp tfvars/dev-terraform.tfvars.example tfvars/dev-terraform.tfvars
cp tfvars/stg-terraform.tfvars.example tfvars/stg-terraform.tfvars
cp tfvars/prod-terraform.tfvars.example tfvars/prod-terraform.tfvars
```

**Key configurations to update:**

#### In all tfvars files:
- `gitlab_org` - Your GitLab organization name
- `base_modules` - Module repositories and versions
- VPC names (must match your existing VPCs)
- Subnet names (must match your existing subnets)
- Key pair names (must exist in your AWS accounts)

#### Environment-specific values:
- `instance_type` - Different sizes per environment
- `root_volume_size` - Storage requirements
- `ami_name` - AMI selection criteria
- SSL certificates for production ALB

### 2. Create User Data Scripts

Create server initialization scripts:

```bash
# Copy example files
cp userdata/userdata-linux.sh.example userdata/userdata-linux.sh
# cp userdata/userdata-windows.ps1.example userdata/userdata-windows.ps1  # If needed
```

**Customize the scripts for your application:**
- Install required software packages
- Configure application settings
- Set up monitoring and logging
- Configure environment-specific settings

### 3. Set Up AWS Credentials

Configure the following GitHub repository secrets:

#### Go to: Repository Settings → Secrets and variables → Actions

**Required Secrets:**
```
AWS_ACCESS_KEY_ID          - AWS access key for deployments
AWS_SECRET_ACCESS_KEY      - AWS secret key for deployments
PRIVATE_REPO_TOKEN         - GitHub token for private module access
```

**Optional Secrets:**
```
GITLAB_TOKEN              - GitLab token if using GitLab modules
SLACK_WEBHOOK_URL         - For deployment notifications
```

#### AWS Credentials Setup

**Option 1: IAM User (Simple)**
1. Create IAM user with programmatic access
2. Attach policies: `PowerUserAccess` or custom deployment policy
3. Add access key and secret to GitHub secrets

**Option 2: Cross-Account Roles (Recommended)**
1. Create deployment role in each AWS account
2. Configure trust relationship with GitHub Actions
3. Use OIDC provider for secure authentication

### 4. Configure GitHub Environments

The wrapper has created GitHub environments, but you need to add reviewers:

#### Go to: Repository Settings → Environments

**Staging Environment:**
- Add required reviewers from your team
- Set deployment branch rule to `staging`

**Production Environment:**
- Add senior team members as reviewers
- Set deployment branch rule to `production`
- Consider adding wait timer for production deployments

### 5. Test Your Setup

**Step 1: Validate Configuration**
```bash
# Check Terraform syntax
terraform fmt -check
terraform validate
```

**Step 2: Test Development Deployment**
```bash
# Switch to dev branch
git checkout dev

# Add your configurations
git add tfvars/ userdata/
git commit -m "feat: add initial infrastructure configuration"
git push origin dev

# Monitor GitHub Actions for deployment
```

**Step 3: Verify Infrastructure**
- Check AWS console for created resources
- Verify EC2 instances are running
- Test ALB endpoints
- Check user data script execution logs

## 🔧 Advanced Configuration

### Custom Modules

To add custom modules to your infrastructure:

1. **Add module to main.tf:**
```hcl
module "custom_module" {
  source = "git::https://github.com/your-org/custom-module.git?ref=v1.0.0"
  for_each = var.custom_spec
  
  # Module parameters
  name = each.key
  # ... other parameters
}
```

2. **Add variable to variables.tf:**
```hcl
variable "custom_spec" {
  description = "Custom module specifications"
  type        = any
  default     = {}
}
```

3. **Configure in tfvars files:**
```hcl
custom_spec = {
  "resource-1" = {
    # Configuration parameters
  }
}
```

### Environment-Specific Configurations

**Different VPCs per environment:**
```hcl
# dev-terraform.tfvars
ec2_spec = {
  "web-server" = {
    vpc_name = "dev-vpc"
    subnet_name = "dev-public-subnet-1"
  }
}

# prod-terraform.tfvars
ec2_spec = {
  "web-server" = {
    vpc_name = "prod-vpc"
    subnet_name = "prod-public-subnet-1"
  }
}
```

**Different instance sizes:**
```hcl
# dev-terraform.tfvars - Cost optimized
ec2_spec = {
  "web-server" = {
    instance_type = "t3.micro"
    root_volume_size = 20
  }
}

# prod-terraform.tfvars - Performance optimized
ec2_spec = {
  "web-server-1" = {
    instance_type = "t3.large"
    root_volume_size = 100
  },
  "web-server-2" = {
    instance_type = "t3.large"
    root_volume_size = 100
  }
}
```

## 🚀 Deployment Workflow

### GitOps Workflow
1. **Development**: Push to `dev` branch → Auto-deploy to dev environment
2. **Staging**: Merge dev to `staging` → Requires team approval → Deploy to staging
3. **Production**: Merge staging to `production` → Requires senior approval → Deploy to production

### Manual Deployment
```bash
# Local development testing
./deploy.sh dev plan
./deploy.sh dev apply

# Staging deployment
./deploy.sh staging plan
./deploy.sh staging apply

# Production deployment (with confirmation)
./deploy.sh production plan
./deploy.sh production apply
```

## 🛡️ Security Best Practices

### Secrets Management
- Never commit secrets to repository
- Use AWS Systems Manager Parameter Store
- Use AWS Secrets Manager for database passwords
- Rotate credentials regularly

### Access Control
- Use least privilege IAM policies
- Enable MFA for AWS accounts
- Restrict GitHub repository access
- Use branch protection rules

### Monitoring
- Enable CloudTrail logging
- Set up CloudWatch alarms
- Monitor deployment pipelines
- Review access logs regularly

## 🔍 Troubleshooting

### Common Issues

**Terraform Backend Errors:**
```bash
# Initialize backend
terraform init -backend-config=shared/backend-dev.hcl

# If backend doesn't exist, run setup
./scripts/setup-backend-per-account.sh
```

**Module Download Failures:**
- Check PRIVATE_REPO_TOKEN has access to module repositories
- Verify module repository URLs in main.tf
- Ensure module versions/tags exist

**AWS Permission Errors:**
- Verify AWS credentials in GitHub secrets
- Check IAM policies have required permissions
- Ensure cross-account roles are configured correctly

**VPC/Subnet Not Found:**
- Verify VPC and subnet names in tfvars files
- Check that resources exist in target AWS accounts
- Ensure Name tags match exactly

### Getting Help

1. **Check Logs:**
   - GitHub Actions workflow logs
   - CloudWatch logs for EC2 instances
   - Terraform plan/apply output

2. **Validate Configuration:**
   ```bash
   terraform fmt -check
   terraform validate
   terraform plan -var-file=tfvars/dev-terraform.tfvars
   ```

3. **Contact Support:**
   - Create issue in this repository
   - Contact DevOps team
   - Check documentation in docs/ folder

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitOps Best Practices](https://www.gitops.tech/)

---

**Next Steps:**
1. Complete the required actions above
2. Test your development environment
3. Set up monitoring and alerting
4. Document your application-specific configurations
5. Train your team on the GitOps workflow
EOF

    print_success "Setup instructions created"
}

# Function to set up GitOps branches and environments
setup_gitops() {
    print_status "Setting up GitOps branches and environments..."
    
    # Create GitOps branches
    ./scripts/create-gitops-branches.sh
    
    # Set up GitHub environments with approvers
    print_status "Setting up GitHub environments with approvers..."
    
    # Convert comma-separated approvers to JSON array
    if [ -n "$STAGING_APPROVERS" ]; then
        STAGING_REVIEWERS=$(echo "$STAGING_APPROVERS" | sed 's/,/","/g' | sed 's/^/["/' | sed 's/$/"]/')
    else
        STAGING_REVIEWERS='[]'
    fi
    
    if [ -n "$PROD_APPROVERS" ]; then
        PROD_REVIEWERS=$(echo "$PROD_APPROVERS" | sed 's/,/","/g' | sed 's/^/["/' | sed 's/$/"]/')
    else
        PROD_REVIEWERS='[]'
    fi
    
    # Create environments with reviewers
    gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        "/repos/$GITHUB_ORG/$REPO_NAME/environments/staging" \
        --input - << EOF
{
  "wait_timer": 0,
  "prevent_self_review": true,
  "reviewers": $(echo "$STAGING_REVIEWERS" | jq '[.[] | {"type": "User", "id": null}]' --argjson reviewers "$STAGING_REVIEWERS"),
  "deployment_branch_policy": {
    "protected_branches": false,
    "custom_branch_policies": true
  }
}
EOF

    gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        "/repos/$GITHUB_ORG/$REPO_NAME/environments/production" \
        --input - << EOF
{
  "wait_timer": 300,
  "prevent_self_review": true,
  "reviewers": $(echo "$PROD_REVIEWERS" | jq '[.[] | {"type": "User", "id": null}]' --argjson reviewers "$PROD_REVIEWERS"),
  "deployment_branch_policy": {
    "protected_branches": false,
    "custom_branch_policies": true
  }
}
EOF

    print_success "GitOps setup completed"
}

# Function to commit and push initial setup
commit_initial_setup() {
    print_status "Committing initial setup..."
    
    # Add all files
    git add .
    
    # Create initial commit
    git commit -m "feat: initial infrastructure setup for $APP_NAME

- Add Terraform infrastructure orchestration
- Configure GitOps workflow for dev/staging/production
- Set up GitHub environments with approvals
- Add example configurations for tfvars and userdata
- Configure AWS accounts: dev($DEV_ACCOUNT_ID), staging($STAGING_ACCOUNT_ID), prod($PROD_ACCOUNT_ID)

Next steps:
1. Configure tfvars files with your specific requirements
2. Add userdata scripts for server initialization
3. Set up AWS credentials in GitHub secrets
4. Push to dev branch to start deployment"

    # Push to main branch
    git push origin main
    
    print_success "Initial setup committed and pushed"
}

# Function to display final instructions
show_final_instructions() {
    print_header "Setup Complete!"
    
    echo ""
    print_success "Your infrastructure repository has been created successfully!"
    echo ""
    echo "Repository: https://github.com/$GITHUB_ORG/$REPO_NAME"
    echo ""
    
    print_header "Next Steps"
    echo ""
    echo "1. 📝 Configure your infrastructure:"
    echo "   cd $REPO_NAME"
    echo "   cp tfvars/dev-terraform.tfvars.example tfvars/dev-terraform.tfvars"
    echo "   cp tfvars/stg-terraform.tfvars.example tfvars/stg-terraform.tfvars"
    echo "   cp tfvars/prod-terraform.tfvars.example tfvars/prod-terraform.tfvars"
    echo "   # Edit each file with your requirements"
    echo ""
    echo "2. 🖥️ Add user data scripts:"
    echo "   cp userdata/userdata-linux.sh.example userdata/userdata-linux.sh"
    echo "   # Customize for your application"
    echo ""
    echo "3. 🔐 Set up AWS credentials in GitHub:"
    echo "   - Go to: https://github.com/$GITHUB_ORG/$REPO_NAME/settings/secrets/actions"
    echo "   - Add: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, PRIVATE_REPO_TOKEN"
    echo ""
    echo "4. 🚀 Deploy your infrastructure:"
    echo "   git checkout dev"
    echo "   git add tfvars/ userdata/"
    echo "   git commit -m 'feat: add infrastructure configuration'"
    echo "   git push origin dev"
    echo ""
    
    print_header "Environment Configuration"
    echo ""
    echo "✅ Dev Environment: Auto-deploy (Account: $DEV_ACCOUNT_ID)"
    echo "⚠️  Staging Environment: Requires approval from: $STAGING_APPROVERS"
    echo "⚠️  Production Environment: Requires approval from: $PROD_APPROVERS"
    echo ""
    
    print_header "Documentation"
    echo ""
    echo "📖 Detailed setup instructions: $REPO_NAME/SETUP.md"
    echo "📖 Architecture documentation: $REPO_NAME/docs/"
    echo "📖 Troubleshooting guide: $REPO_NAME/docs/TROUBLESHOOTING.md"
    echo ""
    
    print_success "Happy deploying! 🎉"
}

# Main execution
main() {
    print_header "App Team Infrastructure Wrapper"
    
    # Check prerequisites
    check_prerequisites
    
    # Collect user input
    collect_input
    
    # Create GitHub repository
    create_github_repo
    
    # If repository already exists, navigate to it
    if [ "$REPO_EXISTS" = true ]; then
        if [ ! -d "$REPO_NAME" ]; then
            gh repo clone "$GITHUB_ORG/$REPO_NAME"
        fi
        cd "$REPO_NAME"
    fi
    
    # Copy base files and create structure
    copy_base_files
    create_empty_directories
    update_configurations
    create_app_readme
    create_setup_instructions
    
    # Set up GitOps workflow
    setup_gitops
    
    # Commit initial setup
    commit_initial_setup
    
    # Show final instructions
    show_final_instructions
}

# Run main function
main "$@"