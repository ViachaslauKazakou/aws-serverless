#!/bin/bash

# Task 7: Создание Lambda функции для API Gateway
# Этот скрипт создает Lambda с нуля

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Переменные
FUNCTION_NAME="task7-contacts-lambda"
RUNTIME="python3.11"  # или nodejs18.x, nodejs20.x
HANDLER="index.handler"  # или index.lambda_handler для Python
ROLE_NAME="task7-lambda-execution-role"
REGION="eu-west-1"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Создание Lambda функции              ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Шаг 1: Создать Lambda execution role
echo -e "${YELLOW}📋 Шаг 1/5: Создание IAM Role для Lambda...${NC}"

# Trust policy для Lambda
cat > /tmp/lambda-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Создать role
aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file:///tmp/lambda-trust-policy.json \
    --description "Execution role for Task 7 Lambda function" \
    2>/dev/null || echo -e "${YELLOW}⚠️  Role уже существует${NC}"

# Добавить managed policy для CloudWatch Logs
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" \
    2>/dev/null || echo -e "${YELLOW}⚠️  Policy уже прикреплена${NC}"

# Получить Role ARN
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
echo -e "${GREEN}✅ IAM Role создан: $ROLE_ARN${NC}"
echo ""

# Подождать пока role будет готов
echo -e "${YELLOW}⏳ Ожидание 10 секунд для propagation IAM role...${NC}"
sleep 10

# Шаг 2: Создать Lambda code
echo -e "${YELLOW}📝 Шаг 2/5: Создание Lambda кода...${NC}"

# Python версия
cat > /tmp/lambda_function.py <<'EOF'
import json

def lambda_handler(event, context):
    """
    Lambda function для возврата списка контактов.
    Работает с API Gateway HTTP API (Payload Format 2.0).
    """
    
    print(f"Event: {json.dumps(event)}")
    
    # Список контактов (mock data)
    contacts = [
        {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com",
            "phone": "+1 (555) 123-4567"
        },
        {
            "id": 2,
            "name": "Jane Smith",
            "email": "jane@example.com",
            "phone": "+1 (555) 987-6543"
        },
        {
            "id": 3,
            "name": "Bob Johnson",
            "email": "bob@example.com",
            "phone": "+1 (555) 456-7890"
        }
    ]
    
    # Для API Gateway HTTP API нужен такой формат response
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"  # CORS
        },
        "body": json.dumps(contacts)
    }
EOF

# Node.js версия (альтернатива)
cat > /tmp/index.js <<'EOF'
exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    // Список контактов (mock data)
    const contacts = [
        {
            id: 1,
            name: "John Doe",
            email: "john@example.com",
            phone: "+1 (555) 123-4567"
        },
        {
            id: 2,
            name: "Jane Smith",
            email: "jane@example.com",
            phone: "+1 (555) 987-6543"
        },
        {
            id: 3,
            name: "Bob Johnson",
            email: "bob@example.com",
            phone: "+1 (555) 456-7890"
        }
    ];
    
    // Для API Gateway HTTP API нужен такой формат response
    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'  // CORS
        },
        body: JSON.stringify(contacts)
    };
};
EOF

# Упаковать в ZIP
cd /tmp
if [ "$RUNTIME" == "python3.11" ]; then
    zip -q lambda-code.zip lambda_function.py
    HANDLER="lambda_function.lambda_handler"
else
    zip -q lambda-code.zip index.js
    HANDLER="index.handler"
fi

echo -e "${GREEN}✅ Lambda код создан и упакован${NC}"
echo ""

# Шаг 3: Создать Lambda функцию
echo -e "${YELLOW}🚀 Шаг 3/5: Создание Lambda функции...${NC}"

aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime "$RUNTIME" \
    --role "$ROLE_ARN" \
    --handler "$HANDLER" \
    --zip-file fileb:///tmp/lambda-code.zip \
    --timeout 30 \
    --memory-size 128 \
    --description "Lambda function for Task 7 - returns contacts list" \
    --environment "Variables={ENVIRONMENT=production}" \
    2>/dev/null || echo -e "${YELLOW}⚠️  Lambda функция уже существует${NC}"

# Получить Lambda ARN
LAMBDA_ARN=$(aws lambda get-function \
    --function-name "$FUNCTION_NAME" \
    --query 'Configuration.FunctionArn' \
    --output text)

echo -e "${GREEN}✅ Lambda функция создана: $LAMBDA_ARN${NC}"
echo ""

# Шаг 4: Протестировать Lambda
echo -e "${YELLOW}🧪 Шаг 4/5: Тестирование Lambda функции...${NC}"

# Создать test event (API Gateway HTTP API format)
cat > /tmp/test-event.json <<'EOF'
{
  "version": "2.0",
  "routeKey": "GET /contacts",
  "rawPath": "/contacts",
  "rawQueryString": "",
  "headers": {
    "accept": "*/*",
    "content-length": "0",
    "host": "example.execute-api.eu-west-1.amazonaws.com",
    "user-agent": "curl/7.79.1"
  },
  "requestContext": {
    "accountId": "123456789012",
    "apiId": "api123",
    "http": {
      "method": "GET",
      "path": "/contacts",
      "protocol": "HTTP/1.1",
      "sourceIp": "1.2.3.4",
      "userAgent": "curl/7.79.1"
    },
    "routeKey": "GET /contacts",
    "stage": "$default",
    "time": "01/Jan/2024:12:00:00 +0000",
    "timeEpoch": 1704110400000
  }
}
EOF

# Вызвать Lambda
aws lambda invoke \
    --function-name "$FUNCTION_NAME" \
    --payload file:///tmp/test-event.json \
    /tmp/lambda-response.json \
    --query 'StatusCode' \
    --output text > /dev/null

# Проверить response
if [ -f /tmp/lambda-response.json ]; then
    echo -e "${GREEN}✅ Lambda успешно выполнилась${NC}"
    echo -e "${GREEN}Response:${NC}"
    cat /tmp/lambda-response.json | python3 -m json.tool 2>/dev/null || cat /tmp/lambda-response.json
else
    echo -e "${RED}❌ Ошибка вызова Lambda${NC}"
fi
echo ""

# Шаг 5: Информация о Lambda
echo -e "${YELLOW}📊 Шаг 5/5: Информация о Lambda функции...${NC}"

aws lambda get-function-configuration \
    --function-name "$FUNCTION_NAME" \
    --query '{Name:FunctionName, Runtime:Runtime, Handler:Handler, State:State, Memory:MemorySize, Timeout:Timeout, LastModified:LastModified}' \
    --output table

echo ""

# Итоги
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ✅ Lambda функция создана!           ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Созданные ресурсы:${NC}"
echo -e "  ✅ IAM Role: $ROLE_NAME"
echo -e "  ✅ Lambda Function: $FUNCTION_NAME"
echo -e "  ✅ Runtime: $RUNTIME"
echo -e "  ✅ Handler: $HANDLER"
echo ""
echo -e "${YELLOW}Lambda ARN (для API Gateway):${NC}"
echo -e "  $LAMBDA_ARN"
echo ""
echo -e "${YELLOW}Следующие шаги:${NC}"
echo -e "  1. Создать API Gateway: ./create-api-gateway.sh"
echo -e "  2. Создать Integration: ./create-integration.sh"
echo -e "  3. Добавить Permission: ./add-lambda-permission.sh"
echo ""
echo -e "${YELLOW}Полезные команды:${NC}"
echo -e "  # Обновить код Lambda"
echo -e "  aws lambda update-function-code --function-name $FUNCTION_NAME --zip-file fileb://lambda-code.zip"
echo ""
echo -e "  # Проверить логи"
echo -e "  aws logs tail /aws/lambda/$FUNCTION_NAME --follow"
echo ""
echo -e "  # Удалить Lambda"
echo -e "  aws lambda delete-function --function-name $FUNCTION_NAME"
echo -e "  aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
echo -e "  aws iam delete-role --role-name $ROLE_NAME"
echo ""
