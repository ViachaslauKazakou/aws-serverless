# AWS IAM Task 2 - Quick Commands
# Эти команды можно скопировать и выполнить по отдельности

# ============================================================
# НАСТРОЙКА ОКРУЖЕНИЯ
# ============================================================

export AWS_ACCESS_KEY_ID=AKIA4SDNVQZ7K5LP7AXA
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# Проверка подключения
aws sts get-caller-identity

# ============================================================
# MOVE 1: Создание и присоединение Inline Policy
# ============================================================

# Создать inline policy для роли (разрешает ListAllMyBuckets)
aws iam put-role-policy \
    --role-name cmtr-4n6e9j62-iam-pela-iam_role \
    --policy-name ListAllBucketsPolicy \
    --policy-document file://inline-policy.json

# Проверка inline политик роли
aws iam list-role-policies \
    --role-name cmtr-4n6e9j62-iam-pela-iam_role

# Просмотр содержимого inline policy
aws iam get-role-policy \
    --role-name cmtr-4n6e9j62-iam-pela-iam_role \
    --policy-name ListAllBucketsPolicy

# ============================================================
# MOVE 2: Создание Resource-Based Policy для bucket
# ============================================================

# Применить bucket policy
aws s3api put-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-pela-bucket-1-162653 \
    --policy file://bucket-policy.json

# Проверка bucket policy
aws s3api get-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-pela-bucket-1-162653 \
    --query Policy --output text

# Форматированный вывод (требует jq)
aws s3api get-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-pela-bucket-1-162653 \
    --query Policy --output text | jq '.'

# ============================================================
# ВЕРИФИКАЦИЯ через IAM Policy Simulator
# ============================================================

# Тест 1: ListAllMyBuckets (должен быть allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:ListAllMyBuckets

# Тест 2: ListBucket для bucket-1 (должен быть allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:ListBucket \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653

# Тест 3: GetObject для bucket-1 (должен быть allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653/test-object

# Тест 4: PutObject для bucket-1 (должен быть allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:PutObject \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653/test-object

# Тест 5: ListBucket для bucket-2 (должен быть implicitDeny)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:ListBucket \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-2-162653

# Тест 6: GetObject для bucket-2 (должен быть implicitDeny)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-2-162653/test-object

# Тест 7: PutObject для bucket-2 (должен быть implicitDeny)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:PutObject \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-2-162653/test-object

# Комплексный тест (все действия сразу)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:ListAllMyBuckets s3:ListBucket s3:GetObject s3:PutObject \
  --resource-arns \
    arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653 \
    arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653/test-object

# ============================================================
# ДОПОЛНИТЕЛЬНЫЕ ПРОВЕРКИ
# ============================================================

# Получить информацию о роли
aws iam get-role --role-name cmtr-4n6e9j62-iam-pela-iam_role

# Список всех inline политик роли
aws iam list-role-policies --role-name cmtr-4n6e9j62-iam-pela-iam_role

# Список attached managed политик роли
aws iam list-attached-role-policies --role-name cmtr-4n6e9j62-iam-pela-iam_role

# Список объектов в bucket-1
aws s3 ls s3://cmtr-4n6e9j62-iam-pela-bucket-1-162653/

# Список объектов в bucket-2
aws s3 ls s3://cmtr-4n6e9j62-iam-pela-bucket-2-162653/

# Проверка bucket-2 (не должно быть политики)
aws s3api get-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-pela-bucket-2-162653 2>&1 || echo "No policy (as expected)"

# ============================================================
# ОТКАТ ИЗМЕНЕНИЙ (если нужно)
# ============================================================

# Удалить inline policy
aws iam delete-role-policy \
    --role-name cmtr-4n6e9j62-iam-pela-iam_role \
    --policy-name ListAllBucketsPolicy

# Удалить bucket policy
aws s3api delete-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-pela-bucket-1-162653
