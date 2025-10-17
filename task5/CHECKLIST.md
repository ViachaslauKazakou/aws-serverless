# ✅ Task 5: Чек-лист выполнения

## 📋 Pre-requisites

- [ ] AWS CLI установлен (`aws --version`)
- [ ] bash shell доступен
- [ ] curl установлен (для тестирования)
- [ ] Credentials получены из задачи
- [ ] Region установлен на `eu-west-1`

## 🔑 Setup

- [ ] Установлены environment variables:
  ```bash
  export AWS_ACCESS_KEY_ID=AKIAR7HWYB7GGJEF5KH7
  export AWS_SECRET_ACCESS_KEY=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
  export AWS_DEFAULT_REGION=eu-west-1
  ```
- [ ] Проверка credentials: `aws sts get-caller-identity`
- [ ] Account ID подтвержден: `135808946124`

## 🔍 Исследование (Discovery)

- [ ] Lambda function найдена:
  ```bash
  aws lambda get-function --function-name cmtr-4n6e9j62-iam-lp-lambda
  ```
  - [ ] Function Name: `cmtr-4n6e9j62-iam-lp-lambda`
  - [ ] Runtime: `python3.9`
  - [ ] Handler: `get_aws_users.lambda_handler`
  - [ ] State: `Active`

- [ ] Execution Role найдена:
  ```bash
  aws iam get-role --role-name cmtr-4n6e9j62-iam-lp-iam_role
  ```
  - [ ] Role Name: `cmtr-4n6e9j62-iam-lp-iam_role`

- [ ] API Gateway найден:
  ```bash
  aws apigatewayv2 get-apis --query "Items[?Name=='cmtr-4n6e9j62-iam-lp-apigwv2_api']"
  ```
  - [ ] API Name: `cmtr-4n6e9j62-iam-lp-apigwv2_api`
  - [ ] API ID записан (понадобится)
  - [ ] API Endpoint записан (понадобится)

## 📝 Шаг 1: Identity-based Policy (Execution Role)

- [ ] Определена нужная AWS Managed Policy: `AWSLambda_ReadOnlyAccess`
  - ❌ Не `AWSLambdaFullAccess` (too broad)
  - ❌ Не `ReadOnlyAccess` (too broad)
  - ✅ Именно `AWSLambda_ReadOnlyAccess` (least privilege)

- [ ] Policy attached к execution role:
  ```bash
  aws iam attach-role-policy \
      --role-name cmtr-4n6e9j62-iam-lp-iam_role \
      --policy-arn arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess
  ```

- [ ] Проверка attached policy:
  ```bash
  aws iam list-attached-role-policies --role-name cmtr-4n6e9j62-iam-lp-iam_role
  ```
  - [ ] `AWSLambda_ReadOnlyAccess` присутствует в списке

- [ ] (Опционально) Симуляция permissions:
  ```bash
  aws iam simulate-principal-policy \
      --policy-source-arn arn:aws:iam::135808946124:role/cmtr-4n6e9j62-iam-lp-iam_role \
      --action-names lambda:ListFunctions lambda:GetFunction
  ```
  - [ ] Оба actions: `allowed`

## 🔐 Шаг 2: Resource-based Policy (Lambda Permission)

- [ ] API Gateway ID получен (из Discovery):
  ```bash
  API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='cmtr-4n6e9j62-iam-lp-apigwv2_api'].ApiId" --output text)
  ```

- [ ] Lambda permission добавлен:
  ```bash
  aws lambda add-permission \
      --function-name cmtr-4n6e9j62-iam-lp-lambda \
      --statement-id AllowAPIGatewayInvoke \
      --action lambda:InvokeFunction \
      --principal apigateway.amazonaws.com \
      --source-arn "arn:aws:execute-api:eu-west-1:135808946124:${API_ID}/*/*"
  ```
  - [ ] Команда выполнена успешно (или "already exists" - это OK)

- [ ] Проверка Lambda policy:
  ```bash
  aws lambda get-policy --function-name cmtr-4n6e9j62-iam-lp-lambda
  ```
  - [ ] Policy содержит statement с Sid `AllowAPIGatewayInvoke`
  - [ ] Principal: `apigateway.amazonaws.com`
  - [ ] Action: `lambda:InvokeFunction`
  - [ ] Source ARN указывает на API Gateway

## ✅ Верификация

### Тест 1: Execution Role Policy
```bash
aws iam list-attached-role-policies --role-name cmtr-4n6e9j62-iam-lp-iam_role
```
- [ ] ✅ `AWSLambda_ReadOnlyAccess` в списке

### Тест 2: Lambda Resource-based Policy
```bash
aws lambda get-policy --function-name cmtr-4n6e9j62-iam-lp-lambda | jq '.Policy | fromjson'
```
- [ ] ✅ Statement с principal `apigateway.amazonaws.com` найден

### Тест 3: API Gateway Integration
```bash
aws apigatewayv2 get-integrations --api-id $API_ID
```
- [ ] ✅ Интеграция с Lambda функцией существует

### Тест 4: HTTP Request к API
```bash
API_ENDPOINT=$(aws apigatewayv2 get-apis --query "Items[?Name=='cmtr-4n6e9j62-iam-lp-apigwv2_api'].ApiEndpoint" --output text)
curl -i $API_ENDPOINT
```
- [ ] ✅ HTTP Status Code: `200`
- [ ] ✅ Content-Type: `application/json`
- [ ] ✅ Response body содержит список Lambda функций

### Тест 5: Browser Test
- [ ] Открыть API Endpoint в браузере
- [ ] ✅ JSON с Lambda функциями отображается

## 🎯 Итоговая проверка

### Identity-based Policy (Move 1)
- [ ] ✅ AWS Managed Policy `AWSLambda_ReadOnlyAccess` attached к execution role
- [ ] ✅ Lambda function может читать информацию о Lambda функциях
- [ ] ✅ Соблюден Least Privilege principle

### Resource-based Policy (Move 2)
- [ ] ✅ Lambda permission для API Gateway добавлен
- [ ] ✅ API Gateway может вызывать Lambda функцию
- [ ] ✅ Source ARN ограничивает доступ только к конкретному API

### Функциональность
- [ ] ✅ HTTP запрос к API Gateway успешен (200)
- [ ] ✅ Lambda функция выполняется без ошибок
- [ ] ✅ Возвращается корректный JSON ответ
- [ ] ✅ Список Lambda функций включает тестовую функцию

## 📊 Результаты

### Что настроено:
- [x] Identity-based policy (Execution Role)
  - Policy: `AWSLambda_ReadOnlyAccess`
  - Attached to: `cmtr-4n6e9j62-iam-lp-iam_role`
  - Permissions: `lambda:Get*`, `lambda:List*`

- [x] Resource-based policy (Lambda Function)
  - Statement ID: `AllowAPIGatewayInvoke`
  - Principal: `apigateway.amazonaws.com`
  - Action: `lambda:InvokeFunction`
  - Condition: Source ARN = API Gateway

### Что работает:
- [x] Lambda может получать список Lambda функций
- [x] API Gateway может вызывать Lambda функцию
- [x] HTTP API возвращает корректный JSON

### Демонстрируемые концепции:
- [x] Identity-based vs Resource-based policies
- [x] AWS Managed Policies
- [x] Service-to-service permissions
- [x] Least Privilege principle
- [x] Principal: Service (не user/role)

## 🔄 Cleanup (опционально)

Если нужно откатить изменения:

- [ ] Удалить Lambda permission:
  ```bash
  aws lambda remove-permission \
      --function-name cmtr-4n6e9j62-iam-lp-lambda \
      --statement-id AllowAPIGatewayInvoke
  ```

- [ ] Detach managed policy:
  ```bash
  aws iam detach-role-policy \
      --role-name cmtr-4n6e9j62-iam-lp-iam_role \
      --policy-arn arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess
  ```

- [ ] Проверка cleanup:
  - [ ] Lambda policy не содержит API Gateway statement
  - [ ] Execution role не имеет `AWSLambda_ReadOnlyAccess`

## 📝 Заметки

### Важные моменты:
- Используется AWS Managed Policy (не custom)
- Resource-based policy через `add-permission` (не policy document)
- Source ARN с wildcards `*/*` для всех stages/routes
- Principal указан как service, не IAM entity

### Типичные ошибки:
- ❌ Неправильная AWS Managed Policy (не `AWSLambda_ReadOnlyAccess`)
- ❌ Забыть указать Source ARN в Lambda permission
- ❌ Неправильный Principal (должен быть `apigateway.amazonaws.com`)
- ❌ Неправильный region или account ID

### Best Practices:
- ✅ Least Privilege (ReadOnly, не FullAccess)
- ✅ Explicit Source ARN (не `*`)
- ✅ Service principal (не `*`)
- ✅ Unique Statement ID

## 🎓 Выводы

После выполнения Task 5 вы поняли:

- [x] Разницу между Identity-based и Resource-based policies
- [x] Как использовать AWS Managed Policies
- [x] Как настроить Lambda + API Gateway integration
- [x] Принцип Least Privilege в IAM
- [x] Service-to-service authorization

## 🎉 Поздравляем!

Все чекбоксы отмечены? 

**Task 5 выполнен успешно! 🚀**

---

**Следующие шаги:**
- Изучите ARCHITECTURE.md для понимания архитектуры
- Прочитайте PROJECT_SUMMARY.md для закрепления
- Попробуйте выполнить cleanup и настроить заново
