# Provider and region
variable "region" {
  default = "us-east-1"
}

provider "aws" {
  region = var.region
}

# Variables
variable "openweather_api_key" {
  description = "OpenWeather API key"
  type        = string
  sensitive   = true
}

variable "from_email" {
  description = "Gmail address to send notifications from"
  type        = string
}

variable "smtp_password" {
  description = "Gmail app password (generate from Google Account settings)"
  type        = string
  sensitive   = true
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "weather_notifier_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for CloudWatch Logs only (no SES needed for free version)
resource "aws_iam_role_policy" "lambda_policy" {
  name = "weather_notifier_lambda_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "weather_notifier" {
  function_name    = "weatherNotifier"
  handler          = "notifier.WeatherHandler::handleRequest"
  runtime          = "java17"
  role             = aws_iam_role.lambda_exec.arn
  filename         = "../target/weather-notifier-1.0-SNAPSHOT.jar"
  source_code_hash = filebase64sha256("../target/weather-notifier-1.0-SNAPSHOT.jar")
  timeout          = 30
  memory_size      = 512

  environment {
    variables = {
      OPENWEATHER_API_KEY = var.openweather_api_key
      FROM_EMAIL          = var.from_email
      SMTP_PASSWORD       = var.smtp_password
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy
  ]
}

# API Gateway to capture real client IP (still FREE within limits)
resource "aws_api_gateway_rest_api" "weather_api" {
  name        = "weather-notifier-api"
  description = "API Gateway for Weather Notifier - Captures real client IP"
}

resource "aws_api_gateway_resource" "weather_resource" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  parent_id   = aws_api_gateway_rest_api.weather_api.root_resource_id
  path_part   = "weather"
}

resource "aws_api_gateway_method" "weather_method" {
  rest_api_id   = aws_api_gateway_rest_api.weather_api.id
  resource_id   = aws_api_gateway_resource.weather_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "weather_integration" {
  rest_api_id             = aws_api_gateway_rest_api.weather_api.id
  resource_id             = aws_api_gateway_resource.weather_resource.id
  http_method             = aws_api_gateway_method.weather_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.weather_notifier.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.weather_notifier.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.weather_api.execution_arn}/*/*"
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "weather_deploy" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id

  depends_on = [aws_api_gateway_integration.weather_integration]

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.weather_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.weather_api.id
  stage_name    = "prod"
}

# Outputs
output "lambda_function_name" {
  value = aws_lambda_function.weather_notifier.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.weather_notifier.arn
}

output "invocation_command" {
  value = "aws lambda invoke --function-name ${aws_lambda_function.weather_notifier.function_name} --payload '{\"email\":\"your@email.com\",\"city\":\"London\"}' response.json"
}
