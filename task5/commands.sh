#!/bin/bash

# Task 5: Lambda + API Gateway Permissions
# Готовые команды для ручного выполнения

# ===========================================
# CREDENTIALS
# ===========================================

export AWS_ACCESS_KEY_ID=AKIAR7HWYB7GGJEF5KH7
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# ===========================================
# ПЕРЕМЕННЫЕ
# ===========================================

ROLE_NAME="cmtr-4n6e9j62-iam-lp-iam_role"
LAMBDA_FUNCTION="cmtr-4n6e9j62-iam-lp-lambda"
API_NAME="cmtr-4n6e9j62-iam-lp-apigwv2_api"
REGION="eu-west-1"
ACCOUNT_ID="135808946124"

# Получить API Gateway ID
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='$API_NAME'].ApiId" --output text)
echo "API Gateway ID: $API_ID"

# Получить API Endpoint
API_ENDPOINT=$(aws apigatewayv2 get-apis --query "Items[?Name=='$API_NAME'].ApiEndpoint" --output text)
echo "API Endpoint: $API_ENDPOINT"

# ===========================================
# ШАГ 1: ATTACH MANAGED POLICY К EXECUTION ROLE
# ===========================================

# 1.1 Проверить текущие attached policies
aws iam list-attached-role-policies --role-name "$ROLE_NAME"

# 1.2 Attach AWSLambda_ReadOnlyAccess
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"

# 1.3 Проверить policy attached
aws iam list-attached-role-policies --role-name "$ROLE_NAME"

# 1.4 Проверить что роль может делать lambda:ListFunctions
aws iam simulate-principal-policy \
    --policy-source-arn "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME" \
    --action-names "lambda:ListFunctions" "lambda:GetFunction"

# ===========================================
# ШАГ 2: RESOURCE-BASED POLICY ДЛЯ LAMBDA
# ===========================================

# 2.1 Проверить текущую policy Lambda
aws lambda get-policy --function-name "$LAMBDA_FUNCTION"

# 2.2 Добавить permission для API Gateway
aws lambda add-permission \
    --function-name "$LAMBDA_FUNCTION" \
    --statement-id "AllowAPIGatewayInvoke" \
    --action "lambda:InvokeFunction" \
    --principal "apigateway.amazonaws.com" \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*"

# 2.3 Проверить policy после добавления
aws lambda get-policy --function-name "$LAMBDA_FUNCTION" | jq '.Policy | fromjson'

# 2.4 Альтернативный способ - через JSON
cat > lambda-permission.json << 'EOF'
{
  "StatementId": "AllowAPIGatewayInvoke",
  "Action": "lambda:InvokeFunction",
  "Principal": "apigateway.amazonaws.com",
  "SourceArn": "arn:aws:execute-api:REGION:ACCOUNT_ID:API_ID/*/*"
}
EOF

# ===========================================
# ВЕРИФИКАЦИЯ
# ===========================================

# Тест 1: Проверить Lambda function
aws lambda get-function --function-name "$LAMBDA_FUNCTION"

# Тест 2: Проверить execution role
aws iam get-role --role-name "$ROLE_NAME"

# Тест 3: Проверить attached policies
aws iam list-attached-role-policies --role-name "$ROLE_NAME"

# Тест 4: Проверить Lambda resource-based policy
aws lambda get-policy --function-name "$LAMBDA_FUNCTION"

# Тест 5: Проверить API Gateway
aws apigatewayv2 get-api --api-id "$API_ID"

# Тест 6: Получить API integrations
aws apigatewayv2 get-integrations --api-id "$API_ID"

# Тест 7: Проверить API routes
aws apigatewayv2 get-routes --api-id "$API_ID"

# ===========================================
# ПРАКТИЧЕСКОЕ ТЕСТИРОВАНИЕ
# ===========================================

# Тест 1: Invoke Lambda напрямую (если есть права)
aws lambda invoke \
    --function-name "$LAMBDA_FUNCTION" \
    --payload '{}' \
    response.json

cat response.json

# Тест 2: HTTP запрос к API Gateway
curl "$API_ENDPOINT"

# Тест 3: HTTP запрос с headers
curl -i "$API_ENDPOINT"

# Тест 4: Через browser
echo "Откройте в браузере: $API_ENDPOINT"

# ===========================================
# УДАЛЕНИЕ PERMISSION (CLEANUP)
# ===========================================

# Удалить Lambda permission
aws lambda remove-permission \
    --function-name "$LAMBDA_FUNCTION" \
    --statement-id "AllowAPIGatewayInvoke"

# Detach managed policy
aws iam detach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"

# ===========================================
# ДОПОЛНИТЕЛЬНЫЕ КОМАНДЫ
# ===========================================

# Получить Lambda code
aws lambda get-function --function-name "$LAMBDA_FUNCTION" --query 'Code.Location' --output text

# Download Lambda code
wget $(aws lambda get-function --function-name "$LAMBDA_FUNCTION" --query 'Code.Location' --output text) -O lambda-code.zip

# Unzip и посмотреть код
unzip lambda-code.zip
cat get_aws_users.py

# Получить Lambda environment variables
aws lambda get-function-configuration --function-name "$LAMBDA_FUNCTION" --query 'Environment'

# Получить Lambda logs
aws logs tail "/aws/lambda/$LAMBDA_FUNCTION" --follow

# CloudWatch Logs для Lambda
aws logs describe-log-streams \
    --log-group-name "/aws/lambda/$LAMBDA_FUNCTION" \
    --order-by LastEventTime \
    --descending

# ===========================================
# API GATEWAY ДОПОЛНИТЕЛЬНО
# ===========================================

# Получить все APIs
aws apigatewayv2 get-apis

# Получить stages
aws apigatewayv2 get-stages --api-id "$API_ID"

# Получить deployments
aws apigatewayv2 get-deployments --api-id "$API_ID"

# Получить authorizers (если есть)
aws apigatewayv2 get-authorizers --api-id "$API_ID"

# ===========================================
# ПОЛЕЗНЫЕ ССЫЛКИ
# ===========================================

# AWS Lambda Documentation:
# https://docs.aws.amazon.com/lambda/latest/dg/welcome.html

# API Gateway HTTP APIs:
# https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html

# Lambda Permissions:
# https://docs.aws.amazon.com/lambda/latest/dg/lambda-permissions.html

# Resource-based Policies:
# https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html
