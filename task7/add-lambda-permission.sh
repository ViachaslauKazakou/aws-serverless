#!/bin/bash

# Task 7: Добавление Lambda Permission для API Gateway
# Позволяет API Gateway вызывать Lambda функцию

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Добавление Lambda Permission         ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Параметры (можно переопределить через environment variables)
LAMBDA_FUNCTION="${LAMBDA_FUNCTION:-task7-contacts-lambda}"
API_ID="${API_ID:-erv7myh2nb}"
REGION="${REGION:-eu-west-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

echo -e "${YELLOW}Конфигурация:${NC}"
echo -e "  Lambda: $LAMBDA_FUNCTION"
echo -e "  API ID: $API_ID"
echo -e "  Region: $REGION"
echo -e "  Account: $ACCOUNT_ID"
echo ""

# Проверить что Lambda существует
echo -e "${YELLOW}🔍 Проверка Lambda функции...${NC}"
LAMBDA_ARN=$(aws lambda get-function \
    --function-name "$LAMBDA_FUNCTION" \
    --query 'Configuration.FunctionArn' \
    --output text 2>/dev/null)

if [ -z "$LAMBDA_ARN" ]; then
    echo -e "${RED}❌ Lambda функция не найдена: $LAMBDA_FUNCTION${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Lambda ARN: $LAMBDA_ARN${NC}"
echo ""

# Проверить что API Gateway существует
echo -e "${YELLOW}🔍 Проверка API Gateway...${NC}"
API_NAME=$(aws apigatewayv2 get-api \
    --api-id "$API_ID" \
    --query 'Name' \
    --output text 2>/dev/null)

if [ -z "$API_NAME" ]; then
    echo -e "${RED}❌ API Gateway не найден: $API_ID${NC}"
    exit 1
fi

echo -e "${GREEN}✅ API Gateway: $API_NAME (ID: $API_ID)${NC}"
echo ""

# Source ARN для API Gateway
# Формат: arn:aws:execute-api:region:account-id:api-id/*/*
# Паттерн /*/* означает: любой stage / любой HTTP метод и path
SOURCE_ARN="arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*"

echo -e "${YELLOW}Source ARN: $SOURCE_ARN${NC}"
echo ""

# Добавить permission
echo -e "${YELLOW}🔐 Добавление permission...${NC}"

# Statement ID должен быть уникальным
STATEMENT_ID="AllowAPIGatewayInvoke-${API_ID}"

# Попытка добавить permission
ADD_RESULT=$(aws lambda add-permission \
    --function-name "$LAMBDA_FUNCTION" \
    --statement-id "$STATEMENT_ID" \
    --action "lambda:InvokeFunction" \
    --principal "apigateway.amazonaws.com" \
    --source-arn "$SOURCE_ARN" \
    --output json 2>&1)

# Проверить результат
if echo "$ADD_RESULT" | grep -q "ResourceConflictException"; then
    echo -e "${YELLOW}⚠️  Permission уже существует${NC}"
    
    # Предложить удалить и пересоздать
    echo -e "${YELLOW}Хотите удалить и пересоздать? (y/n)${NC}"
    read -r RESPONSE
    
    if [ "$RESPONSE" == "y" ]; then
        echo -e "${YELLOW}🗑️  Удаление существующего permission...${NC}"
        aws lambda remove-permission \
            --function-name "$LAMBDA_FUNCTION" \
            --statement-id "$STATEMENT_ID" \
            --output json > /dev/null
        
        echo -e "${GREEN}✅ Permission удален${NC}"
        
        echo -e "${YELLOW}🔐 Создание нового permission...${NC}"
        aws lambda add-permission \
            --function-name "$LAMBDA_FUNCTION" \
            --statement-id "$STATEMENT_ID" \
            --action "lambda:InvokeFunction" \
            --principal "apigateway.amazonaws.com" \
            --source-arn "$SOURCE_ARN" \
            --output json > /dev/null
        
        echo -e "${GREEN}✅ Permission пересоздан${NC}"
    fi
else
    echo -e "${GREEN}✅ Permission успешно добавлен${NC}"
fi

echo ""

# Верификация
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Верификация Permission                ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Получить policy Lambda функции
echo -e "${YELLOW}📋 Получение Lambda Policy...${NC}"
LAMBDA_POLICY=$(aws lambda get-policy \
    --function-name "$LAMBDA_FUNCTION" \
    --query 'Policy' \
    --output text 2>/dev/null)

if [ -n "$LAMBDA_POLICY" ]; then
    echo -e "${GREEN}✅ Lambda Policy существует${NC}"
    echo ""
    
    # Парсить и показать в удобном виде
    echo -e "${YELLOW}Policy содержимое:${NC}"
    echo "$LAMBDA_POLICY" | python3 -m json.tool 2>/dev/null | grep -A 15 "$STATEMENT_ID" || \
        echo "$LAMBDA_POLICY" | python3 -m json.tool 2>/dev/null
else
    echo -e "${RED}❌ Lambda Policy не найден${NC}"
fi

echo ""

# Проверить конкретные значения в policy
echo -e "${YELLOW}🧪 Проверка Policy параметров...${NC}"

# Проверить Principal
if echo "$LAMBDA_POLICY" | grep -q "apigateway.amazonaws.com"; then
    echo -e "${GREEN}✅ Principal: apigateway.amazonaws.com${NC}"
else
    echo -e "${RED}❌ Principal не найден${NC}"
fi

# Проверить Action
if echo "$LAMBDA_POLICY" | grep -q "lambda:InvokeFunction"; then
    echo -e "${GREEN}✅ Action: lambda:InvokeFunction${NC}"
else
    echo -e "${RED}❌ Action не найден${NC}"
fi

# Проверить Source ARN
if echo "$LAMBDA_POLICY" | grep -q "$API_ID"; then
    echo -e "${GREEN}✅ Source ARN содержит API ID: $API_ID${NC}"
else
    echo -e "${RED}❌ Source ARN не содержит API ID${NC}"
fi

echo ""

# Тест: попробовать вызвать через API Gateway
echo -e "${YELLOW}🧪 Тест: API Gateway -> Lambda...${NC}"

API_ENDPOINT=$(aws apigatewayv2 get-api \
    --api-id "$API_ID" \
    --query 'ApiEndpoint' \
    --output text)

FULL_ENDPOINT="$API_ENDPOINT/contacts"

echo -e "${BLUE}   URL: $FULL_ENDPOINT${NC}"
echo -e "${YELLOW}   Отправка HTTP GET запроса...${NC}"

# Подождать немного для propagation
sleep 2

HTTP_CODE=$(curl -s -o /tmp/api-response.json -w "%{http_code}" "$FULL_ENDPOINT" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✅ HTTP 200: Lambda успешно вызывается через API Gateway${NC}"
    echo ""
    echo -e "${YELLOW}Response (первые 10 строк):${NC}"
    cat /tmp/api-response.json | python3 -m json.tool 2>/dev/null | head -10 || cat /tmp/api-response.json | head -10
    rm -f /tmp/api-response.json
elif [ "$HTTP_CODE" == "403" ]; then
    echo -e "${RED}❌ HTTP 403: Forbidden - Permission не работает${NC}"
    echo -e "${YELLOW}Возможные причины:${NC}"
    echo -e "  1. Source ARN не совпадает с API Gateway ARN"
    echo -e "  2. Statement ID конфликтует с другим permission"
    echo -e "  3. Нужно подождать несколько секунд для propagation"
elif [ "$HTTP_CODE" == "404" ]; then
    echo -e "${YELLOW}⚠️  HTTP 404: Route не найден или не привязан к Lambda${NC}"
    echo -e "${YELLOW}Проверьте:${NC}"
    echo -e "  aws apigatewayv2 get-routes --api-id $API_ID"
elif [ "$HTTP_CODE" == "000" ]; then
    echo -e "${RED}❌ Не удалось подключиться к API${NC}"
else
    echo -e "${YELLOW}⚠️  HTTP $HTTP_CODE: Неожиданный ответ${NC}"
    cat /tmp/api-response.json 2>/dev/null || echo "(no response body)"
    rm -f /tmp/api-response.json
fi

echo ""

# Информация о Statement ID
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ℹ️  Дополнительная информация          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Statement ID: $STATEMENT_ID${NC}"
echo -e "${YELLOW}Source ARN: $SOURCE_ARN${NC}"
echo ""
echo -e "${YELLOW}Команды для управления permission:${NC}"
echo ""
echo -e "# Просмотр текущего policy"
echo -e "aws lambda get-policy --function-name $LAMBDA_FUNCTION | jq"
echo ""
echo -e "# Удаление permission"
echo -e "aws lambda remove-permission \\"
echo -e "    --function-name $LAMBDA_FUNCTION \\"
echo -e "    --statement-id $STATEMENT_ID"
echo ""
echo -e "# Добавление permission для конкретного route"
echo -e "# Формат Source ARN: arn:aws:execute-api:region:account:api-id/stage/method/path"
echo -e "aws lambda add-permission \\"
echo -e "    --function-name $LAMBDA_FUNCTION \\"
echo -e "    --statement-id AllowAPIGatewayInvokeGET \\"
echo -e "    --action lambda:InvokeFunction \\"
echo -e "    --principal apigateway.amazonaws.com \\"
echo -e "    --source-arn \"arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/GET/contacts\""
echo ""
echo -e "# Добавление permission для всех stages и routes (текущая конфигурация)"
echo -e "aws lambda add-permission \\"
echo -e "    --function-name $LAMBDA_FUNCTION \\"
echo -e "    --statement-id $STATEMENT_ID \\"
echo -e "    --action lambda:InvokeFunction \\"
echo -e "    --principal apigateway.amazonaws.com \\"
echo -e "    --source-arn \"$SOURCE_ARN\""
echo ""
echo -e "${YELLOW}Source ARN Паттерны:${NC}"
echo -e "  */*              - Все stages, все routes"
echo -e "  \$default/*       - Stage \$default, все routes"
echo -e "  */GET/contacts   - Все stages, только GET /contacts"
echo -e "  \$default/GET/*   - Stage \$default, все GET routes"
echo ""
echo -e "${GREEN}✅ Permission настроен!${NC}"
echo ""
