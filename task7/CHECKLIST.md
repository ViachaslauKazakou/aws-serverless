# ✅ Task 7: Чек-лист выполнения - API Gateway + Lambda Integration

## 📋 О чек-листе

Используйте этот чек-лист для систематической проверки всех шагов Task 7. Отмечайте каждый пункт по мере выполнения.

**Как использовать:**
- ✅ - выполнено и проверено
- ⏳ - в процессе выполнения
- ❌ - не выполнено или ошибка
- ⚠️ - выполнено с предупреждениями

---

## 🔧 Pre-Flight Checklist

### Подготовка окружения

- [ ] **AWS CLI установлен**
  ```bash
  aws --version
  # Должен быть AWS CLI v2.x.x
  ```

- [ ] **jq установлен** (опционально, для форматирования JSON)
  ```bash
  jq --version
  # jq-1.6 или выше
  ```

- [ ] **curl установлен**
  ```bash
  curl --version
  # curl 7.x или выше
  ```

### AWS Credentials

- [ ] **Credentials экспортированы**
  ```bash
  export AWS_ACCESS_KEY_ID=AKIAWCYYADEDESGATYGT
  export AWS_SECRET_ACCESS_KEY=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
  export AWS_DEFAULT_REGION=eu-west-1
  ```

- [ ] **Credentials валидны**
  ```bash
  aws sts get-caller-identity
  # Account: 418272778502
  ```

### Переменные

- [ ] **Переменные определены**
  ```bash
  API_ID="erv7myh2nb"
  ROUTE_ID="py00o9v"
  LAMBDA_FUNCTION="cmtr-4n6e9j62-api-gwlp-lambda-contacts"
  REGION="eu-west-1"
  ACCOUNT_ID="418272778502"
  ```

---

## 🔍 Проверка существующих ресурсов

### API Gateway

- [ ] **API Gateway существует**
  ```bash
  aws apigatewayv2 get-api --api-id $API_ID
  # Должен вернуть API details
  ```

- [ ] **API Type = HTTP**
  ```bash
  aws apigatewayv2 get-api --api-id $API_ID --query 'ProtocolType' --output text
  # Должен быть: HTTP
  ```

- [ ] **API Endpoint доступен**
  ```bash
  API_ENDPOINT=$(aws apigatewayv2 get-api --api-id $API_ID --query 'ApiEndpoint' --output text)
  echo $API_ENDPOINT
  # https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com
  ```

### Route

- [ ] **Route существует**
  ```bash
  aws apigatewayv2 get-route --api-id $API_ID --route-id $ROUTE_ID
  # Должен вернуть route details
  ```

- [ ] **Route Key = GET /contacts**
  ```bash
  aws apigatewayv2 get-route --api-id $API_ID --route-id $ROUTE_ID --query 'RouteKey' --output text
  # Должен быть: GET /contacts
  ```

### Lambda Function

- [ ] **Lambda функция существует**
  ```bash
  aws lambda get-function --function-name $LAMBDA_FUNCTION
  # Должен вернуть function details
  ```

- [ ] **Lambda State = Active**
  ```bash
  aws lambda get-function-configuration --function-name $LAMBDA_FUNCTION --query 'State' --output text
  # Должен быть: Active
  ```

- [ ] **Lambda ARN получен**
  ```bash
  LAMBDA_ARN=$(aws lambda get-function --function-name $LAMBDA_FUNCTION --query 'Configuration.FunctionArn' --output text)
  echo $LAMBDA_ARN
  # arn:aws:lambda:eu-west-1:418272778502:function:cmtr-4n6e9j62-api-gwlp-lambda-contacts
  ```

---

## 🔗 Шаг 1: Создание Lambda Integration

### Создание Integration

- [ ] **Integration создан**
  ```bash
  aws apigatewayv2 create-integration \
      --api-id $API_ID \
      --integration-type AWS_PROXY \
      --integration-uri $LAMBDA_ARN \
      --payload-format-version 2.0
  # Должен вернуть IntegrationId
  ```

- [ ] **Integration ID сохранен**
  ```bash
  INTEGRATION_ID=$(aws apigatewayv2 get-integrations --api-id $API_ID \
      --query "Items[?IntegrationUri=='$LAMBDA_ARN'].IntegrationId" --output text)
  echo $INTEGRATION_ID
  # Например: abc123def
  ```

### Верификация Integration

- [ ] **IntegrationType = AWS_PROXY**
  ```bash
  aws apigatewayv2 get-integration --api-id $API_ID --integration-id $INTEGRATION_ID \
      --query 'IntegrationType' --output text
  # Должен быть: AWS_PROXY
  ```

- [ ] **IntegrationUri указывает на Lambda**
  ```bash
  aws apigatewayv2 get-integration --api-id $API_ID --integration-id $INTEGRATION_ID \
      --query 'IntegrationUri' --output text
  # Должен быть Lambda ARN
  ```

- [ ] **PayloadFormatVersion = 2.0**
  ```bash
  aws apigatewayv2 get-integration --api-id $API_ID --integration-id $INTEGRATION_ID \
      --query 'PayloadFormatVersion' --output text
  # Должен быть: 2.0
  ```

- [ ] **Timeout = 30000ms**
  ```bash
  aws apigatewayv2 get-integration --api-id $API_ID --integration-id $INTEGRATION_ID \
      --query 'TimeoutInMillis' --output text
  # Должен быть: 30000
  ```

---

## 🔗 Шаг 2: Привязка Route к Integration

### Обновление Route

- [ ] **Route обновлен**
  ```bash
  aws apigatewayv2 update-route \
      --api-id $API_ID \
      --route-id $ROUTE_ID \
      --target "integrations/$INTEGRATION_ID"
  # Должен вернуть обновленный route
  ```

### Верификация Route

- [ ] **Route Target = integrations/$INTEGRATION_ID**
  ```bash
  aws apigatewayv2 get-route --api-id $API_ID --route-id $ROUTE_ID \
      --query 'Target' --output text
  # Должен быть: integrations/abc123def (ваш Integration ID)
  ```

- [ ] **RouteKey не изменился**
  ```bash
  aws apigatewayv2 get-route --api-id $API_ID --route-id $ROUTE_ID \
      --query 'RouteKey' --output text
  # Должен быть: GET /contacts
  ```

---

## 🔐 Шаг 3: Добавление Lambda Permission

### Создание Permission

- [ ] **Source ARN создан**
  ```bash
  SOURCE_ARN="arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*"
  echo $SOURCE_ARN
  # arn:aws:execute-api:eu-west-1:418272778502:erv7myh2nb/*/*
  ```

- [ ] **Lambda permission добавлен**
  ```bash
  aws lambda add-permission \
      --function-name $LAMBDA_FUNCTION \
      --statement-id AllowAPIGatewayInvoke-task7 \
      --action lambda:InvokeFunction \
      --principal apigateway.amazonaws.com \
      --source-arn $SOURCE_ARN
  # Должен вернуть Statement
  ```

### Верификация Permission

- [ ] **Lambda policy содержит statement**
  ```bash
  aws lambda get-policy --function-name $LAMBDA_FUNCTION
  # Должен содержать AllowAPIGatewayInvoke-task7
  ```

- [ ] **Principal = apigateway.amazonaws.com**
  ```bash
  aws lambda get-policy --function-name $LAMBDA_FUNCTION | \
      jq '.Policy | fromjson | .Statement[] | select(.Sid=="AllowAPIGatewayInvoke-task7") | .Principal.Service'
  # Должен быть: "apigateway.amazonaws.com"
  ```

- [ ] **Action = lambda:InvokeFunction**
  ```bash
  aws lambda get-policy --function-name $LAMBDA_FUNCTION | \
      jq '.Policy | fromjson | .Statement[] | select(.Sid=="AllowAPIGatewayInvoke-task7") | .Action'
  # Должен быть: "lambda:InvokeFunction"
  ```

- [ ] **SourceArn правильный**
  ```bash
  aws lambda get-policy --function-name $LAMBDA_FUNCTION | \
      jq '.Policy | fromjson | .Statement[] | select(.Sid=="AllowAPIGatewayInvoke-task7") | .Condition.ArnLike."AWS:SourceArn"'
  # Должен быть: "arn:aws:execute-api:eu-west-1:418272778502:erv7myh2nb/*/*"
  ```

---

## 🧪 Шаг 4: Тестирование API

### HTTP Requests

- [ ] **API endpoint доступен**
  ```bash
  FULL_ENDPOINT="$API_ENDPOINT/contacts"
  curl -s "$FULL_ENDPOINT" | head -5
  # Должен вернуть JSON
  ```

- [ ] **HTTP Status = 200**
  ```bash
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FULL_ENDPOINT")
  echo $HTTP_CODE
  # Должен быть: 200
  ```

- [ ] **Response = JSON array**
  ```bash
  curl -s "$FULL_ENDPOINT" | jq 'type'
  # Должен быть: "array"
  ```

- [ ] **Response содержит контакты**
  ```bash
  curl -s "$FULL_ENDPOINT" | jq '.[0] | keys'
  # Должен содержать: id, name, email, phone
  ```

- [ ] **Content-Type = application/json**
  ```bash
  curl -s -I "$FULL_ENDPOINT" | grep -i content-type
  # Должен быть: content-type: application/json
  ```

### Browser Test

- [ ] **API открывается в браузере**
  ```bash
  # macOS
  open "$FULL_ENDPOINT"
  
  # Linux
  xdg-open "$FULL_ENDPOINT"
  
  # Или скопируйте: https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts
  ```
  
  **Ожидаемый результат:** JSON массив с контактами отображается в браузере

### Direct Lambda Test

- [ ] **Lambda вызывается напрямую**
  ```bash
  aws lambda invoke \
      --function-name $LAMBDA_FUNCTION \
      --payload '{"httpMethod":"GET","path":"/contacts"}' \
      response.json
  
  cat response.json
  # Должен содержать statusCode, headers, body
  ```

- [ ] **Lambda response имеет правильный format**
  ```bash
  jq '.statusCode' response.json
  # Должен быть: 200
  
  jq '.headers."Content-Type"' response.json
  # Должен быть: "application/json"
  
  jq '.body | fromjson | type' response.json
  # Должен быть: "array"
  ```

---

## 📊 Шаг 5: Мониторинг и Logs

### Lambda Logs

- [ ] **Lambda logs доступны**
  ```bash
  aws logs tail /aws/lambda/$LAMBDA_FUNCTION --since 5m
  # Должен показать последние logs
  ```

- [ ] **Logs содержат START/END/REPORT**
  ```bash
  aws logs tail /aws/lambda/$LAMBDA_FUNCTION --since 5m | grep -E "START|END|REPORT"
  # Должен показать execution logs
  ```

- [ ] **Нет ERROR в logs**
  ```bash
  aws logs filter-log-events \
      --log-group-name /aws/lambda/$LAMBDA_FUNCTION \
      --filter-pattern "ERROR" \
      --max-items 10
  # Должен быть пустой или нет критических ошибок
  ```

### CloudWatch Metrics

- [ ] **Lambda invocations > 0**
  ```bash
  aws cloudwatch get-metric-statistics \
      --namespace AWS/Lambda \
      --metric-name Invocations \
      --dimensions Name=FunctionName,Value=$LAMBDA_FUNCTION \
      --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
      --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
      --period 300 \
      --statistics Sum \
      --query 'Datapoints[*].Sum' --output text
  # Должен быть > 0
  ```

- [ ] **Lambda errors = 0**
  ```bash
  aws cloudwatch get-metric-statistics \
      --namespace AWS/Lambda \
      --metric-name Errors \
      --dimensions Name=FunctionName,Value=$LAMBDA_FUNCTION \
      --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
      --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
      --period 300 \
      --statistics Sum \
      --query 'Datapoints[*].Sum' --output text
  # Должен быть 0 или пусто
  ```

- [ ] **Lambda duration < 1000ms**
  ```bash
  aws cloudwatch get-metric-statistics \
      --namespace AWS/Lambda \
      --metric-name Duration \
      --dimensions Name=FunctionName,Value=$LAMBDA_FUNCTION \
      --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
      --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
      --period 300 \
      --statistics Average \
      --query 'Datapoints[*].Average' --output text
  # Должен быть < 1000ms (обычно 50-200ms)
  ```

---

## 🏗 Шаг 6: Архитектурная верификация

### Component Relationships

- [ ] **API Gateway → Route → Integration → Lambda (цепочка)**
  ```bash
  # 1. API Gateway
  aws apigatewayv2 get-api --api-id $API_ID --query 'Name' --output text
  
  # 2. Route в API
  aws apigatewayv2 get-route --api-id $API_ID --route-id $ROUTE_ID --query 'RouteKey' --output text
  
  # 3. Route target = Integration
  ROUTE_TARGET=$(aws apigatewayv2 get-route --api-id $API_ID --route-id $ROUTE_ID --query 'Target' --output text)
  echo $ROUTE_TARGET  # integrations/...
  
  # 4. Integration → Lambda
  aws apigatewayv2 get-integration --api-id $API_ID --integration-id $INTEGRATION_ID \
      --query 'IntegrationUri' --output text  # Lambda ARN
  ```

### Security Configuration

- [ ] **Lambda resource-based policy существует**
  ```bash
  aws lambda get-policy --function-name $LAMBDA_FUNCTION | \
      jq '.Policy | fromjson | .Statement | length'
  # Должен быть > 0
  ```

- [ ] **API Gateway может вызывать Lambda**
  ```bash
  aws lambda get-policy --function-name $LAMBDA_FUNCTION | \
      jq '.Policy | fromjson | .Statement[] | select(.Principal.Service=="apigateway.amazonaws.com")'
  # Должен существовать
  ```

- [ ] **Source ARN ограничивает доступ**
  ```bash
  aws lambda get-policy --function-name $LAMBDA_FUNCTION | \
      jq '.Policy | fromjson | .Statement[] | select(.Principal.Service=="apigateway.amazonaws.com") | .Condition'
  # Должен содержать ArnLike condition
  ```

---

## ✅ Финальная проверка

### All-In-One Verification Script

Запустите этот скрипт для полной проверки:

```bash
#!/bin/bash

echo "=== Task 7: Final Verification ==="
echo ""

# 1. API Gateway
echo "1️⃣ API Gateway:"
aws apigatewayv2 get-api --api-id $API_ID --query '[Name,ProtocolType,ApiEndpoint]' --output table
echo ""

# 2. Routes
echo "2️⃣ Routes:"
aws apigatewayv2 get-routes --api-id $API_ID --query 'Items[*].[RouteKey,Target]' --output table
echo ""

# 3. Integrations
echo "3️⃣ Integrations:"
aws apigatewayv2 get-integrations --api-id $API_ID --query 'Items[*].[IntegrationId,IntegrationType,PayloadFormatVersion]' --output table
echo ""

# 4. Lambda Permission
echo "4️⃣ Lambda Permission:"
aws lambda get-policy --function-name $LAMBDA_FUNCTION | \
    jq '.Policy | fromjson | .Statement[] | select(.Principal.Service=="apigateway.amazonaws.com") | {Sid, Action, Principal: .Principal.Service}'
echo ""

# 5. HTTP Test
echo "5️⃣ HTTP Test:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_ENDPOINT/contacts")
echo "Status Code: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ API works!"
    curl -s "$API_ENDPOINT/contacts" | jq '. | length'
    echo "contacts returned"
else
    echo "❌ API failed with status $HTTP_CODE"
fi
echo ""

# 6. Lambda Logs
echo "6️⃣ Recent Lambda Invocations:"
aws logs filter-log-events \
    --log-group-name /aws/lambda/$LAMBDA_FUNCTION \
    --filter-pattern "REPORT RequestId" \
    --max-items 3 \
    --query 'events[*].message' \
    --output text | grep -oP 'Duration: \K[0-9.]+ ms' | head -3
echo ""

echo "=== ✅ Verification Complete ==="
```

### Success Criteria

Все следующие критерии должны быть выполнены:

- ✅ **API Gateway** существует и имеет тип HTTP
- ✅ **Route** `GET /contacts` привязан к Lambda Integration
- ✅ **Integration** типа AWS_PROXY с Payload Version 2.0
- ✅ **Lambda** имеет resource-based policy для API Gateway
- ✅ **HTTP запрос** возвращает 200 OK
- ✅ **Response** содержит JSON массив контактов
- ✅ **Lambda logs** показывают успешные invocations
- ✅ **CloudWatch Metrics** показывают invocations без ошибок

---

## 🔧 Troubleshooting Checklist

Если что-то не работает, проверьте:

### API возвращает 403 Forbidden

- [ ] Lambda permission существует
- [ ] Principal = `apigateway.amazonaws.com`
- [ ] Source ARN правильный
- [ ] Statement ID уникальный

**Fix:**
```bash
aws lambda add-permission \
    --function-name $LAMBDA_FUNCTION \
    --statement-id AllowAPIGatewayInvoke-task7 \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*"
```

### API возвращает 500 Internal Server Error

- [ ] Lambda logs показывают ошибку?
- [ ] Lambda State = Active?
- [ ] Lambda response format правильный?
- [ ] Lambda timeout не exceeded?

**Fix:**
```bash
# Проверить logs
aws logs tail /aws/lambda/$LAMBDA_FUNCTION --since 5m

# Протестировать Lambda напрямую
aws lambda invoke \
    --function-name $LAMBDA_FUNCTION \
    --payload '{"httpMethod":"GET","path":"/contacts"}' \
    response.json
cat response.json
```

### Route не вызывает Lambda

- [ ] Route Target = `integrations/$INTEGRATION_ID`?
- [ ] Integration существует?
- [ ] Integration URI = Lambda ARN?

**Fix:**
```bash
# Проверить route target
aws apigatewayv2 get-route --api-id $API_ID --route-id $ROUTE_ID --query 'Target'

# Обновить route
aws apigatewayv2 update-route \
    --api-id $API_ID \
    --route-id $ROUTE_ID \
    --target "integrations/$INTEGRATION_ID"
```

### Integration не работает

- [ ] IntegrationType = AWS_PROXY?
- [ ] PayloadFormatVersion = 2.0?
- [ ] IntegrationUri правильный?

**Fix:**
```bash
# Удалить старый integration
aws apigatewayv2 delete-integration --api-id $API_ID --integration-id $INTEGRATION_ID

# Создать новый
aws apigatewayv2 create-integration \
    --api-id $API_ID \
    --integration-type AWS_PROXY \
    --integration-uri $LAMBDA_ARN \
    --payload-format-version 2.0
```

---

## 📈 Performance Checklist

### Response Time

- [ ] **First request (cold start) < 3000ms**
  ```bash
  time curl -s "$API_ENDPOINT/contacts" > /dev/null
  ```

- [ ] **Warm requests < 200ms**
  ```bash
  # Сделать 5 запросов подряд
  for i in {1..5}; do
      time curl -s "$API_ENDPOINT/contacts" > /dev/null
  done
  ```

### Lambda Performance

- [ ] **Average duration < 500ms**
  ```bash
  aws cloudwatch get-metric-statistics \
      --namespace AWS/Lambda \
      --metric-name Duration \
      --dimensions Name=FunctionName,Value=$LAMBDA_FUNCTION \
      --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
      --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
      --period 300 \
      --statistics Average
  ```

- [ ] **Memory usage < 50% allocated**
  ```bash
  aws logs filter-log-events \
      --log-group-name /aws/lambda/$LAMBDA_FUNCTION \
      --filter-pattern "REPORT" \
      --max-items 5 \
      --query 'events[*].message' \
      --output text | grep -oP 'Memory Size: \K[0-9]+ MB.*Max Memory Used: \K[0-9]+ MB'
  ```

---

## 🎯 Learning Outcomes Checklist

После выполнения Task 7 вы должны понимать:

### Concepts

- [ ] Разницу между HTTP API и REST API
- [ ] Что такое AWS_PROXY integration
- [ ] Payload Format Version 2.0 vs 1.0
- [ ] Resource-based policy vs Identity-based policy
- [ ] Source ARN и его роль в security

### Skills

- [ ] Создавать Lambda integrations
- [ ] Обновлять routes в API Gateway
- [ ] Добавлять Lambda permissions
- [ ] Тестировать API endpoints
- [ ] Читать Lambda logs
- [ ] Troubleshoot API Gateway + Lambda issues

### AWS CLI Commands

- [ ] `aws apigatewayv2 create-integration`
- [ ] `aws apigatewayv2 update-route`
- [ ] `aws lambda add-permission`
- [ ] `aws lambda get-policy`
- [ ] `aws logs tail`
- [ ] `aws cloudwatch get-metric-statistics`

---

## ✅ Итоговый статус

Подсчитайте выполненные пункты:

```
Pre-Flight: ____ / 8
Существующие ресурсы: ____ / 9
Lambda Integration: ____ / 5
Route Update: ____ / 2
Lambda Permission: ____ / 5
API Testing: ____ / 10
Monitoring: ____ / 6
Architecture: ____ / 3
Final Verification: ____ / 8

TOTAL: ____ / 56
```

**Success Threshold**: > 52 / 56 (> 93%)

---

## 📝 Следующие шаги

После завершения чек-листа:

- [ ] Прочитать [ARCHITECTURE.md](./ARCHITECTURE.md)
- [ ] Изучить [PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)
- [ ] Экспериментировать с разными integration types
- [ ] Добавить новые routes (POST, PUT, DELETE)

---

**🎉 Поздравляем! Task 7 выполнен успешно!**

Вы настроили полноценную интеграцию API Gateway с Lambda функцией!
