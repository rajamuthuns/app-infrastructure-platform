# Platform Repository Setup Guide

This guide helps you set up a dedicated platform repository for app team infrastructure creation.

## 🎯 Recommended Setup: Dedicated Platform Repository

### Step 1: Create Platform Repository

```bash
# Create new repository for platform engineering
gh repo create your-org/app-infrastructure-platform \
  --description "Platform Engineering tools for app team infrastructure creation" \
  --private

# Clone the repository
git clone https://github.com/your-org/app-infrastructure-platform.git
cd app-infrastructure-platform
```

### Step 2: Copy Platform Files

```bash
# Copy all app-team-wrapper contents to repository root
# From your current workspace directory:
cp -r app-team-wrapper/* /path/to/app-infrastructure-platform/
cp -r app-team-wrapper/.github /path/to/app-infrastructure-platform/

# Navigate to platform repository
cd /path/to/app-infrastructure-platform
```

### Step 3: Configure Repository Variable

The workflow is already configured to use a repository variable for your base infrastructure repository. You just need to set it up:

```bash
# Go to: Settings → Secrets and variables → Actions → Variables
# Add this variable:
# Name: BASE_INFRASTRUCTURE_REPO
# Value: your-org/terraform-base-infrastructure

# The workflow will automatically use this to checkout your base infrastructure files
```

### Step 4: Configure Secrets and Variables

Set up required GitHub secrets and variables in your platform repository:

#### Secrets (Settings → Secrets and variables → Actions → Secrets):
```bash
PLATFORM_GITHUB_TOKEN    # GitHub token with org admin permissions
SLACK_WEBHOOK_URL        # For notifications (optional)
```

#### Variables (Settings → Secrets and variables → Actions → Variables):
```bash
BASE_INFRASTRUCTURE_REPO  # Your base infrastructure repository (e.g., "your-org/terraform-base-infrastructure")
```

**Important**: The `BASE_INFRASTRUCTURE_REPO` variable tells the workflow where to find your base infrastructure files.

### Step 5: Test the Setup

```bash
# Test the interactive script
./create-app-infrastructure.sh

# Test the API trigger script
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

## 🔧 Alternative: Keep in Current Workspace

If you prefer to keep everything in your current workspace:

### Update Workflow Paths

```yaml
# In .github/workflows/create-app-infrastructure.yml
# Update file copy paths to reference the correct locations:

- name: Copy base infrastructure files
  run: |
    cd target-repo
    
    # Copy from workspace root (not relative paths)
    cp ../main.tf .
    cp ../variables.tf .
    # ... etc
```

### Update Script Paths

```bash
# In create-app-infrastructure.sh
# Update the SCRIPT_DIR and BASE_DIR variables:

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"  # Points to workspace root
```

## 🎯 Recommended Repository Structure

### Dedicated Platform Repository:
```
app-infrastructure-platform/
├── README.md                           # Platform overview
├── SETUP.md                            # Setup instructions
├── CREDENTIALS-SETUP.md                # AWS setup guide
├── PLATFORM-SETUP-GUIDE.md            # This file
├── create-app-infrastructure.sh        # Interactive script
├── validate-setup.sh                   # Validation script
├── .github/workflows/
│   └── create-app-infrastructure.yml   # Pipeline workflow
└── scripts/
    └── trigger-via-api.sh              # API trigger script
```

### Base Infrastructure Repository (separate):
```
terraform-base-infrastructure/
├── README.md                           # Base infrastructure docs
├── main.tf                             # Base Terraform files
├── variables.tf
├── outputs.tf
├── backend.tf
├── config/
├── shared/
├── scripts/
├── docs/
└── .github/workflows/                  # Base infrastructure workflows
```

## 🚀 Benefits of Dedicated Repository

1. **Clear Separation** - Platform tools vs base infrastructure
2. **Access Control** - Different permissions for different teams
3. **Easier Maintenance** - Focused repositories are easier to manage
4. **Better Documentation** - Each repo has specific purpose and docs
5. **Scalability** - Platform can evolve independently

## 🔄 Migration Steps

If you're moving from current workspace to dedicated repository:

```bash
# 1. Create new platform repository
gh repo create your-org/app-infrastructure-platform --private

# 2. Clone both repositories
git clone https://github.com/your-org/app-infrastructure-platform.git
git clone https://github.com/your-org/your-base-infrastructure-repo.git

# 3. Copy platform files
cp -r your-base-infrastructure-repo/app-team-wrapper/* app-infrastructure-platform/
cp -r your-base-infrastructure-repo/app-team-wrapper/.github app-infrastructure-platform/

# 4. Update workflow to reference base infrastructure repo
# Edit app-infrastructure-platform/.github/workflows/create-app-infrastructure.yml

# 5. Commit and push
cd app-infrastructure-platform
git add .
git commit -m "feat: initial platform engineering setup"
git push origin main

# 6. Configure secrets and test
```

## 🆘 Support

- **Platform Setup Issues**: Check this guide and test with dry-run options
- **Workflow Issues**: Review GitHub Actions logs and workflow configuration
- **App Team Issues**: Direct them to generated repository documentation

---

**Choose the setup that best fits your organization's structure and preferences!**