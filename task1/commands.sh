# AWS IAM Task - Quick Commands
# Эти команды можно скопировать и выполнить по отдельности

# ============================================================
# НАСТРОЙКА ОКРУЖЕНИЯ
# ============================================================

export AWS_ACCESS_KEY_ID=AKIAZPPF72N7EHDWSCFI
export AWS_SECRET_ACCESS_KEY=
export AWS_DEFAULT_REGION=eu-west-1

# Проверка подключения
aws sts get-caller-identity

# ============================================================
# MOVE 1: Присоединение AWS Managed Policy для S3
# ============================================================

aws iam attach-role-policy \
    --role-name cmtr-4n6e9j62-iam-peld-iam_role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Проверка присоединенных политик
aws iam list-attached-role-policies \
    --role-name cmtr-4n6e9j62-iam-peld-iam_role

# ============================================================
# MOVE 2: Обновление Bucket Policy
# ============================================================

# Применение bucket policy из файла
aws s3api put-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738 \
    --policy file://bucket-policy.json

# Проверка bucket policy
aws s3api get-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738 \
    --query Policy --output text

# Форматированный вывод (требует jq)
aws s3api get-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738 \
    --query Policy --output text | jq '.'

# ============================================================
# ВЕРИФИКАЦИЯ через IAM Policy Simulator
# ============================================================

# Симуляция попытки удаления объекта
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role \
    --action-names s3:DeleteObject \
    --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test-object

# Симуляция других операций S3 (должны быть разрешены)
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role \
    --action-names s3:GetObject s3:PutObject s3:ListBucket \
    --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test-object

# ============================================================
# ДОПОЛНИТЕЛЬНЫЕ ПРОВЕРКИ
# ============================================================

# Получить информацию о роли
aws iam get-role --role-name cmtr-4n6e9j62-iam-peld-iam_role

# Список всех политик роли (включая inline)
aws iam list-role-policies --role-name cmtr-4n6e9j62-iam-peld-iam_role

# Получить информацию о bucket
aws s3api get-bucket-location --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738

# Список объектов в bucket (если есть доступ)
aws s3 ls s3://cmtr-4n6e9j62-iam-peld-bucket-2911738/

# ============================================================
# ОТКАТ ИЗМЕНЕНИЙ (если нужно)
# ============================================================

# Отсоединить политику от роли
aws iam detach-role-policy \
    --role-name cmtr-4n6e9j62-iam-peld-iam_role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Удалить bucket policy
aws s3api delete-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738
