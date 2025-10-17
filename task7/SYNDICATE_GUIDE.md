# Создание Lambda с использованием Syndicate Framework

## Что такое Syndicate?

**Syndicate** — это фреймворк для разработки и деплоя serverless приложений на AWS. Основные возможности:

- 🚀 Автоматическое создание и настройка AWS ресурсов
- 📦 Упрощенная работа с зависимостями (pip, npm)
- 🏗️ Инфраструктура как код (IaC)
- 🔄 Управление версиями и rollback
- 🧪 Встроенное тестирование
- 📝 Автогенерация документации

## Установка Syndicate

### Prerequisites

```bash
# Python 3.8+
python3 --version

# AWS CLI configured
aws configure list

# pip или pipenv
pip3 --version
```

### Установка через pip

```bash
# Установка syndicate
pip3 install aws-syndicate

# Проверка установки
syndicate --version
```

### Установка через pipenv (рекомендуется)

```bash
# Создать виртуальное окружение
mkdir ~/my-syndicate-project
cd ~/my-syndicate-project

# Установить pipenv
pip3 install pipenv

# Создать окружение и установить syndicate
pipenv install aws-syndicate

# Активировать окружение
pipenv shell
```

## Создание проекта Syndicate

### Шаг 1: Инициализация проекта

```bash
# Создать новый проект
syndicate generate project \
    --name task7-contacts-api \
    --region eu-west-1

cd task7-contacts-api
```

Структура проекта:

```
task7-contacts-api/
├── deployment_resources.json    # Конфигурация ресурсов AWS
├── syndicate.yml               # Настройки Syndicate
├── syndicate_aliases.yml       # Алиасы команд
├── src/                        # Исходный код Lambda
│   └── lambdas/
│       └── hello_world/
│           └── handler.py
└── tests/                      # Тесты
    └── test_hello_world.py
```

### Шаг 2: Настройка конфигурации

**syndicate.yml** — главный конфигурационный файл:

```yaml
# syndicate.yml
project_path: .
project_name: task7-contacts-api
resources_suffix: dev
deploy_target_bucket: syndicate-artifacts-${account_id}-${region}
deploy_target_bucket_region: eu-west-1

# Алиас для AWS credentials
credentials_aliases:
  - task7-dev

# Регионы для деплоя
regions:
  - eu-west-1

# Build configurations
build_projects_mapping:
  python:
    - src/lambdas
```

**Создать AWS credentials alias:**

```bash
# Создать конфигурацию для syndicate
syndicate create_deploy_target_bucket \
    --bundle_name task7-contacts-api \
    --deploy_target_bucket syndicate-artifacts-418272778502-eu-west-1 \
    --region eu-west-1 \
    --credentials_alias task7-dev
```

## Создание Lambda функции для Contacts API

### Структура Lambda

```bash
# Создать папку для Lambda
mkdir -p src/lambdas/contacts_api
cd src/lambdas/contacts_api
```

### handler.py - код Lambda

```python
# src/lambdas/contacts_api/handler.py

import json
import os
from syndicate.core.helper.decorators import lambda_handler

# Декоратор @lambda_handler автоматически логирует события
@lambda_handler()
def lambda_handler(event, context):
    """
    Lambda handler for Contacts API
    Supports GET /contacts endpoint
    """
    
    # Mock данные contacts
    contacts = [
        {
            "id": 1,
            "name": "Elma Herring",
            "email": "elmaherring@conjurica.com",
            "phone": "+1 (866) 456-2052"
        },
        {
            "id": 2,
            "name": "Bell Burgess",
            "email": "bellburgess@conjurica.com",
            "phone": "+1 (934) 520-2048"
        },
        {
            "id": 3,
            "name": "Hobbs Ferrell",
            "email": "hobbsferrell@conjurica.com",
            "phone": "+1 (948) 527-2232"
        }
    ]
    
    # Логирование (автоматически попадает в CloudWatch)
    print(f"Received event: {json.dumps(event)}")
    
    # API Gateway HTTP API Payload Format 2.0
    http_method = event.get('requestContext', {}).get('http', {}).get('method')
    path = event.get('rawPath', '/')
    
    # Обработка GET /contacts
    if http_method == 'GET' and path == '/contacts':
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(contacts)
        }
    
    # Обработка GET /contacts/{id}
    if http_method == 'GET' and path.startswith('/contacts/'):
        contact_id = int(path.split('/')[-1])
        contact = next((c for c in contacts if c['id'] == contact_id), None)
        
        if contact:
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps(contact)
            }
        else:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'Contact not found'})
            }
    
    # Route не найден
    return {
        'statusCode': 404,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({'error': 'Not Found'})
    }
```

### requirements.txt - зависимости

```txt
# src/lambdas/contacts_api/requirements.txt

# Syndicate runtime helpers
aws-syndicate>=1.0.0

# Optional: работа с данными
# boto3  # уже включен в Lambda runtime
# requests
```

### lambda_config.json - конфигурация Lambda

```json
{
  "lambda-config": {
    "contacts_api": {
      "name": "cmtr-4n6e9j62-api-gwlp-lambda-contacts",
      "runtime": "python3.9",
      "memory": 512,
      "timeout": 30,
      "publish": true,
      "alias": "dev",
      "env_variables": {
        "ENVIRONMENT": "development",
        "LOG_LEVEL": "INFO"
      },
      "iam_role_name": "contacts-api-lambda-role",
      "resource_type": "lambda"
    }
  }
}
```

## Конфигурация IAM Role

### deployment_resources.json

```json
{
  "lambda_iam_roles": {
    "contacts-api-lambda-role": {
      "predefined_policies": [
        "AWSLambdaBasicExecutionRole"
      ],
      "trusted_service": [
        "lambda"
      ],
      "custom_policies": []
    }
  }
}
```

## Конфигурация API Gateway

Добавить в **deployment_resources.json**:

```json
{
  "api_gateway_v2": {
    "task7-contacts-api": {
      "name": "task7-contacts-api",
      "protocol_type": "HTTP",
      "cors_configuration": {
        "allow_origins": ["*"],
        "allow_methods": ["GET", "POST", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"],
        "max_age": 3600
      },
      "routes": [
        {
          "route_key": "GET /contacts",
          "target": {
            "integration_type": "AWS_PROXY",
            "lambda": "contacts_api"
          }
        },
        {
          "route_key": "GET /contacts/{id}",
          "target": {
            "integration_type": "AWS_PROXY",
            "lambda": "contacts_api"
          }
        }
      ],
      "deploy_stage": "$default",
      "auto_deploy": true
    }
  }
}
```

## Полный deployment_resources.json

```json
{
  "lambda_iam_roles": {
    "contacts-api-lambda-role": {
      "predefined_policies": [
        "AWSLambdaBasicExecutionRole"
      ],
      "trusted_service": [
        "lambda"
      ],
      "custom_policies": []
    }
  },
  
  "lambda": {
    "contacts_api": {
      "name": "cmtr-4n6e9j62-api-gwlp-lambda-contacts",
      "runtime": "python3.9",
      "memory": 512,
      "timeout": 30,
      "publish": true,
      "alias": "dev",
      "env_variables": {
        "ENVIRONMENT": "development",
        "LOG_LEVEL": "INFO"
      },
      "iam_role_name": "contacts-api-lambda-role",
      "resource_type": "lambda"
    }
  },
  
  "api_gateway_v2": {
    "task7-contacts-api": {
      "name": "task7-contacts-api",
      "protocol_type": "HTTP",
      "cors_configuration": {
        "allow_origins": ["*"],
        "allow_methods": ["GET", "POST", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"],
        "max_age": 3600
      },
      "routes": [
        {
          "route_key": "GET /contacts",
          "target": {
            "integration_type": "AWS_PROXY",
            "lambda": "contacts_api"
          }
        },
        {
          "route_key": "GET /contacts/{id}",
          "target": {
            "integration_type": "AWS_PROXY",
            "lambda": "contacts_api"
          }
        },
        {
          "route_key": "POST /contacts",
          "target": {
            "integration_type": "AWS_PROXY",
            "lambda": "contacts_api"
          }
        },
        {
          "route_key": "DELETE /contacts/{id}",
          "target": {
            "integration_type": "AWS_PROXY",
            "lambda": "contacts_api"
          }
        }
      ],
      "deploy_stage": "$default",
      "auto_deploy": true
    }
  }
}
```

## Команды Syndicate

### Build проекта

```bash
# Собрать все Lambda функции
syndicate build

# Build создаст .syndicate директорию с артефактами
```

### Deploy на AWS

```bash
# Первый deploy
syndicate deploy \
    --bundle_name task7-contacts-api-v1 \
    --deploy_target_bucket syndicate-artifacts-418272778502-eu-west-1

# Syndicate автоматически:
# 1. Создаст IAM роль
# 2. Загрузит Lambda код в S3
# 3. Создаст Lambda функцию
# 4. Создаст API Gateway
# 5. Настроит Integration
# 6. Добавит Lambda Permission
# 7. Deploy API Gateway
```

### Update существующего деплоя

```bash
# Обновить Lambda код
syndicate update \
    --bundle_name task7-contacts-api-v1 \
    --deploy_target_bucket syndicate-artifacts-418272778502-eu-west-1
```

### Просмотр деплоев

```bash
# Список всех деплоев
syndicate list_deploy_resources \
    --bundle_name task7-contacts-api-v1

# Детали конкретного деплоя
syndicate describe_deploy_resources \
    --bundle_name task7-contacts-api-v1
```

### Удаление ресурсов

```bash
# Полное удаление всех ресурсов
syndicate clean \
    --bundle_name task7-contacts-api-v1 \
    --deploy_target_bucket syndicate-artifacts-418272778502-eu-west-1

# Syndicate удалит:
# - API Gateway
# - Lambda функцию
# - IAM роль
# - CloudWatch Logs
```

## Тестирование

### Локальное тестирование

```bash
# Создать тестовое событие
cat > test_event.json <<EOF
{
  "version": "2.0",
  "routeKey": "GET /contacts",
  "rawPath": "/contacts",
  "requestContext": {
    "http": {
      "method": "GET",
      "path": "/contacts"
    }
  }
}
EOF

# Запустить Lambda локально (если установлен SAM)
sam local invoke contacts_api -e test_event.json
```

### Тестирование на AWS

```bash
# После deploy получить API endpoint
API_ENDPOINT=$(aws apigatewayv2 get-apis \
    --query "Items[?Name=='task7-contacts-api'].ApiEndpoint" \
    --output text)

# Тестовый запрос
curl $API_ENDPOINT/contacts

# Ожидаемый ответ:
# [{"id": 1, "name": "Elma Herring", ...}]
```

## Мониторинг

```bash
# CloudWatch Logs
aws logs tail /aws/lambda/cmtr-4n6e9j62-api-gwlp-lambda-contacts --follow

# Метрики Lambda
aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Invocations \
    --dimensions Name=FunctionName,Value=cmtr-4n6e9j62-api-gwlp-lambda-contacts \
    --statistics Sum \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-02T00:00:00Z \
    --period 3600
```

## CI/CD интеграция

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      
      - name: Install Syndicate
        run: pip install aws-syndicate
      
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-west-1
      
      - name: Build
        run: syndicate build
      
      - name: Deploy
        run: |
          syndicate deploy \
            --bundle_name task7-contacts-api-${{ github.sha }} \
            --deploy_target_bucket syndicate-artifacts-418272778502-eu-west-1
```

## Преимущества Syndicate vs AWS CLI

| Аспект | AWS CLI | Syndicate |
|--------|---------|-----------|
| **Деплой** | Ручные команды | Одна команда |
| **Зависимости** | Вручную упаковывать | Автоматически |
| **IAM Roles** | Создавать вручную | Автоматически |
| **Версионирование** | Самостоятельно | Встроено |
| **Rollback** | Сложно | `syndicate rollback` |
| **API Gateway** | Множество команд | Конфигурация в JSON |
| **Мониторинг** | AWS Console | Встроенные команды |
| **Тестирование** | Отдельные инструменты | Интегрировано |

## Best Practices

### 1. Структура проекта

```
project/
├── src/
│   ├── lambdas/
│   │   ├── contacts_api/         # Отдельная папка для каждой Lambda
│   │   │   ├── handler.py
│   │   │   ├── requirements.txt
│   │   │   └── tests/
│   │   └── auth/
│   │       ├── handler.py
│   │       └── requirements.txt
│   └── layers/                   # Lambda Layers
│       └── common/
├── deployment_resources.json     # Вся инфраструктура
├── syndicate.yml
└── tests/
```

### 2. Environment Variables

```json
{
  "lambda": {
    "contacts_api": {
      "env_variables": {
        "ENVIRONMENT": "${env:ENVIRONMENT}",
        "DB_HOST": "${ssm:/task7/db/host}",
        "API_KEY": "${secrets:/task7/api/key}"
      }
    }
  }
}
```

### 3. Layers для зависимостей

```json
{
  "lambda_layer": {
    "common_layer": {
      "deployment_package": "layers/common",
      "runtimes": ["python3.9"],
      "architectures": ["x86_64"]
    }
  },
  "lambda": {
    "contacts_api": {
      "layers": ["common_layer"]
    }
  }
}
```

### 4. Alarms и Monitoring

```json
{
  "cloudwatch_alarm": {
    "contacts-api-errors": {
      "metric_name": "Errors",
      "namespace": "AWS/Lambda",
      "statistic": "Sum",
      "period": 300,
      "evaluation_periods": 1,
      "threshold": 10,
      "comparison_operator": "GreaterThanThreshold",
      "dimensions": {
        "FunctionName": "contacts_api"
      }
    }
  }
}
```

## Troubleshooting

### Проблема: Build fails

```bash
# Проверить синтаксис Python
python3 -m py_compile src/lambdas/contacts_api/handler.py

# Проверить зависимости
pip install -r src/lambdas/contacts_api/requirements.txt
```

### Проблема: Deploy fails

```bash
# Проверить AWS credentials
aws sts get-caller-identity

# Проверить S3 bucket
aws s3 ls s3://syndicate-artifacts-418272778502-eu-west-1

# Verbose mode
syndicate deploy --verbose
```

### Проблема: Lambda timeout

```json
{
  "lambda": {
    "contacts_api": {
      "timeout": 60,  // Увеличить до 60 секунд
      "memory": 1024  // Больше памяти = быстрее CPU
    }
  }
}
```

## Дополнительные ресурсы

- 📚 [Syndicate Documentation](https://github.com/epam/aws-syndicate)
- 📖 [Examples Repository](https://github.com/epam/aws-syndicate-examples)
- 🎓 [EPAM Training](https://learn.epam.com/)

## Сравнение с Task 7 setup script

**setup-iam-task7.sh** (manual approach):
```bash
# 50+ строк команд AWS CLI
# Ручное создание IAM роли
# Ручная упаковка Lambda
# Ручная настройка API Gateway
```

**Syndicate** (declarative approach):
```bash
# deployment_resources.json (20 строк)
syndicate build
syndicate deploy --bundle_name task7-v1
# Готово!
```

---

✅ **Вывод**: Syndicate идеален для production deployments, AWS CLI подходит для обучения и понимания AWS архитектуры.
