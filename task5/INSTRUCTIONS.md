# 📖 Task 5: Пошаговые инструкции

## 🎯 Цель задачи

Настроить два типа permissions для Lambda функции:
1. **Identity-based**: Attach AWS managed policy к execution role
2. **Resource-based**: Добавить Lambda permission для API Gateway

## 📋 Pre-requisites

- [x] AWS CLI установлен и настроен
- [x] bash shell
- [x] curl (для тестирования API)
- [x] jq (опционально, для форматирования JSON)

## 🔐 Шаг 0: Настройка credentials

```bash
export AWS_ACCESS_KEY_ID=AKIAR7HWYB7GGJEF5KH7
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
    "UserId": "...",
    "Account": "135808946124",
    "Arn": "arn:aws:iam::135808946124:user/cmtr-4n6e9j62"
}
```

## 🔍 Шаг 1: Изучение существующих ресурсов

### 1.1 Проверить Lambda функцию

```bash
aws lambda get-function --function-name cmtr-4n6e9j62-iam-lp-lambda
```

**Что проверить:**
- ✅ Имя функции: `cmtr-4n6e9j62-iam-lp-lambda`
- ✅ Runtime: `python3.9`
- ✅ Handler: `get_aws_users.lambda_handler`
- ✅ Role: `arn:aws:iam::135808946124:role/cmtr-4n6e9j62-iam-lp-iam_role`

### 1.2 Проверить Execution Role

```bash
aws iam get-role --role-name cmtr-4n6e9j62-iam-lp-iam_role
```

**Что проверить:**
- ✅ Role Name: `cmtr-4n6e9j62-iam-lp-iam_role`
- ✅ Trust Policy: Lambda может assume эту роль

### 1.3 Проверить текущие attached policies

```bash
aws iam list-attached-role-policies --role-name cmtr-4n6e9j62-iam-lp-iam_role
```

**Текущее состояние:** Возможно, нет никаких attached policies или есть базовые

### 1.4 Получить API Gateway информацию

```bash
# Получить API ID
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='cmtr-4n6e9j62-iam-lp-apigwv2_api'].ApiId" --output text)
echo "API Gateway ID: $API_ID"

# Получить API Endpoint
API_ENDPOINT=$(aws apigatewayv2 get-apis --query "Items[?Name=='cmtr-4n6e9j62-iam-lp-apigwv2_api'].ApiEndpoint" --output text)
echo "API Endpoint: $API_ENDPOINT"
```

**Сохраните эти значения** - понадобятся дальше!

## 📝 Шаг 2: Attach AWS Managed Policy (Identity-based)

### 2.1 Понять какая policy нужна

Lambda функция с handler `get_aws_users.lambda_handler` должна получать список Lambda функций.

**Нужные permissions:**
- `lambda:ListFunctions` - основное действие
- `lambda:GetFunction` - опционально, для деталей

**Выбор policy:**
Из списка в задаче правильный ответ: **`AWSLambda_ReadOnlyAccess`**

❌ `AWSLambdaFullAccess` - слишком много прав
❌ `ReadOnlyAccess` - слишком широко (все сервисы)
❌ `LambdaReadOnlyAccess` - нет такой policy
❌ `AWSLambdaBasicExecutionRole` - только CloudWatch Logs
✅ **`AWSLambda_ReadOnlyAccess`** - точно то, что нужно (least privilege)
❌ `LambdaBasicExecutionRole` - нет такой policy

### 2.2 Посмотреть содержимое policy (опционально)

```bash
# Получить ARN
POLICY_ARN="arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"

# Получить default version
aws iam get-policy --policy-arn $POLICY_ARN

# Получить policy document
VERSION_ID=$(aws iam get-policy --policy-arn $POLICY_ARN --query 'Policy.DefaultVersionId' --output text)
aws iam get-policy-version --policy-arn $POLICY_ARN --version-id $VERSION_ID
```

**Что в policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:Get*",
        "lambda:List*"
      ],
      "Resource": "*"
    }
  ]
}
```

### 2.3 Attach policy к execution role

```bash
aws iam attach-role-policy \
    --role-name cmtr-4n6e9j62-iam-lp-iam_role \
    --policy-arn arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess
```

**Успех:** Команда вернет пустой результат (это нормально)

### 2.4 Проверить что policy attached

```bash
aws iam list-attached-role-policies --role-name cmtr-4n6e9j62-iam-lp-iam_role
```

**Ожидаемый результат:**
```json
{
    "AttachedPolicies": [
        {
            "PolicyName": "AWSLambda_ReadOnlyAccess",
            "PolicyArn": "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
        }
    ]
}
```

### 2.5 Verify permissions (опционально)

```bash
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::135808946124:role/cmtr-4n6e9j62-iam-lp-iam_role \
    --action-names lambda:ListFunctions lambda:GetFunction
```

**Ожидается:** `EvaluationResult: "allowed"` для обоих actions

## 🔐 Шаг 3: Добавить Resource-based Policy для Lambda

### 3.1 Понять концепцию

**Resource-based policy** на Lambda функции позволяет ДРУГИМ сервисам (в нашем случае API Gateway) вызывать функцию.

**Компоненты:**
- **Principal**: `apigateway.amazonaws.com` (сервис API Gateway)
- **Action**: `lambda:InvokeFunction`
- **Source ARN**: `arn:aws:execute-api:region:account:api-id/*/*`

### 3.2 Проверить текущую policy Lambda (если есть)

```bash
aws lambda get-policy --function-name cmtr-4n6e9j62-iam-lp-lambda
```

**Возможный результат:**
- Ошибка "ResourceNotFoundException" - policy еще нет (это OK)
- JSON с Policy - уже есть permissions

### 3.3 Добавить permission для API Gateway

```bash
# Используем переменные из Шага 1.4
aws lambda add-permission \
    --function-name cmtr-4n6e9j62-iam-lp-lambda \
    --statement-id AllowAPIGatewayInvoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:eu-west-1:135808946124:${API_ID}/*/*"
```

**Параметры:**
- `--statement-id` - уникальный ID (можно любой)
- `--action` - что разрешаем
- `--principal` - кому разрешаем (service)
- `--source-arn` - конкретный API Gateway (`*/*` = все stages/routes)

**Успешный результат:**
```json
{
    "Statement": "{\"Sid\":\"AllowAPIGatewayInvoke\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"apigateway.amazonaws.com\"},\"Action\":\"lambda:InvokeFunction\",\"Resource\":\"arn:aws:lambda:eu-west-1:135808946124:function:cmtr-4n6e9j62-iam-lp-lambda\",\"Condition\":{\"ArnLike\":{\"AWS:SourceArn\":\"arn:aws:execute-api:eu-west-1:135808946124:API_ID/*/*\"}}}"
}
```

### 3.4 Проверить Lambda policy

```bash
aws lambda get-policy --function-name cmtr-4n6e9j62-iam-lp-lambda
```

**С jq для красоты:**
```bash
aws lambda get-policy --function-name cmtr-4n6e9j62-iam-lp-lambda | jq '.Policy | fromjson'
```

**Ожидаемая структура:**
```json
{
  "Version": "2012-10-17",
  "Id": "default",
  "Statement": [
    {
      "Sid": "AllowAPIGatewayInvoke",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:eu-west-1:135808946124:function:cmtr-4n6e9j62-iam-lp-lambda",
      "Condition": {
        "ArnLike": {
          "AWS:SourceArn": "arn:aws:execute-api:eu-west-1:135808946124:API_ID/*/*"
        }
      }
    }
  ]
}
```

## ✅ Шаг 4: Верификация

### 4.1 Проверить Execution Role permissions

```bash
# Список attached policies
aws iam list-attached-role-policies --role-name cmtr-4n6e9j62-iam-lp-iam_role
```

✅ Должен быть `AWSLambda_ReadOnlyAccess`

### 4.2 Проверить Lambda Resource-based Policy

```bash
aws lambda get-policy --function-name cmtr-4n6e9j62-iam-lp-lambda
```

✅ Должен быть statement с principal `apigateway.amazonaws.com`

### 4.3 Протестировать API Gateway

```bash
# Через curl
curl -i $API_ENDPOINT
```

**Ожидаемый результат:**
```
HTTP/2 200
content-type: application/json
...

{
  "functions": [
    {
      "FunctionName": "cmtr-4n6e9j62-iam-lp-lambda",
      ...
    }
  ]
}
```

✅ HTTP 200 с JSON списком Lambda функций

### 4.4 Тест через браузер

Откройте в браузере:
```
https://[ваш-api-id].execute-api.eu-west-1.amazonaws.com/
```

✅ Должен показать JSON с Lambda функциями

### 4.5 Проверить API Gateway integration

```bash
aws apigatewayv2 get-integrations --api-id $API_ID
```

✅ Должна быть интеграция с Lambda функцией

## 📊 Итоговая проверка

### Чек-лист:

- [x] **Credentials** настроены и работают
- [x] **Lambda function** существует и активна
- [x] **Execution role** имеет attached policy `AWSLambda_ReadOnlyAccess`
- [x] **Lambda function** имеет resource-based policy для API Gateway
- [x] **API Gateway** возвращает HTTP 200 с JSON
- [x] **JSON ответ** содержит список Lambda функций

## 🧪 Дополнительные тесты

### Тест 1: Invoke Lambda напрямую (если есть права)

```bash
aws lambda invoke \
    --function-name cmtr-4n6e9j62-iam-lp-lambda \
    --payload '{}' \
    response.json

cat response.json
```

### Тест 2: Проверить CloudWatch Logs

```bash
aws logs tail /aws/lambda/cmtr-4n6e9j62-iam-lp-lambda --follow
```

### Тест 3: Посмотреть код Lambda (опционально)

```bash
# Получить URL для скачивания кода
CODE_URL=$(aws lambda get-function --function-name cmtr-4n6e9j62-iam-lp-lambda --query 'Code.Location' --output text)

# Скачать и распаковать
curl -o lambda-code.zip "$CODE_URL"
unzip lambda-code.zip
cat get_aws_users.py
```

## 🔄 Cleanup (если нужно откатить)

### Удалить Lambda permission

```bash
aws lambda remove-permission \
    --function-name cmtr-4n6e9j62-iam-lp-lambda \
    --statement-id AllowAPIGatewayInvoke
```

### Detach managed policy

```bash
aws iam detach-role-policy \
    --role-name cmtr-4n6e9j62-iam-lp-iam_role \
    --policy-arn arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess
```

## 💡 Важные концепции

### Identity-based vs Resource-based

**Identity-based Policy** (Шаг 2):
- Attached к IAM identity (user, role, group)
- Определяет ЧТО может делать identity
- Пример: "Эта роль может вызывать lambda:ListFunctions"

**Resource-based Policy** (Шаг 3):
- Attached к ресурсу (Lambda, S3, SNS, etc.)
- Определяет КТО может использовать ресурс
- Пример: "API Gateway может вызывать эту Lambda функцию"

### Least Privilege Principle

- ❌ Не использовать `*` в actions без необходимости
- ❌ Не давать `FullAccess` если нужен только readonly
- ✅ Использовать AWS Managed Policies для стандартных сценариев
- ✅ Указывать конкретный Source ARN в conditions

## 🆘 Troubleshooting

### Error: "An error occurred (NoSuchEntity)"
**Причина:** Role или function не существует
**Решение:** Проверьте имена ресурсов

### Error: "User is not authorized"
**Причина:** Credentials не настроены или неверные
**Решение:** Проверьте AWS_ACCESS_KEY_ID и AWS_SECRET_ACCESS_KEY

### API возвращает 403
**Причина:** Нет Lambda permission для API Gateway
**Решение:** Выполните Шаг 3.3

### Lambda не может получить список функций
**Причина:** Нет `AWSLambda_ReadOnlyAccess` policy
**Решение:** Выполните Шаг 2.3

### "Permission already exists"
**Причина:** Statement ID уже используется
**Решение:** Это OK - permission уже добавлен, или используйте другой statement-id

## 📚 Дополнительная информация

- [AWS Lambda Permissions](https://docs.aws.amazon.com/lambda/latest/dg/lambda-permissions.html)
- [Resource-based Policies](https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html)
- [API Gateway Permissions](https://docs.aws.amazon.com/apigateway/latest/developerguide/permissions.html)
- [IAM Policy Evaluation Logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html)

---

**Поздравляем! Task 5 выполнен! 🎉**
