# AWS IAM Task 3 - Quick Commands
# Role Assumption Configuration

# ============================================================
# НАСТРОЙКА ОКРУЖЕНИЯ
# ============================================================

export AWS_ACCESS_KEY_ID=AKIAY6QVYZH2ESZQQ6CV
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# Проверка подключения
aws sts get-caller-identity

# ============================================================
# ШАГ 1: Inline Policy для assume роли
# ============================================================

# Создать inline policy (разрешает AssumeRole)
aws iam put-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-assume \
    --policy-name AssumeReadOnlyRolePolicy \
    --policy-document file://assume-role-policy.json

# Проверка inline политик
aws iam list-role-policies \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-assume

# Просмотр политики
aws iam get-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-assume \
    --policy-name AssumeReadOnlyRolePolicy

# ============================================================
# ШАГ 2: Присоединить ReadOnlyAccess к readonly роли
# ============================================================

aws iam attach-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly \
    --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Проверка attached политик
aws iam list-attached-role-policies \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly

# ============================================================
# ШАГ 3: Обновить Trust Policy для readonly роли
# ============================================================

aws iam update-assume-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly \
    --policy-document file://trust-policy.json

# Проверка Trust Policy
aws iam get-role \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly \
    --query 'Role.AssumeRolePolicyDocument'

# ============================================================
# ВЕРИФИКАЦИЯ через Policy Simulator
# ============================================================

# Тест 1: AssumeRole для assume роли (должен быть allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-assume \
  --action-names sts:AssumeRole \
  --resource-arns arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly

# Тест 2: Read операции для readonly роли (должны быть allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly \
  --action-names ec2:DescribeInstances s3:ListAllMyBuckets iam:ListRoles

# Тест 3: Write операции для readonly роли (должны быть denied)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly \
  --action-names ec2:RunInstances s3:PutObject iam:CreateUser

# ============================================================
# ПРАКТИЧЕСКАЯ ПРОВЕРКА (Role Assumption)
# ============================================================

# Шаг 1: Assume первую роль (если у вас есть права)
# Замените YOUR_SESSION_NAME на любое имя
aws sts assume-role \
    --role-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-assume \
    --role-session-name test-session

# Скопируйте AccessKeyId, SecretAccessKey, SessionToken из вывода

# Шаг 2: Установите временные credentials
# export AWS_ACCESS_KEY_ID=<AccessKeyId>
# export AWS_SECRET_ACCESS_KEY=<SecretAccessKey>
# export AWS_SESSION_TOKEN=<SessionToken>

# Шаг 3: Assume вторую роль (readonly)
aws sts assume-role \
    --role-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly \
    --role-session-name readonly-session

# Шаг 4: Установите credentials из шага 3 и тестируйте

# Тест read операции (должны работать)
aws ec2 describe-instances
aws s3 ls
aws iam list-roles

# Тест write операции (должны быть запрещены)
aws ec2 run-instances --image-id ami-12345678 --instance-type t2.micro
# Ожидается: Access Denied

aws s3 mb s3://test-bucket-12345
# Ожидается: Access Denied

# ============================================================
# ДОПОЛНИТЕЛЬНЫЕ ПРОВЕРКИ
# ============================================================

# Информация об обеих ролях
aws iam get-role --role-name cmtr-4n6e9j62-iam-ar-iam_role-assume
aws iam get-role --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly

# Все политики assume роли
aws iam list-role-policies --role-name cmtr-4n6e9j62-iam-ar-iam_role-assume
aws iam list-attached-role-policies --role-name cmtr-4n6e9j62-iam-ar-iam_role-assume

# Все политики readonly роли
aws iam list-role-policies --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly
aws iam list-attached-role-policies --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly

# ============================================================
# ОТКАТ ИЗМЕНЕНИЙ (если нужно)
# ============================================================

# Удалить inline policy
aws iam delete-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-assume \
    --policy-name AssumeReadOnlyRolePolicy

# Отсоединить ReadOnlyAccess
aws iam detach-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly \
    --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Примечание: Trust Policy нельзя просто удалить, 
# её нужно заменить на другую политику
