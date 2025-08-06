#!/bin/bash

# Weather Notifier Build and Deployment Script

set -e

echo "🌤️  Weather Notifier Build Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}❌ Maven is not installed. Please install Maven first.${NC}"
    exit 1
fi

# Clean and compile
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
mvn clean

echo -e "${YELLOW}🔨 Compiling and packaging...${NC}"
mvn package

# Check if JAR was created
JAR_FILE="target/weather-notifier-1.0-SNAPSHOT.jar"
if [ -f "$JAR_FILE" ]; then
    echo -e "${GREEN}✅ JAR file created successfully: $JAR_FILE${NC}"
    echo -e "${GREEN}📦 File size: $(du -h $JAR_FILE | cut -f1)${NC}"
else
    echo -e "${RED}❌ JAR file not found. Build may have failed.${NC}"
    exit 1
fi

# Run tests
echo -e "${YELLOW}🧪 Running tests...${NC}"
mvn test

echo -e "${GREEN}🎉 Build completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Configure your terraform.tfvars file"
echo "2. Run: cd terraform && terraform apply"
echo "3. Or deploy with Ansible: ansible-playbook ansible/playbook.yml"
