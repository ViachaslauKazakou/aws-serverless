# Task 6: S3 + SQS + Lambda Event-Driven Architecture

## 📋 Описание

Task 6 демонстрирует создание event-driven архитектуры с использованием AWS S3, SQS и Lambda. Когда файл загружается в S3 bucket (folder `input/`), отправляется notification в SQS queue, который trigger-ит Lambda функцию для обработки файла.

## 🎯 Цель

Настроить event-driven pipeline:
1. **S3 Event Notification** → публикует события в SQS при загрузке файлов в `input/`
2. **SQS → Lambda trigger** → Lambda poll-ит messages из queue
3. **Lambda processing** → обрабатывает файлы и сохраняет результат в `output/`

## 📁 Структура

```
task6/
├── setup-iam-task6.sh       # Автоматическая настройка (основной скрипт)
├── commands.sh              # Готовые команды для ручного выполнения
├── README.md                # Общее описание
├── QUICKSTART.md            # Быстрый старт
├── INDEX.md                 # Навигация по документации
├── INSTRUCTIONS.md          # Подробные инструкции
├── CHECKLIST.md             # Чек-лист выполнения
├── ARCHITECTURE.md          # Архитектура решения
└── PROJECT_SUMMARY.md       # Итоговая сводка
```

## 🚀 Быстрый старт

### Автоматическая настройка:

```bash
cd task6
chmod +x setup-iam-task6.sh
./setup-iam-task6.sh
```

### Ручная настройка:

```bash
cd task6
# Смотрите commands.sh для всех команд
source commands.sh
```

## 🔐 AWS Resources

- **S3 Bucket**: `cmtr-4n6e9j62-s3-snlt-bucket-962877`
  - Folder: `input/` - для загрузки файлов
  - Folder: `output/` - для обработанных файлов (создается автоматически)
  
- **SQS Queue**: `cmtr-4n6e9j62-s3-snlt-queue`
  - Destination для S3 events
  - Event source для Lambda
  
- **Lambda Function**: `cmtr-4n6e9j62-s3-snlt-lambda`
  - Poll-ит messages из SQS
  - Обрабатывает файлы из S3
  - Сохраняет результаты в S3

- **Region**: `eu-west-1`
- **Account ID**: `842676008964`

## 📚 Три шага настройки

### Шаг 1: S3 Event Notification → SQS
```bash
aws s3api put-bucket-notification-configuration \
    --bucket cmtr-4n6e9j62-s3-snlt-bucket-962877 \
    --notification-configuration '{
      "QueueConfigurations": [{
        "QueueArn": "arn:aws:sqs:eu-west-1:842676008964:cmtr-4n6e9j62-s3-snlt-queue",
        "Events": ["s3:ObjectCreated:*"],
        "Filter": {"Key": {"FilterRules": [{"Name": "prefix", "Value": "input/"}]}}
      }]
    }'
```

### Шаг 2: SQS → Lambda Event Source Mapping
```bash
aws lambda create-event-source-mapping \
    --function-name cmtr-4n6e9j62-s3-snlt-lambda \
    --event-source-arn arn:aws:sqs:eu-west-1:842676008964:cmtr-4n6e9j62-s3-snlt-queue \
    --batch-size 10
```

### Шаг 3: Загрузить тестовый файл
```bash
echo "Test file" > test.txt
aws s3 cp test.txt s3://cmtr-4n6e9j62-s3-snlt-bucket-962877/input/
```

## 🔑 Credentials

```bash
export AWS_ACCESS_KEY_ID=AKIA4IM3HPACLXLPMS77
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1
```

## ✅ Верификация

### Проверить S3 notification:
```bash
aws s3api get-bucket-notification-configuration \
    --bucket cmtr-4n6e9j62-s3-snlt-bucket-962877
```

### Проверить Lambda trigger:
```bash
aws lambda list-event-source-mappings \
    --function-name cmtr-4n6e9j62-s3-snlt-lambda
```

### Проверить обработанные файлы:
```bash
aws s3 ls s3://cmtr-4n6e9j62-s3-snlt-bucket-962877/output/ --recursive
```

## 🎓 Что демонстрирует Task 6

1. **S3 Event Notifications**:
   - Publish события при ObjectCreated
   - Фильтрация по prefix (input/)
   - Destination: SQS queue

2. **SQS as Event Buffer**:
   - Decoupling между S3 и Lambda
   - Reliable message delivery
   - Batch processing

3. **Lambda Event Source Mapping**:
   - Poll-based invocation
   - Automatic scaling
   - Batch size configuration

4. **Event-Driven Architecture**:
   - Asynchronous processing
   - Serverless pipeline
   - Automatic file processing

## 🏗️ Архитектура

```
┌─────────────┐
│    User     │
└──────┬──────┘
       │ Upload file
       ▼
┌─────────────────────────────┐
│     S3 Bucket               │
│  input/test.txt             │
└──────┬──────────────────────┘
       │ S3 Event Notification
       │ (ObjectCreated:*)
       ▼
┌─────────────────────────────┐
│     SQS Queue               │
│  (event buffer)             │
└──────┬──────────────────────┘
       │ Event Source Mapping
       │ (poll every ~1 sec)
       ▼
┌─────────────────────────────┐
│  Lambda Function            │
│  (process file)             │
└──────┬──────────────────────┘
       │ Write processed file
       ▼
┌─────────────────────────────┐
│     S3 Bucket               │
│  output/processed/...       │
└─────────────────────────────┘
```

## 📖 Документация

- **QUICKSTART.md** - Быстрый старт (5 минут)
- **INSTRUCTIONS.md** - Пошаговая инструкция
- **ARCHITECTURE.md** - Детальная архитектура
- **CHECKLIST.md** - Чек-лист выполнения
- **PROJECT_SUMMARY.md** - Итоговая сводка

## 🔄 Cleanup

```bash
# Удалить Lambda trigger
MAPPING_UUID=$(aws lambda list-event-source-mappings \
    --function-name cmtr-4n6e9j62-s3-snlt-lambda \
    --query 'EventSourceMappings[0].UUID' --output text)
aws lambda delete-event-source-mapping --uuid $MAPPING_UUID

# Удалить S3 notification
aws s3api put-bucket-notification-configuration \
    --bucket cmtr-4n6e9j62-s3-snlt-bucket-962877 \
    --notification-configuration '{}'

# Очистить bucket
aws s3 rm s3://cmtr-4n6e9j62-s3-snlt-bucket-962877/input/ --recursive
aws s3 rm s3://cmtr-4n6e9j62-s3-snlt-bucket-962877/output/ --recursive
```

## 💡 Ключевые моменты

1. **S3 Event Notification Filter**:
   - Prefix: `input/` - только файлы в этой папке
   - Events: `s3:ObjectCreated:*` - любой тип создания объекта
   - Destination: SQS queue ARN

2. **SQS as Buffer**:
   - Decouples S3 from Lambda
   - Guarantees message delivery
   - Allows batch processing

3. **Lambda Event Source Mapping**:
   - Poll-based (не push-based как SNS)
   - Batch size 10 = до 10 messages одновременно
   - Automatic retries on failure

4. **Async Processing**:
   - Upload → immediate response
   - Processing happens asynchronously
   - Check output/ folder for results

## 📚 Полезные ссылки

- [S3 Event Notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html)
- [Using Lambda with SQS](https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html)
- [S3 Event Message Structure](https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-content-structure.html)
- [Event Source Mappings](https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventsourcemapping.html)

## 🆘 Troubleshooting

### Problem: Файлы не появляются в output/
- **Причина 1**: Lambda ошибка при обработке
- **Решение**: Проверить CloudWatch Logs
  ```bash
  aws logs tail /aws/lambda/cmtr-4n6e9j62-s3-snlt-lambda --follow
  ```

- **Причина 2**: Event source mapping не активен
- **Решение**: Проверить статус
  ```bash
  aws lambda list-event-source-mappings --function-name cmtr-4n6e9j62-s3-snlt-lambda
  ```

### Problem: S3 notification не срабатывает
- **Причина**: Файл загружен не в input/ folder
- **Решение**: Загрузить именно в `s3://bucket/input/file.txt`

### Problem: Lambda не получает messages
- **Причина**: Event source mapping не создан
- **Решение**: Выполнить Шаг 2

## 🎯 Результат

После выполнения Task 6:
- ✅ S3 events публикуются в SQS при загрузке в input/
- ✅ Lambda автоматически triggered при новых messages
- ✅ Файлы обрабатываются и сохраняются в output/
- ✅ Event-driven pipeline полностью функционирует

---

**Связанные задачи:**
- Task 1-5: IAM policies и permissions
- Task 6: Event-driven architecture (S3 + SQS + Lambda)

**Следующий уровень:**
- SNS topic notifications
- EventBridge rules
- Step Functions workflows
