#!/bin/bash

# Validation script for app team infrastructure setup
# This script helps validate that the infrastructure setup is correct

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

# Validation counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Function to run a check
run_check() {
    local check_name="$1"
    local check_command="$2"
    local is_critical="${3:-true}"
    
    echo -n "Checking $check_name... "
    
    if eval "$check_command" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        ((CHECKS_PASSED++))
        return 0
    else
        if [ "$is_critical" = "true" ]; then
            echo -e "${RED}✗${NC}"
            ((CHECKS_FAILED++))
        else
            echo -e "${YELLOW}⚠${NC}"
            ((CHECKS_WARNING++))
        fi
        return 1
    fi
}

# Function to validate file exists and has content
validate_file() {
    local file_path="$1"
    local description="$2"
    local is_critical="${3:-true}"
    
    if run_check "$description" "[ -f '$file_path' ] && [ -s '$file_path' ]" "$is_critical"; then
        return 0
    else
        if [ "$is_critical" = "true" ]; then
            print_error "Missing or empty file: $file_path"
        else
            print_warning "Missing or empty file: $file_path"
        fi
        return 1
    fi
}

# Function to validate directory exists
validate_directory() {
    local dir_path="$1"
    local description="$2"
    
    if run_check "$description" "[ -d '$dir_path' ]"; then
        return 0
    else
        print_error "Missing directory: $dir_path"
        return 1
    fi
}

# Function to validate JSON file
validate_json() {
    local file_path="$1"
    local description="$2"
    
    if run_check "$description" "python3 -m json.tool '$file_path' > /dev/null 2>&1"; then
        return 0
    else
        print_error "Invalid JSON in file: $file_path"
        return 1
    fi
}

# Function to validate Terraform files
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    if command -v terraform &> /dev/null; then
        if run_check "Terraform syntax" "terraform fmt -check=true -diff=false"; then
            print_success "Terraform formatting is correct"
        else
            print_warning "Terraform files need formatting. Run: terraform fmt"
        fi
        
        if run_check "Terraform validation" "terraform validate"; then
            print_success "Terraform configuration is valid"
        else
            print_error "Terraform configuration has errors"
        fi
    else
        print_warning "Terraform not installed, skipping validation"
        ((CHECKS_WARNING++))
    fi
}

# Function to validate GitHub repository
validate_github_repo() {
    print_status "Validating GitHub repository..."
    
    if command -v gh &> /dev/null; then
        if run_check "GitHub repository access" "gh repo view"; then
            print_success "GitHub repository is accessible"
            
            # Check if branches exist
            if run_check "dev branch exists" "gh api repos/:owner/:repo/branches/dev" "false"; then
                print_success "Dev branch exists"
            else
                print_warning "Dev branch not found. Run: ./scripts/create-gitops-branches.sh"
            fi
            
            if run_check "staging branch exists" "gh api repos/:owner/:repo/branches/staging" "false"; then
                print_success "Staging branch exists"
            else
                print_warning "Staging branch not found. Run: ./scripts/create-gitops-branches.sh"
            fi
            
            if run_check "production branch exists" "gh api repos/:owner/:repo/branches/production" "false"; then
                print_success "Production branch exists"
            else
                print_warning "Production branch not found. Run: ./scripts/create-gitops-branches.sh"
            fi
            
            # Check environments
            if run_check "GitHub environments" "gh api repos/:owner/:repo/environments" "false"; then
                print_success "GitHub environments are configured"
            else
                print_warning "GitHub environments not configured. Run: ./scripts/setup-github-environments.sh"
            fi
            
        else
            print_error "Cannot access GitHub repository. Check authentication: gh auth status"
        fi
    else
        print_warning "GitHub CLI not installed, skipping repository validation"
        ((CHECKS_WARNING++))
    fi
}

# Function to validate AWS configuration
validate_aws_config() {
    print_status "Validating AWS configuration..."
    
    # Check AWS accounts configuration
    if validate_file "config/aws-accounts.json" "AWS accounts configuration"; then
        if validate_json "config/aws-accounts.json" "AWS accounts JSON format"; then
            # Check if account IDs are valid format
            local account_ids=$(python3 -c "
import json
with open('config/aws-accounts.json') as f:
    data = json.load(f)
    for env, config in data.items():
        account_id = config.get('account_id', '')
        if not account_id.isdigit() or len(account_id) != 12:
            print(f'Invalid account ID for {env}: {account_id}')
            exit(1)
print('All account IDs are valid')
" 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                print_success "AWS account IDs are valid"
            else
                print_error "Invalid AWS account ID format in config/aws-accounts.json"
                ((CHECKS_FAILED++))
            fi
        fi
    fi
    
    # Check backend configurations
    validate_file "shared/backend-dev.hcl" "Dev backend configuration" "false"
    validate_file "shared/backend-staging.hcl" "Staging backend configuration" "false"
    validate_file "shared/backend-prod.hcl" "Production backend configuration" "false"
}

# Function to validate tfvars configuration
validate_tfvars() {
    print_status "Validating tfvars configuration..."
    
    # Check if tfvars directory exists
    if validate_directory "tfvars" "tfvars directory"; then
        # Check for example files
        validate_file "tfvars/dev-terraform.tfvars.example" "Dev tfvars example" "false"
        validate_file "tfvars/stg-terraform.tfvars.example" "Staging tfvars example" "false"
        validate_file "tfvars/prod-terraform.tfvars.example" "Production tfvars example" "false"
        
        # Check for actual configuration files
        local has_configs=false
        
        if [ -f "tfvars/dev-terraform.tfvars" ]; then
            print_success "Dev tfvars configuration exists"
            has_configs=true
        else
            print_warning "Dev tfvars configuration missing. Copy from example file."
        fi
        
        if [ -f "tfvars/stg-terraform.tfvars" ]; then
            print_success "Staging tfvars configuration exists"
            has_configs=true
        else
            print_warning "Staging tfvars configuration missing. Copy from example file."
        fi
        
        if [ -f "tfvars/prod-terraform.tfvars" ]; then
            print_success "Production tfvars configuration exists"
            has_configs=true
        else
            print_warning "Production tfvars configuration missing. Copy from example file."
        fi
        
        if [ "$has_configs" = false ]; then
            print_error "No tfvars configuration files found. App team needs to create them."
            ((CHECKS_FAILED++))
        fi
    fi
}

# Function to validate userdata scripts
validate_userdata() {
    print_status "Validating userdata scripts..."
    
    # Check if userdata directory exists
    if validate_directory "userdata" "userdata directory"; then
        # Check for example files
        validate_file "userdata/userdata-linux.sh.example" "Linux userdata example" "false"
        validate_file "userdata/userdata-windows.ps1.example" "Windows userdata example" "false"
        
        # Check for actual scripts
        local has_scripts=false
        
        if [ -f "userdata/userdata-linux.sh" ]; then
            print_success "Linux userdata script exists"
            has_scripts=true
            
            # Check if script is executable
            if [ -x "userdata/userdata-linux.sh" ]; then
                print_success "Linux userdata script is executable"
            else
                print_warning "Linux userdata script is not executable. Run: chmod +x userdata/userdata-linux.sh"
                ((CHECKS_WARNING++))
            fi
        else
            print_warning "Linux userdata script missing. Copy from example file."
        fi
        
        if [ -f "userdata/userdata-windows.ps1" ]; then
            print_success "Windows userdata script exists"
            has_scripts=true
        else
            print_warning "Windows userdata script missing (optional)."
        fi
        
        if [ "$has_scripts" = false ]; then
            print_warning "No userdata scripts found. App team should create them."
            ((CHECKS_WARNING++))
        fi
    fi
}

# Function to validate GitHub secrets
validate_github_secrets() {
    print_status "Validating GitHub secrets..."
    
    if command -v gh &> /dev/null; then
        # Check for required secrets
        local required_secrets=("AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "PRIVATE_REPO_TOKEN")
        local missing_secrets=()
        
        for secret in "${required_secrets[@]}"; do
            if gh secret list | grep -q "$secret"; then
                print_success "Secret $secret is configured"
            else
                print_error "Missing required secret: $secret"
                missing_secrets+=("$secret")
                ((CHECKS_FAILED++))
            fi
        done
        
        if [ ${#missing_secrets[@]} -gt 0 ]; then
            print_error "Missing GitHub secrets. Add them in repository settings:"
            for secret in "${missing_secrets[@]}"; do
                echo "  - $secret"
            done
        fi
    else
        print_warning "GitHub CLI not available, cannot check secrets"
        ((CHECKS_WARNING++))
    fi
}

# Function to validate documentation
validate_documentation() {
    print_status "Validating documentation..."
    
    validate_file "README.md" "Main README"
    validate_file "SETUP.md" "Setup instructions"
    validate_directory "docs" "Documentation directory"
    
    if [ -d "docs" ]; then
        validate_file "docs/ARCHITECTURE.md" "Architecture documentation" "false"
        validate_file "docs/TROUBLESHOOTING.md" "Troubleshooting guide" "false"
        validate_file "docs/GITHUB_ACTIONS_SETUP.md" "GitHub Actions setup guide" "false"
    fi
}

# Function to validate scripts
validate_scripts() {
    print_status "Validating scripts..."
    
    if validate_directory "scripts" "Scripts directory"; then
        local scripts=("create-gitops-branches.sh" "setup-github-environments.sh" "setup-branch-protection.sh")
        
        for script in "${scripts[@]}"; do
            if validate_file "scripts/$script" "Script $script" "false"; then
                if [ -x "scripts/$script" ]; then
                    print_success "Script $script is executable"
                else
                    print_warning "Script $script is not executable. Run: chmod +x scripts/$script"
                    ((CHECKS_WARNING++))
                fi
            fi
        done
    fi
    
    # Check main deployment script
    if validate_file "deploy.sh" "Deployment script"; then
        if [ -x "deploy.sh" ]; then
            print_success "Deployment script is executable"
        else
            print_warning "Deployment script is not executable. Run: chmod +x deploy.sh"
            ((CHECKS_WARNING++))
        fi
    fi
}

# Function to show summary
show_summary() {
    print_header "Validation Summary"
    
    echo ""
    print_success "Checks passed: $CHECKS_PASSED"
    if [ $CHECKS_WARNING -gt 0 ]; then
        print_warning "Warnings: $CHECKS_WARNING"
    fi
    if [ $CHECKS_FAILED -gt 0 ]; then
        print_error "Checks failed: $CHECKS_FAILED"
    fi
    echo ""
    
    if [ $CHECKS_FAILED -eq 0 ]; then
        if [ $CHECKS_WARNING -eq 0 ]; then
            print_success "🎉 All validations passed! Your infrastructure setup is ready."
        else
            print_warning "⚠️  Setup is mostly ready, but please address the warnings above."
        fi
        echo ""
        echo "Next steps:"
        echo "1. Ensure tfvars files are configured with your requirements"
        echo "2. Ensure userdata scripts are customized for your application"
        echo "3. Verify GitHub secrets are configured"
        echo "4. Deploy to dev environment: git checkout dev && git push origin dev"
    else
        print_error "❌ Setup validation failed. Please fix the errors above before proceeding."
        echo ""
        echo "Common fixes:"
        echo "1. Run terraform fmt to fix formatting issues"
        echo "2. Create missing tfvars files from examples"
        echo "3. Set up GitHub secrets in repository settings"
        echo "4. Run setup scripts: ./scripts/create-gitops-branches.sh"
    fi
    
    echo ""
}

# Main validation function
main() {
    print_header "Infrastructure Setup Validation"
    
    echo "This script validates your infrastructure setup to ensure everything is configured correctly."
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "main.tf" ] || [ ! -f "variables.tf" ]; then
        print_error "This doesn't appear to be an infrastructure repository."
        print_error "Please run this script from the root of your infrastructure repository."
        exit 1
    fi
    
    # Run all validations
    validate_terraform
    echo ""
    
    validate_github_repo
    echo ""
    
    validate_aws_config
    echo ""
    
    validate_tfvars
    echo ""
    
    validate_userdata
    echo ""
    
    validate_github_secrets
    echo ""
    
    validate_documentation
    echo ""
    
    validate_scripts
    echo ""
    
    # Show summary
    show_summary
    
    # Exit with appropriate code
    if [ $CHECKS_FAILED -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Infrastructure Setup Validation Script"
    echo ""
    echo "Usage: $0"
    echo ""
    echo "This script validates your infrastructure setup including:"
    echo "  - Terraform configuration"
    echo "  - GitHub repository and branches"
    echo "  - AWS configuration"
    echo "  - tfvars files"
    echo "  - userdata scripts"
    echo "  - GitHub secrets"
    echo "  - Documentation"
    echo "  - Scripts and permissions"
    echo ""
    echo "Run this script from the root of your infrastructure repository."
    exit 0
fi

# Run main function
main "$@"