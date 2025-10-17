#!/bin/bash

# Task 7: API Gateway + Lambda Integration
# Готовые команды для ручного выполнения

# ===========================================
# CREDENTIALS
# ===========================================

export AWS_ACCESS_KEY_ID=AKIAWCYYADEDESGATYGT
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# ===========================================
# ПЕРЕМЕННЫЕ
# ===========================================

API_ID="erv7myh2nb"
ROUTE_ID="py00o9v"
LAMBDA_FUNCTION="cmtr-4n6e9j62-api-gwlp-lambda-contacts"
REGION="eu-west-1"
ACCOUNT_ID="418272778502"

# ===========================================
# ПРОВЕРКА СУЩЕСТВУЮЩИХ РЕСУРСОВ
# ===========================================

# Проверить API Gateway
aws apigatewayv2 get-api --api-id $API_ID

# Получить API endpoint
aws apigatewayv2 get-api --api-id $API_ID --query '[ApiEndpoint,Name,ProtocolType]' --output table

# Список всех routes
aws apigatewayv2 get-routes --api-id $API_ID

# Детали конкретного route
aws apigatewayv2 get-route --api-id $API_ID --route-id $ROUTE_ID

# Проверить Lambda function
aws lambda get-function --function-name $LAMBDA_FUNCTION

# Lambda configuration
aws lambda get-function-configuration --function-name $LAMBDA_FUNCTION --query '[FunctionName,Runtime,Handler,State]' --output table

# Lambda ARN
LAMBDA_ARN=$(aws lambda get-function --function-name $LAMBDA_FUNCTION --query 'Configuration.FunctionArn' --output text)
echo "Lambda ARN: $LAMBDA_ARN"

# ===========================================
# ШАГ 1: СОЗДАТЬ LAMBDA INTEGRATION
# ===========================================

# 1.1 Проверить существующие integrations
aws apigatewayv2 get-integrations --api-id $API_ID

# 1.2 Создать Lambda integration
aws apigatewayv2 create-integration \
    --api-id $API_ID \
    --integration-type AWS_PROXY \
    --integration-uri $LAMBDA_ARN \
    --payload-format-version 2.0

# 1.3 Получить Integration ID
INTEGRATION_ID=$(aws apigatewayv2 get-integrations --api-id $API_ID \
    --query "Items[?IntegrationUri=='$LAMBDA_ARN'].IntegrationId" --output text)
echo "Integration ID: $INTEGRATION_ID"

# 1.4 Проверить детали integration
aws apigatewayv2 get-integration \
    --api-id $API_ID \
    --integration-id $INTEGRATION_ID

# 1.5 Альтернативный способ создания с дополнительными параметрами
aws apigatewayv2 create-integration \
    --api-id $API_ID \
    --integration-type AWS_PROXY \
    --integration-method POST \
    --integration-uri $LAMBDA_ARN \
    --payload-format-version 2.0 \
    --timeout-in-millis 30000

# ===========================================
# ШАГ 2: ПРИВЯЗАТЬ INTEGRATION К ROUTE
# ===========================================

# 2.1 Проверить текущий route target
aws apigatewayv2 get-route \
    --api-id $API_ID \
    --route-id $ROUTE_ID \
    --query '[RouteKey,Target]' \
    --output table

# 2.2 Обновить route для использования Lambda integration
aws apigatewayv2 update-route \
    --api-id $API_ID \
    --route-id $ROUTE_ID \
    --target "integrations/$INTEGRATION_ID"

# 2.3 Проверить что route обновлен
aws apigatewayv2 get-route \
    --api-id $API_ID \
    --route-id $ROUTE_ID

# 2.4 Альтернативный способ - создать новый route (если нужен)
aws apigatewayv2 create-route \
    --api-id $API_ID \
    --route-key "GET /contacts" \
    --target "integrations/$INTEGRATION_ID"

# ===========================================
# ШАГ 3: НАСТРОИТЬ LAMBDA PERMISSIONS
# ===========================================

# 3.1 Проверить текущие Lambda permissions
aws lambda get-policy --function-name $LAMBDA_FUNCTION

# 3.2 Добавить permission для API Gateway
SOURCE_ARN="arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*"

aws lambda add-permission \
    --function-name $LAMBDA_FUNCTION \
    --statement-id AllowAPIGatewayInvoke-task7 \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn $SOURCE_ARN

# 3.3 Проверить что permission добавлен
aws lambda get-policy --function-name $LAMBDA_FUNCTION | jq '.Policy | fromjson'

# 3.4 Более специфичный source ARN (только для конкретного route)
SOURCE_ARN_SPECIFIC="arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/GET/contacts"

aws lambda add-permission \
    --function-name $LAMBDA_FUNCTION \
    --statement-id AllowAPIGatewayInvokeSpecific \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn $SOURCE_ARN_SPECIFIC

# ===========================================
# ВЕРИФИКАЦИЯ
# ===========================================

# Тест 1: Проверить API Gateway configuration
aws apigatewayv2 get-api --api-id $API_ID --query '[Name,ApiEndpoint,ProtocolType]' --output table

# Тест 2: Проверить routes
aws apigatewayv2 get-routes --api-id $API_ID --query 'Items[*].[RouteKey,Target]' --output table

# Тест 3: Проверить integrations
aws apigatewayv2 get-integrations --api-id $API_ID --query 'Items[*].[IntegrationId,IntegrationType,IntegrationUri]' --output table

# Тест 4: HTTP запрос к API
API_ENDPOINT=$(aws apigatewayv2 get-api --api-id $API_ID --query 'ApiEndpoint' --output text)
curl "$API_ENDPOINT/contacts"

# Тест 5: HTTP запрос с headers
curl -i "$API_ENDPOINT/contacts"

# Тест 6: Через browser
echo "Open in browser: $API_ENDPOINT/contacts"

# Тест 7: Проверить Lambda invocations
aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Invocations \
    --dimensions Name=FunctionName,Value=$LAMBDA_FUNCTION \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum

# ===========================================
# МОНИТОРИНГ И ЛОГИ
# ===========================================

# Lambda logs
aws logs tail /aws/lambda/$LAMBDA_FUNCTION --follow

# Последние 50 log events
aws logs tail /aws/lambda/$LAMBDA_FUNCTION --since 10m

# API Gateway access logs (если настроены)
aws apigatewayv2 get-stage --api-id $API_ID --stage-name '$default' --query 'AccessLogSettings'

# Lambda errors
aws logs filter-log-events \
    --log-group-name /aws/lambda/$LAMBDA_FUNCTION \
    --filter-pattern "ERROR" \
    --max-items 10

# ===========================================
# ДОПОЛНИТЕЛЬНЫЕ ОПЕРАЦИИ
# ===========================================

# Получить Lambda code
CODE_URL=$(aws lambda get-function --function-name $LAMBDA_FUNCTION --query 'Code.Location' --output text)
curl -o lambda-code.zip "$CODE_URL"
unzip lambda-code.zip
cat index.js  # или другой handler file

# Test Lambda локально (invoke напрямую)
aws lambda invoke \
    --function-name $LAMBDA_FUNCTION \
    --payload '{"httpMethod":"GET","path":"/contacts"}' \
    response.json

cat response.json

# Получить API Gateway stages
aws apigatewayv2 get-stages --api-id $API_ID

# Получить default stage
aws apigatewayv2 get-stage --api-id $API_ID --stage-name '$default'

# Deploy API (если нужно)
aws apigatewayv2 create-deployment --api-id $API_ID

# ===========================================
# TROUBLESHOOTING
# ===========================================

# Problem: API returns 500 Internal Server Error
# 1. Проверить Lambda logs
aws logs tail /aws/lambda/$LAMBDA_FUNCTION --since 5m

# 2. Проверить Lambda state
aws lambda get-function-configuration --function-name $LAMBDA_FUNCTION --query 'State'

# 3. Test Lambda напрямую
aws lambda invoke --function-name $LAMBDA_FUNCTION --payload '{}' test-output.json
cat test-output.json

# Problem: API returns 403 Forbidden
# 1. Проверить Lambda permission
aws lambda get-policy --function-name $LAMBDA_FUNCTION

# 2. Проверить source ARN
aws lambda get-policy --function-name $LAMBDA_FUNCTION | jq '.Policy | fromjson | .Statement[] | select(.Principal.Service == "apigateway.amazonaws.com")'

# Problem: Route не работает
# 1. Проверить route target
aws apigatewayv2 get-route --api-id $API_ID --route-id $ROUTE_ID --query 'Target'

# 2. Проверить что integration существует
aws apigatewayv2 get-integration --api-id $API_ID --integration-id $INTEGRATION_ID

# Problem: Lambda не вызывается
# 1. Проверить integration type
aws apigatewayv2 get-integration --api-id $API_ID --integration-id $INTEGRATION_ID --query 'IntegrationType'

# 2. Должен быть AWS_PROXY для Lambda
# 3. Проверить payload format version
aws apigatewayv2 get-integration --api-id $API_ID --integration-id $INTEGRATION_ID --query 'PayloadFormatVersion'

# ===========================================
# CLEANUP (удаление настроек)
# ===========================================

# Удалить route target
aws apigatewayv2 update-route \
    --api-id $API_ID \
    --route-id $ROUTE_ID \
    --target ""

# Удалить integration
aws apigatewayv2 delete-integration \
    --api-id $API_ID \
    --integration-id $INTEGRATION_ID

# Удалить Lambda permission
aws lambda remove-permission \
    --function-name $LAMBDA_FUNCTION \
    --statement-id AllowAPIGatewayInvoke-task7

# Проверить что удалено
aws apigatewayv2 get-integrations --api-id $API_ID
aws lambda get-policy --function-name $LAMBDA_FUNCTION

# ===========================================
# ПОЛЕЗНЫЕ ССЫЛКИ
# ===========================================

# API Gateway HTTP APIs:
# https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html

# Lambda Proxy Integration:
# https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html

# API Gateway + Lambda:
# https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html

# Payload Format Version 2.0:
# https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html
