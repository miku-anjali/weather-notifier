# Weather Notifier

A simple weather notification service that sends weather updates to your email. It automatically detects your location and sends personalized weather information with helpful suggestions.

## What it does

- Gets current weather for any city or automatically detects your location
- Sends weather information to your email with smart suggestions (like "bring an umbrella" for rain)
- Runs completely free using AWS Lambda, Gmail, and OpenWeatherMap free APIs

## Prerequisites

- Java 11+
- Maven
- AWS CLI configured
- Terraform

## Setup (Free Version)

### 1. Get API Keys

**OpenWeatherMap (Free)**
1. Go to [openweathermap.org/api](https://openweathermap.org/api)
2. Sign up for free account
3. Get your API key (1000 calls/day free)

**Gmail App Password (Free)**
1. Enable 2-Factor Authentication on your Gmail
2. Go to [Google Account Security](https://myaccount.google.com/security)
3. Generate App Password for "Mail"
4. Copy the 16-character password

### 2. Configure Environment Variables

```bash
export OPENWEATHER_API_KEY="your_api_key_here"
export GMAIL_EMAIL="your-email@gmail.com"
export GMAIL_APP_PASSWORD="your_16_char_app_password"
```

### 3. Build and Deploy

```bash
# Build the project
./scripts/build.sh

# Deploy to AWS (free tier)
./scripts/test-free-deployment.sh
```

## How to Use

### Quick Test
```bash
# Send weather for your current location
./scripts/auto-weather.sh your-email@example.com
```

### Using AWS Lambda Directly
```bash
# Auto-detect location
aws lambda invoke --function-name weatherNotifier \
  --payload '{"email":"your-email@example.com"}' \
  result.json

# Specific city
aws lambda invoke --function-name weatherNotifier \
  --payload '{"email":"your-email@example.com","city":"London"}' \
  result.json
```

## What You Get

The service sends you an HTML email with:
- Current weather conditions and temperature
- Personalized suggestions based on weather (umbrella for rain, jacket for cold, etc.)
- Clean, easy-to-read format

## Cost

**$0.00** - Everything runs on free tiers:
- AWS Lambda: 1M free requests/month
- Gmail SMTP: Free (500 emails/day limit)
- OpenWeatherMap: 1000 free API calls/day
- CloudWatch Logs: 5GB free/month

## Troubleshooting

**Build fails?**
```bash
mvn clean
./scripts/build.sh
```

**Deployment issues?**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Validate Terraform
cd terraform && terraform validate
```

**No email received?**
- Check your Gmail app password is correct
- Make sure 2FA is enabled on Gmail
- Check spam folder

**Weather API errors?**
- Verify your OpenWeatherMap API key
- Check if you've exceeded 1000 daily calls

## Files

```
weather-notifier/
├── src/                    # Java source code
├── terraform/              # AWS infrastructure
├── scripts/                # Build and deployment scripts
├── pom.xml                 # Maven configuration
└── README.md               # This file
```
