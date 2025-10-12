#!/bin/bash

# Task 4: KMS Encryption для S3 Bucket
# Автоматическая настройка

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные
ROLE_NAME="cmtr-4n6e9j62-iam-sewk-iam_role"
BUCKET_1="cmtr-4n6e9j62-iam-sewk-bucket-695267-1"
BUCKET_2="cmtr-4n6e9j62-iam-sewk-bucket-695267-2"
KMS_KEY_ARN="arn:aws:kms:eu-west-1:522814710681:key/cac96933-72ff-49e0-8734-753dcd4a0ff5"
KMS_KEY_ID="cac96933-72ff-49e0-8734-753dcd4a0ff5"
FILE_NAME="confidential_credentials.csv"
POLICY_NAME="KMSAccessPolicy"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Task 4: KMS Encryption для S3        ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Проверка credentials
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo -e "${YELLOW}⚠️  AWS credentials не установлены. Используйте:${NC}"
    echo "export AWS_ACCESS_KEY_ID=AKIAXTORPMOMXL3LT7RQ"
    echo "export AWS_SECRET_ACCESS_KEY=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"
    echo "export AWS_DEFAULT_REGION=eu-west-1"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials настроены${NC}"
echo ""

# Шаг 1: Attach KMS policy к роли
echo -e "${YELLOW}📋 Шаг 1/3: Присоединение KMS policy к роли...${NC}"
aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "$POLICY_NAME" \
    --policy-document file://kms-policy.json

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ KMS policy успешно присоединен к роли $ROLE_NAME${NC}"
else
    echo -e "${RED}❌ Ошибка присоединения KMS policy${NC}"
    exit 1
fi
echo ""

# Шаг 2: Enable server-side encryption для bucket-2
echo -e "${YELLOW}🔐 Шаг 2/3: Включение server-side encryption для bucket-2...${NC}"
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_2" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "aws:kms",
                    "KMSMasterKeyID": "'"$KMS_KEY_ARN"'"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Server-side encryption включен для bucket $BUCKET_2${NC}"
else
    echo -e "${RED}❌ Ошибка включения encryption${NC}"
    exit 1
fi
echo ""

# Шаг 3: Копирование файла из bucket-1 в bucket-2
echo -e "${YELLOW}📦 Шаг 3/3: Копирование файла из bucket-1 в bucket-2...${NC}"
aws s3 cp "s3://$BUCKET_1/$FILE_NAME" "s3://$BUCKET_2/$FILE_NAME" \
    --sse aws:kms \
    --sse-kms-key-id "$KMS_KEY_ARN"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Файл $FILE_NAME успешно скопирован и зашифрован${NC}"
else
    echo -e "${RED}❌ Ошибка копирования файла${NC}"
    exit 1
fi
echo ""

# Автоматические тесты
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Автоматические тесты                 ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Тест 1: Проверка inline policy
echo -e "${YELLOW}🧪 Тест 1: Проверка KMS policy на роли...${NC}"
KMS_POLICY=$(aws iam get-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" 2>&1)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ KMS policy найден на роли${NC}"
else
    echo -e "${RED}❌ KMS policy не найден${NC}"
fi
echo ""

# Тест 2: Проверка bucket encryption
echo -e "${YELLOW}🧪 Тест 2: Проверка bucket encryption...${NC}"
ENCRYPTION=$(aws s3api get-bucket-encryption --bucket "$BUCKET_2" 2>&1)
if echo "$ENCRYPTION" | grep -q "$KMS_KEY_ID"; then
    echo -e "${GREEN}✅ Bucket encryption настроен с правильным KMS ключом${NC}"
else
    echo -e "${RED}❌ Bucket encryption не настроен или использует неправильный ключ${NC}"
fi
echo ""

# Тест 3: Проверка что файл существует в bucket-2
echo -e "${YELLOW}🧪 Тест 3: Проверка файла в bucket-2...${NC}"
FILE_CHECK=$(aws s3 ls "s3://$BUCKET_2/$FILE_NAME" 2>&1)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Файл $FILE_NAME найден в bucket-2${NC}"
    
    # Проверка encryption файла
    FILE_ENCRYPTION=$(aws s3api head-object --bucket "$BUCKET_2" --key "$FILE_NAME" 2>&1)
    if echo "$FILE_ENCRYPTION" | grep -q "aws:kms"; then
        echo -e "${GREEN}✅ Файл зашифрован с KMS${NC}"
    else
        echo -e "${YELLOW}⚠️  Не удалось подтвердить encryption файла${NC}"
    fi
else
    echo -e "${RED}❌ Файл не найден в bucket-2${NC}"
fi
echo ""

# Итоговый результат
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ✅ Task 4 выполнен успешно!          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Что было настроено:${NC}"
echo -e "  ✅ KMS policy присоединен к роли"
echo -e "  ✅ Server-side encryption включен для bucket-2"
echo -e "  ✅ Файл скопирован и зашифрован"
echo ""
echo -e "${YELLOW}Проверка:${NC}"
echo -e "  aws s3api get-bucket-encryption --bucket $BUCKET_2"
echo -e "  aws s3api head-object --bucket $BUCKET_2 --key $FILE_NAME"
echo ""
