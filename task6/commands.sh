#!/bin/bash

# Task 6: S3 + SQS + Lambda Event-Driven Architecture
# Готовые команды для ручного выполнения

# ===========================================
# CREDENTIALS
# ===========================================

export AWS_ACCESS_KEY_ID=AKIA4IM3HPACLXLPMS77
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# ===========================================
# ПЕРЕМЕННЫЕ
# ===========================================

BUCKET_NAME="cmtr-4n6e9j62-s3-snlt-bucket-962877"
QUEUE_NAME="cmtr-4n6e9j62-s3-snlt-queue"
LAMBDA_FUNCTION="cmtr-4n6e9j62-s3-snlt-lambda"
REGION="eu-west-1"
ACCOUNT_ID="842676008964"

QUEUE_URL="https://sqs.$REGION.amazonaws.com/$ACCOUNT_ID/$QUEUE_NAME"
QUEUE_ARN="arn:aws:sqs:$REGION:$ACCOUNT_ID:$QUEUE_NAME"

# ===========================================
# ПРОВЕРКА СУЩЕСТВУЮЩИХ РЕСУРСОВ
# ===========================================

# Проверить S3 bucket
aws s3 ls | grep cmtr-4n6e9j62-s3-snlt

# Просмотреть содержимое bucket
aws s3 ls s3://$BUCKET_NAME/
aws s3 ls s3://$BUCKET_NAME/input/
aws s3 ls s3://$BUCKET_NAME/output/

# Проверить SQS queue
aws sqs list-queues | grep cmtr-4n6e9j62-s3-snlt

# Получить Queue attributes
aws sqs get-queue-attributes \
    --queue-url "$QUEUE_URL" \
    --attribute-names All

# Получить Queue ARN
aws sqs get-queue-attributes \
    --queue-url "$QUEUE_URL" \
    --attribute-names QueueArn \
    --query 'Attributes.QueueArn' \
    --output text

# Проверить Lambda function
aws lambda get-function --function-name $LAMBDA_FUNCTION

# Список Lambda functions
aws lambda list-functions --query "Functions[?contains(FunctionName, 'cmtr-4n6e9j62')].[FunctionName,Runtime,State]" --output table

# ===========================================
# ШАГ 1: S3 EVENT NOTIFICATION → SQS
# ===========================================

# 1.1 Проверить текущую notification configuration
aws s3api get-bucket-notification-configuration --bucket $BUCKET_NAME

# 1.2 Создать notification configuration JSON
cat > s3-notification-config.json << EOF
{
  "QueueConfigurations": [
    {
      "Id": "S3ToSQSNotification",
      "QueueArn": "$QUEUE_ARN",
      "Events": [
        "s3:ObjectCreated:*"
      ],
      "Filter": {
        "Key": {
          "FilterRules": [
            {
              "Name": "prefix",
              "Value": "input/"
            }
          ]
        }
      }
    }
  ]
}
EOF

# 1.3 Применить notification configuration
aws s3api put-bucket-notification-configuration \
    --bucket $BUCKET_NAME \
    --notification-configuration file://s3-notification-config.json

# 1.4 Проверить что notification настроен
aws s3api get-bucket-notification-configuration --bucket $BUCKET_NAME

# 1.5 Альтернативный способ (через AWS CLI параметры)
aws s3api put-bucket-notification-configuration \
    --bucket $BUCKET_NAME \
    --notification-configuration '{
      "QueueConfigurations": [
        {
          "Id": "S3ToSQSNotification",
          "QueueArn": "'"$QUEUE_ARN"'",
          "Events": ["s3:ObjectCreated:*"],
          "Filter": {
            "Key": {
              "FilterRules": [
                {"Name": "prefix", "Value": "input/"}
              ]
            }
          }
        }
      ]
    }'

# ===========================================
# ШАГ 2: SQS EVENT SOURCE → LAMBDA
# ===========================================

# 2.1 Проверить существующие event source mappings
aws lambda list-event-source-mappings --function-name $LAMBDA_FUNCTION

# 2.2 Создать event source mapping (Lambda trigger)
aws lambda create-event-source-mapping \
    --function-name $LAMBDA_FUNCTION \
    --event-source-arn $QUEUE_ARN \
    --batch-size 10

# 2.3 Получить UUID созданного mapping
MAPPING_UUID=$(aws lambda list-event-source-mappings \
    --function-name $LAMBDA_FUNCTION \
    --query "EventSourceMappings[?EventSourceArn=='$QUEUE_ARN'].UUID" \
    --output text)
echo "Mapping UUID: $MAPPING_UUID"

# 2.4 Проверить статус event source mapping
aws lambda get-event-source-mapping --uuid $MAPPING_UUID

# 2.5 Подождать пока mapping станет Enabled
# Статус может быть: Creating → Enabling → Enabled
watch -n 5 "aws lambda get-event-source-mapping --uuid $MAPPING_UUID --query '[State,LastProcessingResult]' --output table"

# 2.6 Список всех event source mappings для Lambda
aws lambda list-event-source-mappings \
    --function-name $LAMBDA_FUNCTION \
    --query 'EventSourceMappings[*].[UUID,State,EventSourceArn]' \
    --output table

# ===========================================
# ШАГ 3: ЗАГРУЗИТЬ ТЕСТОВЫЙ ФАЙЛ
# ===========================================

# 3.1 Создать тестовый файл
cat > test-file.txt << EOF
This is a test file for Task 6
Uploaded at: $(date)
S3 + SQS + Lambda event-driven architecture
Testing file processing workflow
EOF

# 3.2 Загрузить файл в S3 input/ folder
aws s3 cp test-file.txt s3://$BUCKET_NAME/input/

# 3.3 Проверить что файл загружен
aws s3 ls s3://$BUCKET_NAME/input/

# 3.4 Загрузить несколько файлов
for i in {1..3}; do
    echo "Test file $i - $(date)" > test-file-$i.txt
    aws s3 cp test-file-$i.txt s3://$BUCKET_NAME/input/
done

# 3.5 Проверить содержимое файла
aws s3 cp s3://$BUCKET_NAME/input/test-file.txt - | cat

# ===========================================
# ВЕРИФИКАЦИЯ
# ===========================================

# Тест 1: Проверить S3 notification configuration
aws s3api get-bucket-notification-configuration \
    --bucket $BUCKET_NAME \
    --query 'QueueConfigurations[*].[Id,QueueArn,Events[0]]' \
    --output table

# Тест 2: Проверить Lambda event source mapping
aws lambda list-event-source-mappings \
    --function-name $LAMBDA_FUNCTION \
    --query 'EventSourceMappings[*].[UUID,State,BatchSize]' \
    --output table

# Тест 3: Проверить обработанные файлы в output/
aws s3 ls s3://$BUCKET_NAME/output/ --recursive

# Тест 4: Посчитать файлы в output/
aws s3 ls s3://$BUCKET_NAME/output/ --recursive | wc -l

# Тест 5: Скачать обработанный файл
# Найти первый файл в output/
OUTPUT_FILE=$(aws s3 ls s3://$BUCKET_NAME/output/ --recursive | head -1 | awk '{print $4}')
aws s3 cp s3://$BUCKET_NAME/$OUTPUT_FILE - | cat

# Тест 6: Проверить SQS messages
aws sqs get-queue-attributes \
    --queue-url $QUEUE_URL \
    --attribute-names ApproximateNumberOfMessages,ApproximateNumberOfMessagesNotVisible

# Тест 7: Receive message from queue (если есть)
aws sqs receive-message \
    --queue-url $QUEUE_URL \
    --max-number-of-messages 1

# ===========================================
# МОНИТОРИНГ И ЛОГИ
# ===========================================

# CloudWatch Logs для Lambda
aws logs tail /aws/lambda/$LAMBDA_FUNCTION --follow

# Последние 50 log events
aws logs tail /aws/lambda/$LAMBDA_FUNCTION --since 10m

# Получить log streams
aws logs describe-log-streams \
    --log-group-name /aws/lambda/$LAMBDA_FUNCTION \
    --order-by LastEventTime \
    --descending \
    --max-items 5

# Lambda invocations метрики
aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Invocations \
    --dimensions Name=FunctionName,Value=$LAMBDA_FUNCTION \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum

# SQS metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/SQS \
    --metric-name NumberOfMessagesSent \
    --dimensions Name=QueueName,Value=$QUEUE_NAME \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum

# ===========================================
# ДОПОЛНИТЕЛЬНЫЕ ОПЕРАЦИИ
# ===========================================

# Скачать Lambda code
CODE_URL=$(aws lambda get-function --function-name $LAMBDA_FUNCTION --query 'Code.Location' --output text)
curl -o lambda-code.zip "$CODE_URL"
unzip lambda-code.zip
cat lambda_function.py  # или другой файл handler

# Lambda configuration
aws lambda get-function-configuration --function-name $LAMBDA_FUNCTION

# Lambda environment variables
aws lambda get-function-configuration \
    --function-name $LAMBDA_FUNCTION \
    --query 'Environment'

# Invoke Lambda вручную (test event)
aws lambda invoke \
    --function-name $LAMBDA_FUNCTION \
    --payload '{"Records":[{"s3":{"bucket":{"name":"'$BUCKET_NAME'"},"object":{"key":"input/test-file.txt"}}}]}' \
    response.json

cat response.json

# ===========================================
# CLEANUP (удаление настроек)
# ===========================================

# Удалить Lambda event source mapping
MAPPING_UUID=$(aws lambda list-event-source-mappings \
    --function-name $LAMBDA_FUNCTION \
    --query "EventSourceMappings[?EventSourceArn=='$QUEUE_ARN'].UUID" \
    --output text)

aws lambda delete-event-source-mapping --uuid $MAPPING_UUID

# Удалить S3 notification configuration
aws s3api put-bucket-notification-configuration \
    --bucket $BUCKET_NAME \
    --notification-configuration '{}'

# Проверить что удалено
aws s3api get-bucket-notification-configuration --bucket $BUCKET_NAME
aws lambda list-event-source-mappings --function-name $LAMBDA_FUNCTION

# Очистить input/ folder
aws s3 rm s3://$BUCKET_NAME/input/ --recursive

# Очистить output/ folder
aws s3 rm s3://$BUCKET_NAME/output/ --recursive

# ===========================================
# TROUBLESHOOTING
# ===========================================

# Problem: Файлы не появляются в output/
# 1. Проверить Lambda logs
aws logs tail /aws/lambda/$LAMBDA_FUNCTION --since 15m

# 2. Проверить Lambda errors
aws lambda get-function-configuration \
    --function-name $LAMBDA_FUNCTION \
    --query 'LastUpdateStatus'

# 3. Проверить SQS Dead Letter Queue (если настроена)
aws sqs get-queue-attributes \
    --queue-url $QUEUE_URL \
    --attribute-names RedrivePolicy

# 4. Проверить permissions
aws lambda get-policy --function-name $LAMBDA_FUNCTION

# Problem: S3 notification не работает
# 1. Проверить что SQS policy разрешает S3 send messages
aws sqs get-queue-attributes \
    --queue-url $QUEUE_URL \
    --attribute-names Policy

# 2. Тест notification вручную
aws s3api put-bucket-notification-configuration \
    --bucket $BUCKET_NAME \
    --notification-configuration file://s3-notification-config.json

# Problem: Lambda trigger не активируется
# 1. Проверить batch size
aws lambda get-event-source-mapping --uuid $MAPPING_UUID --query 'BatchSize'

# 2. Проверить maximum batching window
aws lambda get-event-source-mapping --uuid $MAPPING_UUID --query 'MaximumBatchingWindowInSeconds'

# ===========================================
# ПОЛЕЗНЫЕ ССЫЛКИ
# ===========================================

# AWS S3 Event Notifications:
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html

# Using Lambda with SQS:
# https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html

# S3 Event Message Structure:
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-content-structure.html

# Lambda Event Source Mappings:
# https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventsourcemapping.html
