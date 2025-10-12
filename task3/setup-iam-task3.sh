#!/bin/bash

# AWS IAM Task 3 Setup Script - Role Assumption
# Настройка assume role и trust policy

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Настройка AWS credentials...${NC}"
export AWS_ACCESS_KEY_ID=AKIAY6QVYZH2ESZQQ6CV
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# Переменные
ASSUME_ROLE="cmtr-4n6e9j62-iam-ar-iam_role-assume"
READONLY_ROLE="cmtr-4n6e9j62-iam-ar-iam_role-readonly"
ACCOUNT_ID="615299729908"
ASSUME_POLICY_NAME="AssumeReadOnlyRolePolicy"

echo -e "${BLUE}Проверка подключения к AWS...${NC}"
aws sts get-caller-identity

echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Шаг 1: Присоединение политики AssumeRole к assume роли${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

echo "Создаем inline policy для ${ASSUME_ROLE}..."
echo "Политика разрешает: sts:AssumeRole для readonly роли"

aws iam put-role-policy \
    --role-name "${ASSUME_ROLE}" \
    --policy-name "${ASSUME_POLICY_NAME}" \
    --policy-document file://assume-role-policy.json

echo -e "${GREEN}✓ Inline policy успешно создана${NC}"

echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Шаг 2: Присоединение ReadOnlyAccess к readonly роли${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

echo "Присоединяем AWS Managed Policy: ReadOnlyAccess..."

aws iam attach-role-policy \
    --role-name "${READONLY_ROLE}" \
    --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess"

echo -e "${GREEN}✓ ReadOnlyAccess policy присоединена${NC}"

echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Шаг 3: Обновление Trust Policy для readonly роли${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

echo "Обновляем Trust Policy для ${READONLY_ROLE}..."
echo "Разрешаем assume от ${ASSUME_ROLE}..."

aws iam update-assume-role-policy \
    --role-name "${READONLY_ROLE}" \
    --policy-document file://trust-policy.json

echo -e "${GREEN}✓ Trust Policy успешно обновлена${NC}"

echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Проверка настроек${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}1. Inline политики assume роли:${NC}"
aws iam list-role-policies --role-name "${ASSUME_ROLE}"

echo -e "\n${YELLOW}2. Attached политики readonly роли:${NC}"
aws iam list-attached-role-policies --role-name "${READONLY_ROLE}"

echo -e "\n${YELLOW}3. Trust Policy readonly роли:${NC}"
aws iam get-role --role-name "${READONLY_ROLE}" --query 'Role.AssumeRolePolicyDocument'

echo -e "\n${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Task 3 выполнена!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"

echo -e "\n${BLUE}Верификация через AWS IAM Policy Simulator:${NC}"

echo -e "\n${YELLOW}Тест 1: AssumeRole для assume роли (должен быть ALLOWED)${NC}"
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::${ACCOUNT_ID}:role/${ASSUME_ROLE} \
  --action-names sts:AssumeRole \
  --resource-arns arn:aws:iam::${ACCOUNT_ID}:role/${READONLY_ROLE} \
  --query 'EvaluationResults[0].[EvalActionName,EvalDecision]' \
  --output text

echo -e "\n${YELLOW}Тест 2: Чтение EC2 для readonly роли (должен быть ALLOWED)${NC}"
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::${ACCOUNT_ID}:role/${READONLY_ROLE} \
  --action-names ec2:DescribeInstances \
  --query 'EvaluationResults[0].[EvalActionName,EvalDecision]' \
  --output text

echo -e "\n${RED}Тест 3: Запись EC2 для readonly роли (должен быть DENIED)${NC}"
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::${ACCOUNT_ID}:role/${READONLY_ROLE} \
  --action-names ec2:RunInstances \
  --query 'EvaluationResults[0].[EvalActionName,EvalDecision]' \
  --output text

echo -e "\n${BLUE}Практическая проверка (опционально):${NC}"
echo -e "1. Assume роль assume:"
echo -e "   aws sts assume-role --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${ASSUME_ROLE} --role-session-name test"
echo -e "\n2. Используя credentials из шага 1, assume readonly роль:"
echo -e "   aws sts assume-role --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${READONLY_ROLE} --role-session-name test"
echo -e "\n3. Используя credentials из шага 2, попробуйте read операции (должны работать)"
echo -e "4. Попробуйте write операции (должны быть запрещены)"

echo -e "\n${BLUE}Web UI для проверки:${NC}"
echo -e "https://policysim.aws.amazon.com/"
