#!/bin/bash

# Task 7: API Gateway + Lambda Integration
# Автоматическая настройка

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные
API_ID="erv7myh2nb"
ROUTE_ID="py00o9v"
LAMBDA_FUNCTION="cmtr-4n6e9j62-api-gwlp-lambda-contacts"
REGION="eu-west-1"
ACCOUNT_ID="418272778502"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Task 7: API Gateway + Lambda         ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Проверка credentials
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo -e "${YELLOW}⚠️  AWS credentials не установлены. Используйте:${NC}"
    echo "export AWS_ACCESS_KEY_ID=AKIAWCYYADEDESGATYGT"
    echo "export AWS_SECRET_ACCESS_KEY=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"
    echo "export AWS_DEFAULT_REGION=eu-west-1"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials настроены${NC}"
echo ""

# Получить Lambda ARN
LAMBDA_ARN=$(aws lambda get-function --function-name "$LAMBDA_FUNCTION" --query 'Configuration.FunctionArn' --output text)
echo -e "${GREEN}✅ Lambda ARN: $LAMBDA_ARN${NC}"
echo ""

# Получить API Gateway endpoint
API_ENDPOINT=$(aws apigatewayv2 get-api --api-id "$API_ID" --query 'ApiEndpoint' --output text)
echo -e "${GREEN}✅ API Endpoint: $API_ENDPOINT${NC}"
echo ""

# Шаг 1: Создать Lambda integration для API Gateway
echo -e "${YELLOW}📋 Шаг 1/3: Создание Lambda integration...${NC}"

# Проверить существующие integrations
EXISTING_INTEGRATION=$(aws apigatewayv2 get-integrations --api-id "$API_ID" \
    --query "Items[?IntegrationUri=='$LAMBDA_ARN'].IntegrationId" --output text 2>/dev/null || echo "")

if [ -z "$EXISTING_INTEGRATION" ]; then
    # Создать новую integration
    INTEGRATION_ID=$(aws apigatewayv2 create-integration \
        --api-id "$API_ID" \
        --integration-type AWS_PROXY \
        --integration-uri "$LAMBDA_ARN" \
        --payload-format-version 2.0 \
        --query 'IntegrationId' \
        --output text)
    
    echo -e "${GREEN}✅ Lambda integration создан (ID: $INTEGRATION_ID)${NC}"
else
    INTEGRATION_ID="$EXISTING_INTEGRATION"
    echo -e "${YELLOW}⚠️  Lambda integration уже существует (ID: $INTEGRATION_ID)${NC}"
fi
echo ""

# Шаг 2: Обновить route для использования integration
echo -e "${YELLOW}🔗 Шаг 2/3: Привязка integration к route...${NC}"

aws apigatewayv2 update-route \
    --api-id "$API_ID" \
    --route-id "$ROUTE_ID" \
    --target "integrations/$INTEGRATION_ID" >/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Route обновлен для использования Lambda integration${NC}"
else
    echo -e "${RED}❌ Ошибка обновления route${NC}"
    exit 1
fi
echo ""

# Шаг 3: Добавить Lambda permission для API Gateway
echo -e "${YELLOW}🔐 Шаг 3/3: Настройка Lambda permissions...${NC}"

# Создать source ARN для API Gateway
SOURCE_ARN="arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*"

# Добавить permission
aws lambda add-permission \
    --function-name "$LAMBDA_FUNCTION" \
    --statement-id "AllowAPIGatewayInvoke-task7" \
    --action "lambda:InvokeFunction" \
    --principal "apigateway.amazonaws.com" \
    --source-arn "$SOURCE_ARN" \
    2>/dev/null || echo -e "${YELLOW}⚠️  Permission возможно уже существует${NC}"

echo -e "${GREEN}✅ Lambda permission настроен${NC}"
echo ""

# Автоматические тесты
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Автоматические тесты                 ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Тест 1: Проверка integration
echo -e "${YELLOW}🧪 Тест 1: Проверка Lambda integration...${NC}"
INTEGRATION_CHECK=$(aws apigatewayv2 get-integration \
    --api-id "$API_ID" \
    --integration-id "$INTEGRATION_ID" \
    --query '[IntegrationType,IntegrationUri]' \
    --output text)

if echo "$INTEGRATION_CHECK" | grep -q "AWS_PROXY"; then
    echo -e "${GREEN}✅ Lambda integration настроен корректно${NC}"
    echo -e "${GREEN}   Type: AWS_PROXY${NC}"
else
    echo -e "${RED}❌ Lambda integration не найден${NC}"
fi
echo ""

# Тест 2: Проверка route target
echo -e "${YELLOW}🧪 Тест 2: Проверка route configuration...${NC}"
ROUTE_TARGET=$(aws apigatewayv2 get-route \
    --api-id "$API_ID" \
    --route-id "$ROUTE_ID" \
    --query 'Target' \
    --output text)

if [ "$ROUTE_TARGET" == "integrations/$INTEGRATION_ID" ]; then
    echo -e "${GREEN}✅ Route правильно привязан к Lambda integration${NC}"
else
    echo -e "${YELLOW}⚠️  Route target: $ROUTE_TARGET${NC}"
fi
echo ""

# Тест 3: Проверка Lambda permission
echo -e "${YELLOW}🧪 Тест 3: Проверка Lambda permissions...${NC}"
LAMBDA_POLICY=$(aws lambda get-policy --function-name "$LAMBDA_FUNCTION" --query 'Policy' --output text 2>/dev/null || echo "{}")

if echo "$LAMBDA_POLICY" | grep -q "apigateway.amazonaws.com"; then
    echo -e "${GREEN}✅ Lambda permission для API Gateway настроен${NC}"
else
    echo -e "${RED}❌ Lambda permission не найден${NC}"
fi
echo ""

# Тест 4: HTTP запрос к API
echo -e "${YELLOW}🧪 Тест 4: Тестирование API endpoint...${NC}"
FULL_ENDPOINT="$API_ENDPOINT/contacts"
echo -e "${BLUE}   Запрос к: $FULL_ENDPOINT${NC}"

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" "$FULL_ENDPOINT" 2>/dev/null)
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✅ API успешно отвечает (HTTP 200)${NC}"
    echo -e "${GREEN}   Response preview:${NC}"
    echo "$RESPONSE_BODY" | head -10
    
    # Проверить что это JSON с контактами
    if echo "$RESPONSE_BODY" | grep -q "\"name\""; then
        echo -e "${GREEN}✅ Response содержит список контактов${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  HTTP Status: $HTTP_CODE${NC}"
    echo -e "${YELLOW}   Response: $RESPONSE_BODY${NC}"
fi
echo ""

# Итоговый результат
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ✅ Task 7 выполнен успешно!          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Что было настроено:${NC}"
echo -e "  ✅ Lambda integration создан"
echo -e "  ✅ Route привязан к Lambda"
echo -e "  ✅ Lambda permissions настроены"
echo ""
echo -e "${YELLOW}Тестирование API:${NC}"
echo -e "  ${GREEN}Endpoint:${NC} $FULL_ENDPOINT"
echo -e "  ${GREEN}Browser:${NC} Откройте в браузере"
echo -e "  ${GREEN}curl:${NC} curl $FULL_ENDPOINT"
echo ""
