# 🏗️ Task 5: Архитектура решения

## 📐 Обзор архитектуры

Task 5 демонстрирует интеграцию AWS Lambda с API Gateway, используя два типа IAM policies для полного контроля доступа.

## 🎯 Компоненты системы

### 1. API Gateway (HTTP API)
```
┌─────────────────────────────────────┐
│     API Gateway HTTP API            │
│  cmtr-4n6e9j62-iam-lp-apigwv2_api   │
├─────────────────────────────────────┤
│  Type: HTTP API (v2)                │
│  Region: eu-west-1                  │
│  Integration: Lambda Proxy          │
│  Route: ANY /                       │
└─────────────────────────────────────┘
```

**Назначение:**
- Предоставляет HTTP endpoint для вызова Lambda
- Проксирует запросы к Lambda функции
- Автоматически преобразует HTTP → Lambda Event

### 2. Lambda Function
```
┌─────────────────────────────────────┐
│      Lambda Function                │
│  cmtr-4n6e9j62-iam-lp-lambda        │
├─────────────────────────────────────┤
│  Runtime: Python 3.9                │
│  Handler: get_aws_users             │
│  Description: Returns Lambda list   │
│  State: Active                      │
└─────────────────────────────────────┘
```

**Назначение:**
- Получает список всех Lambda функций в аккаунте
- Использует boto3 для вызова Lambda API
- Возвращает JSON с информацией о функциях

### 3. Execution Role
```
┌─────────────────────────────────────┐
│      IAM Role                       │
│  cmtr-4n6e9j62-iam-lp-iam_role      │
├─────────────────────────────────────┤
│  Type: Lambda Execution Role        │
│  Trust Policy: Lambda service       │
│  Attached Policies:                 │
│    - AWSLambda_ReadOnlyAccess       │
└─────────────────────────────────────┘
```

**Назначение:**
- Lambda assume эту роль при выполнении
- Определяет ЧТО может делать Lambda
- Дает права на Lambda API (ListFunctions, GetFunction)

## 🔄 Архитектурная диаграмма (Full Flow)

```
   ┌──────────┐
   │  Client  │  (Browser / curl)
   └────┬─────┘
        │ HTTP GET https://api.endpoint/
        │
        ▼
┌───────────────────────────────────────┐
│      API Gateway (HTTP API)           │
│  cmtr-4n6e9j62-iam-lp-apigwv2_api     │
└───────┬───────────────────────────────┘
        │ Needs: lambda:InvokeFunction
        │ Via: Resource-based Policy
        │       ↓
        │   ┌───────────────────────────────┐
        │   │ Lambda Resource-based Policy  │
        │   │ Principal: apigateway...      │
        │   │ Action: lambda:InvokeFunction │
        │   └───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│      Lambda Function                  │
│  cmtr-4n6e9j62-iam-lp-lambda          │
│  Handler: get_aws_users.lambda_handler│
└───────┬───────────────────────────────┘
        │ Assumes Role
        │
        ▼
┌───────────────────────────────────────┐
│      Execution Role                   │
│  cmtr-4n6e9j62-iam-lp-iam_role        │
│  + AWSLambda_ReadOnlyAccess           │
└───────┬───────────────────────────────┘
        │ Needs: lambda:ListFunctions
        │ Via: Identity-based Policy
        │       ↓
        │   ┌───────────────────────────────┐
        │   │ AWS Managed Policy            │
        │   │ AWSLambda_ReadOnlyAccess      │
        │   │ Actions: lambda:Get*, List*   │
        │   └───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│      AWS Lambda Service API           │
│  lambda:ListFunctions                 │
│  lambda:GetFunction                   │
└───────────────────────────────────────┘
```

## 🔐 Два типа IAM Policies

### Identity-based Policy (Execution Role)

```
┌────────────────────────────────────────────────────┐
│              Identity-based Policy                 │
├────────────────────────────────────────────────────┤
│  Where:  Attached to IAM Role                      │
│  Type:   AWS Managed Policy                        │
│  Name:   AWSLambda_ReadOnlyAccess                  │
│  ARN:    arn:aws:iam::aws:policy/...               │
│                                                     │
│  Question: ЧТО может делать identity?              │
│  Answer:   Читать Lambda функции                   │
│                                                     │
│  Document:                                         │
│  {                                                  │
│    "Version": "2012-10-17",                        │
│    "Statement": [{                                 │
│      "Effect": "Allow",                            │
│      "Action": [                                   │
│        "lambda:Get*",                              │
│        "lambda:List*"                              │
│      ],                                            │
│      "Resource": "*"                               │
│    }]                                              │
│  }                                                 │
└────────────────────────────────────────────────────┘
```

**Ключевые характеристики:**
- ✅ Attached к IAM role
- ✅ Определяет permissions identity
- ✅ Используется при Lambda выполняет код
- ✅ Least Privilege: ReadOnly, не FullAccess

### Resource-based Policy (Lambda Function)

```
┌────────────────────────────────────────────────────┐
│              Resource-based Policy                 │
├────────────────────────────────────────────────────┤
│  Where:  Attached to Lambda Function               │
│  Type:   Lambda Permission                         │
│  Sid:    AllowAPIGatewayInvoke                     │
│                                                     │
│  Question: КТО может использовать ресурс?          │
│  Answer:   API Gateway service                     │
│                                                     │
│  Document:                                         │
│  {                                                  │
│    "Version": "2012-10-17",                        │
│    "Statement": [{                                 │
│      "Sid": "AllowAPIGatewayInvoke",               │
│      "Effect": "Allow",                            │
│      "Principal": {                                │
│        "Service": "apigateway.amazonaws.com"       │
│      },                                            │
│      "Action": "lambda:InvokeFunction",            │
│      "Resource": "arn:aws:lambda:...:function:...",│
│      "Condition": {                                │
│        "ArnLike": {                                │
│          "AWS:SourceArn": "arn:aws:execute-api:..."│
│        }                                           │
│      }                                             │
│    }]                                              │
│  }                                                 │
└────────────────────────────────────────────────────┘
```

**Ключевые характеристики:**
- ✅ Attached к Lambda resource
- ✅ Определяет кто может invoke
- ✅ Principal: Service (не IAM user/role)
- ✅ Condition: Ограничение по Source ARN

## 🔀 Policy Evaluation Flow

### Сценарий: API Gateway вызывает Lambda

```
Step 1: API Gateway → Lambda
┌─────────────────────────────────────┐
│  Check: Lambda Resource-based Policy│
├─────────────────────────────────────┤
│  Principal: apigateway.amazonaws.com│
│  Action: lambda:InvokeFunction      │
│  Condition: Source ARN matches      │
│                                     │
│  Result: ✅ ALLOW                   │
└─────────────────────────────────────┘

Step 2: Lambda → Lambda API (list functions)
┌─────────────────────────────────────┐
│  Check: Execution Role Policy       │
├─────────────────────────────────────┤
│  Policy: AWSLambda_ReadOnlyAccess   │
│  Action: lambda:ListFunctions       │
│  Resource: *                        │
│                                     │
│  Result: ✅ ALLOW                   │
└─────────────────────────────────────┘
```

### Сценарий: Неавторизованный service пытается вызвать Lambda

```
Step 1: Unknown Service → Lambda
┌─────────────────────────────────────┐
│  Check: Lambda Resource-based Policy│
├─────────────────────────────────────┤
│  Principal: unknown.amazonaws.com   │
│  Expected: apigateway.amazonaws.com │
│                                     │
│  Result: ❌ IMPLICIT DENY           │
└─────────────────────────────────────┘

Request blocked ⛔
```

## 🎭 Роли компонентов

### API Gateway
- **Роль**: Клиент Lambda функции
- **Нужны права**: `lambda:InvokeFunction`
- **Как получает**: Resource-based policy на Lambda
- **Principal**: `apigateway.amazonaws.com` (service principal)

### Lambda Function
- **Роль 1**: Сервер для API Gateway
  - Принимает invocations от API Gateway
  - Контролируется: Resource-based policy
  
- **Роль 2**: Клиент Lambda API
  - Вызывает Lambda API для получения списка функций
  - Контролируется: Identity-based policy (execution role)

### Execution Role
- **Роль**: Identity для Lambda
- **Assumed by**: Lambda service
- **Определяет**: Что может делать Lambda код
- **Управляется**: IAM policies (attached)

## 🔍 Сравнение двух подходов

### Identity-based (Execution Role)
```
WHO?    → Lambda Function (execution role)
WHAT?   → lambda:ListFunctions, lambda:GetFunction
WHERE?  → AWS Lambda Service API
HOW?    → Attached AWS Managed Policy
WHEN?   → Lambda код выполняется
```

### Resource-based (Lambda Permission)
```
WHO?    → API Gateway Service
WHAT?   → lambda:InvokeFunction
WHERE?  → Specific Lambda Function
HOW?    → add-permission statement
WHEN?   → API Gateway вызывает Lambda
```

## 📊 Permission Matrix

| Action | Who | Policy Type | Policy Location | Purpose |
|--------|-----|-------------|-----------------|---------|
| `lambda:InvokeFunction` | API Gateway | Resource-based | Lambda Function | API → Lambda |
| `lambda:ListFunctions` | Lambda (via role) | Identity-based | Execution Role | Lambda → Lambda API |
| `lambda:GetFunction` | Lambda (via role) | Identity-based | Execution Role | Lambda → Lambda API |

## 🏛️ Trust Relationships

### Lambda Trust Policy (Execution Role)
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}
```

**Означает:** Lambda service может assume эту роль

### Lambda Resource Policy (Function)
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "AllowAPIGatewayInvoke",
    "Effect": "Allow",
    "Principal": {
      "Service": "apigateway.amazonaws.com"
    },
    "Action": "lambda:InvokeFunction",
    "Resource": "arn:aws:lambda:eu-west-1:135808946124:function:cmtr-4n6e9j62-iam-lp-lambda",
    "Condition": {
      "ArnLike": {
        "AWS:SourceArn": "arn:aws:execute-api:eu-west-1:135808946124:*/*/*"
      }
    }
  }]
}
```

**Означает:** API Gateway service может invoke эту Lambda функцию

## 🔐 Security Best Practices

### 1. Least Privilege
✅ **Применено:**
- Используется `AWSLambda_ReadOnlyAccess`, не `AWSLambdaFullAccess`
- Только необходимые actions: `Get*`, `List*`
- Source ARN ограничивает вызовы конкретным API

❌ **Не делать:**
- `"Action": "lambda:*"` (слишком широко)
- `"Resource": "*"` в resource-based policy
- `"Principal": "*"` (открывает всем)

### 2. Explicit Source ARN
✅ **Применено:**
```json
"Condition": {
  "ArnLike": {
    "AWS:SourceArn": "arn:aws:execute-api:region:account:api-id/*/*"
  }
}
```

**Защищает от:**
- Вызовов из других API Gateway в том же аккаунте
- Вызовов из других аккаунтов

### 3. Service Principal
✅ **Применено:**
```json
"Principal": {
  "Service": "apigateway.amazonaws.com"
}
```

**Лучше чем:**
- `"Principal": "*"` (кто угодно)
- `"Principal": {"AWS": "arn:aws:iam::account:root"}` (весь аккаунт)

### 4. AWS Managed Policies
✅ **Применено:**
- Используется `AWSLambda_ReadOnlyAccess`
- Обновляется AWS автоматически
- Следует AWS best practices

**Преимущества:**
- Не нужно поддерживать самостоятельно
- Проверены AWS security team
- Автоматически обновляются при появлении новых actions

## 📈 Масштабирование архитектуры

### Добавить больше API Endpoints
```bash
# Текущий permission работает для всех routes в API
"SourceArn": "arn:aws:execute-api:region:account:api-id/*/*"
                                                        ↑↑
                                              stage + route wildcards
```

### Добавить другой API Gateway
```bash
# Нужен дополнительный statement:
aws lambda add-permission \
    --statement-id AllowAnotherAPIGateway \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:region:account:another-api-id/*/*"
```

### Добавить другие actions для Lambda
```bash
# Если нужны write permissions, attach другую policy:
aws iam attach-role-policy \
    --role-name cmtr-4n6e9j62-iam-lp-iam_role \
    --policy-arn arn:aws:iam::aws:policy/AWSLambdaFullAccess
```

## 🎓 Ключевые выводы

### Identity-based Policy
- 🎯 **Вопрос**: Что может делать identity?
- 📍 **Location**: Attached to IAM identity (user, role, group)
- 🔧 **Control**: Actions на resources
- 📝 **Пример**: "Lambda execution role может вызывать lambda:ListFunctions"

### Resource-based Policy
- 🎯 **Вопрос**: Кто может использовать resource?
- 📍 **Location**: Attached to resource (Lambda, S3, SNS, etc.)
- 🔧 **Control**: Principals могут access resource
- 📝 **Пример**: "API Gateway может вызывать эту Lambda функцию"

### Когда использовать что?

**Identity-based:**
- ✅ Когда контролируете identity (users, roles)
- ✅ Для permissions внутри аккаунта
- ✅ Стандартные AWS Managed Policies

**Resource-based:**
- ✅ Cross-service access (API Gateway → Lambda)
- ✅ Cross-account access
- ✅ Service principals (не IAM entities)

## 🔄 Sequence Diagram

```
Client          API Gateway          Lambda          Execution Role    Lambda API
  │                  │                  │                   │              │
  │─────GET /───────>│                  │                   │              │
  │                  │                  │                   │              │
  │                  │──Check Resource──>│                  │              │
  │                  │    based policy   │                  │              │
  │                  │<─────✅ Allow─────│                  │              │
  │                  │                  │                   │              │
  │                  │───Invoke Lambda──>│                  │              │
  │                  │                  │                   │              │
  │                  │                  │──Assume Role────>│              │
  │                  │                  │<────Credentials───│              │
  │                  │                  │                   │              │
  │                  │                  │──ListFunctions───────────────────>│
  │                  │                  │  (uses role creds)               │
  │                  │                  │                   │              │
  │                  │                  │<───Function List──────────────────│
  │                  │                  │                   │              │
  │                  │<──Return JSON────│                   │              │
  │<────JSON─────────│                  │                   │              │
  │                  │                  │                   │              │
```

---

**Эта архитектура демонстрирует правильное разделение concerns в AWS IAM:**
- Identity-based для execution permissions
- Resource-based для cross-service access
- Least Privilege principle
- Service-to-service authorization
