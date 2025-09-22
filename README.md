# App Team Infrastructure Wrapper

This wrapper provides a streamlined way for Platform Engineering teams to create infrastructure repositories for application teams. It includes both manual wrapper scripts and automated pipeline workflows.

## 🎯 What This Wrapper Provides

- ✅ **Manual Wrapper Script** - Interactive script for one-off repository creation
- ✅ **Automated Pipeline** - GitHub Actions workflow for scalable repository creation
- ✅ **Complete Project Skeleton** - All necessary Terraform files and configurations
- ✅ **GitOps Workflow Setup** - Automated dev → staging → production promotion
- ✅ **GitHub Environments** - Proper approval workflows and branch protection
- ✅ **Documentation Generation** - Comprehensive setup guides and examples
- ✅ **Main Workspace README** - Copies complete platform documentation to app repos
- ✅ **Template Configurations** - Empty tfvars and userdata with examples

## 🚀 Usage Options

### Option 1: Manual Wrapper Script (Interactive)

For one-off repository creation with interactive prompts:

```bash
# Prerequisites: GitHub CLI, Git, Terraform (optional)
./create-app-infrastructure.sh

# Follow interactive prompts for:
# - App name, GitHub org, AWS accounts
# - Team members for approvals
# - Notification preferences
```

### Option 2: Automated Pipeline (Scalable)

For automated repository creation via GitHub Actions:

#### Manual Trigger (GitHub UI)
1. Go to Actions → "Create App Team Infrastructure Repository"
2. Click "Run workflow"
3. Fill in the form with app details
4. Click "Run workflow"

#### API Trigger (Programmatic)
```bash
# Using the provided script
./scripts/trigger-via-api.sh \
  -a my-web-app \
  -o acme-corp \
  -c team@acme.com \
  -d 123456789012 \
  -s 123456789013 \
  -p 123456789014 \
  --staging-approvers john,jane \
  --prod-approvers senior-dev,tech-lead

# Or direct API call
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/your-org/platform-repo/actions/workflows/create-app-infrastructure.yml/dispatches \
  -d '{"ref": "main", "inputs": {...}}'
```

## 📁 Generated Repository Structure

```
my-web-app-infrastructure/
├── README.md                          # App-specific documentation
├── PLATFORM-README.md                 # Complete platform documentation (from main workspace)
├── SETUP.md                           # Detailed setup instructions
├── CREDENTIALS-SETUP.md               # AWS credentials setup guide
├── main.tf                            # Infrastructure orchestration
├── variables.tf                       # Variable definitions
├── outputs.tf                         # Output definitions
├── backend.tf                         # Backend configuration
├── Makefile                           # Deployment shortcuts
├── deploy.sh                          # Local deployment script
├── .gitignore                         # Git ignore rules
├── .github/workflows/                 # GitOps CI/CD pipelines
├── config/                            # Environment configurations
├── shared/                            # Backend configurations
├── scripts/                           # Setup and utility scripts
├── docs/                              # Documentation
├── tfvars/                            # ⚠️ EMPTY - App team adds configs
│   ├── README.md                      # Instructions for app team
│   ├── dev-terraform.tfvars.example   # Example configuration
│   ├── stg-terraform.tfvars.example   # Example configuration
│   └── prod-terraform.tfvars.example  # Example configuration
├── userdata/                          # ⚠️ EMPTY - App team adds scripts
│   ├── README.md                      # Instructions for app team
│   ├── userdata-linux.sh.example     # Example Linux script
│   └── userdata-windows.ps1.example  # Example Windows script
└── validate-setup.sh                  # Validation script for app team
```

## 🔧 What App Teams Need to Do

After repository creation, app teams need to:

1. **Clone Repository** - `git clone <repository-url>`
2. **Configure Infrastructure** - Copy and customize tfvars example files
3. **Add User Data Scripts** - Copy and customize userdata example files
4. **Set Up AWS Credentials** - Configure GitHub repository secrets
5. **Deploy** - Push to dev branch to start GitOps workflow

The generated repository includes:
- **SETUP.md** - Detailed setup instructions
- **CREDENTIALS-SETUP.md** - AWS credentials setup guide
- **PLATFORM-README.md** - Complete platform documentation from main workspace
- **validate-setup.sh** - Script to validate configuration

## 🛡️ Security & Approvals

The wrapper automatically configures:

- **Dev Environment**: No approvals (auto-deploy)
- **Staging Environment**: Requires team approval for deployment
- **Production Environment**: Requires senior team approval + terraform apply approval
- **Branch Protection**: Prevents direct pushes to staging/production

## 📋 Wrapper Components

### Files in this Directory

- **`create-app-infrastructure.sh`** - Interactive wrapper script
- **`validate-setup.sh`** - Setup validation script
- **`.github/workflows/create-app-infrastructure.yml`** - Automated pipeline workflow
- **`scripts/trigger-via-api.sh`** - API trigger script for pipeline
- **`README.md`** - This file
- **`SETUP.md`** - Detailed setup guide for Platform Engineering teams
- **`CREDENTIALS-SETUP.md`** - AWS credentials setup guide
- **`PLATFORM-PIPELINE-README.md`** - Pipeline-specific documentation

### Features Included

- ✅ Multi-environment support (dev/staging/production)
- ✅ GitOps workflow with automatic promotion
- ✅ Infrastructure as Code with Terraform
- ✅ Modular architecture using base modules
- ✅ Automated testing and validation
- ✅ Security best practices with approval workflows
- ✅ Comprehensive documentation and examples
- ✅ Main workspace README copied to app repositories
- ✅ Pipeline automation for scalable repository creation

## 🚀 Platform Engineering Setup

### Prerequisites

1. **GitHub Repository** with this wrapper
2. **GitHub Secrets** configured:
   - `PLATFORM_GITHUB_TOKEN` - Token with org admin permissions
   - `SLACK_WEBHOOK_URL` - For notifications (optional)
3. **GitHub CLI** installed and authenticated
4. **Permissions** to create repositories in target organizations

### Quick Setup

1. **Copy this wrapper** to your platform repository
2. **Configure GitHub secrets** in your platform repository
3. **Test the pipeline** with a sample app team request
4. **Document the process** for your platform engineering team

## 🆘 Support

### For Platform Engineering Teams
1. Review `SETUP.md` for detailed setup instructions
2. Check `PLATFORM-PIPELINE-README.md` for pipeline documentation
3. Test with `validate-setup.sh` script
4. Monitor pipeline executions in GitHub Actions

### For App Teams
1. Check the generated `SETUP.md` file in their repository
2. Review `PLATFORM-README.md` for complete platform documentation
3. Use `validate-setup.sh` to verify their configuration
4. Contact Platform Engineering team for support