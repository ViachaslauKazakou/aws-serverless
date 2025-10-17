# Task 7 Contacts API - Syndicate Project

Пример полного Syndicate проекта для Task 7.

## Структура проекта

```
syndicate-example/
├── README.md                       # Этот файл
├── syndicate.yml                   # Конфигурация Syndicate
├── syndicate_aliases.yml           # Алиасы команд
├── deployment_resources.json       # Описание AWS ресурсов
├── src/
│   └── lambdas/
│       └── contacts_api/
│           ├── handler.py          # Lambda handler
│           ├── requirements.txt    # Python зависимости
│           └── tests/
│               └── test_handler.py # Unit tests
└── .github/
    └── workflows/
        └── deploy.yml              # CI/CD pipeline

```

## Quick Start

### 1. Установка

```bash
# Установить Syndicate
pip3 install aws-syndicate

# Или через pipenv
pipenv install aws-syndicate
pipenv shell
```

### 2. Конфигурация AWS

```bash
# Создать S3 bucket для артефактов
aws s3 mb s3://syndicate-artifacts-418272778502-eu-west-1 --region eu-west-1

# Или через Syndicate
syndicate create_deploy_target_bucket \
    --bundle_name task7-contacts-api \
    --deploy_target_bucket syndicate-artifacts-418272778502-eu-west-1 \
    --region eu-west-1 \
    --credentials_alias task7-dev
```

### 3. Build

```bash
cd syndicate-example

# Собрать Lambda packages
syndicate build
```

### 4. Deploy

```bash
# Первый deploy
syndicate deploy \
    --bundle_name task7-contacts-api-v1 \
    --deploy_target_bucket syndicate-artifacts-418272778502-eu-west-1

# Syndicate автоматически создаст:
# ✅ IAM Role для Lambda
# ✅ Lambda функцию
# ✅ API Gateway HTTP API
# ✅ Integration (AWS_PROXY)
# ✅ Routes (GET /contacts, POST /contacts, etc.)
# ✅ Lambda Permission
# ✅ CloudWatch Log Groups
```

### 5. Тестирование

```bash
# Получить API endpoint
API_ENDPOINT=$(aws apigatewayv2 get-apis \
    --query "Items[?Name=='task7-contacts-api'].ApiEndpoint" \
    --output text)

echo "API Endpoint: $API_ENDPOINT"

# Тестовый запрос
curl $API_ENDPOINT/contacts

# Ожидаемый ответ:
# [
#   {"id": 1, "name": "Elma Herring", "email": "elmaherring@conjurica.com", ...},
#   {"id": 2, "name": "Bell Burgess", "email": "bellburgess@conjurica.com", ...},
#   {"id": 3, "name": "Hobbs Ferrell", "email": "hobbsferrell@conjurica.com", ...}
# ]
```

### 6. Мониторинг

```bash
# CloudWatch Logs
aws logs tail /aws/lambda/cmtr-4n6e9j62-api-gwlp-lambda-contacts --follow

# Lambda метрики
aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Invocations \
    --dimensions Name=FunctionName,Value=cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --statistics Sum \
    --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300
```

### 7. Update код

```bash
# Изменить handler.py

# Пересобрать
syndicate build

# Обновить Lambda
syndicate update \
    --bundle_name task7-contacts-api-v1 \
    --deploy_target_bucket syndicate-artifacts-418272778502-eu-west-1
```

### 8. Cleanup

```bash
# Удалить все ресурсы
syndicate clean \
    --bundle_name task7-contacts-api-v1 \
    --deploy_target_bucket syndicate-artifacts-418272778502-eu-west-1

# Будут удалены:
# ❌ API Gateway
# ❌ Lambda функция
# ❌ IAM Role
# ❌ CloudWatch Logs
# ❌ Lambda Permission
```

## Основные команды

| Команда | Описание |
|---------|----------|
| `syndicate build` | Собрать Lambda packages |
| `syndicate deploy` | Создать/обновить все ресурсы |
| `syndicate update` | Обновить Lambda код |
| `syndicate list_deploy_resources` | Список деплоев |
| `syndicate describe_deploy_resources` | Детали деплоя |
| `syndicate clean` | Удалить все ресурсы |
| `syndicate generate lambda` | Создать новую Lambda |
| `syndicate package_meta` | Просмотр метаданных |

## Файлы конфигурации

### syndicate.yml
Главный конфигурационный файл проекта.

### deployment_resources.json
Декларативное описание всех AWS ресурсов:
- Lambda functions
- IAM roles
- API Gateway HTTP APIs
- Routes
- Integrations

### syndicate_aliases.yml
Алиасы для часто используемых команд.

## Сравнение с AWS CLI

### AWS CLI подход (setup-iam-task7.sh)
```bash
# 1. Создать IAM роль (10 команд)
aws iam create-role ...
aws iam attach-role-policy ...

# 2. Упаковать Lambda (5 команд)
zip deployment.zip ...
aws lambda create-function ...

# 3. Создать API Gateway (20+ команд)
aws apigatewayv2 create-api ...
aws apigatewayv2 create-route ...
aws apigatewayv2 create-integration ...

# 4. Добавить permissions
aws lambda add-permission ...

# Итого: 50+ строк bash кода
```

### Syndicate подход
```bash
# 1. Описать ресурсы в deployment_resources.json (30 строк)

# 2. Deploy
syndicate build
syndicate deploy --bundle_name task7-v1

# Итого: 2 команды
```

## Преимущества Syndicate

✅ **Декларативная конфигурация** - вся инфраструктура в JSON
✅ **Автоматические зависимости** - pip packages автоматически упаковываются
✅ **Версионирование** - каждый deploy имеет уникальный bundle name
✅ **Rollback** - легко откатиться на предыдущую версию
✅ **CI/CD friendly** - одна команда для деплоя
✅ **Мониторинг** - встроенные команды для просмотра логов и метрик

## Best Practices

1. **Bundle naming** - используйте семантическое версионирование:
   ```bash
   syndicate deploy --bundle_name task7-contacts-api-v1.0.0
   ```

2. **Environment variables** - храните конфиги в SSM/Secrets Manager:
   ```json
   "env_variables": {
     "DB_HOST": "${ssm:/task7/db/host}"
   }
   ```

3. **Layers** - общие зависимости выносите в Lambda Layers

4. **Tests** - запускайте unit tests перед build:
   ```bash
   python -m pytest src/lambdas/contacts_api/tests/
   syndicate build
   ```

5. **Git tags** - тегируйте релизы:
   ```bash
   git tag -a v1.0.0 -m "Initial release"
   git push origin v1.0.0
   ```

## Troubleshooting

### Проблема: Syndicate не находит AWS credentials

```bash
# Проверить
aws sts get-caller-identity

# Настроить
aws configure

# Или использовать environment variables
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=eu-west-1
```

### Проблема: Build fails

```bash
# Проверить синтаксис Python
python3 -m py_compile src/lambdas/contacts_api/handler.py

# Проверить зависимости
pip install -r src/lambdas/contacts_api/requirements.txt

# Verbose mode
syndicate build --verbose
```

### Проблема: Deploy fails - S3 bucket не существует

```bash
# Создать bucket
aws s3 mb s3://syndicate-artifacts-418272778502-eu-west-1 --region eu-west-1

# Или через Syndicate
syndicate create_deploy_target_bucket \
    --bundle_name task7 \
    --deploy_target_bucket syndicate-artifacts-418272778502-eu-west-1 \
    --region eu-west-1
```

### Проблема: API Gateway 404

```bash
# Проверить routes
aws apigatewayv2 get-routes --api-id <api-id>

# Проверить integration
aws apigatewayv2 get-integrations --api-id <api-id>

# Пересоздать deployment
syndicate update --bundle_name task7-contacts-api-v1
```

## Дополнительные ресурсы

- 📚 [Syndicate GitHub](https://github.com/epam/aws-syndicate)
- 📖 [Examples](https://github.com/epam/aws-syndicate-examples)
- 🎥 [Video Tutorials](https://www.youtube.com/results?search_query=aws+syndicate+framework)

## Support

Вопросы и issues: [GitHub Issues](https://github.com/epam/aws-syndicate/issues)

---

**Note**: Этот пример использует существующие ресурсы Task 7:
- API Gateway: `erv7myh2nb`
- Lambda: `cmtr-4n6e9j62-api-gwlp-lambda-contacts`

Если хотите создать новые ресурсы, измените `name` в `deployment_resources.json`.
