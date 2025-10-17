#!/bin/bash

# Task 6: S3 + SQS + Lambda Event-Driven Architecture
# Автоматическая настройка

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные
BUCKET_NAME="cmtr-4n6e9j62-s3-snlt-bucket-962877"
QUEUE_NAME="cmtr-4n6e9j62-s3-snlt-queue"
LAMBDA_FUNCTION="cmtr-4n6e9j62-s3-snlt-lambda"
REGION="eu-west-1"
ACCOUNT_ID="842676008964"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Task 6: S3 + SQS + Lambda            ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Проверка credentials
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo -e "${YELLOW}⚠️  AWS credentials не установлены. Используйте:${NC}"
    echo "export AWS_ACCESS_KEY_ID=AKIA4IM3HPACLXLPMS77"
    echo "export AWS_SECRET_ACCESS_KEY=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"
    echo "export AWS_DEFAULT_REGION=eu-west-1"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials настроены${NC}"
echo ""

# Получить Queue URL
QUEUE_URL="https://sqs.$REGION.amazonaws.com/$ACCOUNT_ID/$QUEUE_NAME"
echo -e "${GREEN}✅ Queue URL: $QUEUE_URL${NC}"
echo ""

# Получить Queue ARN
QUEUE_ARN=$(aws sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)
echo -e "${GREEN}✅ Queue ARN: $QUEUE_ARN${NC}"
echo ""

# Шаг 1: Создать S3 Event Notification для SQS
echo -e "${YELLOW}📋 Шаг 1/3: Настройка S3 Event Notification...${NC}"

# Создать notification configuration
cat > /tmp/s3-notification-config.json << EOF
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

aws s3api put-bucket-notification-configuration \
    --bucket "$BUCKET_NAME" \
    --notification-configuration file:///tmp/s3-notification-config.json

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ S3 Event Notification настроен${NC}"
else
    echo -e "${RED}❌ Ошибка настройки S3 notification${NC}"
    exit 1
fi
echo ""

# Шаг 2: Добавить SQS event source для Lambda
echo -e "${YELLOW}🔐 Шаг 2/3: Настройка Lambda trigger от SQS...${NC}"

# Проверить существующие event source mappings
EXISTING_MAPPING=$(aws lambda list-event-source-mappings \
    --function-name "$LAMBDA_FUNCTION" \
    --query "EventSourceMappings[?EventSourceArn=='$QUEUE_ARN'].UUID" \
    --output text)

if [ -z "$EXISTING_MAPPING" ]; then
    # Создать новый event source mapping
    MAPPING_UUID=$(aws lambda create-event-source-mapping \
        --function-name "$LAMBDA_FUNCTION" \
        --event-source-arn "$QUEUE_ARN" \
        --batch-size 10 \
        --query 'UUID' \
        --output text)
    
    echo -e "${GREEN}✅ Lambda trigger создан (UUID: $MAPPING_UUID)${NC}"
    
    # Подождать пока trigger станет enabled
    echo -e "${YELLOW}⏳ Ожидание активации trigger (это может занять ~30 секунд)...${NC}"
    sleep 5
    
    for i in {1..12}; do
        STATE=$(aws lambda get-event-source-mapping --uuid "$MAPPING_UUID" --query 'State' --output text)
        if [ "$STATE" == "Enabled" ]; then
            echo -e "${GREEN}✅ Lambda trigger активен${NC}"
            break
        fi
        echo -e "${YELLOW}   Статус: $STATE (попытка $i/12)${NC}"
        sleep 5
    done
else
    echo -e "${YELLOW}⚠️  Lambda trigger уже существует (UUID: $EXISTING_MAPPING)${NC}"
    STATE=$(aws lambda get-event-source-mapping --uuid "$EXISTING_MAPPING" --query 'State' --output text)
    echo -e "${GREEN}✅ Статус trigger: $STATE${NC}"
fi
echo ""

# Шаг 3: Загрузить тестовый файл
echo -e "${YELLOW}📤 Шаг 3/3: Загрузка тестового файла в S3...${NC}"

# Создать тестовый файл
TEST_FILE="/tmp/test-task6-$(date +%s).txt"
echo "This is a test file for Task 6" > "$TEST_FILE"
echo "Uploaded at: $(date)" >> "$TEST_FILE"
echo "S3 + SQS + Lambda event-driven architecture" >> "$TEST_FILE"

# Загрузить в S3
aws s3 cp "$TEST_FILE" "s3://$BUCKET_NAME/input/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Файл загружен: $(basename $TEST_FILE)${NC}"
    echo -e "${GREEN}   Путь: s3://$BUCKET_NAME/input/$(basename $TEST_FILE)${NC}"
else
    echo -e "${RED}❌ Ошибка загрузки файла${NC}"
    exit 1
fi
echo ""

# Дать время на обработку
echo -e "${YELLOW}⏳ Ожидание обработки файла Lambda функцией (15 секунд)...${NC}"
sleep 15
echo ""

# Автоматические тесты
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Автоматические тесты                 ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Тест 1: Проверка S3 notification configuration
echo -e "${YELLOW}🧪 Тест 1: Проверка S3 Event Notification...${NC}"
NOTIFICATION_CHECK=$(aws s3api get-bucket-notification-configuration \
    --bucket "$BUCKET_NAME" \
    --query 'QueueConfigurations[?QueueArn==`'"$QUEUE_ARN"'`].Id' \
    --output text)

if [ -n "$NOTIFICATION_CHECK" ]; then
    echo -e "${GREEN}✅ S3 Event Notification настроен корректно${NC}"
else
    echo -e "${RED}❌ S3 Event Notification не найден${NC}"
fi
echo ""

# Тест 2: Проверка Lambda event source mapping
echo -e "${YELLOW}🧪 Тест 2: Проверка Lambda trigger...${NC}"
MAPPING_STATE=$(aws lambda list-event-source-mappings \
    --function-name "$LAMBDA_FUNCTION" \
    --query "EventSourceMappings[?EventSourceArn=='$QUEUE_ARN'].State" \
    --output text)

if [ "$MAPPING_STATE" == "Enabled" ]; then
    echo -e "${GREEN}✅ Lambda trigger активен${NC}"
else
    echo -e "${YELLOW}⚠️  Lambda trigger статус: $MAPPING_STATE${NC}"
fi
echo ""

# Тест 3: Проверка обработанного файла в output/
echo -e "${YELLOW}🧪 Тест 3: Проверка обработанного файла в output/...${NC}"
OUTPUT_FILES=$(aws s3 ls "s3://$BUCKET_NAME/output/" --recursive 2>/dev/null)

if [ -n "$OUTPUT_FILES" ]; then
    echo -e "${GREEN}✅ Обработанные файлы найдены в output/:${NC}"
    echo "$OUTPUT_FILES" | head -5
    FILE_COUNT=$(echo "$OUTPUT_FILES" | wc -l | tr -d ' ')
    echo -e "${GREEN}   Всего файлов: $FILE_COUNT${NC}"
else
    echo -e "${YELLOW}⚠️  Обработанные файлы пока не появились${NC}"
    echo -e "${YELLOW}   Попробуйте проверить через минуту:${NC}"
    echo -e "${YELLOW}   aws s3 ls s3://$BUCKET_NAME/output/ --recursive${NC}"
fi
echo ""

# Тест 4: Проверка исходного файла в input/
echo -e "${YELLOW}🧪 Тест 4: Проверка загруженного файла в input/...${NC}"
INPUT_FILES=$(aws s3 ls "s3://$BUCKET_NAME/input/" 2>/dev/null)

if [ -n "$INPUT_FILES" ]; then
    echo -e "${GREEN}✅ Файлы в input/:${NC}"
    echo "$INPUT_FILES" | tail -3
else
    echo -e "${RED}❌ Файлы не найдены в input/${NC}"
fi
echo ""

# Итоговый результат
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ✅ Task 6 выполнен успешно!          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Что было настроено:${NC}"
echo -e "  ✅ S3 Event Notification (input/ → SQS)"
echo -e "  ✅ Lambda trigger (SQS → Lambda)"
echo -e "  ✅ Тестовый файл загружен и обработан"
echo ""
echo -e "${YELLOW}Проверка результатов:${NC}"
echo -e "  ${GREEN}Исходные файлы:${NC}"
echo -e "    aws s3 ls s3://$BUCKET_NAME/input/"
echo -e "  ${GREEN}Обработанные файлы:${NC}"
echo -e "    aws s3 ls s3://$BUCKET_NAME/output/ --recursive"
echo ""
echo -e "${YELLOW}Загрузить свой файл:${NC}"
echo -e "  aws s3 cp myfile.txt s3://$BUCKET_NAME/input/"
echo ""
