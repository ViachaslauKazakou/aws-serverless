# AWS IAM Task - Архитектура и поток политик

## Визуальная схема решения

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS ACCOUNT                              │
│                       ID: 651706749822                           │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │                    IAM ROLE                            │     │
│  │         cmtr-4n6e9j62-iam-peld-iam_role               │     │
│  │                                                        │     │
│  │  ┌──────────────────────────────────────────────┐     │     │
│  │  │  IDENTITY-BASED POLICY (Attached)           │     │     │
│  │  │                                              │     │     │
│  │  │  Policy: AmazonS3FullAccess (AWS Managed)  │     │     │
│  │  │  Effect: ALLOW                              │     │     │
│  │  │  Actions: s3:*                              │     │     │
│  │  │  Resources: *                               │     │     │
│  │  │                                              │     │     │
│  │  │  ✓ GetObject     ✓ PutObject               │     │     │
│  │  │  ✓ ListBucket    ✓ DeleteObject ⚠️          │     │     │
│  │  └──────────────────────────────────────────────┘     │     │
│  └────────────────────────────────────────────────────────┘     │
│                              │                                   │
│                              │ Пытается выполнить                │
│                              │ s3:DeleteObject                   │
│                              ▼                                   │
│  ┌────────────────────────────────────────────────────────┐     │
│  │                    S3 BUCKET                           │     │
│  │      cmtr-4n6e9j62-iam-peld-bucket-2911738            │     │
│  │                                                        │     │
│  │  ┌──────────────────────────────────────────────┐     │     │
│  │  │  RESOURCE-BASED POLICY (Bucket Policy)      │     │     │
│  │  │                                              │     │     │
│  │  │  Effect: DENY ❌                             │     │     │
│  │  │  Principal: cmtr-4n6e9j62-iam-peld-iam_role│     │     │
│  │  │  Action: s3:DeleteObject                    │     │     │
│  │  │  Resource: bucket-2911738/*                 │     │     │
│  │  │                                              │     │     │
│  │  │  ❌ EXPLICIT DENY WINS!                      │     │     │
│  │  └──────────────────────────────────────────────┘     │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Логика оценки политик (Policy Evaluation Logic)

```
┌──────────────────────────────────────────────────────────┐
│         AWS IAM Policy Evaluation Flow                    │
└──────────────────────────────────────────────────────────┘
                        │
                        ▼
          ┌─────────────────────────┐
          │   1. Default: DENY      │
          └─────────────────────────┘
                        │
                        ▼
          ┌─────────────────────────┐
          │ 2. Есть Explicit DENY? │
          └─────────────────────────┘
                   /        \
                 YES         NO
                  │           │
                  ▼           ▼
          ┌──────────┐   ┌──────────┐
          │  DENY ❌  │   │ 3. Есть  │
          └──────────┘   │  ALLOW?  │
                         └──────────┘
                            /     \
                          YES      NO
                           │        │
                           ▼        ▼
                    ┌──────────┐ ┌──────────┐
                    │ ALLOW ✓  │ │  DENY ❌  │
                    └──────────┘ └──────────┘
```

## Матрица разрешений для роли

После применения обеих политик:

| Действие S3         | Identity Policy | Bucket Policy | Итоговый результат |
|---------------------|-----------------|---------------|--------------------|
| s3:ListBucket       | ALLOW ✓         | -             | ALLOW ✓            |
| s3:GetObject        | ALLOW ✓         | -             | ALLOW ✓            |
| s3:PutObject        | ALLOW ✓         | -             | ALLOW ✓            |
| s3:DeleteObject     | ALLOW ✓         | DENY ❌       | **DENY ❌**        |
| s3:DeleteBucket     | ALLOW ✓         | -             | ALLOW ✓            |
| s3:GetBucketPolicy  | ALLOW ✓         | -             | ALLOW ✓            |

## Ключевые принципы AWS IAM

### 1. **Explicit Deny всегда побеждает**
   - Если хоть одна политика содержит Deny, запрос будет отклонен
   - Не имеет значения, сколько политик разрешают действие

### 2. **По умолчанию все запрещено**
   - Если нет явного Allow, запрос будет отклонен
   - Нужен хотя бы один Allow для разрешения действия

### 3. **Порядок оценки политик**
   1. Explicit Deny (любой источник)
   2. Organization SCPs
   3. Resource-based policies
   4. Identity-based policies
   5. IAM permissions boundaries
   6. Session policies

### 4. **Типы политик в задаче**

#### Identity-Based Policy (AmazonS3FullAccess):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "s3:*",
    "Resource": "*"
  }]
}
```

#### Resource-Based Policy (Bucket Policy):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Deny",
    "Principal": {
      "AWS": "arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role"
    },
    "Action": "s3:DeleteObject",
    "Resource": "arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/*"
  }]
}
```

## Сценарии использования

### ✅ Разрешенные действия:

```bash
# Чтение объектов
aws s3 cp s3://bucket-2911738/file.txt .

# Загрузка объектов
aws s3 cp file.txt s3://bucket-2911738/

# Список объектов
aws s3 ls s3://bucket-2911738/
```

### ❌ Запрещенные действия:

```bash
# Удаление объектов - будет заблокировано!
aws s3 rm s3://bucket-2911738/file.txt
# Error: Access Denied
```

## Почему это безопасно?

1. **Защита от случайного удаления**: Даже администратор с полным доступом не сможет удалить данные
2. **Audit trail**: Все попытки удаления будут залогированы в CloudTrail
3. **Гибкость**: Можно легко изменить политику для других ролей или пользователей
4. **Compliance**: Соответствует best practices для защиты критичных данных

## Дополнительные улучшения (опционально)

Можно добавить дополнительные ограничения:

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
      "Action": [
        "s3:DeleteObject",
        "s3:DeleteObjectVersion"
      ],
      "Resource": "arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/*"
    }
  ]
}
```

## Проверка через Policy Simulator

Web UI: https://policysim.aws.amazon.com/

Параметры для теста:
- **Role**: cmtr-4n6e9j62-iam-peld-iam_role
- **Service**: Amazon S3
- **Action**: DeleteObject
- **Resource**: arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test
- **Expected Result**: ❌ Denied
