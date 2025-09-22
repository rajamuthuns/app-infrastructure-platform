# Deployment Architecture for Platform Engineering

This document explains how the platform engineering solution works with separate repositories.

## 🏗️ Repository Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                Platform Repository                          │
│            (app-infrastructure-platform)                    │
├─────────────────────────────────────────────────────────────┤
│  ├── README.md                                              │
│  ├── create-app-infrastructure.sh                           │
│  ├── .github/workflows/create-app-infrastructure.yml        │
│  └── scripts/trigger-via-api.sh                             │
│                                                             │
│  Purpose: Platform Engineering tools and workflows          │
└─────────────────────┬───────────────────────────────────────┘
                      │ References via BASE_INFRASTRUCTURE_REPO
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Base Infrastructure Repository               │
│              (terraform-base-infrastructure)                │
├─────────────────────────────────────────────────────────────┤
│  ├── README.md              ← Copied to app repos           │
│  ├── main.tf                ← Copied to app repos           │
│  ├── variables.tf           ← Copied to app repos           │
│  ├── .github/workflows/     ← Copied to app repos           │
│  ├── config/                ← Copied to app repos           │
│  ├── shared/                ← Copied to app repos           │
│  └── docs/                  ← Copied to app repos           │
│                                                             │
│  Purpose: Base infrastructure templates and workflows       │
└─────────────────────┬───────────────────────────────────────┘
                      │ Files copied to
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                App Team Repository                          │
│                (my-app-infrastructure)                      │
├─────────────────────────────────────────────────────────────┤
│  ├── README.md              ← App-specific                  │
│  ├── PLATFORM-README.md     ← From base repo                │
│  ├── main.tf                ← From base repo                │
│  ├── .github/workflows/     ← From base repo                │
│  ├── tfvars/                ← Empty, app team fills         │
│  └── userdata/              ← Empty, app team fills         │
│                                                             │
│  Purpose: App-specific infrastructure                       │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Workflow Process

### 1. Platform Engineering Triggers Pipeline

```bash
# Manual trigger via GitHub Actions UI
# OR
# API trigger via script
./scripts/trigger-via-api.sh -a my-app -o acme-corp ...
```

### 2. Pipeline Execution Steps

1. **Validate Inputs** - Check app name, AWS accounts, approvers
2. **Create Repository** - Create new repo in target organization
3. **Checkout Base Infrastructure** - Access base repo using `BASE_INFRASTRUCTURE_REPO` variable
4. **Copy Files** - Copy all base infrastructure files to new app repo
5. **Setup GitOps** - Create branches, environments, protection rules
6. **Notify** - Send notifications to app team and Slack

### 3. File Copying Process

```yaml
# The workflow does this:
- name: Checkout base infrastructure repository
  uses: actions/checkout@v4
  with:
    repository: ${{ vars.BASE_INFRASTRUCTURE_REPO }}  # e.g., "your-org/terraform-base-infrastructure"
    token: ${{ secrets.PLATFORM_GITHUB_TOKEN }}
    path: base-repo

# Then copies files:
cp ../base-repo/main.tf .
cp ../base-repo/.github/workflows/* .github/workflows/
cp ../base-repo/README.md PLATFORM-README.md
# ... etc
```

## 🔧 Configuration Requirements

### Platform Repository Setup

1. **Repository Variable**:
   ```
   Name: BASE_INFRASTRUCTURE_REPO
   Value: your-org/terraform-base-infrastructure
   ```

2. **Repository Secrets**:
   ```
   PLATFORM_GITHUB_TOKEN: GitHub token with org admin permissions
   SLACK_WEBHOOK_URL: For notifications (optional)
   ```

### Base Infrastructure Repository

Must contain these files/directories:
- `main.tf`, `variables.tf`, `outputs.tf`, `backend.tf`
- `Makefile`, `deploy.sh`, `.gitignore`
- `config/` - AWS account configurations
- `shared/` - Backend configurations
- `scripts/` - Utility scripts
- `.github/workflows/` - **GitOps workflows (copied to app repos)**
- `docs/` - Documentation
- `README.md` - **Complete platform documentation (copied as PLATFORM-README.md)**

## 🎯 What App Teams Get

Each generated app repository contains:

### From Base Infrastructure Repository:
- ✅ **Complete Terraform setup** (main.tf, variables.tf, etc.)
- ✅ **GitOps workflows** (.github/workflows/ - identical to base)
- ✅ **Configuration files** (config/, shared/)
- ✅ **Utility scripts** (scripts/)
- ✅ **Documentation** (docs/)
- ✅ **Platform README** (PLATFORM-README.md - complete platform docs)

### Generated by Pipeline:
- ✅ **App-specific README** (tailored quick start guide)
- ✅ **Setup instructions** (SETUP.md)
- ✅ **Credentials guide** (CREDENTIALS-SETUP.md)
- ✅ **Empty tfvars** with examples
- ✅ **Empty userdata** with examples
- ✅ **GitOps branches** (dev, staging, production)
- ✅ **GitHub environments** with approvals
- ✅ **Branch protection** rules

## 🚀 Benefits of This Architecture

### For Platform Engineering:
- ✅ **Centralized Management** - Platform tools in dedicated repo
- ✅ **Base Infrastructure Control** - Maintain templates separately
- ✅ **Scalable Automation** - API-driven repository creation
- ✅ **Audit Trail** - Track all repository creations

### For App Teams:
- ✅ **Complete Setup** - Everything needed to start
- ✅ **Identical Workflows** - Same GitOps process as base infrastructure
- ✅ **Complete Documentation** - Platform README + app-specific guides
- ✅ **Ready to Deploy** - Just add tfvars and userdata

### For Organization:
- ✅ **Consistency** - All app repos follow same patterns
- ✅ **Security** - Proper approvals and branch protection
- ✅ **Maintainability** - Updates to base infrastructure propagate
- ✅ **Governance** - Platform team controls standards

## 🔍 Troubleshooting

### Common Issues:

**"Repository not found" errors:**
- Check `BASE_INFRASTRUCTURE_REPO` variable is set correctly
- Verify `PLATFORM_GITHUB_TOKEN` has access to base infrastructure repo

**"File not found" errors:**
- Ensure base infrastructure repo has all required files
- Check file paths in base repository match expected structure

**"Permission denied" errors:**
- Verify `PLATFORM_GITHUB_TOKEN` has admin permissions in target organization
- Check token has access to both platform and base infrastructure repositories

### Validation:

```bash
# Test the setup
./scripts/trigger-via-api.sh --dry-run \
  -a test-app \
  -o test-org \
  -c test@test.com \
  -d 123456789012 \
  -s 123456789013 \
  -p 123456789014 \
  --staging-approvers john \
  --prod-approvers jane
```

---

**This architecture ensures app teams get complete, working infrastructure repositories with identical workflows to your base infrastructure!** 🎉