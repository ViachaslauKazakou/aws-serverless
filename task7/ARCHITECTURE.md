# 🏗 Task 7: Архитектура - API Gateway + Lambda Integration

## 📐 Обзор архитектуры

Task 7 демонстрирует **синхронную интеграцию** между Amazon API Gateway (HTTP API) и AWS Lambda. Это классический паттерн для создания serverless REST APIs.

---

## 🎯 Архитектурная диаграмма

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         TASK 7                                  │
│             API Gateway + Lambda Integration                    │
└─────────────────────────────────────────────────────────────────┘

                        INTERNET
                           │
                           │ HTTPS
                           │ GET /contacts
                           ▼
              ┌────────────────────────┐
              │   Amazon API Gateway   │
              │      (HTTP API)        │
              │   ID: erv7myh2nb       │
              │                        │
              │  Endpoint:             │
              │  https://erv7myh2nb... │
              └────────────────────────┘
                           │
                           │ Route: py00o9v
                           │ GET /contacts
                           ▼
              ┌────────────────────────┐
              │   Lambda Integration   │
              │   Type: AWS_PROXY      │
              │   Payload: v2.0        │
              │   Timeout: 30s         │
              └────────────────────────┘
                           │
                           │ Invoke
                           │ (Synchronous)
                           ▼
              ┌────────────────────────┐
              │    AWS Lambda          │
              │  api-gwlp-lambda-      │
              │      contacts          │
              │                        │
              │  Runtime: Node.js/Py   │
              │  Handler: index.handler│
              └────────────────────────┘
                           │
                           │ Return
                           │ (JSON Response)
                           ▼
              ┌────────────────────────┐
              │   Response Format      │
              │   {                    │
              │     statusCode: 200,   │
              │     headers: {...},    │
              │     body: "[...]"      │
              │   }                    │
              └────────────────────────┘
                           │
                           │
                           ▼
                        CLIENT
                   [Contact List JSON]
```

---

## 🔄 Request Flow

### Детальный flow запроса

```
1. CLIENT
   │
   ├─> HTTP GET https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts
   │
   │
2. API GATEWAY (HTTP API)
   │
   ├─> Receive request
   ├─> Route matching: GET /contacts → Route ID: py00o9v
   ├─> Check route target → integrations/abc123def
   │
   │
3. INTEGRATION (AWS_PROXY)
   │
   ├─> Transform HTTP request → Lambda Event (Payload v2.0)
   │   {
   │     "version": "2.0",
   │     "routeKey": "GET /contacts",
   │     "rawPath": "/contacts",
   │     "headers": {...},
   │     "requestContext": {...}
   │   }
   │
   ├─> Check Lambda Permission (Resource-based Policy)
   │   ✅ Principal: apigateway.amazonaws.com
   │   ✅ SourceArn: arn:aws:execute-api:...:erv7myh2nb/*/*
   │
   ├─> Invoke Lambda (Synchronous)
   │
   │
4. LAMBDA FUNCTION
   │
   ├─> Execution starts
   ├─> Process event
   ├─> Generate contacts list
   ├─> Format response
   │   {
   │     "statusCode": 200,
   │     "headers": {"Content-Type": "application/json"},
   │     "body": "[{\"id\":1,\"name\":\"John\",...}]"
   │   }
   │
   ├─> Return response
   │
   │
5. INTEGRATION (AWS_PROXY)
   │
   ├─> Receive Lambda response
   ├─> Transform Lambda response → HTTP response
   │   - statusCode → HTTP Status Code
   │   - headers → HTTP Headers
   │   - body → HTTP Body
   │
   │
6. API GATEWAY
   │
   ├─> Send HTTP response to client
   │   HTTP/2 200 OK
   │   Content-Type: application/json
   │   [
   │     {"id": 1, "name": "John Doe", ...},
   │     {"id": 2, "name": "Jane Smith", ...}
   │   ]
   │
   │
7. CLIENT
   │
   └─> Receive JSON response
       └─> Display contacts
```

---

## 🧩 Компоненты системы

### 1. Amazon API Gateway (HTTP API)

**Характеристики:**
- **Type**: HTTP API (не REST API)
- **ID**: `erv7myh2nb`
- **Region**: `eu-west-1`
- **Protocol**: HTTP/1.1, HTTP/2
- **Endpoint**: `https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com`

**Конфигурация:**
```json
{
  "ApiId": "erv7myh2nb",
  "Name": "task7-api",
  "ProtocolType": "HTTP",
  "ApiEndpoint": "https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com",
  "ApiKeySelectionExpression": "$request.header.x-api-key",
  "RouteSelectionExpression": "$request.method $request.path"
}
```

**Особенности HTTP API:**
- ✅ Дешевле REST API на 71%
- ✅ Меньше latency (~30%)
- ✅ Проще в настройке
- ✅ Автоматический CORS
- ❌ Нет API Keys
- ❌ Нет Usage Plans
- ❌ Нет Request Validation

---

### 2. Route

**Характеристики:**
- **ID**: `py00o9v`
- **RouteKey**: `GET /contacts`
- **Target**: `integrations/<integration-id>`
- **Authorization**: None (public endpoint)

**Конфигурация:**
```json
{
  "RouteId": "py00o9v",
  "RouteKey": "GET /contacts",
  "Target": "integrations/abc123def",
  "ApiKeyRequired": false,
  "AuthorizationType": "NONE"
}
```

**Route Matching Logic:**
```
Request: GET https://erv7myh2nb.../contacts
         ^^^                      ^^^^^^^^
         │                        │
         │                        └─> Path: /contacts
         └─> Method: GET

Route Key: GET /contacts
           ^^^  ^^^^^^^^
           │    │
           │    └─> Matches path
           └─> Matches method

✅ MATCH → Execute Integration
```

---

### 3. Integration (AWS_PROXY)

**Характеристики:**
- **Type**: `AWS_PROXY`
- **Method**: `POST` (всегда POST для Lambda)
- **URI**: Lambda ARN
- **Payload Format**: Version 2.0
- **Timeout**: 30000ms (30 секунд)

**Конфигурация:**
```json
{
  "IntegrationId": "abc123def",
  "IntegrationType": "AWS_PROXY",
  "IntegrationMethod": "POST",
  "IntegrationUri": "arn:aws:lambda:eu-west-1:418272778502:function:cmtr-4n6e9j62-api-gwlp-lambda-contacts",
  "PayloadFormatVersion": "2.0",
  "TimeoutInMillis": 30000
}
```

**AWS_PROXY vs AWS:**

| Feature | AWS_PROXY | AWS |
|---------|-----------|-----|
| Request Transform | Автоматический | VTL Templates |
| Response Transform | Автоматический | VTL Templates |
| Lambda Control | Полный (status, headers) | Ограниченный |
| Setup Complexity | Простой | Сложный |
| Use Case | Большинство случаев | Legacy, специфичные требования |

---

### 4. Lambda Function

**Характеристики:**
- **Name**: `cmtr-4n6e9j62-api-gwlp-lambda-contacts`
- **Runtime**: Node.js / Python (зависит от реализации)
- **Handler**: `index.handler` (или другой)
- **Memory**: 128 MB (по умолчанию)
- **Timeout**: 30 секунд (по умолчанию)

**Event Format (Payload v2.0):**
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
    "x-amzn-trace-id": "Root=1-...",
    "x-forwarded-for": "1.2.3.4",
    "x-forwarded-port": "443",
    "x-forwarded-proto": "https"
  },
  "requestContext": {
    "accountId": "418272778502",
    "apiId": "erv7myh2nb",
    "domainName": "erv7myh2nb.execute-api.eu-west-1.amazonaws.com",
    "domainPrefix": "erv7myh2nb",
    "http": {
      "method": "GET",
      "path": "/contacts",
      "protocol": "HTTP/1.1",
      "sourceIp": "1.2.3.4",
      "userAgent": "curl/7.79.1"
    },
    "requestId": "abc123-def456-...",
    "routeKey": "GET /contacts",
    "stage": "$default",
    "time": "01/Jan/2024:12:00:00 +0000",
    "timeEpoch": 1704110400000
  },
  "isBase64Encoded": false
}
```

**Response Format:**
```javascript
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*"
  },
  "body": "[{\"id\":1,\"name\":\"John Doe\",\"email\":\"john@example.com\",\"phone\":\"+1234567890\"},{\"id\":2,\"name\":\"Jane Smith\",\"email\":\"jane@example.com\",\"phone\":\"+0987654321\"}]"
}
```

**Важно:**
- `statusCode` - **число**, не строка
- `headers` - **объект** с HTTP headers
- `body` - **строка**, даже для JSON (JSON.stringify)

---

## 🔐 Security Architecture

### Lambda Resource-Based Policy

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

**Компоненты policy:**

1. **Principal**: `apigateway.amazonaws.com`
   - Кто может вызывать Lambda
   - AWS service (API Gateway)

2. **Action**: `lambda:InvokeFunction`
   - Что разрешено делать
   - Только invoke (не update, не delete)

3. **Resource**: Lambda ARN
   - К какой Lambda применяется
   - Конкретная функция

4. **Condition**: Source ARN
   - Ограничение по источнику
   - Только конкретный API Gateway

**Source ARN Pattern:**
```
arn:aws:execute-api:{region}:{account}:{api-id}/{stage}/{method}/{path}
arn:aws:execute-api:eu-west-1:418272778502:erv7myh2nb/*/*
                     ^^^^^^^^^  ^^^^^^^^^^^^  ^^^^^^^^^^^ ^^^^
                     region     account       api-id      any stage/method/path
```

**Варианты Source ARN:**
- `/*/*` - любой stage, любой метод/path
- `/$default/*` - только stage $default, любой метод/path
- `/*/GET/contacts` - любой stage, только GET /contacts
- `/$default/GET/contacts` - только $default stage и GET /contacts

---

### Lambda Execution Role

Lambda также имеет **Execution Role** (Identity-based policy):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:eu-west-1:418272778502:*"
    }
  ]
}
```

**Назначение:**
- Разрешения для **Lambda самой**
- Что Lambda может делать с AWS services
- Например: писать логи в CloudWatch

**Разница между Resource-based и Identity-based:**

| Aspect | Resource-based Policy | Identity-based Policy |
|--------|----------------------|----------------------|
| Attached to | Lambda function | IAM Role |
| Controls | Кто может вызвать Lambda | Что Lambda может делать |
| Used in Task 7 | ✅ Yes (API Gateway → Lambda) | ✅ Yes (Lambda → CloudWatch) |
| Example | Allow apigateway.amazonaws.com | Allow logs:PutLogEvents |

---

## 🔄 Integration Types (сравнение)

### 1. AWS_PROXY (используется в Task 7)

**Характеристики:**
- Lambda получает **весь HTTP request**
- Lambda **полностью контролирует response**
- API Gateway **не трансформирует** request/response
- **Автоматическая** сериализация/десериализация

**Use Cases:**
- ✅ Стандартные REST APIs
- ✅ Когда Lambda нужен полный контроль
- ✅ Динамические headers, status codes
- ✅ Большинство serverless applications

**Request Transformation:**
```
HTTP Request → Lambda Event (Payload v2.0)
```

**Response Transformation:**
```
Lambda Response → HTTP Response
```

---

### 2. AWS (с mapping templates)

**Характеристики:**
- API Gateway **трансформирует** request через VTL templates
- API Gateway **трансформирует** response через VTL templates
- Lambda не видит HTTP specifics
- **Ручная** настройка transformations

**Use Cases:**
- Legacy Lambda functions
- Специфичные transformations
- Когда нельзя менять код Lambda

**Request Transformation:**
```
HTTP Request → VTL Template → Custom Lambda Event
```

**Response Transformation:**
```
Lambda Response → VTL Template → Custom HTTP Response
```

**Пример VTL Template:**
```vtl
{
  "operation": "$context.httpMethod",
  "body": $input.json('$'),
  "queryParams": {
    #foreach($param in $input.params().querystring.keySet())
      "$param": "$util.escapeJavaScript($input.params().querystring.get($param))"
      #if($foreach.hasNext),#end
    #end
  }
}
```

---

### 3. HTTP_PROXY

**Характеристики:**
- Проксирование на **внешний HTTP endpoint**
- API Gateway передает request "as is"
- Не для Lambda, для HTTP services

**Use Cases:**
- ✅ Проксирование на внешние APIs
- ✅ Integration с on-premise HTTP services
- ✅ Migration от monolith к microservices

**Architecture:**
```
Client → API Gateway → External HTTP API
                 │
                 └─> https://external-api.com/endpoint
```

---

### 4. MOCK

**Характеристики:**
- API Gateway возвращает **статичный response**
- Нет backend вызова
- Для тестирования и prototyping

**Use Cases:**
- ✅ Тестирование API Gateway routing
- ✅ API mocking для frontend development
- ✅ Health check endpoints

**Architecture:**
```
Client → API Gateway → Mock Response (no backend)
                 │
                 └─> Return {"status": "ok"}
```

---

## 📊 Payload Format Versions

### Version 2.0 (используется в Task 7)

**Преимущества:**
- ✅ Более простой JSON structure
- ✅ Меньше вложенных объектов
- ✅ Лучше performance
- ✅ Рекомендуется для новых проектов

**Event Structure:**
```javascript
{
  "version": "2.0",
  "routeKey": "GET /contacts",
  "rawPath": "/contacts",
  "rawQueryString": "",
  "headers": {...},
  "requestContext": {
    "http": {
      "method": "GET",
      "path": "/contacts"
    }
  }
}
```

**Доступ к данным:**
```javascript
// Method
event.requestContext.http.method

// Path
event.requestContext.http.path

// Headers
event.headers['content-type']

// Query params
event.queryStringParameters?.name
```

---

### Version 1.0 (legacy)

**Характеристики:**
- Старый format для REST APIs
- Больше вложенных объектов
- Обратная совместимость

**Event Structure:**
```javascript
{
  "resource": "/contacts",
  "path": "/contacts",
  "httpMethod": "GET",
  "headers": {...},
  "queryStringParameters": null,
  "pathParameters": null,
  "requestContext": {
    "resourcePath": "/contacts",
    "httpMethod": "GET",
    "path": "/default/contacts"
  }
}
```

**Доступ к данным:**
```javascript
// Method
event.httpMethod

// Path
event.path

// Headers
event.headers['Content-Type']

// Query params
event.queryStringParameters?.name
```

---

## 🔄 Synchronous vs Asynchronous Invocation

### Task 7: Synchronous (используется)

```
Client → API Gateway → Lambda → Response → API Gateway → Client
         │                                              │
         └───────────── Waits for response ────────────┘
              (blocks until Lambda returns)
```

**Характеристики:**
- ✅ Client получает **немедленный response**
- ✅ API Gateway **ждет** Lambda completion
- ✅ Timeout: max 30 секунд (API Gateway limit)
- ❌ Client должен **wait** (может быть slow)

**Use Cases:**
- REST APIs
- Real-time queries
- Interactive applications

---

### Task 6: Asynchronous (для сравнения)

```
S3 → Event Notification → SQS → Lambda
     │                          │
     └─> Continues immediately  └─> Processes later
         (no waiting)               (eventual consistency)
```

**Характеристики:**
- ✅ Источник **не ждет** Lambda completion
- ✅ Lambda может выполняться **долго** (> 30 сек)
- ✅ Automatic retries при ошибках
- ❌ Нет immediate response

**Use Cases:**
- Event processing
- File uploads
- Background jobs

---

## 🏛 Архитектурные паттерны

### Pattern 1: Single Lambda per Route (Task 7)

```
API Gateway
  ├─> GET /contacts → Lambda 1
  ├─> POST /contacts → Lambda 2
  ├─> GET /contacts/{id} → Lambda 3
  └─> DELETE /contacts/{id} → Lambda 4
```

**Плюсы:**
- ✅ Каждая Lambda делает одну вещь (SRP)
- ✅ Легко масштабировать отдельные endpoints
- ✅ Изоляция ошибок

**Минусы:**
- ❌ Много Lambda functions
- ❌ Дублирование кода (common logic)

---

### Pattern 2: Single Lambda for all Routes

```
API Gateway
  ├─> GET /contacts ────┐
  ├─> POST /contacts ───┤
  ├─> GET /contacts/{id}├─> Lambda (router)
  └─> DELETE /contacts/{id}
```

Lambda код:
```javascript
exports.handler = async (event) => {
  const method = event.requestContext.http.method;
  const path = event.rawPath;
  
  if (method === 'GET' && path === '/contacts') {
    return listContacts();
  } else if (method === 'POST' && path === '/contacts') {
    return createContact(event);
  } else if (method === 'GET' && path.startsWith('/contacts/')) {
    return getContact(event);
  } else if (method === 'DELETE' && path.startsWith('/contacts/')) {
    return deleteContact(event);
  }
};
```

**Плюсы:**
- ✅ Одна Lambda function
- ✅ Shared code легко использовать

**Минусы:**
- ❌ Одна Lambda делает слишком много (нарушает SRP)
- ❌ Сложнее масштабировать
- ❌ Ошибка в одном route влияет на все

---

### Pattern 3: Microservices (рекомендуется)

```
API Gateway
  ├─> /contacts → Contacts Service (Lambda + DynamoDB)
  ├─> /users → Users Service (Lambda + RDS)
  └─> /orders → Orders Service (Lambda + DynamoDB)
```

**Плюсы:**
- ✅ Каждый service независимый
- ✅ Разные databases для разных services
- ✅ Команды могут работать параллельно

**Минусы:**
- ❌ Сложнее управление
- ❌ Inter-service communication

---

## 📈 Performance Considerations

### Cold Start vs Warm Start

**Cold Start (первый запрос):**
```
API Gateway → Lambda (не running)
                │
                ├─> Download code
                ├─> Initialize runtime
                ├─> Initialize handler
                └─> Execute function
                
Duration: 1000-3000ms
```

**Warm Start (последующие запросы):**
```
API Gateway → Lambda (already running)
                │
                └─> Execute function
                
Duration: 50-200ms
```

**Optimization strategies:**
1. **Provisioned Concurrency** - pre-warmed instances
2. **Smaller deployment packages** - faster download
3. **Minimal dependencies** - faster initialization
4. **Connection pooling** - reuse DB connections

---

### Latency Breakdown

**Total API Latency:**
```
Total = API Gateway + Lambda + Response
        (10-50ms)   (50-200ms) (10-50ms)
        
Typical: 100-300ms (warm)
Cold start: 1000-3000ms (first request)
```

**API Gateway Latency:**
- Route matching: 5-10ms
- Integration call: 5-10ms
- Response transformation: 5-10ms

**Lambda Latency:**
- Cold start: 500-2000ms
- Warm execution: 50-200ms
- Depends on code complexity

---

## 🔍 Monitoring Architecture

### CloudWatch Logs Flow

```
Lambda Function
  │
  ├─> Console.log() / print()
  │
  └─> CloudWatch Logs
        │
        ├─> Log Group: /aws/lambda/cmtr-4n6e9j62-api-gwlp-lambda-contacts
        │
        └─> Log Streams: 2024/01/01/[$LATEST]abc123...
              │
              ├─> START RequestId: abc123-def456
              ├─> [INFO] Processing GET /contacts
              ├─> [DEBUG] Found 2 contacts
              ├─> END RequestId: abc123-def456
              └─> REPORT RequestId: abc123-def456
                    Duration: 45.67 ms
                    Billed Duration: 46 ms
                    Memory Size: 128 MB
                    Max Memory Used: 65 MB
```

---

### CloudWatch Metrics

**Lambda Metrics:**
- `Invocations` - количество вызовов
- `Errors` - количество ошибок
- `Duration` - время выполнения
- `Throttles` - количество throttled invocations
- `ConcurrentExecutions` - текущие параллельные executions

**API Gateway Metrics:**
- `Count` - количество API requests
- `4XXError` - client errors
- `5XXError` - server errors
- `Latency` - total latency
- `IntegrationLatency` - backend latency

---

## 🎯 Design Decisions

### Почему HTTP API, а не REST API?

**HTTP API (выбран в Task 7):**
- ✅ Проще в настройке
- ✅ Дешевле (71% cheaper)
- ✅ Быстрее (~30% меньше latency)
- ✅ Автоматический CORS
- ✅ Достаточно features для большинства случаев

**REST API (альтернатива):**
- API Keys и Usage Plans
- Request/Response validation
- Более детальный контроль
- Legacy integrations

**Вердикт**: HTTP API для новых проектов, REST API только если нужны специфичные features.

---

### Почему AWS_PROXY integration?

**AWS_PROXY (выбран в Task 7):**
- ✅ Lambda получает все HTTP данные
- ✅ Lambda контролирует response format
- ✅ Простая настройка
- ✅ Гибкость

**AWS (альтернатива):**
- VTL templates для transformations
- Сложнее в настройке
- Использовать только если нельзя менять Lambda код

**Вердикт**: AWS_PROXY для 95% случаев.

---

### Почему Payload Format Version 2.0?

**Version 2.0 (выбран в Task 7):**
- ✅ Современный format
- ✅ Проще структура
- ✅ Лучше performance
- ✅ Рекомендуется AWS

**Version 1.0 (legacy):**
- Обратная совместимость с REST API
- Устаревший format

**Вердикт**: Version 2.0 для всех новых HTTP APIs.

---

## 📚 Best Practices

### Security

1. **Используйте Resource-based Policy**
   - Ограничьте Source ARN
   - Только конкретный API Gateway

2. **Least Privilege для Execution Role**
   - Только необходимые permissions
   - Конкретные resources

3. **Enable CloudTrail**
   - Audit API calls
   - Security monitoring

---

### Performance

1. **Minimize Cold Starts**
   - Provisioned Concurrency для критичных APIs
   - Smaller deployment packages
   - Minimal dependencies

2. **Optimize Lambda**
   - Reuse connections
   - Connection pooling
   - Caching

3. **Monitor Performance**
   - CloudWatch Metrics
   - X-Ray tracing
   - Custom metrics

---

### Cost Optimization

1. **Right-size Lambda Memory**
   - Больше memory = быстрее execution = дешевле
   - Test different memory sizes

2. **Use HTTP API вместо REST API**
   - 71% дешевле
   - Достаточно features

3. **Monitor Usage**
   - CloudWatch Metrics
   - Cost allocation tags
   - Budget alerts

---

## 🔄 Сравнение с Task 5

### Task 5: Lambda → API Gateway

```
Lambda Function
  │
  │ Identity-based Policy (Lambda Role)
  │ Action: execute-api:Invoke
  │
  ▼
API Gateway
```

**Направление**: Lambda вызывает API Gateway

---

### Task 7: API Gateway → Lambda

```
API Gateway
  │
  │ Resource-based Policy (Lambda Function)
  │ Principal: apigateway.amazonaws.com
  │
  ▼
Lambda Function
```

**Направление**: API Gateway вызывает Lambda

---

**Ключевая разница:**
- Task 5: **Identity-based policy** (у Lambda Role)
- Task 7: **Resource-based policy** (у Lambda Function)

---

## 🎓 Key Takeaways

1. **API Gateway + Lambda** = классический serverless REST API pattern
2. **AWS_PROXY integration** = Lambda получает полный контроль
3. **Resource-based policy** = Lambda разрешает вызовы от API Gateway
4. **Payload Format v2.0** = современный, производительный format
5. **HTTP API** = проще, дешевле, быстрее чем REST API
6. **Synchronous invocation** = client ждет response
7. **Cold start** = важная оптимизация для production

---

**📖 Дополнительное чтение:**
- [QUICKSTART.md](./QUICKSTART.md) - быстрый старт
- [INSTRUCTIONS.md](./INSTRUCTIONS.md) - детальные инструкции
- [PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md) - итоги и выводы
