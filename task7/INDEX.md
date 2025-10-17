# 📚 Task 7: Документация - API Gateway + Lambda Integration

## 🎯 О задании

**Task 7** демонстрирует интеграцию Amazon API Gateway (HTTP API) с AWS Lambda функцией. Вы научитесь создавать публичные REST API endpoints с Lambda backend'ом.

**Время выполнения**: 5-10 минут  
**Сложность**: ⭐⭐⭐ (Средняя)  
**AWS Account**: 418272778502

---

## 📖 Навигация по документации

### 🚀 Быстрый старт
- **[QUICKSTART.md](./QUICKSTART.md)** - Запуск за 5 минут
  - Настройка credentials
  - Запуск автоматического скрипта
  - Проверка результата
  - Решение частых проблем

### 📝 Детальные инструкции
- **[INSTRUCTIONS.md](./INSTRUCTIONS.md)** - Пошаговое руководство
  - Ручное выполнение каждого шага
  - Объяснение каждой команды
  - Проверка промежуточных результатов
  - Детальное тестирование

### ✅ Проверка
- **[CHECKLIST.md](./CHECKLIST.md)** - Чек-лист выполнения
  - Pre-flight проверки
  - Проверка каждого шага
  - Финальная валидация
  - Troubleshooting guide

### 🏗 Архитектура
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Техническая документация
  - Диаграммы архитектуры
  - Описание всех компонентов
  - Data flow
  - Security considerations

### 📊 Итоги
- **[PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)** - Резюме проекта
  - Что было создано
  - Ключевые выводы
  - Best practices
  - Применение в реальных проектах

---

## 🛠 Файлы проекта

### Скрипты
```
task7/
├── setup-iam-task7.sh      # Автоматическая настройка (запустите это!)
└── commands.sh              # Все команды для ручного выполнения
```

### Документация
```
task7/
├── README.md               # Исходное задание
├── QUICKSTART.md           # ⭐ Начните отсюда!
├── INDEX.md                # 📍 Вы здесь
├── INSTRUCTIONS.md         # Подробные инструкции
├── CHECKLIST.md            # Чек-лист проверки
├── ARCHITECTURE.md         # Техническая документация
└── PROJECT_SUMMARY.md      # Итоги и выводы
```

---

## 🎓 Что вы изучите

### 1. API Gateway (HTTP API)
- Создание Lambda Integrations
- Настройка Routes
- Payload Format Version 2.0
- Разница между HTTP API и REST API

### 2. Lambda Function
- Resource-based policies для API Gateway
- Event format для HTTP API integrations
- Response format для AWS_PROXY
- Direct invocation vs API Gateway invocation

### 3. Integration Types
- **AWS_PROXY** - полная интеграция с Lambda
- **AWS** - с mapping templates
- **HTTP_PROXY** - проксирование внешних HTTP APIs
- **MOCK** - для тестирования

### 4. Permissions & Security
- Lambda resource-based policy
- API Gateway principal
- Source ARN для ограничения доступа
- Public endpoints vs Authorized endpoints

### 5. Testing & Monitoring
- HTTP requests через curl/browser
- Direct Lambda invocation для debugging
- CloudWatch Logs для Lambda
- CloudWatch Metrics для API Gateway

---

## 🔧 Технический стек

### AWS Services
- **Amazon API Gateway** (HTTP API) - REST API endpoint
- **AWS Lambda** - Backend logic
- **CloudWatch Logs** - Логирование
- **CloudWatch Metrics** - Мониторинг
- **IAM** - Resource-based policies

### Tools
- **AWS CLI v2** - для всех операций
- **curl** - для тестирования HTTP endpoints
- **jq** - для парсинга JSON responses
- **bash** - для скриптов автоматизации

---

## 📦 AWS Resources

### Существующие ресурсы
```
API Gateway:
  ID: erv7myh2nb
  Type: HTTP API
  Endpoint: https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com
  Protocol: HTTP/1.1, HTTP/2

Route:
  ID: py00o9v
  Key: GET /contacts
  Path: /contacts
  Method: GET

Lambda Function:
  Name: cmtr-4n6e9j62-api-gwlp-lambda-contacts
  Runtime: Node.js/Python (зависит от реализации)
  Handler: Возвращает JSON массив контактов
```

### Ресурсы, которые будут созданы
```
Integration:
  Type: AWS_PROXY
  IntegrationUri: Lambda ARN
  PayloadFormatVersion: 2.0
  Timeout: 30000ms

Lambda Permission:
  StatementId: AllowAPIGatewayInvoke-task7
  Action: lambda:InvokeFunction
  Principal: apigateway.amazonaws.com
  SourceArn: arn:aws:execute-api:eu-west-1:418272778502:erv7myh2nb/*/*
```

---

## 🎯 Цели обучения

После выполнения Task 7 вы сможете:

✅ Создавать Lambda integrations для API Gateway  
✅ Настраивать resource-based policies на Lambda  
✅ Понимать разницу между типами integrations  
✅ Работать с Payload Format Version 2.0  
✅ Тестировать API endpoints разными способами  
✅ Читать и анализировать Lambda logs  
✅ Troubleshoot проблемы с API Gateway + Lambda  
✅ Использовать AWS_PROXY integration type  

---

## 🚦 С чего начать?

### Для новичков
1. 📖 Прочитайте [README.md](./README.md) - исходное задание
2. 🚀 Следуйте [QUICKSTART.md](./QUICKSTART.md) - запустите автоматический скрипт
3. ✅ Проверьте результат по [CHECKLIST.md](./CHECKLIST.md)

### Для продвинутых
1. 📝 Изучите [INSTRUCTIONS.md](./INSTRUCTIONS.md) - выполните вручную
2. 🏗 Читайте [ARCHITECTURE.md](./ARCHITECTURE.md) - поймите архитектуру
3. 🔍 Экспериментируйте с разными типами integrations

### Для экспертов
1. 📊 Анализируйте [PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)
2. 🛠 Изучите код Lambda функции
3. 🎨 Реализуйте свой вариант с дополнительными features

---

## 📋 Быстрые команды

### Запуск автоматической настройки
```bash
cd /Users/Viachaslau_Kazakou/Work/IAM-task/task7
chmod +x setup-iam-task7.sh
./setup-iam-task7.sh
```

### Тестирование API
```bash
# curl
curl https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts

# Browser
open https://erv7myh2nb.execute-api.eu-west-1.amazonaws.com/contacts
```

### Проверка конфигурации
```bash
# API Gateway
aws apigatewayv2 get-api --api-id erv7myh2nb

# Routes
aws apigatewayv2 get-routes --api-id erv7myh2nb

# Integrations
aws apigatewayv2 get-integrations --api-id erv7myh2nb

# Lambda permissions
aws lambda get-policy --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts
```

### Мониторинг
```bash
# Lambda logs (real-time)
aws logs tail /aws/lambda/cmtr-4n6e9j62-api-gwlp-lambda-contacts --follow

# Lambda invocations
aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Invocations \
    --dimensions Name=FunctionName,Value=cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum
```

---

## 🔗 Связь с другими задачами

### Task 5: API Gateway Authorizer + Lambda
- Task 5: **Identity-based policy** (Lambda → API Gateway)
- Task 7: **Resource-based policy** (API Gateway → Lambda)
- Task 5: Lambda **вызывает** API Gateway
- Task 7: API Gateway **вызывает** Lambda

### Task 6: S3 + SQS + Lambda
- Task 6: Event-driven (S3 → SQS → Lambda)
- Task 7: Synchronous (API Gateway → Lambda → Response)
- Task 6: Асинхронная обработка
- Task 7: Синхронный REST API

---

## 📚 Дополнительные ресурсы

### AWS Documentation
- [API Gateway HTTP APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [Lambda Proxy Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html)
- [API Gateway + Lambda](https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html)
- [Payload Format Version 2.0](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html)

### Best Practices
- [API Gateway Best Practices](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-best-practices.html)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Serverless Architectures](https://aws.amazon.com/serverless/)

---

## ❓ FAQ

### Q: В чем разница между HTTP API и REST API в API Gateway?

**A:** HTTP API:
- ✅ Проще в настройке
- ✅ На 71% дешевле
- ✅ Быстрее (меньше latency)
- ❌ Меньше features (нет API keys, usage plans, request validation)

REST API:
- ✅ Больше features
- ✅ Request/response transformations
- ✅ API keys, usage plans
- ❌ Дороже
- ❌ Больше latency

### Q: Что такое AWS_PROXY integration?

**A:** AWS_PROXY - это тип интеграции, при котором:
- Lambda получает **весь HTTP request** (headers, query params, body)
- Lambda **полностью контролирует response** (status code, headers, body)
- API Gateway **не трансформирует** request/response
- Lambda должен вернуть **правильный format** response

### Q: Зачем нужен Lambda permission для API Gateway?

**A:** Это **resource-based policy** на Lambda:
- Разрешает API Gateway **вызывать** Lambda функцию
- Без этого API Gateway получит **403 Forbidden**
- Principal = `apigateway.amazonaws.com`
- Source ARN ограничивает **какой конкретно API** может вызывать

### Q: Что такое Payload Format Version 2.0?

**A:** Это **новый формат** event для Lambda:
- Более простой JSON structure
- Меньше вложенных объектов
- Лучше performance
- Рекомендуется для **новых проектов**
- Version 1.0 - для обратной совместимости

### Q: Можно ли использовать POST/PUT/DELETE методы?

**A:** Да! Просто создайте routes для других методов:
```bash
# POST /contacts
aws apigatewayv2 create-route \
    --api-id erv7myh2nb \
    --route-key "POST /contacts" \
    --target "integrations/$INTEGRATION_ID"

# DELETE /contacts/{id}
aws apigatewayv2 create-route \
    --api-id erv7myh2nb \
    --route-key "DELETE /contacts/{id}" \
    --target "integrations/$INTEGRATION_ID"
```

Lambda получит метод в `event.requestContext.http.method`.

---

## 🆘 Нужна помощь?

### Частые проблемы

#### API возвращает 403 Forbidden
```bash
# Решение: Добавить Lambda permission
aws lambda add-permission \
    --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --statement-id AllowAPIGatewayInvoke-task7 \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:eu-west-1:418272778502:erv7myh2nb/*/*"
```

#### API возвращает 500 Internal Server Error
```bash
# Решение: Проверить Lambda logs
aws logs tail /aws/lambda/cmtr-4n6e9j62-api-gwlp-lambda-contacts --since 5m

# Протестировать Lambda напрямую
aws lambda invoke \
    --function-name cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --payload '{"httpMethod":"GET","path":"/contacts"}' \
    response.json
```

#### Route не вызывает Lambda
```bash
# Решение: Проверить route target
aws apigatewayv2 get-route \
    --api-id erv7myh2nb \
    --route-id py00o9v \
    --query 'Target'

# Должен быть: "integrations/$INTEGRATION_ID"
```

### Дополнительная помощь
- 📝 [INSTRUCTIONS.md](./INSTRUCTIONS.md) - подробные инструкции
- ✅ [CHECKLIST.md](./CHECKLIST.md) - систематическая проверка
- 🏗 [ARCHITECTURE.md](./ARCHITECTURE.md) - как все работает

---

## 📊 Структура Task 7

```
Task 7: API Gateway + Lambda Integration
│
├── 🚀 Quick Start (5 минут)
│   ├── Setup credentials
│   ├── Run setup-iam-task7.sh
│   └── Test API endpoint
│
├── 📝 Manual Setup (15 минут)
│   ├── Step 1: Create Lambda Integration
│   ├── Step 2: Update Route target
│   └── Step 3: Add Lambda Permission
│
├── ✅ Verification
│   ├── Integration exists
│   ├── Route target is correct
│   ├── Lambda permission added
│   └── API returns 200 OK
│
└── 🎓 Learning Outcomes
    ├── API Gateway concepts
    ├── Lambda integrations
    ├── Resource-based policies
    └── API testing strategies
```

---

## 🎯 Следующие шаги

1. ✅ Выполните Task 7 с помощью [QUICKSTART.md](./QUICKSTART.md)
2. 📖 Изучите архитектуру в [ARCHITECTURE.md](./ARCHITECTURE.md)
3. 🔍 Экспериментируйте с разными integration types
4. 📊 Прочитайте итоги в [PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)

---

**Удачи в изучении API Gateway + Lambda! 🚀**

Если остались вопросы - начните с [QUICKSTART.md](./QUICKSTART.md) и запустите автоматический скрипт. Все тесты и проверки выполнятся автоматически!
