#!/bin/bash

# AWS IAM Task Setup Script
# Этот скрипт выполняет настройку IAM политик для роли и S3 bucket

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Настройка AWS credentials
echo -e "${BLUE}Настройка AWS credentials...${NC}"
export AWS_ACCESS_KEY_ID=AKIAZPPF72N7EHDWSCFI
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# Переменные
ROLE_NAME="cmtr-4n6e9j62-iam-peld-iam_role"
BUCKET_NAME="cmtr-4n6e9j62-iam-peld-bucket-2911738"
ACCOUNT_ID="651706749822"

echo -e "${BLUE}Проверка подключения к AWS...${NC}"
aws sts get-caller-identity

echo -e "\n${BLUE}Шаг 1: Присоединение AWS Managed Policy для полного доступа к S3${NC}"
echo "Присоединяем политику AmazonS3FullAccess к роли ${ROLE_NAME}..."
aws iam attach-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-arn "arn:aws:iam::aws:policy/AmazonS3FullAccess"

echo -e "${GREEN}✓ Политика AmazonS3FullAccess успешно присоединена к роли${NC}"

echo -e "\n${BLUE}Шаг 2: Получение текущей bucket policy${NC}"
echo "Получаем текущую политику для bucket ${BUCKET_NAME}..."

# Попытка получить существующую политику
EXISTING_POLICY=$(aws s3api get-bucket-policy --bucket "${BUCKET_NAME}" --query Policy --output text 2>/dev/null || echo "")

if [ -z "$EXISTING_POLICY" ]; then
    echo "Bucket не имеет существующей политики. Создаем новую..."
    POLICY_JSON='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyDeleteObjectForRole",
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::'${ACCOUNT_ID}':role/'${ROLE_NAME}'"
      },
      "Action": "s3:DeleteObject",
      "Resource": "arn:aws:s3:::'${BUCKET_NAME}'/*"
    }
  ]
}'
else
    echo "Существующая политика найдена. Обновляем её..."
    # Здесь нужно будет объединить существующую политику с новым правилом
    # Для упрощения создаем новую политику с Deny правилом
    POLICY_JSON=$(echo "$EXISTING_POLICY" | jq '. + {Statement: [.Statement[] + {
      "Sid": "DenyDeleteObjectForRole",
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::'${ACCOUNT_ID}':role/'${ROLE_NAME}'"
      },
      "Action": "s3:DeleteObject",
      "Resource": "arn:aws:s3:::'${BUCKET_NAME}'/*"
    }]}' 2>/dev/null || echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyDeleteObjectForRole",
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::'${ACCOUNT_ID}':role/'${ROLE_NAME}'"
      },
      "Action": "s3:DeleteObject",
      "Resource": "arn:aws:s3:::'${BUCKET_NAME}'/*"
    }
  ]
}')
fi

echo -e "\n${BLUE}Применение обновленной bucket policy...${NC}"
echo "$POLICY_JSON" > /tmp/bucket-policy.json
cat /tmp/bucket-policy.json

aws s3api put-bucket-policy \
    --bucket "${BUCKET_NAME}" \
    --policy file:///tmp/bucket-policy.json

echo -e "${GREEN}✓ Bucket policy успешно обновлена${NC}"

echo -e "\n${BLUE}Шаг 3: Проверка настроек${NC}"
echo "Проверяем присоединенные политики роли..."
aws iam list-attached-role-policies --role-name "${ROLE_NAME}"

echo -e "\nПроверяем bucket policy..."
aws s3api get-bucket-policy --bucket "${BUCKET_NAME}" --query Policy --output text | jq '.'

echo -e "\n${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Задача выполнена!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "\n${BLUE}Для проверки используйте AWS IAM Policy Simulator:${NC}"
echo -e "1. Откройте: https://policysim.aws.amazon.com/"
echo -e "2. Выберите роль: ${ROLE_NAME}"
echo -e "3. Выберите сервис: Amazon S3"
echo -e "4. Выберите действие: DeleteObject"
echo -e "5. Укажите ресурс: arn:aws:s3:::${BUCKET_NAME}/*"
echo -e "6. Запустите симуляцию - результат должен быть ${RED}Denied${NC}"
echo -e "\nИли используйте командную строку:"
echo -e "aws iam simulate-principal-policy \\"
echo -e "  --policy-source-arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} \\"
echo -e "  --action-names s3:DeleteObject \\"
echo -e "  --resource-arns arn:aws:s3:::${BUCKET_NAME}/test-object"

rm -f /tmp/bucket-policy.json
