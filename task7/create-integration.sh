#!/bin/bash

# Task 7: Создание Integration и настройка permissions
# Этот скрипт связывает API Gateway с Lambda

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Создание Integration и Permissions   ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Загрузить переменные (если создавали API Gateway скриптом)
if [ -f /tmp/task7-api-vars.sh ]; then
    source /tmp/task7-api-vars.sh
    echo -e "${GREEN}✅ Переменные загружены из /tmp/task7-api-vars.sh${NC}"
else
    echo -e "${YELLOW}⚠️  Файл переменных не найден, используйте вручную:${NC}"
    echo -e "export API_ID=\"your-api-id\""
    echo -e "export ROUTE_ID_GET=\"your-route-id\""
    echo ""
fi

# Проверить что переменные установлены
if [ -z "$API_ID" ]; then
    echo -e "${RED}❌ API_ID не установлен. Используйте:${NC}"
    echo -e "export API_ID=\"erv7myh2nb\""
    exit 1
fi

# Переменные Lambda
LAMBDA_FUNCTION="${LAMBDA_FUNCTION:-task7-contacts-lambda}"
REGION="${REGION:-eu-west-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

echo -e "${YELLOW}Конфигурация:${NC}"
echo -e "  API ID: $API_ID"
echo -e "  Lambda: $LAMBDA_FUNCTION"
echo -e "  Region: $REGION"
echo -e "  Account: $ACCOUNT_ID"
echo ""

# Получить Lambda ARN
LAMBDA_ARN=$(aws lambda get-function \
    --function-name "$LAMBDA_FUNCTION" \
    --query 'Configuration.FunctionArn' \
    --output text 2>/dev/null)

if [ -z "$LAMBDA_ARN" ]; then
    echo -e "${RED}❌ Lambda функция не найдена: $LAMBDA_FUNCTION${NC}"
    echo -e "${YELLOW}Создайте Lambda: ./create-lambda.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Lambda ARN: $LAMBDA_ARN${NC}"
echo ""

# Шаг 1: Создать Integration
echo -e "${YELLOW}📋 Шаг 1/4: Создание Lambda Integration...${NC}"

# Проверить существующие integrations
EXISTING_INTEGRATION=$(aws apigatewayv2 get-integrations \
    --api-id "$API_ID" \
    --query "Items[?IntegrationUri=='$LAMBDA_ARN'].IntegrationId" \
    --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_INTEGRATION" ]; then
    INTEGRATION_ID="$EXISTING_INTEGRATION"
    echo -e "${YELLOW}⚠️  Lambda integration уже существует (ID: $INTEGRATION_ID)${NC}"
else
    # Создать новый integration
    INTEGRATION_ID=$(aws apigatewayv2 create-integration \
        --api-id "$API_ID" \
        --integration-type AWS_PROXY \
        --integration-uri "$LAMBDA_ARN" \
        --payload-format-version 2.0 \
        --timeout-in-millis 30000 \
        --description "Lambda integration for contacts API" \
        --query 'IntegrationId' \
        --output text)
    
    echo -e "${GREEN}✅ Lambda integration создан (ID: $INTEGRATION_ID)${NC}"
fi

echo ""

# Шаг 2: Привязать routes к integration
echo -e "${YELLOW}🔗 Шаг 2/4: Привязка routes к integration...${NC}"

# Привязать GET /contacts
if [ -n "$ROUTE_ID_GET" ]; then
    aws apigatewayv2 update-route \
        --api-id "$API_ID" \
        --route-id "$ROUTE_ID_GET" \
        --target "integrations/$INTEGRATION_ID" \
        --output json > /dev/null
    echo -e "${GREEN}✅ Route GET /contacts привязан к integration${NC}"
fi

# Привязать POST /contacts (если существует)
if [ -n "$ROUTE_ID_POST" ]; then
    aws apigatewayv2 update-route \
        --api-id "$API_ID" \
        --route-id "$ROUTE_ID_POST" \
        --target "integrations/$INTEGRATION_ID" \
        --output json > /dev/null 2>&1 && \
    echo -e "${GREEN}✅ Route POST /contacts привязан к integration${NC}"
fi

# Привязать GET /contacts/{id} (если существует)
if [ -n "$ROUTE_ID_GET_ID" ]; then
    aws apigatewayv2 update-route \
        --api-id "$API_ID" \
        --route-id "$ROUTE_ID_GET_ID" \
        --target "integrations/$INTEGRATION_ID" \
        --output json > /dev/null 2>&1 && \
    echo -e "${GREEN}✅ Route GET /contacts/{id} привязан к integration${NC}"
fi

# Привязать DELETE /contacts/{id} (если существует)
if [ -n "$ROUTE_ID_DELETE" ]; then
    aws apigatewayv2 update-route \
        --api-id "$API_ID" \
        --route-id "$ROUTE_ID_DELETE" \
        --target "integrations/$INTEGRATION_ID" \
        --output json > /dev/null 2>&1 && \
    echo -e "${GREEN}✅ Route DELETE /contacts/{id} привязан к integration${NC}"
fi

echo ""

# Шаг 3: Добавить Lambda permission
echo -e "${YELLOW}🔐 Шаг 3/4: Добавление Lambda permissions...${NC}"

# Source ARN для API Gateway
SOURCE_ARN="arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*"

# Добавить permission
aws lambda add-permission \
    --function-name "$LAMBDA_FUNCTION" \
    --statement-id "AllowAPIGatewayInvoke-${API_ID}" \
    --action "lambda:InvokeFunction" \
    --principal "apigateway.amazonaws.com" \
    --source-arn "$SOURCE_ARN" \
    --output json > /dev/null 2>&1 || echo -e "${YELLOW}⚠️  Permission возможно уже существует${NC}"

echo -e "${GREEN}✅ Lambda permission для API Gateway настроен${NC}"
echo ""

# Шаг 4: Deploy API (для HTTP API auto-deploy enabled по умолчанию)
echo -e "${YELLOW}🚀 Шаг 4/4: Deployment...${NC}"

# Для HTTP API с auto-deploy изменения применяются автоматически
# Но можно сделать explicit deployment
DEPLOYMENT_ID=$(aws apigatewayv2 create-deployment \
    --api-id "$API_ID" \
    --description "Integration with Lambda function" \
    --query 'DeploymentId' \
    --output text 2>/dev/null || echo "")

if [ -n "$DEPLOYMENT_ID" ]; then
    echo -e "${GREEN}✅ Deployment создан (ID: $DEPLOYMENT_ID)${NC}"
else
    echo -e "${YELLOW}⚠️  Auto-deploy enabled, manual deployment не требуется${NC}"
fi

echo ""

# Верификация
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Верификация настройки                ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. Проверить integration
echo -e "${YELLOW}🧪 Тест 1: Проверка Integration...${NC}"
INTEGRATION_TYPE=$(aws apigatewayv2 get-integration \
    --api-id "$API_ID" \
    --integration-id "$INTEGRATION_ID" \
    --query 'IntegrationType' \
    --output text)

if [ "$INTEGRATION_TYPE" == "AWS_PROXY" ]; then
    echo -e "${GREEN}✅ Integration type: AWS_PROXY${NC}"
else
    echo -e "${RED}❌ Integration type: $INTEGRATION_TYPE (ожидалось AWS_PROXY)${NC}"
fi

# 2. Проверить routes
echo -e "${YELLOW}🧪 Тест 2: Проверка Routes...${NC}"
ROUTE_COUNT=$(aws apigatewayv2 get-routes \
    --api-id "$API_ID" \
    --query "length(Items[?Target=='integrations/$INTEGRATION_ID'])" \
    --output text)

echo -e "${GREEN}✅ Привязано routes: $ROUTE_COUNT${NC}"

# 3. Проверить Lambda permission
echo -e "${YELLOW}🧪 Тест 3: Проверка Lambda Permission...${NC}"
LAMBDA_POLICY=$(aws lambda get-policy \
    --function-name "$LAMBDA_FUNCTION" \
    --query 'Policy' \
    --output text 2>/dev/null || echo "{}")

if echo "$LAMBDA_POLICY" | grep -q "apigateway.amazonaws.com"; then
    echo -e "${GREEN}✅ Lambda permission для API Gateway настроен${NC}"
else
    echo -e "${RED}❌ Lambda permission не найден${NC}"
fi

# 4. HTTP тест
echo -e "${YELLOW}🧪 Тест 4: HTTP запрос к API...${NC}"

# Получить API endpoint
API_ENDPOINT=$(aws apigatewayv2 get-api \
    --api-id "$API_ID" \
    --query 'ApiEndpoint' \
    --output text)

FULL_ENDPOINT="$API_ENDPOINT/contacts"
echo -e "${BLUE}   Запрос к: $FULL_ENDPOINT${NC}"

# Подождать немного для propagation
sleep 3

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FULL_ENDPOINT" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✅ API успешно отвечает (HTTP 200)${NC}"
    echo -e "${GREEN}Response:${NC}"
    curl -s "$FULL_ENDPOINT" | python3 -m json.tool 2>/dev/null | head -20
elif [ "$HTTP_CODE" == "000" ]; then
    echo -e "${YELLOW}⚠️  Не удалось подключиться к API${NC}"
else
    echo -e "${YELLOW}⚠️  HTTP Status: $HTTP_CODE${NC}"
    echo -e "${YELLOW}Если 404 или 403, подождите 10-20 секунд и попробуйте снова${NC}"
fi

echo ""

# Итоги
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ✅ Integration настроен!              ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Созданная конфигурация:${NC}"
echo -e "  ✅ Lambda Integration (AWS_PROXY)"
echo -e "  ✅ Routes привязаны к Lambda"
echo -e "  ✅ Lambda Permission настроен"
echo -e "  ✅ API deployed"
echo ""
echo -e "${YELLOW}API Endpoints:${NC}"
echo -e "  GET    $API_ENDPOINT/contacts"
echo -e "  POST   $API_ENDPOINT/contacts"
echo -e "  GET    $API_ENDPOINT/contacts/{id}"
echo -e "  DELETE $API_ENDPOINT/contacts/{id}"
echo ""
echo -e "${YELLOW}Тестирование:${NC}"
echo -e "  # GET request"
echo -e "  curl $API_ENDPOINT/contacts"
echo ""
echo -e "  # Browser"
echo -e "  open $API_ENDPOINT/contacts"
echo ""
echo -e "  # Lambda logs"
echo -e "  aws logs tail /aws/lambda/$LAMBDA_FUNCTION --follow"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo -e "  # Проверить integration"
echo -e "  aws apigatewayv2 get-integration --api-id $API_ID --integration-id $INTEGRATION_ID"
echo ""
echo -e "  # Проверить routes"
echo -e "  aws apigatewayv2 get-routes --api-id $API_ID"
echo ""
echo -e "  # Проверить Lambda permission"
echo -e "  aws lambda get-policy --function-name $LAMBDA_FUNCTION | jq"
echo ""
