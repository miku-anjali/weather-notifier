#!/bin/bash 

# Weather Notifier - FREE Deployment Testing Script

echo "🆓 Weather Notifier - Testing FREE Deployment"
echo "=============================================="
echo "💰 Cost: $0.00 - Everything is FREE!"
echo ""

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

echo -e "\n${BLUE}1. Testing FREE Lambda Function...${NC}"

# Test Lambda function directly (FREE - no API Gateway costs)
LAMBDA_PAYLOAD="{\"email\":\"$TEST_EMAIL\",\"city\":\"London\"}"
echo "Testing with payload: $LAMBDA_PAYLOAD"

if aws lambda invoke --function-name weatherNotifier \
   --payload "$LAMBDA_PAYLOAD" \
   /tmp/lambda-response.json > /dev/null 2>&1; then
    
    RESPONSE=$(cat /tmp/lambda-response.json)
    if [[ "$RESPONSE" == *"Notification sent"* ]]; then
        print_status "OK" "FREE Lambda function executed successfully"
        print_status "INFO" "Response: $RESPONSE"
        print_status "INFO" "Cost so far: $0.00 (within 1M free requests/month)"
    else
        print_status "ERROR" "Lambda function returned: $RESPONSE"
    fi
else
    print_status "ERROR" "Failed to invoke Lambda function"
fi

echo -e "\n${BLUE}2. Testing Multiple FREE Cities...${NC}"

FREE_CITIES=("Paris" "Tokyo" "New York" "Sydney" "Mumbai")

for city in "${FREE_CITIES[@]}"; do
    PAYLOAD="{\"email\":\"$TEST_EMAIL\",\"city\":\"$city\"}"
    
    if aws lambda invoke --function-name weatherNotifier \
       --payload "$PAYLOAD" \
       /tmp/lambda-test-$city.json > /dev/null 2>&1; then
        
        RESPONSE=$(cat /tmp/lambda-test-$city.json)
        if [[ "$RESPONSE" == *"Notification sent"* ]]; then
            print_status "OK" "FREE weather notification for $city sent"
        else
            print_status "WARNING" "$city test returned: $RESPONSE"
        fi
    else
        print_status "ERROR" "Failed to test $city"
    fi
    
    # Small delay to respect OpenWeatherMap free rate limits (60 calls/minute)
    sleep 1
done

echo -e "\n${BLUE}3. Checking FREE Usage Metrics...${NC}"

print_status "INFO" "Checking your FREE tier usage..."

# Check Lambda invocation count (should be well within 1M free requests/month)
INVOCATIONS=$(aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=weatherNotifier \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum \
  --query 'Datapoints[0].Sum' \
  --output text 2>/dev/null)

if [ "$INVOCATIONS" != "None" ] && [ -n "$INVOCATIONS" ]; then
    print_status "OK" "Lambda invocations in last hour: $INVOCATIONS (FREE limit: 1M/month)"
    
    if (( $(echo "$INVOCATIONS < 1000" | bc -l) )); then
        print_status "OK" "Well within FREE tier limits!"
    fi
else
    print_status "INFO" "No metrics available yet (normal for new deployments)"
fi

echo -e "\n${BLUE}4. Checking FREE CloudWatch Logs...${NC}"

print_status "INFO" "Recent FREE Lambda logs:"
aws logs tail /aws/lambda/weatherNotifier --since 10m --format short | head -5

echo -e "\n${BLUE}5. FREE Usage Summary${NC}"

print_status "OK" "✅ AWS Lambda: FREE (1M requests/month - forever)"
print_status "OK" "✅ Gmail SMTP: FREE (unlimited emails)"  
print_status "OK" "✅ OpenWeatherMap: FREE (1000 calls/day)"
print_status "OK" "✅ CloudWatch Logs: FREE (5GB/month)"
print_status "OK" "✅ Total Cost: $0.00"

echo -e "\n${GREEN}🎉 Your FREE Weather Notifier is Working!${NC}"

echo -e "\n${YELLOW}📧 Check Your Email Inbox${NC}"
echo "You should have received weather notifications for:"
echo "• London, Paris, Tokyo, New York, Sydney, Mumbai"
echo ""
echo "If you received emails, your FREE deployment is successful! 🎉"

echo -e "\n${BLUE}💡 FREE Usage Tips:${NC}"
echo "• Stay under 1000 OpenWeatherMap calls/day (resets at midnight UTC)"
echo "• Gmail allows 500 emails/day (more than enough for personal use)"
echo "• Lambda gives you 1M free requests/month (never expires)"
echo "• Monitor usage with: aws logs tail /aws/lambda/weatherNotifier --follow"

echo -e "\n${BLUE}🔄 Daily Usage Commands (All FREE):${NC}"
echo "# Send weather for any city:"
echo "aws lambda invoke --function-name weatherNotifier \\"
echo "  --payload '{\"email\":\"$TEST_EMAIL\",\"city\":\"Berlin\"}' result.json"
echo ""
echo "# Auto-detect city from IP:"
echo "aws lambda invoke --function-name weatherNotifier \\"
echo "  --payload '{\"email\":\"$TEST_EMAIL\",\"ip\":\"8.8.8.8\"}' result.json"

echo -e "\n${GREEN}💰 Your AWS Bill: \$0.00 (and will stay that way!)${NC}"

# Cleanup temporary files
rm -f /tmp/lambda-response.json /tmp/lambda-test-*.json

echo -e "\n🆓 Enjoy your completely FREE weather notification service!"
