# App Team Infrastructure Wrapper - Setup Guide

This guide explains how to use the wrapper to create infrastructure for application teams.

## 🎯 Purpose

The App Team Infrastructure Wrapper automates the creation of complete infrastructure repositories for application teams. It provides:

- ✅ Complete Terraform infrastructure setup
- ✅ GitOps workflow with branch-based deployments
- ✅ GitHub environments with approval workflows
- ✅ Template configurations for easy customization
- ✅ Documentation and setup instructions

## 🔧 Prerequisites

Before running the wrapper, ensure you have:

### Required Tools
```bash
# GitHub CLI (for repository and environment management)
brew install gh  # macOS
# or visit: https://cli.github.com/

# Git (for version control)
git --version

# Terraform (for infrastructure deployment)
brew install terraform  # macOS
# or visit: https://www.terraform.io/downloads

# AWS CLI (optional, for validation)
brew install awscli  # macOS
```

### Authentication Setup
```bash
# Authenticate with GitHub
gh auth login

# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@company.com"

# Verify AWS access (optional)
aws sts get-caller-identity
```

## 🚀 Usage

### Step 1: Run the Wrapper Script

```bash
# Navigate to the wrapper directory
cd app-team-wrapper

# Run the wrapper script
./create-app-infrastructure.sh
```

### Step 2: Provide Required Information

The script will prompt you for:

#### Basic Information
- **App Name**: Your application name (e.g., "my-web-app")
- **GitHub Organization**: Your GitHub org (or leave empty for personal)
- **Repository Name**: Will default to "{app-name}-infrastructure"

#### AWS Account Information
- **Development Account ID**: AWS account for dev environment
- **Staging Account ID**: AWS account for staging environment  
- **Production Account ID**: AWS account for production environment

#### Team Information
- **Staging Approvers**: GitHub usernames for staging approvals (comma-separated)
- **Production Approvers**: GitHub usernames for production approvals (comma-separated)

### Step 3: Review and Confirm

The script will show a summary of your configuration. Review and confirm to proceed.

## 📁 What Gets Created

### Repository Structure
```
my-app-infrastructure/
├── README.md                          # App-specific documentation
├── SETUP.md                           # Detailed setup instructions for app team
├── main.tf                            # Infrastructure orchestration
├── variables.tf                       # Variable definitions
├── outputs.tf                         # Output definitions
├── backend.tf                         # Backend configuration
├── Makefile                           # Deployment shortcuts
├── deploy.sh                          # Local deployment script
├── .gitignore                         # Git ignore rules
├── .github/workflows/                 # GitOps CI/CD pipelines
│   ├── terraform-deploy.yml           # Main deployment workflow
│   └── gitops-promotion.yml           # Auto-promotion workflow
├── config/                            # Environment configurations
│   ├── aws-accounts.json              # AWS account mappings
│   └── gitops-environments.json       # GitOps settings
├── shared/                            # Backend configurations
│   ├── backend-dev.hcl                # Dev backend config
│   ├── backend-staging.hcl            # Staging backend config
│   └── backend-prod.hcl               # Production backend config
├── scripts/                           # Utility scripts
│   ├── create-gitops-branches.sh      # Branch creation
│   ├── setup-github-environments.sh   # Environment setup
│   └── setup-branch-protection.sh     # Branch protection
├── docs/                              # Documentation
│   ├── ARCHITECTURE.md                # Architecture details
│   ├── GITHUB_ACTIONS_SETUP.md        # CI/CD setup
│   └── TROUBLESHOOTING.md             # Common issues
├── tfvars/                            # ⚠️ EMPTY - App team configures
│   ├── README.md                      # Configuration instructions
│   ├── dev-terraform.tfvars.example   # Development example
│   ├── stg-terraform.tfvars.example   # Staging example
│   └── prod-terraform.tfvars.example  # Production example
└── userdata/                          # ⚠️ EMPTY - App team configures
    ├── README.md                      # Script instructions
    ├── userdata-linux.sh.example      # Linux example
    └── userdata-windows.ps1.example   # Windows example
```

### GitHub Configuration
- **Repository**: Created as private repository
- **Branches**: dev, staging, production branches created
- **Environments**: GitHub environments with approval rules
- **Workflows**: GitOps CI/CD pipelines configured

### AWS Integration
- **Account Mapping**: AWS accounts configured for each environment
- **Backend Configuration**: S3 backend setup for each environment
- **Cross-Account Roles**: Ready for OrganizationAccountAccessRole

## 🔧 Post-Creation Steps

After the wrapper completes, the app team needs to:

### 1. Configure Infrastructure (Required)
```bash
cd my-app-infrastructure

# Copy and customize tfvars files
cp tfvars/dev-terraform.tfvars.example tfvars/dev-terraform.tfvars
cp tfvars/stg-terraform.tfvars.example tfvars/stg-terraform.tfvars
cp tfvars/prod-terraform.tfvars.example tfvars/prod-terraform.tfvars

# Edit each file with specific requirements
nano tfvars/dev-terraform.tfvars
nano tfvars/stg-terraform.tfvars
nano tfvars/prod-terraform.tfvars
```

### 2. Add User Data Scripts (Required)
```bash
# Copy and customize user data scripts
cp userdata/userdata-linux.sh.example userdata/userdata-linux.sh
# cp userdata/userdata-windows.ps1.example userdata/userdata-windows.ps1  # If needed

# Customize for your application
nano userdata/userdata-linux.sh
```

### 3. Set Up AWS Credentials (Required)
Go to GitHub repository settings and add secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `PRIVATE_REPO_TOKEN` (for private module access)

### 4. Deploy Infrastructure
```bash
# Switch to dev branch and deploy
git checkout dev
git add tfvars/ userdata/
git commit -m "feat: add infrastructure configuration"
git push origin dev

# GitOps workflow will automatically deploy to dev
# Then create PRs for staging and production
```

## 🛡️ Security and Approvals

### Environment Protection
- **Dev**: No approvals required, auto-deploys
- **Staging**: Requires team member approval
- **Production**: Requires senior team approval + terraform apply approval

### Branch Protection
- **Main**: Protected, requires PR
- **Staging**: Protected, requires PR and approval
- **Production**: Protected, requires PR and approval

### Secrets Management
- AWS credentials stored as GitHub secrets
- No secrets in repository code
- Environment-specific configurations

## 🔍 Customization Options

### Adding Custom Modules
App teams can extend the infrastructure by adding custom modules to `main.tf`:

```hcl
module "custom_module" {
  source = "git::https://github.com/your-org/custom-module.git?ref=v1.0.0"
  for_each = var.custom_spec
  
  # Module parameters
  name = each.key
  # ... other parameters
}
```

### Environment-Specific Configurations
Different configurations per environment in tfvars files:

```hcl
# dev-terraform.tfvars - Small, cost-effective
ec2_spec = {
  "web-server" = {
    instance_type = "t3.micro"
    root_volume_size = 20
  }
}

# prod-terraform.tfvars - Production-grade, multiple instances
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

## 🚨 Troubleshooting

### Common Issues

**Script Permission Denied**
```bash
chmod +x create-app-infrastructure.sh
```

**GitHub CLI Not Authenticated**
```bash
gh auth login
gh auth status
```

**Repository Already Exists**
The script will ask if you want to continue with the existing repository.

**AWS Account ID Format**
Ensure AWS account IDs are 12-digit numbers without spaces or dashes.

### Getting Help

1. Check the generated `SETUP.md` in the created repository
2. Review documentation in the `docs/` folder
3. Contact the DevOps team
4. Create an issue in the base orchestrator repository

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [GitOps Principles](https://www.gitops.tech/)

## 🎯 Best Practices

### For DevOps Teams
- Keep the base orchestrator updated
- Provide clear module documentation
- Monitor wrapper usage and feedback
- Maintain security standards

### For App Teams
- Follow the GitOps workflow
- Test in development first
- Use environment-specific configurations
- Keep secrets secure
- Document custom configurations

---

**Ready to create infrastructure for your app team? Run the wrapper script and get started!** 🚀