# Пошаговая инструкция по выполнению IAM задачи

## Обзор задачи

Задача состоит из **двух основных шагов** (moves):

1. **Move 1**: Присоединить AWS Managed Policy для полного доступа к S3 к IAM роли
2. **Move 2**: Обновить bucket policy для запрета удаления объектов

## Ресурсы

- **IAM Role**: `cmtr-4n6e9j62-iam-peld-iam_role`
- **S3 Bucket**: `cmtr-4n6e9j62-iam-peld-bucket-2911738`
- **Region**: `eu-west-1`
- **Account ID**: `651706749822`

## Вариант 1: Автоматическое выполнение через скрипт

Я создал bash-скрипт `setup-iam-task.sh`, который автоматически выполнит оба шага.

### Запуск скрипта:

```bash
chmod +x setup-iam-task.sh
./setup-iam-task.sh
```

## Вариант 2: Ручное выполнение через AWS CLI

### Настройка окружения:

```bash
export AWS_ACCESS_KEY_ID=AKIAZPPF72N7EHDWSCFI
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1
```

### Move 1: Присоединить AWS Managed Policy для S3

```bash
aws iam attach-role-policy \
    --role-name cmtr-4n6e9j62-iam-peld-iam_role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

### Move 2: Обновить Bucket Policy

Сначала создайте файл `bucket-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyDeleteObjectForRole",
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role"
      },
      "Action": "s3:DeleteObject",
      "Resource": "arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/*"
    }
  ]
}
```

Затем примените политику:

```bash
aws s3api put-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738 \
    --policy file://bucket-policy.json
```

## Вариант 3: Через AWS Console

### Move 1: Присоединить AWS Managed Policy

1. Откройте AWS Console: https://651706749822.signin.aws.amazon.com/console?region=eu-west-1
2. Войдите с credentials:
   - Username: `cmtr-4n6e9j62`
   - Password: `Ka9#yGgVDBMPqLi1`
3. Перейдите в **IAM** → **Roles**
4. Найдите роль `cmtr-4n6e9j62-iam-peld-iam_role`
5. Нажмите **Add permissions** → **Attach policies**
6. Найдите и выберите `AmazonS3FullAccess`
7. Нажмите **Attach policies**

### Move 2: Обновить Bucket Policy

1. Перейдите в **S3**
2. Найдите bucket `cmtr-4n6e9j62-iam-peld-bucket-2911738`
3. Перейдите на вкладку **Permissions**
4. В секции **Bucket policy** нажмите **Edit**
5. Добавьте или обновите политику следующим образом:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyDeleteObjectForRole",
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role"
      },
      "Action": "s3:DeleteObject",
      "Resource": "arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/*"
    }
  ]
}
```

6. Нажмите **Save changes**

## Проверка (Verification)

### Через AWS IAM Policy Simulator (Web):

1. Откройте: https://policysim.aws.amazon.com/
2. Выберите роль: `cmtr-4n6e9j62-iam-peld-iam_role`
3. Выберите сервис: **Amazon S3**
4. Выберите действие: **DeleteObject**
5. Укажите ресурс: `arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/*`
6. Нажмите **Run Simulation**
7. **Ожидаемый результат**: ❌ **Denied**

### Через AWS CLI:

```bash
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role \
  --action-names s3:DeleteObject \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test-object
```

Результат должен показать, что действие **denied**.

## Объяснение решения

### Почему это работает?

1. **Identity-based policy (AmazonS3FullAccess)** дает роли полный доступ ко всем операциям S3, включая DeleteObject
2. **Resource-based policy (Bucket Policy)** с эффектом **Deny** явно запрещает удаление объектов для этой роли
3. В AWS **явный Deny всегда имеет приоритет** над любым Allow, поэтому даже при наличии полного доступа к S3, роль не сможет удалять объекты из этого конкретного bucket

### Ключевые концепции:

- **Identity-based policies**: Политики, присоединенные к IAM пользователям, группам или ролям
- **Resource-based policies**: Политики, присоединенные к AWS ресурсам (например, S3 bucket policy)
- **Deny evaluation**: Deny всегда побеждает Allow в AWS IAM policy evaluation

## Проверка выполнения

Проверьте, что оба шага выполнены:

```bash
# Проверить присоединенные политики к роли
aws iam list-attached-role-policies --role-name cmtr-4n6e9j62-iam-peld-iam_role

# Проверить bucket policy
aws s3api get-bucket-policy --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738 --query Policy --output text | jq '.'
```
