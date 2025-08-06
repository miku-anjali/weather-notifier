#!/bin/bash

# Weather Notifier Deployment Validation Script
# set -e  # Don't exit on errors, we handle them manually

echo "🌤️  Weather Notifier - Pre-Deployment Validation"
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "ERROR" ]; then
        echo -e "${RED}❌ $message${NC}"
        ((ERRORS++))
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
        ((WARNINGS++))
    elif [ "$status" = "INFO" ]; then
        echo -e "${BLUE}ℹ️  $message${NC}"
    fi
}

echo -e "${BLUE}1. Checking Prerequisites...${NC}"

# Check if Java is installed
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
    print_status "OK" "Java is installed: $JAVA_VERSION"
else
    print_status "ERROR" "Java is not installed"
fi

# Check if Maven is installed
if command -v mvn &> /dev/null; then
    MAVEN_VERSION=$(mvn -version | head -1 | awk '{print $3}')
    print_status "OK" "Maven is installed: $MAVEN_VERSION"
else
    print_status "ERROR" "Maven is not installed"
fi

# Check if AWS CLI is installed
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d'/' -f2 | cut -d' ' -f1)
    print_status "OK" "AWS CLI is installed: $AWS_VERSION"
else
    print_status "ERROR" "AWS CLI is not installed"
fi

# Check if Terraform is installed
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform --version | head -1 | awk '{print $2}')
    print_status "OK" "Terraform is installed: $TERRAFORM_VERSION"
else
    print_status "ERROR" "Terraform is not installed"
fi

echo -e "\n${BLUE}2. Checking Project Structure...${NC}"

# Check if JAR file exists
if [ -f "target/weather-notifier-1.0-SNAPSHOT.jar" ]; then
    JAR_SIZE=$(du -h target/weather-notifier-1.0-SNAPSHOT.jar | cut -f1)
    print_status "OK" "JAR file exists: $JAR_SIZE"
else
    print_status "ERROR" "JAR file not found. Run ./build.sh first"
fi

# Check if all Java files exist
JAVA_FILES=(
    "src/main/java/notifier/WeatherHandler.java"
    "src/main/java/notifier/WeatherService.java"
    "src/main/java/notifier/EmailService.java"
    "src/main/java/notifier/GeoService.java"
    "src/main/java/notifier/SuggestionEngine.java"
)

for file in "${JAVA_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_status "OK" "$(basename $file) exists"
    else
        print_status "ERROR" "$(basename $file) not found"
    fi
done

# Check if terraform files exist
if [ -f "terraform/main.tf" ]; then
    print_status "OK" "main.tf exists"
else
    print_status "ERROR" "main.tf not found"
fi

if [ -f "terraform/terraform.tfvars" ]; then
    print_status "OK" "terraform.tfvars exists"
    # Check if variables are configured
    if grep -q "your_openweathermap_api_key_here" terraform/terraform.tfvars; then
        print_status "WARNING" "OpenWeather API key not configured in terraform.tfvars"
    else
        print_status "OK" "OpenWeather API key is configured"
    fi
    
    if grep -q "your-email@example.com" terraform/terraform.tfvars; then
        print_status "WARNING" "Email address not configured in terraform.tfvars"
    else
        print_status "OK" "Email address is configured"
    fi
else
    print_status "ERROR" "terraform.tfvars not found"
fi

echo -e "\n${BLUE}3. Validating Terraform Configuration...${NC}"

# Terraform validation
if (cd terraform && terraform validate > /dev/null 2>&1); then
    print_status "OK" "Terraform configuration is valid"
else
    print_status "ERROR" "Terraform configuration has errors"
fi

echo -e "\n${BLUE}4. Checking AWS Configuration...${NC}"

# Check AWS credentials
if aws sts get-caller-identity > /dev/null 2>&1; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_USER=$(aws sts get-caller-identity --query Arn --output text | cut -d'/' -f2)
    print_status "OK" "AWS credentials configured (Account: $AWS_ACCOUNT, User: $AWS_USER)"
else
    print_status "ERROR" "AWS credentials not configured. Run 'aws configure'"
fi

# Check default region
AWS_REGION=$(aws configure get region 2>/dev/null || echo "not-set")
if [ "$AWS_REGION" != "not-set" ]; then
    print_status "OK" "AWS region configured: $AWS_REGION"
else
    print_status "WARNING" "AWS region not configured, will use us-east-1"
fi

echo -e "\n${BLUE}5. Pre-Deployment Checklist:${NC}"

print_status "INFO" "Get OpenWeatherMap API key from: https://openweathermap.org/api"
print_status "INFO" "Verify your email in SES: aws ses verify-email-identity --email-address your@email.com"
print_status "INFO" "Configure terraform.tfvars with your actual API key and email"
print_status "INFO" "Review AWS costs: Lambda ~$0.20/1M requests, SES ~$0.10/1K emails"

echo -e "\n${BLUE}6. Summary:${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_status "OK" "All checks passed! Ready to deploy."
    echo -e "\n${GREEN}Next steps:${NC}"
    echo "1. Edit terraform.tfvars with your API keys"
    echo "2. Run: terraform plan"
    echo "3. Run: terraform apply"
elif [ $ERRORS -eq 0 ] && [ $WARNINGS -gt 0 ]; then
    print_status "WARNING" "$WARNINGS warnings found. Address them before deploying."
else
    print_status "ERROR" "$ERRORS errors found. Fix them before proceeding."
    exit 1
fi

echo -e "\n${BLUE}Deployment Commands:${NC}"
echo "terraform plan                    # Review what will be created"
echo "terraform apply                   # Deploy infrastructure"
echo "terraform destroy                 # Clean up resources"
