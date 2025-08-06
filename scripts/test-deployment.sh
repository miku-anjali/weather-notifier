#!/bin/bash

# Weather Notifier - Post Deployment Testing Script

echo "🧪 Weather Notifier - Testing Deployment"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "ERROR" ]; then
        echo -e "${RED}❌ $message${NC}"
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    elif [ "$status" = "INFO" ]; then
        echo -e "${BLUE}ℹ️  $message${NC}"
    fi
}

# Read user input for test email
echo -e "${BLUE}Enter your email address for testing:${NC}"
read -p "Email: " TEST_EMAIL

if [ -z "$TEST_EMAIL" ]; then
    print_status "ERROR" "Email address is required"
    exit 1
fi

echo -e "\n${BLUE}1. Testing Lambda Function...${NC}"

# Test Lambda function directly
LAMBDA_PAYLOAD="{\"email\":\"$TEST_EMAIL\",\"city\":\"London\"}"
echo "Testing with payload: $LAMBDA_PAYLOAD"

if aws lambda invoke --function-name weatherNotifier \
   --payload "$LAMBDA_PAYLOAD" \
   /tmp/lambda-response.json > /dev/null 2>&1; then
    
    RESPONSE=$(cat /tmp/lambda-response.json)
    if [[ "$RESPONSE" == *"Notification sent"* ]]; then
        print_status "OK" "Lambda function executed successfully"
        print_status "INFO" "Response: $RESPONSE"
    else
        print_status "ERROR" "Lambda function returned unexpected response: $RESPONSE"
    fi
else
    print_status "ERROR" "Failed to invoke Lambda function"
fi

echo -e "\n${BLUE}2. Testing with Different Cities...${NC}"

CITIES=("Paris" "Tokyo" "New York" "Sydney")

for city in "${CITIES[@]}"; do
    PAYLOAD="{\"email\":\"$TEST_EMAIL\",\"city\":\"$city\"}"
    
    if aws lambda invoke --function-name weatherNotifier \
       --payload "$PAYLOAD" \
       /tmp/lambda-test-$city.json > /dev/null 2>&1; then
        
        RESPONSE=$(cat /tmp/lambda-test-$city.json)
        if [[ "$RESPONSE" == *"Notification sent"* ]]; then
            print_status "OK" "Weather notification for $city sent"
        else
            print_status "WARNING" "$city test returned: $RESPONSE"
        fi
    else
        print_status "ERROR" "Failed to test $city"
    fi
done

echo -e "\n${BLUE}3. Testing API Gateway Endpoint...${NC}"

# Get API Gateway URL from Terraform output
if [ -f "terraform/terraform.tfstate" ]; then
    API_URL=$(cd terraform && terraform output -raw api_gateway_url 2>/dev/null)
    
    if [ -n "$API_URL" ] && [ "$API_URL" != "null" ]; then
        print_status "INFO" "Testing API Gateway: $API_URL"
        
        API_PAYLOAD="{\"email\":\"$TEST_EMAIL\",\"city\":\"Berlin\"}"
        
        HTTP_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
                       -X POST "$API_URL" \
                       -H "Content-Type: application/json" \
                       -d "$API_PAYLOAD")
        
        HTTP_BODY=$(echo $HTTP_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
        HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -E 's/.*HTTPSTATUS:([0-9]{3})$/\1/')
        
        if [ "$HTTP_STATUS" = "200" ]; then
            print_status "OK" "API Gateway endpoint working (HTTP $HTTP_STATUS)"
            print_status "INFO" "API Response: $HTTP_BODY"
        else
            print_status "ERROR" "API Gateway returned HTTP $HTTP_STATUS: $HTTP_BODY"
        fi
    else
        print_status "WARNING" "API Gateway URL not found in terraform output"
    fi
else
    print_status "WARNING" "Terraform state not found, skipping API Gateway test"
fi

echo -e "\n${BLUE}4. Checking CloudWatch Logs...${NC}"

print_status "INFO" "Recent Lambda logs:"
aws logs tail /aws/lambda/weatherNotifier --since 5m --format short | head -10

echo -e "\n${BLUE}5. SES Email Status...${NC}"

# Check SES sending statistics
SES_STATS=$(aws ses get-send-statistics --query 'SendDataPoints[-1]' --output table 2>/dev/null)
if [ $? -eq 0 ]; then
    print_status "OK" "SES is operational"
    echo "Recent sending statistics:"
    echo "$SES_STATS"
else
    print_status "WARNING" "Could not retrieve SES statistics"
fi

echo -e "\n${BLUE}6. Summary${NC}"

print_status "INFO" "Test completed! Check your email for weather notifications"
print_status "INFO" "If you received emails, the deployment is successful!"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Check your email inbox for weather notifications"
echo "2. Monitor CloudWatch logs for any errors"
echo "3. Test the API endpoint with different payloads"
echo "4. Consider setting up CloudWatch alarms for monitoring"

echo -e "\n${BLUE}Useful Commands:${NC}"
echo "# View live logs:"
echo "aws logs tail /aws/lambda/weatherNotifier --follow"
echo ""
echo "# Test API with curl:"
echo "curl -X POST $API_URL \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"email\":\"$TEST_EMAIL\",\"city\":\"Madrid\"}'"

# Cleanup temporary files
rm -f /tmp/lambda-response.json /tmp/lambda-test-*.json

echo -e "\n🎉 Testing complete!"
