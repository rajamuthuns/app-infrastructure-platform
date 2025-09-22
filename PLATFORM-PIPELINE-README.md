# Platform Engineering Pipeline for App Team Infrastructure

This pipeline allows Platform Engineering teams to create infrastructure repositories for app teams through automated workflows.

## 🎯 Overview

The Platform Engineering Pipeline provides:

- ✅ **Remote Repository Creation** - Creates repos in app team's GitHub organization
- ✅ **Automated Skeleton Setup** - Deploys complete infrastructure template
- ✅ **Configuration Management** - Sets up environments, branches, and approvals
- ✅ **Documentation Generation** - Creates comprehensive README and setup guides
- ✅ **Notification System** - Notifies app teams when their repo is ready
- ✅ **Audit Trail** - Tracks all repository creations and configurations

## 🏗️ Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                Platform Engineering Team                     │
├─────────────────────────────────────────────────────────────┤
│  1. Trigger Pipeline (Manual/API/Form)                      │
│     ├── App Team Details                                    │
│     ├── Repository Configuration                            │
│     └── Environment Settings                                │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                GitHub Actions Pipeline                      │
├─────────────────────────────────────────────────────────────┤
│  2. Repository Creation Workflow                            │
│     ├── Create GitHub Repository                            │
│     ├── Set up Branch Structure                             │
│     ├── Configure Environments                              │
│     ├── Set Branch Protection Rules                         │
│     └── Deploy Infrastructure Skeleton                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                App Team Repository                          │
├─────────────────────────────────────────────────────────────┤
│  3. Ready-to-Use Infrastructure Repository                  │
│     ├── Complete Terraform Setup                            │
│     ├── GitOps Workflows                                    │
│     ├── Example Configurations                              │
│     ├── Documentation & Guides                              │
│     └── Notification to App Team                            │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Pipeline Triggers

### 1. Manual Trigger (GitHub Actions UI)
Platform engineers can trigger via GitHub Actions interface with form inputs.

### 2. API Trigger (REST API)
External systems can trigger via GitHub API with JSON payload.

### 3. Issue-Based Trigger
App teams create issues with specific templates, pipeline auto-triggers.

### 4. Webhook Trigger
Integration with ticketing systems (Jira, ServiceNow) or internal portals.

## 📋 Pipeline Inputs

The pipeline accepts these parameters:

```yaml
inputs:
  app_name:
    description: 'Application name (e.g., my-web-app)'
    required: true
    type: string
  
  target_github_org:
    description: 'Target GitHub organization for app team'
    required: true
    type: string
  
  app_team_contacts:
    description: 'App team contact emails (comma-separated)'
    required: true
    type: string
  
  dev_account_id:
    description: 'AWS Development Account ID'
    required: true
    type: string
  
  staging_account_id:
    description: 'AWS Staging Account ID'
    required: true
    type: string
  
  prod_account_id:
    description: 'AWS Production Account ID'
    required: true
    type: string
  
  staging_approvers:
    description: 'GitHub usernames for staging approvals (comma-separated)'
    required: true
    type: string
  
  prod_approvers:
    description: 'GitHub usernames for production approvals (comma-separated)'
    required: true
    type: string
  
  notification_slack_channel:
    description: 'Slack channel for notifications (optional)'
    required: false
    type: string
  
  custom_modules:
    description: 'Additional modules to include (JSON format, optional)'
    required: false
    type: string
```

## 🔧 Setup Instructions

### 1. Configure Platform Repository

Set up the platform repository with required secrets and permissions.

### 2. Set Up GitHub App (Recommended)

Create a GitHub App for cross-organization repository management.

### 3. Configure Notification Channels

Set up Slack, email, or other notification systems.

### 4. Deploy Pipeline

Deploy the GitHub Actions workflow to your platform repository.

## 📖 Usage Examples

### Manual Trigger Example
```bash
# Via GitHub CLI
gh workflow run create-app-infrastructure.yml \
  -f app_name="my-web-app" \
  -f target_github_org="acme-corp" \
  -f app_team_contacts="team@acme-corp.com" \
  -f dev_account_id="123456789012" \
  -f staging_account_id="123456789013" \
  -f prod_account_id="123456789014" \
  -f staging_approvers="john,jane" \
  -f prod_approvers="senior-dev,tech-lead"
```

### API Trigger Example
```bash
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/platform-team/infrastructure-platform/actions/workflows/create-app-infrastructure.yml/dispatches \
  -d '{
    "ref": "main",
    "inputs": {
      "app_name": "my-web-app",
      "target_github_org": "acme-corp",
      "app_team_contacts": "team@acme-corp.com",
      "dev_account_id": "123456789012",
      "staging_account_id": "123456789013",
      "prod_account_id": "123456789014",
      "staging_approvers": "john,jane",
      "prod_approvers": "senior-dev,tech-lead"
    }
  }'
```

### Using the API Trigger Script
```bash
# Basic usage
./scripts/trigger-via-api.sh \
  -a my-web-app \
  -o acme-corp \
  -c team@acme.com \
  -d 123456789012 \
  -s 123456789013 \
  -p 123456789014 \
  --staging-approvers john,jane \
  --prod-approvers senior-dev,tech-lead

# With optional parameters
./scripts/trigger-via-api.sh \
  -a my-api \
  -o acme-corp \
  -c api-team@acme.com \
  -d 123456789012 \
  -s 123456789013 \
  -p 123456789014 \
  --staging-approvers john,jane \
  --prod-approvers senior-dev,tech-lead \
  -r us-west-2 \
  --slack-channel '#api-team-notifications'
```

## 🛡️ Security & Permissions

### Required GitHub Permissions
- Repository creation in target organizations
- Branch protection rule management
- Environment configuration
- Secrets management (for app team repos)

### Required Secrets
- `PLATFORM_GITHUB_TOKEN` - GitHub token with org admin permissions
- `SLACK_WEBHOOK_URL` - For notifications (optional)
- `AWS_PLATFORM_ACCESS_KEY_ID` - For AWS validation (optional)
- `AWS_PLATFORM_SECRET_ACCESS_KEY` - For AWS validation (optional)

## 📊 Monitoring & Auditing

The pipeline provides:
- Execution logs and status tracking
- Repository creation audit trail
- Success/failure notifications
- Metrics and reporting dashboard

## 🔄 What Gets Created

### Repository Structure
```
my-app-infrastructure/
├── README.md                          # App-specific documentation
├── PLATFORM-README.md                 # Complete platform documentation (from main workspace)
├── SETUP.md                           # Detailed setup instructions for app team
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
├── scripts/                           # Utility scripts
├── docs/                              # Documentation
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

## 🆘 Troubleshooting

### Common Issues

**Script Permission Denied**
```bash
chmod +x scripts/trigger-via-api.sh
```

**GitHub CLI Not Authenticated**
```bash
gh auth login
gh auth status
```

**Repository Already Exists**
The pipeline will ask if you want to continue with the existing repository.

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

**Ready to create infrastructure for your app team? Run the pipeline and get started!** 🚀