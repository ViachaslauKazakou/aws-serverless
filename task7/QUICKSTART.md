# 🚀 Task 7: Quick Start - API Gateway + Lambda

## Что делает этот таск?

Task 7 демонстрирует интеграцию **API Gateway** с **Lambda функцией**. Вы создадите HTTP endpoint, который будет вызывать Lambda функцию и возвращать список контактов.

**Цель задания**: Настроить полноценное REST API с Lambda backend'ом за 5 минут! 🎯

## Быстрый старт (5 минут)

### 1️⃣ Настроить credentials

```bash
export AWS_ACCESS_KEY_ID=AKIAWCYYADEDESGATYGT
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1
```

### 2️⃣ Запустить автоматическую настройку

```bash
cd /Users/Viachaslau_Kazakou/Work/IAM-task/task7
chmod +x setup-iam-task7.sh
./setup-iam-task7.sh
```

### 3️⃣ Протестировать API

```bash
# Через curl
curl https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts

# Или откройте в браузере
open https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts
```

**Ожидаемый результат**: JSON массив с контактами
```json
[
  {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890"
  },
  {
    "id": 2,
    "name": "Jane Smith",
    "email": "jane@example.com",
    "phone": "+0987654321"
  }
]
```

✅ **Готово!** API работает через Lambda интеграцию!

---

## Что произошло за кулисами?

### Шаг 1: Lambda Integration создан
```bash
aws apigatewayv2 create-integration \
    --api-id erv7myh2nb \
    --integration-type AWS_PROXY \
    --integration-uri arn:aws:lambda:eu-west-1:418272778502:function:cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --payload-format-version 2.0
```

**Что это делает?**
- Создает связь между API Gateway и Lambda
- `AWS_PROXY` = Lambda получает весь HTTP request
- `payload-format-version 2.0` = новый формат для HTTP APIs

### Шаг 2: Route привязан к Integration
```bash
aws apigatewayv2 update-route \
    --api-id erv7myh2nb \
    --route-id py00o9v \
    --target "integrations/$INTEGRATION_ID"
```

**Что это делает?**
- Route `GET /contacts` теперь вызывает Lambda
- Все запросы на `/contacts` идут в Lambda

### Шаг 3: Lambda Permission добавлен
```bash
aws lambda add-permission \
    --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --statement-id AllowAPIGatewayInvoke-task7 \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:eu-west-1:418272778502:erv7myh2nb/*/*"
```

**Что это делает?**
- Lambda разрешает вызовы от API Gateway
- **Resource-based policy** на Lambda функции
- Без этого API Gateway получит 403 Forbidden

---

## Архитектура решения

```
┌─────────────────────────────────────────────────────────────┐
│                         TASK 7                              │
│              API Gateway + Lambda Integration               │
└─────────────────────────────────────────────────────────────┘

                      Internet
                         │
                         │ GET /contacts
                         ▼
              ┌──────────────────────┐
              │   API Gateway        │
              │  (HTTP API)          │
              │  erv7myh2nb          │
              └──────────────────────┘
                         │
                         │ Integration (AWS_PROXY)
                         │
                         ▼
              ┌──────────────────────┐
              │   Lambda Function    │
              │  api-gwlp-lambda-    │
              │      contacts        │
              └──────────────────────┘
                         │
                         │ Return JSON
                         ▼
                  [Contact List]

┌────────────────────────────────────────────────────────────┐
│  PERMISSIONS:                                              │
│  ✅ Lambda resource-based policy: Allow apigateway.com    │
│  ✅ Lambda execution role: Basic Lambda permissions       │
└────────────────────────────────────────────────────────────┘
```

---

## Основные компоненты

### 1. **API Gateway** (HTTP API)
- **ID**: `erv7myh2nb`
- **Type**: HTTP API (проще и дешевле чем REST API)
- **Endpoint**: `https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com`
- **Protocol**: HTTP/1.1 и HTTP/2

### 2. **Route**
- **ID**: `py00o9v`
- **Path**: `GET /contacts`
- **Target**: Lambda Integration
- **Authorization**: None (public endpoint)

### 3. **Lambda Function**
- **Name**: `cmtr-4n6e9j62-api-gwlp-lambda-contacts`
- **Runtime**: Node.js / Python (зависит от реализации)
- **Handler**: Возвращает список контактов
- **Response**: JSON массив

### 4. **Integration**
- **Type**: `AWS_PROXY`
- **Method**: `POST` (всегда POST для Lambda)
- **Payload Format**: Version 2.0
- **Timeout**: 30 секунд

---

## Типы Integration в API Gateway

### 1. **AWS_PROXY** (используется в Task 7) ✅
```bash
# Lambda получает полный HTTP request
--integration-type AWS_PROXY
```

**Плюсы:**
- Lambda видит все HTTP headers, query params, body
- Полный контроль над response (status code, headers, body)
- Простая настройка

**Минусы:**
- Lambda должен возвращать правильный format response
- Нельзя трансформировать request/response в API Gateway

### 2. **AWS** (с mapping templates)
```bash
# API Gateway трансформирует request/response
--integration-type AWS
```

**Плюсы:**
- Можно изменять request/response через VTL templates
- Не нужно менять код Lambda

**Минусы:**
- Сложная настройка
- VTL templates - дополнительная логика

### 3. **HTTP_PROXY** (для внешних HTTP endpoints)
```bash
# Проксировать на внешний HTTP API
--integration-type HTTP_PROXY
--integration-uri https://external-api.com/endpoint
```

### 4. **MOCK** (для тестирования)
```bash
# Возвращать статичный response без backend
--integration-type MOCK
```

---

## Lambda Event Format (Payload 2.0)

Lambda получает event в следующем формате:

```javascript
{
  "version": "2.0",
  "routeKey": "GET /contacts",
  "rawPath": "/contacts",
  "rawQueryString": "",
  "headers": {
    "accept": "*/*",
    "content-length": "0",
    "host": "erv7myh2nb.execute-api.eu-west-1.amazonaws.com",
    "user-agent": "curl/7.79.1",
    "x-amzn-trace-id": "Root=1-..."
  },
  "requestContext": {
    "accountId": "418272778502",
    "apiId": "erv7myh2nb",
    "domainName": "erv7myh2nb.execute-api.eu-west-1.amazonaws.com",
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
  },
  "isBase64Encoded": false
}
```

Lambda должен вернуть response в формате:

```javascript
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "[{\"id\":1,\"name\":\"John\"}]"
}
```

---

## Частые проблемы и решения

### ❌ Problem: API возвращает 403 Forbidden

**Причина**: Lambda не имеет permission для вызова от API Gateway

**Решение**:
```bash
# Проверить Lambda policy
aws lambda get-policy --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts

# Добавить permission
aws lambda add-permission \
    --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --statement-id AllowAPIGatewayInvoke-task7 \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:eu-west-1:418272778502:erv7myh2nb/*/*"
```

### ❌ Problem: API возвращает 500 Internal Server Error

**Причина**: Lambda упала с ошибкой или вернула неправильный response format

**Решение**:
```bash
# Проверить Lambda logs
aws logs tail /aws/lambda/cmtr-4n6e9j62-api-gwlp-lambda-contacts --since 5m

# Протестировать Lambda напрямую
aws lambda invoke \
    --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --payload '{"httpMethod":"GET","path":"/contacts"}' \
    response.json

cat response.json
```

### ❌ Problem: Route не вызывает Lambda

**Причина**: Route не привязан к Integration

**Решение**:
```bash
# Проверить route target
aws apigatewayv2 get-route \
    --api-id erv7myh2nb \
    --route-id py00o9v \
    --query 'Target'

# Должен быть: "integrations/$INTEGRATION_ID"

# Привязать к integration
aws apigatewayv2 update-route \
    --api-id erv7myh2nb \
    --route-id py00o9v \
    --target "integrations/$INTEGRATION_ID"
```

### ❌ Problem: Integration не найден

**Причина**: Integration был удален или не создан

**Решение**:
```bash
# Список всех integrations
aws apigatewayv2 get-integrations --api-id erv7myh2nb

# Создать новый integration
LAMBDA_ARN="arn:aws:lambda:eu-west-1:418272778502:function:cmtr-4n6e9j62-api-gwlp-lambda-contacts"

aws apigatewayv2 create-integration \
    --api-id erv7myh2nb \
    --integration-type AWS_PROXY \
    --integration-uri $LAMBDA_ARN \
    --payload-format-version 2.0
```

---

## Тестирование API

### 1. **Через curl**
```bash
# Простой GET запрос
curl https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts

# С headers
curl -i https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts

# С форматированием JSON
curl https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts | jq .

# Измерить время ответа
time curl https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts
```

### 2. **Через browser**
```bash
# Открыть в браузере
open https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts

# Или просто скопируйте URL:
https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts
```

### 3. **Через AWS CLI (direct Lambda invoke)**
```bash
# Протестировать Lambda напрямую (без API Gateway)
aws lambda invoke \
    --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --payload '{"httpMethod":"GET","path":"/contacts"}' \
    response.json

cat response.json
```

### 4. **Через Postman**
```
Method: GET
URL: https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts
Headers: (none required for public endpoint)
```

---

## Мониторинг и Логирование

### Lambda Invocations
```bash
# Смотреть Lambda logs в реальном времени
aws logs tail /aws/lambda/cmtr-4n6e9j62-api-gwlp-lambda-contacts --follow

# Последние 10 минут
aws logs tail /aws/lambda/cmtr-4n6e9j62-api-gwlp-lambda-contacts --since 10m

# Только ошибки
aws logs filter-log-events \
    --log-group-name /aws/lambda/cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --filter-pattern "ERROR" \
    --max-items 10
```

### API Gateway Metrics
```bash
# Количество вызовов Lambda
aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Invocations \
    --dimensions Name=FunctionName,Value=cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum

# Latency (продолжительность выполнения)
aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Duration \
    --dimensions Name=FunctionName,Value=cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average,Maximum

# Ошибки
aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Errors \
    --dimensions Name=FunctionName,Value=cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum
```

---

## Полезные команды

### API Gateway
```bash
# Получить API details
aws apigatewayv2 get-api --api-id erv7myh2nb

# Список всех routes
aws apigatewayv2 get-routes --api-id erv7myh2nb

# Список всех integrations
aws apigatewayv2 get-integrations --api-id erv7myh2nb

# Получить stage configuration
aws apigatewayv2 get-stage --api-id erv7myh2nb --stage-name '$default'
```

### Lambda
```bash
# Lambda configuration
aws lambda get-function-configuration \
    --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts

# Lambda policy (permissions)
aws lambda get-policy \
    --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts

# Скачать Lambda code
CODE_URL=$(aws lambda get-function \
    --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --query 'Code.Location' --output text)
curl -o lambda-code.zip "$CODE_URL"
unzip lambda-code.zip
```

---

## Следующие шаги

После выполнения Task 7 вы узнали:

✅ Как создать Lambda Integration в API Gateway  
✅ Как настроить Resource-based policy на Lambda  
✅ Как тестировать API endpoints  
✅ Разницу между AWS_PROXY и другими типами integration  
✅ Формат Lambda event для Payload Version 2.0  

**Хотите углубиться?**

1. 📖 Прочитайте [ARCHITECTURE.md](./ARCHITECTURE.md) - детальная архитектура
2. 📝 Изучите [INSTRUCTIONS.md](./INSTRUCTIONS.md) - пошаговые инструкции
3. ✅ Пройдите [CHECKLIST.md](./CHECKLIST.md) - чек-лист для проверки

---

## Cleanup (удаление ресурсов)

```bash
# 1. Отвязать route от integration
aws apigatewayv2 update-route \
    --api-id erv7myh2nb \
    --route-id py00o9v \
    --target ""

# 2. Удалить integration
INTEGRATION_ID=$(aws apigatewayv2 get-integrations --api-id erv7myh2nb \
    --query 'Items[0].IntegrationId' --output text)

aws apigatewayv2 delete-integration \
    --api-id erv7myh2nb \
    --integration-id $INTEGRATION_ID

# 3. Удалить Lambda permission
aws lambda remove-permission \
    --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --statement-id AllowAPIGatewayInvoke-task7

# Проверить что все удалено
aws apigatewayv2 get-integrations --api-id erv7myh2nb
aws lambda get-policy --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts
```

---

**🎉 Поздравляем! Task 7 выполнен!**

Вы создали полноценное REST API с Lambda backend'ом. Теперь ваше API доступно через HTTPS endpoint и готово к использованию!
