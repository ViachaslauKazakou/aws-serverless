# 📝 Task 7: Подробные инструкции - API Gateway + Lambda Integration

## 📋 Обзор

В этом руководстве мы **вручную** выполним интеграцию API Gateway с Lambda функцией. Каждый шаг объясняется детально с проверкой промежуточных результатов.

**Время выполнения**: 15-20 минут  
**Метод**: Ручное выполнение команд  
**Цель**: Понять каждый шаг настройки

---

## 🎯 Что мы будем делать?

```
┌─────────────────────────────────────────────────┐
│  ШАГИ НАСТРОЙКИ:                                │
│                                                 │
│  1️⃣ Подготовка: Credentials + Переменные       │
│  2️⃣ Проверка: Существующие ресурсы             │
│  3️⃣ Создание: Lambda Integration                │
│  4️⃣ Обновление: Route target                    │
│  5️⃣ Добавление: Lambda Permission               │
│  6️⃣ Тестирование: API endpoint                  │
│  7️⃣ Верификация: Все компоненты                 │
└─────────────────────────────────────────────────┘
```

---

## Шаг 0: Подготовка 🔧

### 0.1 Установить AWS credentials

```bash
export AWS_ACCESS_KEY_ID=AKIAWCYYADEDESGATYGT
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1
```

**Проверка:**
```bash
aws sts get-caller-identity
```

**Ожидаемый результат:**
```json
{
    "UserId": "AIDAWCYYADEDJGOKZLTEE",
    "Account": "418272778502",
    "Arn": "arn:aws:iam::418272778502:user/..."
}
```

✅ **Account ID должен быть 418272778502**

---

### 0.2 Определить переменные

```bash
API_ID="erv7myh2nb"
ROUTE_ID="py00o9v"
LAMBDA_FUNCTION="cmtr-4n6e9j62-api-gwlp-lambda-contacts"
REGION="eu-west-1"
ACCOUNT_ID="418272778502"
```

**Проверка:**
```bash
echo "API_ID: $API_ID"
echo "ROUTE_ID: $ROUTE_ID"
echo "LAMBDA_FUNCTION: $LAMBDA_FUNCTION"
echo "REGION: $REGION"
echo "ACCOUNT_ID: $ACCOUNT_ID"
```

---

## Шаг 1: Проверка существующих ресурсов 🔍

### 1.1 Проверить API Gateway

```bash
aws apigatewayv2 get-api --api-id $API_ID
```

**Что проверяем:**
- ✅ API существует
- ✅ `ProtocolType` = `HTTP` (HTTP API, не REST API)
- ✅ `ApiEndpoint` доступен

**Пример вывода:**
```json
{
    "ApiEndpoint": "https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com",
    "ApiId": "erv7myh2nb",
    "ApiKeySelectionExpression": "$request.header.x-api-key",
    "CreatedDate": "2024-01-01T12:00:00Z",
    "Name": "task7-api",
    "ProtocolType": "HTTP",
    "RouteSelectionExpression": "$request.method $request.path"
}
```

**Сохраним API endpoint:**
```bash
API_ENDPOINT=$(aws apigatewayv2 get-api --api-id $API_ID --query 'ApiEndpoint' --output text)
echo "API Endpoint: $API_ENDPOINT"
```

---

### 1.2 Проверить Route

```bash
aws apigatewayv2 get-route --api-id $API_ID --route-id $ROUTE_ID
```

**Что проверяем:**
- ✅ Route существует
- ✅ `RouteKey` = `GET /contacts`
- ⚠️ `Target` - возможно пустой или указывает на другой integration

**Пример вывода:**
```json
{
    "ApiKeyRequired": false,
    "RouteId": "py00o9v",
    "RouteKey": "GET /contacts",
    "Target": ""
}
```

❗ **Если `Target` пустой** - route еще не привязан к integration (это нормально).

---

### 1.3 Проверить Lambda функцию

```bash
aws lambda get-function --function-name $LAMBDA_FUNCTION
```

**Что проверяем:**
- ✅ Lambda существует
- ✅ `State` = `Active`
- ✅ Lambda ARN доступен

**Сохраним Lambda ARN:**
```bash
LAMBDA_ARN=$(aws lambda get-function --function-name $LAMBDA_FUNCTION --query 'Configuration.FunctionArn' --output text)
echo "Lambda ARN: $LAMBDA_ARN"
```

**Пример ARN:**
```
arn:aws:lambda:eu-west-1:418272778502:function:cmtr-4n6e9j62-api-gwlp-lambda-contacts
```

---

### 1.4 Проверить существующие integrations

```bash
aws apigatewayv2 get-integrations --api-id $API_ID
```

**Что проверяем:**
- ❓ Есть ли уже integration для нашей Lambda?
- ❓ Какой тип integration (`AWS_PROXY`, `HTTP`, `MOCK`)?

**Если integrations нет (пустой массив):**
```json
{
    "Items": []
}
```

**Если integration уже существует:**
```json
{
    "Items": [
        {
            "IntegrationId": "abc123",
            "IntegrationType": "AWS_PROXY",
            "IntegrationUri": "arn:aws:lambda:...",
            "PayloadFormatVersion": "2.0"
        }
    ]
}
```

---

## Шаг 2: Создание Lambda Integration 🔗

### 2.1 Создать Integration

```bash
aws apigatewayv2 create-integration \
    --api-id $API_ID \
    --integration-type AWS_PROXY \
    --integration-uri $LAMBDA_ARN \
    --payload-format-version 2.0
```

**Параметры:**
- `--integration-type AWS_PROXY` - Lambda получает весь HTTP request
- `--integration-uri $LAMBDA_ARN` - ARN нашей Lambda функции
- `--payload-format-version 2.0` - новый формат event (рекомендуется)

**Ожидаемый результат:**
```json
{
    "IntegrationId": "abc123def",
    "IntegrationType": "AWS_PROXY",
    "IntegrationUri": "arn:aws:lambda:eu-west-1:418272778502:function:cmtr-4n6e9j62-api-gwlp-lambda-contacts",
    "PayloadFormatVersion": "2.0",
    "TimeoutInMillis": 30000
}
```

**Сохраним Integration ID:**
```bash
INTEGRATION_ID=$(aws apigatewayv2 get-integrations --api-id $API_ID \
    --query "Items[?IntegrationUri=='$LAMBDA_ARN'].IntegrationId" --output text)
echo "Integration ID: $INTEGRATION_ID"
```

---

### 2.2 Проверить созданный Integration

```bash
aws apigatewayv2 get-integration \
    --api-id $API_ID \
    --integration-id $INTEGRATION_ID
```

**Что проверяем:**
- ✅ `IntegrationType` = `AWS_PROXY`
- ✅ `IntegrationUri` = наш Lambda ARN
- ✅ `PayloadFormatVersion` = `2.0`
- ✅ `TimeoutInMillis` = `30000` (30 секунд)

---

### 2.3 Альтернатива: Integration с дополнительными параметрами

Если хотите больше контроля:

```bash
aws apigatewayv2 create-integration \
    --api-id $API_ID \
    --integration-type AWS_PROXY \
    --integration-method POST \
    --integration-uri $LAMBDA_ARN \
    --payload-format-version 2.0 \
    --timeout-in-millis 30000 \
    --description "Lambda integration for contacts API"
```

**Дополнительные параметры:**
- `--integration-method POST` - метод для вызова Lambda (всегда POST)
- `--timeout-in-millis 30000` - таймаут 30 секунд
- `--description` - описание integration

---

## Шаг 3: Привязка Route к Integration 🔗

### 3.1 Обновить Route

```bash
aws apigatewayv2 update-route \
    --api-id $API_ID \
    --route-id $ROUTE_ID \
    --target "integrations/$INTEGRATION_ID"
```

**Параметры:**
- `--route-id $ROUTE_ID` - ID существующего route (py00o9v)
- `--target "integrations/$INTEGRATION_ID"` - привязываем к созданному integration

**Ожидаемый результат:**
```json
{
    "ApiKeyRequired": false,
    "RouteId": "py00o9v",
    "RouteKey": "GET /contacts",
    "Target": "integrations/abc123def"
}
```

✅ **`Target` теперь должен указывать на integration!**

---

### 3.2 Проверить обновленный Route

```bash
aws apigatewayv2 get-route \
    --api-id $API_ID \
    --route-id $ROUTE_ID
```

**Что проверяем:**
- ✅ `Target` = `integrations/$INTEGRATION_ID`
- ✅ `RouteKey` = `GET /contacts`

**Визуализация:**
```
Route (py00o9v)
  RouteKey: GET /contacts
  Target: integrations/abc123def  ← Теперь привязан!
```

---

### 3.3 Альтернатива: Создать новый Route

Если нужно создать новый route (вместо обновления):

```bash
aws apigatewayv2 create-route \
    --api-id $API_ID \
    --route-key "GET /contacts" \
    --target "integrations/$INTEGRATION_ID"
```

**Когда использовать:**
- Если route не существует
- Если хотите создать дополнительные routes (POST, DELETE и т.д.)

---

## Шаг 4: Добавление Lambda Permission 🔐

### 4.1 Создать Source ARN

```bash
SOURCE_ARN="arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*"
echo "Source ARN: $SOURCE_ARN"
```

**Формат Source ARN:**
```
arn:aws:execute-api:{region}:{account-id}:{api-id}/{stage}/{method}/{path}
```

**В нашем случае:**
```
arn:aws:execute-api:eu-west-1:418272778502:erv7myh2nb/*/*
                    ^^^^^^^^   ^^^^^^^^^^^^  ^^^^^^^^^^^ ^^^^
                    region     account-id    api-id      any stage/method/path
```

`/*/*` означает:
- Первая `*` - любой stage (`$default`, `prod`, `dev` и т.д.)
- Вторая `*` - любой метод и path (GET, POST, /contacts, /users и т.д.)

---

### 4.2 Добавить Permission

```bash
aws lambda add-permission \
    --function-name $LAMBDA_FUNCTION \
    --statement-id AllowAPIGatewayInvoke-task7 \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn $SOURCE_ARN
```

**Параметры:**
- `--function-name` - имя Lambda функции
- `--statement-id` - уникальный ID для permission (можно любой)
- `--action lambda:InvokeFunction` - разрешаем вызывать Lambda
- `--principal apigateway.amazonaws.com` - кто может вызывать (API Gateway)
- `--source-arn` - ограничение: только конкретный API

**Ожидаемый результат:**
```json
{
    "Statement": "{\"Sid\":\"AllowAPIGatewayInvoke-task7\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"apigateway.amazonaws.com\"},\"Action\":\"lambda:InvokeFunction\",\"Resource\":\"arn:aws:lambda:eu-west-1:418272778502:function:cmtr-4n6e9j62-api-gwlp-lambda-contacts\",\"Condition\":{\"ArnLike\":{\"AWS:SourceArn\":\"arn:aws:execute-api:eu-west-1:418272778502:erv7myh2nb/*/*\"}}}"
}
```

---

### 4.3 Проверить Lambda Policy

```bash
aws lambda get-policy --function-name $LAMBDA_FUNCTION
```

**Что проверяем:**
- ✅ `Sid` = `AllowAPIGatewayInvoke-task7`
- ✅ `Principal.Service` = `apigateway.amazonaws.com`
- ✅ `Action` = `lambda:InvokeFunction`
- ✅ `Condition.ArnLike.AWS:SourceArn` = наш API ARN

**Форматированный вывод (с jq):**
```bash
aws lambda get-policy --function-name $LAMBDA_FUNCTION | jq '.Policy | fromjson'
```

**Пример policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAPIGatewayInvoke-task7",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:eu-west-1:418272778502:function:cmtr-4n6e9j62-api-gwlp-lambda-contacts",
      "Condition": {
        "ArnLike": {
          "AWS:SourceArn": "arn:aws:execute-api:eu-west-1:418272778502:erv7myh2nb/*/*"
        }
      }
    }
  ]
}
```

---

### 4.4 Альтернатива: Более специфичный Source ARN

Если хотите ограничить доступ только для конкретного route:

```bash
SOURCE_ARN_SPECIFIC="arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/GET/contacts"

aws lambda add-permission \
    --function-name $LAMBDA_FUNCTION \
    --statement-id AllowAPIGatewayInvokeSpecific \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn $SOURCE_ARN_SPECIFIC
```

**Разница:**
- `/*/*` - любой stage, любой метод/path
- `/*/GET/contacts` - любой stage, только GET /contacts

---

## Шаг 5: Тестирование API 🧪

### 5.1 Получить полный API endpoint

```bash
FULL_ENDPOINT="$API_ENDPOINT/contacts"
echo "Full Endpoint: $FULL_ENDPOINT"
```

**Пример:**
```
https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts
```

---

### 5.2 Тест 1: HTTP запрос через curl

```bash
curl "$FULL_ENDPOINT"
```

**Ожидаемый результат (HTTP 200):**
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

✅ **Если видите JSON с контактами - успех!**

---

### 5.3 Тест 2: HTTP запрос с headers

```bash
curl -i "$FULL_ENDPOINT"
```

**Ожидаемые headers:**
```
HTTP/2 200
content-type: application/json
content-length: 156
date: Mon, 01 Jan 2024 12:00:00 GMT
x-amzn-requestid: abc123-def456-...
x-amz-apigw-id: xyz789=
```

**Что проверяем:**
- ✅ `HTTP/2 200` - успешный response
- ✅ `content-type: application/json` - правильный content type
- ✅ `x-amzn-requestid` - request ID для отладки

---

### 5.4 Тест 3: Через browser

```bash
# macOS
open "$FULL_ENDPOINT"

# Linux
xdg-open "$FULL_ENDPOINT"

# Windows (WSL)
explorer.exe "$FULL_ENDPOINT"
```

**Или просто скопируйте URL:**
```
https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts
```

И откройте в браузере. Должны увидеть JSON с контактами.

---

### 5.5 Тест 4: Форматирование с jq

```bash
curl -s "$FULL_ENDPOINT" | jq .
```

**Красиво отформатированный JSON:**
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

---

### 5.6 Тест 5: Измерить время ответа

```bash
time curl -s "$FULL_ENDPOINT" > /dev/null
```

**Ожидаемое время:**
```
real    0m0.234s
user    0m0.012s
sys     0m0.008s
```

⏱️ **Обычно 200-500ms для первого запроса (cold start)**  
⏱️ **50-150ms для последующих запросов (warm)**

---

## Шаг 6: Верификация всех компонентов ✅

### 6.1 Проверить API Gateway configuration

```bash
aws apigatewayv2 get-api --api-id $API_ID \
    --query '[Name,ApiEndpoint,ProtocolType]' \
    --output table
```

**Ожидаемый вывод:**
```
-------------------------------------------------------------
|                         GetApi                            |
+----------------+------------------+-----------------------+
|  task7-api     |  https://...     |  HTTP                 |
+----------------+------------------+-----------------------+
```

---

### 6.2 Проверить Routes

```bash
aws apigatewayv2 get-routes --api-id $API_ID \
    --query 'Items[*].[RouteKey,Target]' \
    --output table
```

**Ожидаемый вывод:**
```
-----------------------------------------
|              GetRoutes                |
+------------------+--------------------+
|  GET /contacts   |  integrations/... |
+------------------+--------------------+
```

✅ **Target должен указывать на integration!**

---

### 6.3 Проверить Integrations

```bash
aws apigatewayv2 get-integrations --api-id $API_ID \
    --query 'Items[*].[IntegrationId,IntegrationType,IntegrationUri]' \
    --output table
```

**Ожидаемый вывод:**
```
------------------------------------------------------------------------
|                          GetIntegrations                             |
+-------------+--------------+----------------------------------------+
|  abc123def  |  AWS_PROXY   |  arn:aws:lambda:eu-west-1:...         |
+-------------+--------------+----------------------------------------+
```

✅ **IntegrationType должен быть AWS_PROXY!**

---

### 6.4 Проверить Lambda Permission

```bash
aws lambda get-policy --function-name $LAMBDA_FUNCTION | \
    jq '.Policy | fromjson | .Statement[] | select(.Principal.Service == "apigateway.amazonaws.com")'
```

**Ожидаемый вывод:**
```json
{
  "Sid": "AllowAPIGatewayInvoke-task7",
  "Effect": "Allow",
  "Principal": {
    "Service": "apigateway.amazonaws.com"
  },
  "Action": "lambda:InvokeFunction",
  "Resource": "arn:aws:lambda:eu-west-1:418272778502:function:cmtr-4n6e9j62-api-gwlp-lambda-contacts",
  "Condition": {
    "ArnLike": {
      "AWS:SourceArn": "arn:aws:execute-api:eu-west-1:418272778502:erv7myh2nb/*/*"
    }
  }
}
```

✅ **Permission существует с правильным Principal!**

---

## Шаг 7: Дополнительные тесты 🔬

### 7.1 Прямой вызов Lambda (без API Gateway)

```bash
aws lambda invoke \
    --function-name $LAMBDA_FUNCTION \
    --payload '{"httpMethod":"GET","path":"/contacts"}' \
    response.json

cat response.json
```

**Зачем это нужно:**
- Проверить что Lambda работает сама по себе
- Отделить проблемы Lambda от проблем API Gateway
- Увидеть response format для AWS_PROXY

**Ожидаемый response.json:**
```json
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "[{\"id\":1,\"name\":\"John Doe\",\"email\":\"john@example.com\",\"phone\":\"+1234567890\"},{\"id\":2,\"name\":\"Jane Smith\",\"email\":\"jane@example.com\",\"phone\":\"+0987654321\"}]"
}
```

❗ **Обратите внимание на format:**
- `statusCode` - число (не строка)
- `headers` - объект
- `body` - **строка** (не объект), JSON внутри строки

---

### 7.2 Проверить Lambda logs

```bash
aws logs tail /aws/lambda/$LAMBDA_FUNCTION --since 5m
```

**Что искать:**
- ✅ `START RequestId: ...` - Lambda началась
- ✅ `END RequestId: ...` - Lambda закончилась
- ✅ `REPORT RequestId: ...` - статистика (duration, memory)
- ❌ `ERROR` - ошибки в коде

**Пример logs:**
```
2024-01-01T12:00:00.000Z START RequestId: abc123-def456 Version: $LATEST
2024-01-01T12:00:00.050Z END RequestId: abc123-def456
2024-01-01T12:00:00.050Z REPORT RequestId: abc123-def456
    Duration: 45.67 ms
    Billed Duration: 46 ms
    Memory Size: 128 MB
    Max Memory Used: 65 MB
```

---

### 7.3 Проверить Lambda invocations (CloudWatch Metrics)

```bash
aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Invocations \
    --dimensions Name=FunctionName,Value=$LAMBDA_FUNCTION \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum
```

**Что проверяем:**
- Сколько раз вызывалась Lambda
- В какое время были вызовы
- Есть ли pattern (cold start, warm invocations)

---

### 7.4 Проверить Lambda errors

```bash
aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Errors \
    --dimensions Name=FunctionName,Value=$LAMBDA_FUNCTION \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum
```

**Ожидаемый результат:**
```json
{
    "Datapoints": []
}
```

✅ **Пустой массив = нет ошибок!**

---

## Troubleshooting 🔧

### Problem 1: API возвращает 403 Forbidden

**Симптомы:**
```bash
curl "$FULL_ENDPOINT"
{"message":"Missing Authentication Token"}
```

**Или:**
```bash
curl "$FULL_ENDPOINT"
{"message":"Forbidden"}
```

**Причина:**
- Lambda не имеет permission для вызова от API Gateway

**Диагностика:**
```bash
# Проверить Lambda policy
aws lambda get-policy --function-name $LAMBDA_FUNCTION

# Должен быть statement с Principal = apigateway.amazonaws.com
```

**Решение:**
```bash
# Добавить permission
aws lambda add-permission \
    --function-name $LAMBDA_FUNCTION \
    --statement-id AllowAPIGatewayInvoke-task7 \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*"

# Повторить запрос
curl "$FULL_ENDPOINT"
```

---

### Problem 2: API возвращает 500 Internal Server Error

**Симптомы:**
```bash
curl "$FULL_ENDPOINT"
{"message":"Internal Server Error"}
```

**Причины:**
1. Lambda упала с ошибкой
2. Lambda вернула неправильный format response
3. Lambda timeout

**Диагностика:**
```bash
# 1. Проверить Lambda logs
aws logs tail /aws/lambda/$LAMBDA_FUNCTION --since 5m

# 2. Протестировать Lambda напрямую
aws lambda invoke \
    --function-name $LAMBDA_FUNCTION \
    --payload '{"httpMethod":"GET","path":"/contacts"}' \
    response.json

cat response.json

# 3. Проверить Lambda state
aws lambda get-function-configuration \
    --function-name $LAMBDA_FUNCTION \
    --query 'State'
# Должен быть "Active"
```

**Решение:**
- Если Lambda упала - исправить код Lambda
- Если неправильный format - Lambda должна возвращать:
  ```json
  {
    "statusCode": 200,
    "headers": {"Content-Type": "application/json"},
    "body": "..."
  }
  ```
- Если timeout - увеличить timeout в Lambda configuration

---

### Problem 3: Route не вызывает Lambda

**Симптомы:**
```bash
curl "$FULL_ENDPOINT"
# Нет ответа или неожиданный ответ
```

**Причина:**
- Route не привязан к Integration

**Диагностика:**
```bash
# Проверить route target
aws apigatewayv2 get-route \
    --api-id $API_ID \
    --route-id $ROUTE_ID \
    --query 'Target'

# Должен быть: "integrations/$INTEGRATION_ID"
```

**Решение:**
```bash
# Получить Integration ID
INTEGRATION_ID=$(aws apigatewayv2 get-integrations --api-id $API_ID \
    --query "Items[?IntegrationUri=='$LAMBDA_ARN'].IntegrationId" --output text)

# Привязать route к integration
aws apigatewayv2 update-route \
    --api-id $API_ID \
    --route-id $ROUTE_ID \
    --target "integrations/$INTEGRATION_ID"
```

---

### Problem 4: Integration не найден

**Симптомы:**
```bash
aws apigatewayv2 get-integration \
    --api-id $API_ID \
    --integration-id $INTEGRATION_ID

# ResourceNotFoundException
```

**Причина:**
- Integration был удален
- Integration не был создан
- Неправильный Integration ID

**Диагностика:**
```bash
# Список всех integrations
aws apigatewayv2 get-integrations --api-id $API_ID
```

**Решение:**
```bash
# Создать новый integration
aws apigatewayv2 create-integration \
    --api-id $API_ID \
    --integration-type AWS_PROXY \
    --integration-uri $LAMBDA_ARN \
    --payload-format-version 2.0
```

---

## Cleanup (удаление) 🧹

Если хотите вернуть все в исходное состояние:

### 1. Отвязать Route от Integration

```bash
aws apigatewayv2 update-route \
    --api-id $API_ID \
    --route-id $ROUTE_ID \
    --target ""
```

### 2. Удалить Integration

```bash
aws apigatewayv2 delete-integration \
    --api-id $API_ID \
    --integration-id $INTEGRATION_ID
```

### 3. Удалить Lambda Permission

```bash
aws lambda remove-permission \
    --function-name $LAMBDA_FUNCTION \
    --statement-id AllowAPIGatewayInvoke-task7
```

### 4. Проверить что все удалено

```bash
# Integrations должны быть пустыми
aws apigatewayv2 get-integrations --api-id $API_ID

# Lambda policy не должен содержать apigateway.amazonaws.com
aws lambda get-policy --function-name $LAMBDA_FUNCTION
```

---

## Итоговая проверка ✅

Выполните эти команды для финальной верификации:

```bash
echo "=== 1. API Gateway ==="
aws apigatewayv2 get-api --api-id $API_ID --query '[Name,ProtocolType]' --output table

echo "=== 2. Routes ==="
aws apigatewayv2 get-routes --api-id $API_ID --query 'Items[*].[RouteKey,Target]' --output table

echo "=== 3. Integrations ==="
aws apigatewayv2 get-integrations --api-id $API_ID --query 'Items[*].[IntegrationType,IntegrationUri]' --output table

echo "=== 4. Lambda Permission ==="
aws lambda get-policy --function-name $LAMBDA_FUNCTION | jq '.Policy | fromjson | .Statement[] | select(.Principal.Service == "apigateway.amazonaws.com") | .Sid'

echo "=== 5. HTTP Test ==="
curl -i "$FULL_ENDPOINT"
```

**Ожидаемые результаты:**
- ✅ API существует, тип HTTP
- ✅ Route `GET /contacts` привязан к integration
- ✅ Integration типа AWS_PROXY указывает на Lambda
- ✅ Lambda имеет permission для API Gateway
- ✅ HTTP запрос возвращает 200 OK с JSON

---

## Следующие шаги 🎯

После успешного выполнения:

1. 📖 Изучите [ARCHITECTURE.md](./ARCHITECTURE.md) - детальная архитектура
2. ✅ Пройдите [CHECKLIST.md](./CHECKLIST.md) - систематическая проверка
3. 📊 Прочитайте [PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md) - итоги и выводы

---

**🎉 Поздравляем! Вы вручную настроили API Gateway + Lambda интеграцию!**

Теперь вы понимаете каждый шаг процесса и можете troubleshoot любые проблемы.
