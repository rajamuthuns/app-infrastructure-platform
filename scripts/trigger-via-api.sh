#!/bin/bash

# Script to trigger the app infrastructure creation pipeline via GitHub API
# This can be used by external systems or for automation

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

# Function to show usage
show_usage() {
    echo "Platform Engineering Pipeline API Trigger"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -a, --app-name APP_NAME              Application name (required)"
    echo "  -o, --target-org ORG                 Target GitHub organization (required)"
    echo "  -c, --contacts EMAILS                App team contact emails, comma-separated (required)"
    echo "  -d, --dev-account ACCOUNT_ID         AWS Development Account ID (required)"
    echo "  -s, --staging-account ACCOUNT_ID     AWS Staging Account ID (required)"
    echo "  -p, --prod-account ACCOUNT_ID        AWS Production Account ID (required)"
    echo "  --staging-approvers USERS            Staging approvers, comma-separated (required)"
    echo "  --prod-approvers USERS               Production approvers, comma-separated (required)"
    echo "  -r, --region REGION                  AWS region (default: us-east-1)"


    echo "  --platform-repo REPO                Platform repository (default: platform-team/infrastructure-platform)"
    echo "  --github-token TOKEN                 GitHub token (or set GITHUB_TOKEN env var)"
    echo "  --dry-run                            Show what would be sent without triggering"
    echo "  -h, --help                           Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  GITHUB_TOKEN                         GitHub token with workflow dispatch permissions"
    echo "  PLATFORM_REPO                       Platform repository (owner/repo format)"
    echo ""
    echo "Examples:"
    echo "  # Basic usage"
    echo "  $0 -a my-web-app -o acme-corp -c team@acme.com \\"
    echo "     -d 123456789012 -s 123456789013 -p 123456789014 \\"
    echo "     --staging-approvers john,jane --prod-approvers senior-dev,tech-lead"
    echo ""
    echo "  # With optional parameters"
    echo "  $0 -a my-api -o acme-corp -c api-team@acme.com \\"
    echo "     -d 123456789012 -s 123456789013 -p 123456789014 \\"
    echo "     --staging-approvers john,jane --prod-approvers senior-dev,tech-lead \\"
    echo "     -r us-west-2"
    echo ""
    echo "  # Dry run to test parameters"
    echo "  $0 --dry-run -a test-app -o test-org -c test@test.com \\"
    echo "     -d 123456789012 -s 123456789013 -p 123456789014 \\"
    echo "     --staging-approvers john --prod-approvers jane"
    echo ""
}

# Default values
AWS_REGION="us-east-1"
PLATFORM_REPO="${PLATFORM_REPO:-platform-team/infrastructure-platform}"
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--app-name)
            APP_NAME="$2"
            shift 2
            ;;
        -o|--target-org)
            TARGET_ORG="$2"
            shift 2
            ;;
        -c|--contacts)
            APP_TEAM_CONTACTS="$2"
            shift 2
            ;;
        -d|--dev-account)
            DEV_ACCOUNT_ID="$2"
            shift 2
            ;;
        -s|--staging-account)
            STAGING_ACCOUNT_ID="$2"
            shift 2
            ;;
        -p|--prod-account)
            PROD_ACCOUNT_ID="$2"
            shift 2
            ;;
        --staging-approvers)
            STAGING_APPROVERS="$2"
            shift 2
            ;;
        --prod-approvers)
            PROD_APPROVERS="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        --platform-repo)
            PLATFORM_REPO="$2"
            shift 2
            ;;
        --github-token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
MISSING_PARAMS=()

if [ -z "$APP_NAME" ]; then
    MISSING_PARAMS+=("--app-name")
fi

if [ -z "$TARGET_ORG" ]; then
    MISSING_PARAMS+=("--target-org")
fi

if [ -z "$APP_TEAM_CONTACTS" ]; then
    MISSING_PARAMS+=("--contacts")
fi

if [ -z "$DEV_ACCOUNT_ID" ]; then
    MISSING_PARAMS+=("--dev-account")
fi

if [ -z "$STAGING_ACCOUNT_ID" ]; then
    MISSING_PARAMS+=("--staging-account")
fi

if [ -z "$PROD_ACCOUNT_ID" ]; then
    MISSING_PARAMS+=("--prod-account")
fi

if [ -z "$STAGING_APPROVERS" ]; then
    MISSING_PARAMS+=("--staging-approvers")
fi

if [ -z "$PROD_APPROVERS" ]; then
    MISSING_PARAMS+=("--prod-approvers")
fi

if [ -z "$GITHUB_TOKEN" ]; then
    MISSING_PARAMS+=("--github-token or GITHUB_TOKEN env var")
fi

if [ ${#MISSING_PARAMS[@]} -gt 0 ]; then
    print_error "Missing required parameters:"
    for param in "${MISSING_PARAMS[@]}"; do
        echo "  - $param"
    done
    echo ""
    show_usage
    exit 1
fi

# Validate input formats
print_status "Validating input parameters..."

# Validate app name format
if [[ ! "$APP_NAME" =~ ^[a-z0-9-]+$ ]]; then
    print_error "App name must contain only lowercase letters, numbers, and hyphens"
    exit 1
fi

# Validate AWS account IDs
for account_name in "DEV_ACCOUNT_ID" "STAGING_ACCOUNT_ID" "PROD_ACCOUNT_ID"; do
    account_value="${!account_name}"
    if [[ ! "$account_value" =~ ^[0-9]{12}$ ]]; then
        print_error "Invalid AWS account ID format for $account_name: $account_value (must be 12 digits)"
        exit 1
    fi
done



print_success "Input validation completed"

# Prepare the API payload
REPO_NAME="${APP_NAME}-infrastructure"

# Combine AWS accounts into the new format
AWS_ACCOUNTS="dev:${DEV_ACCOUNT_ID},staging:${STAGING_ACCOUNT_ID},prod:${PROD_ACCOUNT_ID}"

PAYLOAD=$(cat << EOF
{
  "ref": "main",
  "inputs": {
    "app_name": "$APP_NAME",
    "target_github_org": "$TARGET_ORG",
    "app_team_contacts": "$APP_TEAM_CONTACTS",
    "aws_accounts": "$AWS_ACCOUNTS",
    "staging_approvers": "$STAGING_APPROVERS",
    "prod_approvers": "$PROD_APPROVERS",
    "aws_region": "$AWS_REGION"
  }
}
EOF
)

# Show configuration summary
print_header "Pipeline Trigger Configuration"
echo ""
echo "App Name: $APP_NAME"
echo "Target Organization: $TARGET_ORG"
echo "Repository Name: $REPO_NAME"
echo "App Team Contacts: $APP_TEAM_CONTACTS"
echo ""
echo "AWS Accounts:"
echo "  Development: $DEV_ACCOUNT_ID"
echo "  Staging: $STAGING_ACCOUNT_ID"
echo "  Production: $PROD_ACCOUNT_ID"
echo "  Region: $AWS_REGION"
echo ""
echo "Approvers:"
echo "  Staging: $STAGING_APPROVERS"
echo "  Production: $PROD_APPROVERS"
echo ""
echo "Platform Repository: $PLATFORM_REPO"

echo ""

# Show payload in dry run mode
if [ "$DRY_RUN" = true ]; then
    print_header "Dry Run - API Payload"
    echo ""
    echo "URL: https://api.github.com/repos/$PLATFORM_REPO/actions/workflows/create-app-infrastructure.yml/dispatches"
    echo ""
    echo "Payload:"
    echo "$PAYLOAD" | python3 -m json.tool
    echo ""
    print_success "Dry run completed. No API call was made."
    exit 0
fi

# Confirm before triggering
echo ""
read -p "Do you want to trigger the pipeline with this configuration? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    print_status "Pipeline trigger cancelled"
    exit 0
fi

# Trigger the pipeline
print_status "Triggering infrastructure creation pipeline..."

API_URL="https://api.github.com/repos/$PLATFORM_REPO/actions/workflows/create-app-infrastructure.yml/dispatches"

HTTP_STATUS=$(curl -s -o response.json -w "%{http_code}" \
    -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$API_URL")

if [ "$HTTP_STATUS" -eq 204 ]; then
    print_success "Pipeline triggered successfully!"
    echo ""
    echo "🎉 Infrastructure creation pipeline has been started"
    echo ""
    echo "📋 What happens next:"
    echo "1. Pipeline creates GitHub repository: $TARGET_ORG/$REPO_NAME"
    echo "2. Sets up complete infrastructure skeleton"
    echo "3. Configures GitOps workflow and environments"
    echo "4. Notifies app team when ready"
    echo ""
    echo "🔗 Monitor progress:"
    echo "   https://github.com/$PLATFORM_REPO/actions"
    echo ""
    echo "📧 App team will be notified at: $APP_TEAM_CONTACTS"

    echo ""
    print_success "Pipeline trigger completed!"
else
    print_error "Failed to trigger pipeline (HTTP $HTTP_STATUS)"
    echo ""
    echo "Response:"
    cat response.json
    echo ""
    
    # Common error messages
    case $HTTP_STATUS in
        401)
            print_error "Authentication failed. Check your GitHub token permissions."
            ;;
        404)
            print_error "Repository or workflow not found. Check the platform repository path."
            ;;
        422)
            print_error "Invalid request. Check the input parameters."
            ;;
        *)
            print_error "Unexpected error. Check the response above for details."
            ;;
    esac
    
    exit 1
fi

# Cleanup
rm -f response.json