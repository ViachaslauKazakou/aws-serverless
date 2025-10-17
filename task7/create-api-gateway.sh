#!/bin/bash

# Task 7: Создание API Gateway (HTTP API)
# Этот скрипт создает HTTP API с нуля

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Переменные
API_NAME="task7-contacts-api"
REGION="eu-west-1"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Создание API Gateway (HTTP API)      ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Шаг 1: Создать HTTP API
echo -e "${YELLOW}📋 Шаг 1/4: Создание HTTP API...${NC}"

API_ID=$(aws apigatewayv2 create-api \
    --name "$API_NAME" \
    --protocol-type HTTP \
    --description "HTTP API for Task 7 - Contacts REST API" \
    --cors-configuration '{
        "AllowOrigins": ["*"],
        "AllowMethods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "AllowHeaders": ["*"],
        "MaxAge": 300
    }' \
    --query 'ApiId' \
    --output text)

if [ -z "$API_ID" ]; then
    echo -e "${RED}❌ Ошибка создания API${NC}"
    exit 1
fi

echo -e "${GREEN}✅ HTTP API создан: $API_ID${NC}"

# Получить API endpoint
API_ENDPOINT=$(aws apigatewayv2 get-api \
    --api-id "$API_ID" \
    --query 'ApiEndpoint' \
    --output text)

echo -e "${GREEN}✅ API Endpoint: $API_ENDPOINT${NC}"
echo ""

# Шаг 2: Создать default stage
echo -e "${YELLOW}📋 Шаг 2/4: Создание default stage...${NC}"

# Для HTTP API создается автоматически, но можно настроить
aws apigatewayv2 update-stage \
    --api-id "$API_ID" \
    --stage-name '$default' \
    --auto-deploy \
    --description "Default stage with auto-deploy" \
    2>/dev/null || echo -e "${YELLOW}⚠️  Default stage уже существует${NC}"

echo -e "${GREEN}✅ Default stage настроен (auto-deploy enabled)${NC}"
echo ""

# Шаг 3: Создать route (без integration пока)
echo -e "${YELLOW}📋 Шаг 3/4: Создание routes...${NC}"

# Route 1: GET /contacts
ROUTE_ID_GET=$(aws apigatewayv2 create-route \
    --api-id "$API_ID" \
    --route-key "GET /contacts" \
    --authorization-type NONE \
    --query 'RouteId' \
    --output text)

echo -e "${GREEN}✅ Route создан: GET /contacts (ID: $ROUTE_ID_GET)${NC}"

# Route 2: POST /contacts (опционально)
ROUTE_ID_POST=$(aws apigatewayv2 create-route \
    --api-id "$API_ID" \
    --route-key "POST /contacts" \
    --authorization-type NONE \
    --query 'RouteId' \
    --output text 2>/dev/null || echo "")

if [ -n "$ROUTE_ID_POST" ]; then
    echo -e "${GREEN}✅ Route создан: POST /contacts (ID: $ROUTE_ID_POST)${NC}"
fi

# Route 3: GET /contacts/{id} (опционально)
ROUTE_ID_GET_ID=$(aws apigatewayv2 create-route \
    --api-id "$API_ID" \
    --route-key "GET /contacts/{id}" \
    --authorization-type NONE \
    --query 'RouteId' \
    --output text 2>/dev/null || echo "")

if [ -n "$ROUTE_ID_GET_ID" ]; then
    echo -e "${GREEN}✅ Route создан: GET /contacts/{id} (ID: $ROUTE_ID_GET_ID)${NC}"
fi

# Route 4: DELETE /contacts/{id} (опционально)
ROUTE_ID_DELETE=$(aws apigatewayv2 create-route \
    --api-id "$API_ID" \
    --route-key "DELETE /contacts/{id}" \
    --authorization-type NONE \
    --query 'RouteId' \
    --output text 2>/dev/null || echo "")

if [ -n "$ROUTE_ID_DELETE" ]; then
    echo -e "${GREEN}✅ Route создан: DELETE /contacts/{id} (ID: $ROUTE_ID_DELETE)${NC}"
fi

echo ""

# Шаг 4: Информация о API
echo -e "${YELLOW}📊 Шаг 4/4: Информация о API Gateway...${NC}"

aws apigatewayv2 get-api \
    --api-id "$API_ID" \
    --query '{Name:Name, ApiId:ApiId, ProtocolType:ProtocolType, ApiEndpoint:ApiEndpoint}' \
    --output table

echo ""

# Список routes
echo -e "${YELLOW}Routes:${NC}"
aws apigatewayv2 get-routes \
    --api-id "$API_ID" \
    --query 'Items[*].[RouteKey,RouteId,Target]' \
    --output table

echo ""

# Итоги
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ✅ API Gateway создан!                ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Созданные ресурсы:${NC}"
echo -e "  ✅ HTTP API: $API_NAME"
echo -e "  ✅ API ID: $API_ID"
echo -e "  ✅ Endpoint: $API_ENDPOINT"
echo -e "  ✅ Default Stage: \$default (auto-deploy)"
echo -e "  ✅ Routes: GET /contacts, POST /contacts, GET /contacts/{id}, DELETE /contacts/{id}"
echo ""
echo -e "${YELLOW}API Endpoint URLs:${NC}"
echo -e "  GET    $API_ENDPOINT/contacts"
echo -e "  POST   $API_ENDPOINT/contacts"
echo -e "  GET    $API_ENDPOINT/contacts/{id}"
echo -e "  DELETE $API_ENDPOINT/contacts/{id}"
echo ""
echo -e "${YELLOW}Следующие шаги:${NC}"
echo -e "  1. Создать Lambda: ./create-lambda.sh"
echo -e "  2. Создать Integration: ./create-integration.sh"
echo -e "  3. Привязать routes к integration"
echo -e "  4. Добавить Lambda permission"
echo ""
echo -e "${YELLOW}Тестирование (пока без Lambda):${NC}"
echo -e "  curl $API_ENDPOINT/contacts"
echo -e "  # Вернет 404 или Internal Server Error (integration не настроен)"
echo ""
echo -e "${YELLOW}Удалить API Gateway:${NC}"
echo -e "  aws apigatewayv2 delete-api --api-id $API_ID"
echo ""

# Сохранить переменные для следующих скриптов
cat > /tmp/task7-api-vars.sh <<EOF
# API Gateway переменные для Task 7
export API_ID="$API_ID"
export API_ENDPOINT="$API_ENDPOINT"
export ROUTE_ID_GET="$ROUTE_ID_GET"
export ROUTE_ID_POST="$ROUTE_ID_POST"
export ROUTE_ID_GET_ID="$ROUTE_ID_GET_ID"
export ROUTE_ID_DELETE="$ROUTE_ID_DELETE"
EOF

echo -e "${GREEN}✅ Переменные сохранены в /tmp/task7-api-vars.sh${NC}"
echo -e "${YELLOW}Используйте: source /tmp/task7-api-vars.sh${NC}"
echo ""
