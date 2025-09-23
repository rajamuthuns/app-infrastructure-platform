# Platform Engineering Infrastructure Automation

Streamlined infrastructure repository creation for application teams with automated GitOps workflows.

## 🎯 What This Platform Provides

- ✅ **Automated Repository Creation** - Creates complete infrastructure repos for app teams
- ✅ **GitOps Workflow Setup** - Automated dev → staging → production promotion
- ✅ **GitHub Environments** - Proper approval workflows and branch protection
- ✅ **Complete Project Skeleton** - All necessary Terraform files and configurations
- ✅ **Documentation Generation** - Comprehensive setup guides and examples
- ✅ **Notification System** - Automated app team notifications

## 🏗️ Architecture Overview

```
Platform Repo (this) → Creates → App Team Repos
├── Workflows & Scripts      ├── Complete Infrastructure
├── Base Templates          ├── GitOps Workflows  
└── Documentation          └── Ready-to-Use Setup
```

## 🚀 Quick Start

### Prerequisites
```bash
# Required tools
brew install gh terraform git awscli  # macOS
gh auth login  # Authenticate with GitHub
```

### Usage Options

#### Option 1: GitHub UI (Recommended)
1. Go to **Actions** → "Create App Team Infrastructure Repository"
2. Click **"Run workflow"**
3. Fill in app details and click **"Run workflow"**

#### Option 2: API Trigger
```bash
./scripts/trigger-via-api.sh \
  -a my-web-app \
  -o target-org \
  -c team@company.com \
  -d 123456789012 \
  -s 123456789013 \
  -p 123456789014 \
  --staging-approvers user1,user2 \
  --prod-approvers user3,user4
```

#### Option 3: Manual Script
```bash
./create-app-infrastructure.sh  # Interactive prompts
```

## ⚙️ Configuration

### Required GitHub Secrets
- `PLATFORM_GITHUB_TOKEN` - GitHub token with repo creation permissions

### Optional Secrets (for notifications)
- `SMTP_USERNAME` - Email for notifications
- `SMTP_PASSWORD` - Email password/app password

### Repository Variables
- `BASE_INFRASTRUCTURE_REPO` - Your base infrastructure repository (default: current repo)

## 🔐 AWS Credentials Setup

### Method 1: IAM User (Simple)
```bash
# Create IAM user with PowerUser policy
aws iam create-user --user-name terraform-deployer
aws iam attach-user-policy --user-name terraform-deployer \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Create access keys and add to GitHub secrets:
# AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
```

### Method 2: Cross-Account Roles (Enterprise)
Create deployment roles in each AWS account with trust relationships to GitHub Actions OIDC provider.

## 📖 What App Teams Get

### Repository Structure
```
my-app-infrastructure/
├── main/                    # README + workflows only
├── dev/                     # All config files + examples
├── staging/                 # Empty (promoted via PR)
└── production/              # Empty (promoted via PR)
```

### Complete Setup
- ✅ Terraform infrastructure files
- ✅ Environment-specific tfvars examples
- ✅ Userdata script templates
- ✅ GitHub workflows (build/destroy)
- ✅ AWS account configurations
- ✅ Complete documentation

### GitOps Workflow
- **Dev**: Auto-deploy on push
- **Staging**: PR approval required
- **Production**: PR approval required

## 🆘 Support

- Check workflow logs for issues
- Review generated repository documentation
- Contact Platform Engineering team

---

**Platform Engineering Team**  
Automated infrastructure provisioning for application teams