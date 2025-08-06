#!/bin/bash

# AUTO WEATHER NOTIFIER - Just provide email, location auto-detected!
echo "🌍 AUTO Weather Notifier - FREE IP-based Location Detection"
echo "=========================================================="

if [ -z "$1" ]; then
    echo "Usage: ./auto-weather.sh your-email@example.com"
    echo "Example: ./auto-weather.sh just47721@gmail.com"
    exit 1
fi

EMAIL=$1

echo "📧 Sending weather notification to: $EMAIL"
echo "🎯 Location will be AUTO-DETECTED from your IP address..."
echo "💰 Cost: $0.00 (completely FREE!)"
echo ""

# Send auto-location weather (no city or IP needed - Lambda will detect)
aws lambda invoke --function-name weatherNotifier \
  --cli-binary-format raw-in-base64-out \
  --payload "{\"email\":\"$EMAIL\"}" \
  /tmp/auto_weather_result.json

echo ""
echo "🎯 Result:"
cat /tmp/auto_weather_result.json
echo ""
echo ""
echo "📧 Check your email for the weather notification!"
echo "🌤️ The system automatically detected your location and sent local weather."

# Cleanup
rm -f /tmp/auto_weather_result.json
