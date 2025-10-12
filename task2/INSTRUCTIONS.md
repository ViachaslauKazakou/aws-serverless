# Пошаговая инструкция по выполнению IAM Task 2

## Обзор задачи

Задача состоит из **двух основных шагов** (moves):

1. **Move 1**: Создать inline policy для роли (разрешает просмотр всех buckets)
2. **Move 2**: Создать bucket policy для bucket-1 (разрешает работу с объектами)

## Ресурсы

- **IAM Role**: `cmtr-4n6e9j62-iam-pela-iam_role`
- **S3 Bucket 1**: `cmtr-4n6e9j62-iam-pela-bucket-1-162653` (основной bucket для работы)
- **S3 Bucket 2**: `cmtr-4n6e9j62-iam-pela-bucket-2-162653` (только для проверки, НЕ ТРОГАТЬ!)
- **Region**: `eu-west-1`
- **Account ID**: `863518426750`

## Вариант 1: Автоматическое выполнение через скрипт

Я создал bash-скрипт `setup-iam-task2.sh`, который автоматически выполнит оба шага.

### Запуск скрипта:

```bash
cd task2
chmod +x setup-iam-task2.sh
./setup-iam-task2.sh
```

## Вариант 2: Ручное выполнение через AWS CLI

### Настройка окружения:

```bash
export AWS_ACCESS_KEY_ID=AKIA4SDNVQZ7K5LP7AXA
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1
```

### Move 1: Создать Inline Policy для роли

Inline policy позволит роли просматривать список всех S3 buckets в аккаунте.

**Содержимое файла `inline-policy.json`:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowListAllBuckets",
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "*"
    }
  ]
}
```

**Команда для применения:**
```bash
aws iam put-role-policy \
    --role-name cmtr-4n6e9j62-iam-pela-iam_role \
    --policy-name ListAllBucketsPolicy \
    --policy-document file://inline-policy.json
```

**Проверка:**
```bash
# Список inline политик
aws iam list-role-policies --role-name cmtr-4n6e9j62-iam-pela-iam_role

# Содержимое политики
aws iam get-role-policy \
    --role-name cmtr-4n6e9j62-iam-pela-iam_role \
    --policy-name ListAllBucketsPolicy
```

### Move 2: Создать Bucket Policy

Bucket policy даст роли доступ к объектам в bucket-1.

**Содержимое файла `bucket-policy.json`:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowRoleAccessToBucket",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653",
        "arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653/*"
      ]
    }
  ]
}
```

**Важно:** 
- Два Resource ARN: один для bucket (`arn:aws:s3:::bucket-name`), другой для объектов (`arn:aws:s3:::bucket-name/*`)
- ListBucket работает на уровне bucket
- GetObject и PutObject работают на уровне объектов

**Команда для применения:**
```bash
aws s3api put-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-pela-bucket-1-162653 \
    --policy file://bucket-policy.json
```

**Проверка:**
```bash
aws s3api get-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-pela-bucket-1-162653 \
    --query Policy --output text | jq '.'
```

## Вариант 3: Через AWS Console

### Move 1: Создать Inline Policy

1. Откройте AWS Console: https://863518426750.signin.aws.amazon.com/console?region=eu-west-1
2. Войдите с credentials:
   - Username: `cmtr-4n6e9j62`
   - Password: `Zj3!PVitYLNgG7U8`
3. Перейдите в **IAM** → **Roles**
4. Найдите роль `cmtr-4n6e9j62-iam-pela-iam_role`
5. Перейдите на вкладку **Permissions**
6. Нажмите **Add permissions** → **Create inline policy**
7. Выберите **JSON** и вставьте:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowListAllBuckets",
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "*"
    }
  ]
}
```

8. Нажмите **Review policy**
9. Название политики: `ListAllBucketsPolicy`
10. Нажмите **Create policy**

### Move 2: Создать Bucket Policy

1. Перейдите в **S3**
2. Найдите bucket `cmtr-4n6e9j62-iam-pela-bucket-1-162653`
3. Перейдите на вкладку **Permissions**
4. В секции **Bucket policy** нажмите **Edit**
5. Вставьте следующую политику:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowRoleAccessToBucket",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653",
        "arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653/*"
      ]
    }
  ]
}
```

6. Нажмите **Save changes**

**⚠️ ВАЖНО:** НЕ создавайте политику для bucket-2! Он используется только для проверки.

## Проверка (Verification)

### Через AWS IAM Policy Simulator (Web):

1. Откройте: https://policysim.aws.amazon.com/
2. Выберите роль: `cmtr-4n6e9j62-iam-pela-iam_role`
3. Выберите сервис: **Amazon S3**

**Тест 1: ListAllMyBuckets**
- Action: `ListAllMyBuckets`
- Resource: оставьте пустым (или `*`)
- **Ожидаемый результат**: ✅ **Allowed**

**Тест 2: ListBucket для bucket-1**
- Action: `ListBucket`
- Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653`
- **Ожидаемый результат**: ✅ **Allowed**

**Тест 3: GetObject для bucket-1**
- Action: `GetObject`
- Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653/*`
- **Ожидаемый результат**: ✅ **Allowed**

**Тест 4: PutObject для bucket-1**
- Action: `PutObject`
- Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653/*`
- **Ожидаемый результат**: ✅ **Allowed**

**Тест 5: GetObject для bucket-2**
- Action: `GetObject`
- Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-2-162653/*`
- **Ожидаемый результат**: ❌ **Denied** (implicitDeny)

**Тест 6: ListBucket для bucket-2**
- Action: `ListBucket`
- Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-2-162653`
- **Ожидаемый результат**: ❌ **Denied** (implicitDeny)

### Через AWS CLI:

См. файл `commands.sh` для готовых команд проверки.

## Объяснение решения

### Почему это работает?

1. **Inline Policy на роли** дает право просматривать список всех buckets (ListAllMyBuckets)
2. **Bucket Policy на bucket-1** дает роли права на работу с объектами именно в этом bucket
3. **Bucket-2 не имеет политики**, поэтому роль не имеет прав на работу с ним (implicit deny)

### Матрица разрешений:

| Действие | Bucket-1 | Bucket-2 | Причина |
|----------|----------|----------|---------|
| ListAllMyBuckets | ✅ Allowed | ✅ Allowed | Inline policy на роли |
| ListBucket | ✅ Allowed | ❌ Denied | Bucket policy только для bucket-1 |
| GetObject | ✅ Allowed | ❌ Denied | Bucket policy только для bucket-1 |
| PutObject | ✅ Allowed | ❌ Denied | Bucket policy только для bucket-1 |

### Ключевые концепции:

- **Inline Policy**: Политика, встроенная непосредственно в IAM роль (не переиспользуется)
- **Managed Policy**: Отдельная политика, которую можно присоединить к нескольким ролям
- **Bucket Policy**: Resource-based политика, применяется к конкретному bucket
- **Implicit Deny**: По умолчанию всё запрещено, если нет явного Allow

## Важные замечания

### О Resource ARN в Bucket Policy:

```json
"Resource": [
  "arn:aws:s3:::bucket-name",      // Для действий на уровне bucket (ListBucket)
  "arn:aws:s3:::bucket-name/*"     // Для действий на уровне объектов (GetObject, PutObject)
]
```

### О действиях S3:

- `s3:ListAllMyBuckets` - глобальное действие, работает с `Resource: "*"`
- `s3:ListBucket` - действие на bucket, Resource = `arn:aws:s3:::bucket-name`
- `s3:GetObject`, `s3:PutObject` - действия на объектах, Resource = `arn:aws:s3:::bucket-name/*`

### Отличие от Task 1:

| Аспект | Task 1 | Task 2 |
|--------|--------|--------|
| Identity Policy | AWS Managed Policy (AmazonS3FullAccess) | Inline Policy (custom) |
| Bucket Policy | Deny DeleteObject | Allow GetObject/PutObject/ListBucket |
| Логика | Deny побеждает Allow | Комбинация Allow политик |
| Количество buckets | 1 bucket | 2 buckets (один для работы, один для проверки) |

## Troubleshooting

### Ошибка при создании inline policy через CLI
```bash
# Проверьте JSON синтаксис
cat inline-policy.json | jq '.'

# Если ошибка, исправьте JSON
```

### Ошибка при создании bucket policy
```bash
# Проверьте, что в Resource указаны ОБА ARN
# Проверьте правильность Principal ARN
# Проверьте JSON синтаксис
```

### Policy Simulator показывает неожиданные результаты
```bash
# Подождите 1-2 минуты после применения политик
# Очистите кэш Policy Simulator
# Проверьте правильность Resource ARN
```

## Проверка выполнения

```bash
# Проверить inline политики роли
aws iam list-role-policies --role-name cmtr-4n6e9j62-iam-pela-iam_role

# Проверить bucket policy
aws s3api get-bucket-policy --bucket cmtr-4n6e9j62-iam-pela-bucket-1-162653

# Проверить, что bucket-2 НЕ имеет политики
aws s3api get-bucket-policy --bucket cmtr-4n6e9j62-iam-pela-bucket-2-162653 2>&1
# Ожидается ошибка: NoSuchBucketPolicy
```
