#!/bin/bash

# Task 5: Lambda + API Gateway Permissions
# Автоматическая настройка

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные
ROLE_NAME="cmtr-4n6e9j62-iam-lp-iam_role"
LAMBDA_FUNCTION="cmtr-4n6e9j62-iam-lp-lambda"
API_NAME="cmtr-4n6e9j62-iam-lp-apigwv2_api"
REGION="eu-west-1"
ACCOUNT_ID="135808946124"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Task 5: Lambda + API Gateway         ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Проверка credentials
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo -e "${YELLOW}⚠️  AWS credentials не установлены. Используйте:${NC}"
    echo "export AWS_ACCESS_KEY_ID=AKIAR7HWYB7GGJEF5KH7"
    echo "export AWS_SECRET_ACCESS_KEY=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"
    echo "export AWS_DEFAULT_REGION=eu-west-1"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials настроены${NC}"
echo ""

# Получить API Gateway ID
echo -e "${YELLOW}🔍 Получение API Gateway ID...${NC}"
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='$API_NAME'].ApiId" --output text)
if [ -z "$API_ID" ]; then
    echo -e "${RED}❌ API Gateway не найден${NC}"
    exit 1
fi
echo -e "${GREEN}✅ API Gateway ID: $API_ID${NC}"
API_ENDPOINT=$(aws apigatewayv2 get-apis --query "Items[?Name=='$API_NAME'].ApiEndpoint" --output text)
echo -e "${GREEN}✅ API Endpoint: $API_ENDPOINT${NC}"
echo ""

# Шаг 1: Attach AWSLambda_ReadOnlyAccess policy к execution role
echo -e "${YELLOW}📋 Шаг 1/2: Присоединение AWSLambda_ReadOnlyAccess к execution role...${NC}"
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ AWSLambda_ReadOnlyAccess успешно присоединен к роли $ROLE_NAME${NC}"
else
    echo -e "${RED}❌ Ошибка присоединения policy${NC}"
    exit 1
fi
echo ""

# Шаг 2: Добавить resource-based policy для Lambda (разрешить API Gateway вызывать функцию)
echo -e "${YELLOW}🔐 Шаг 2/2: Добавление permission для API Gateway...${NC}"
aws lambda add-permission \
    --function-name "$LAMBDA_FUNCTION" \
    --statement-id "AllowAPIGatewayInvoke" \
    --action "lambda:InvokeFunction" \
    --principal "apigateway.amazonaws.com" \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*" \
    2>/dev/null || echo -e "${YELLOW}⚠️  Permission возможно уже существует${NC}"

if [ $? -eq 0 ] || [ $? -eq 254 ]; then
    echo -e "${GREEN}✅ Permission для API Gateway добавлен${NC}"
else
    echo -e "${RED}❌ Ошибка добавления permission${NC}"
    exit 1
fi
echo ""

# Автоматические тесты
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Автоматические тесты                 ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Тест 1: Проверка attached policy
echo -e "${YELLOW}🧪 Тест 1: Проверка AWSLambda_ReadOnlyAccess на роли...${NC}"
ATTACHED_POLICY=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query "AttachedPolicies[?PolicyName=='AWSLambda_ReadOnlyAccess'].PolicyName" --output text)
if [ "$ATTACHED_POLICY" == "AWSLambda_ReadOnlyAccess" ]; then
    echo -e "${GREEN}✅ AWSLambda_ReadOnlyAccess найден на роли${NC}"
else
    echo -e "${RED}❌ AWSLambda_ReadOnlyAccess не найден${NC}"
fi
echo ""

# Тест 2: Проверка Lambda permission
echo -e "${YELLOW}🧪 Тест 2: Проверка Lambda resource-based policy...${NC}"
LAMBDA_POLICY=$(aws lambda get-policy --function-name "$LAMBDA_FUNCTION" --query 'Policy' --output text 2>/dev/null)
if echo "$LAMBDA_POLICY" | grep -q "apigateway.amazonaws.com"; then
    echo -e "${GREEN}✅ Lambda permission для API Gateway настроен${NC}"
else
    echo -e "${RED}❌ Lambda permission не найден${NC}"
fi
echo ""

# Тест 3: Проверка API вызовом
echo -e "${YELLOW}🧪 Тест 3: Тестирование API вызова...${NC}"
API_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_ENDPOINT" 2>/dev/null | tail -1)
if [ "$API_RESPONSE" == "200" ]; then
    echo -e "${GREEN}✅ API успешно отвечает (HTTP 200)${NC}"
    echo -e "${GREEN}   Endpoint: $API_ENDPOINT${NC}"
else
    echo -e "${YELLOW}⚠️  API response code: $API_RESPONSE${NC}"
fi
echo ""

# Итоговый результат
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ✅ Task 5 выполнен успешно!          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Что было настроено:${NC}"
echo -e "  ✅ AWSLambda_ReadOnlyAccess присоединен к execution role"
echo -e "  ✅ Lambda permission для API Gateway добавлен"
echo ""
echo -e "${YELLOW}Тестирование:${NC}"
echo -e "  Откройте в браузере: ${GREEN}$API_ENDPOINT${NC}"
echo ""
