#!/bin/bash

# AWS IAM Task 2 Setup Script
# Этот скрипт выполняет настройку IAM политик для роли и S3 bucket

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Настройка AWS credentials
echo -e "${BLUE}Настройка AWS credentials...${NC}"
export AWS_ACCESS_KEY_ID=AKIA4SDNVQZ7K5LP7AXA
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# Переменные
ROLE_NAME="cmtr-4n6e9j62-iam-pela-iam_role"
BUCKET_1="cmtr-4n6e9j62-iam-pela-bucket-1-162653"
BUCKET_2="cmtr-4n6e9j62-iam-pela-bucket-2-162653"
ACCOUNT_ID="863518426750"
INLINE_POLICY_NAME="ListAllBucketsPolicy"

echo -e "${BLUE}Проверка подключения к AWS...${NC}"
aws sts get-caller-identity

echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Move 1: Создание и присоединение Inline Policy к роли${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

echo "Создаем inline policy '${INLINE_POLICY_NAME}' для роли ${ROLE_NAME}..."
echo "Политика разрешает: s3:ListAllMyBuckets"

# Создаем inline policy из файла
aws iam put-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-name "${INLINE_POLICY_NAME}" \
    --policy-document file://inline-policy.json

echo -e "${GREEN}✓ Inline policy успешно создана и присоединена к роли${NC}"

echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Move 2: Создание Resource-Based Policy для bucket${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

echo "Создаем bucket policy для ${BUCKET_1}..."
echo "Политика разрешает роли:"
echo "  - s3:GetObject"
echo "  - s3:PutObject"
echo "  - s3:ListBucket"

aws s3api put-bucket-policy \
    --bucket "${BUCKET_1}" \
    --policy file://bucket-policy.json

echo -e "${GREEN}✓ Bucket policy успешно применена${NC}"

echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Проверка настроек${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}1. Inline политики роли:${NC}"
aws iam list-role-policies --role-name "${ROLE_NAME}"

echo -e "\n${YELLOW}2. Содержимое inline policy:${NC}"
aws iam get-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-name "${INLINE_POLICY_NAME}" \
    --query PolicyDocument

echo -e "\n${YELLOW}3. Bucket policy для ${BUCKET_1}:${NC}"
aws s3api get-bucket-policy \
    --bucket "${BUCKET_1}" \
    --query Policy --output text | jq '.'

echo -e "\n${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Task 2 выполнена!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"

echo -e "\n${BLUE}Верификация через AWS IAM Policy Simulator:${NC}"
echo -e "\n${YELLOW}Тест 1: ListAllMyBuckets (должен быть ALLOWED)${NC}"
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} \
  --action-names s3:ListAllMyBuckets \
  --query 'EvaluationResults[0].[EvalActionName,EvalDecision]' \
  --output text

echo -e "\n${YELLOW}Тест 2: ListBucket для bucket-1 (должен быть ALLOWED)${NC}"
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} \
  --action-names s3:ListBucket \
  --resource-arns arn:aws:s3:::${BUCKET_1} \
  --query 'EvaluationResults[0].[EvalActionName,EvalDecision]' \
  --output text

echo -e "\n${YELLOW}Тест 3: GetObject для bucket-1 (должен быть ALLOWED)${NC}"
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::${BUCKET_1}/test-object \
  --query 'EvaluationResults[0].[EvalActionName,EvalDecision]' \
  --output text

echo -e "\n${YELLOW}Тест 4: PutObject для bucket-1 (должен быть ALLOWED)${NC}"
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} \
  --action-names s3:PutObject \
  --resource-arns arn:aws:s3:::${BUCKET_1}/test-object \
  --query 'EvaluationResults[0].[EvalActionName,EvalDecision]' \
  --output text

echo -e "\n${RED}Тест 5: GetObject для bucket-2 (должен быть DENIED)${NC}"
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::${BUCKET_2}/test-object \
  --query 'EvaluationResults[0].[EvalActionName,EvalDecision]' \
  --output text

echo -e "\n${BLUE}Web UI для проверки:${NC}"
echo -e "https://policysim.aws.amazon.com/"
echo -e "\nВыберите роль: ${ROLE_NAME}"
echo -e "Протестируйте действия для обоих buckets"
