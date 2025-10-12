# 📘 INSTRUCTIONS - Task 3: Role Assumption

## 🎯 Цель задания

Настроить роль `cmtr-4n6e9j62-iam-ar-iam_role-assume`, которая может принять (assume) роль `cmtr-4n6e9j62-iam-ar-iam_role-readonly` с read-only доступом.

## 📚 Что такое Role Assumption?

**Role Assumption** - это механизм, при котором один IAM principal (пользователь, роль, сервис) временно получает права другой роли через действие `sts:AssumeRole`.

### Как это работает:

```
1. Assume Role имеет inline policy: "разрешено делать sts:AssumeRole"
2. ReadOnly Role имеет trust policy: "разрешено assume роли принимать меня"
3. ReadOnly Role имеет ReadOnlyAccess: "read-only права"
```

### Результат:
```
Assume Role → STS AssumeRole → Temporary Credentials → ReadOnly Access ✅
```

## 🛠️ Три метода выполнения

---

## Метод 1: Автоматический скрипт ⚡

### Шаг 1: Запустить скрипт
```bash
cd task3
chmod +x setup-iam-task3.sh
./setup-iam-task3.sh
```

### Что делает скрипт:
1. ✅ Создает inline policy для assume роли
2. ✅ Присоединяет ReadOnlyAccess к readonly роли
3. ✅ Обновляет trust policy readonly роли
4. ✅ Запускает автоматические тесты

### Время: ~2 минуты

---

## Метод 2: Вручную через AWS CLI 🖥️

### Credentials (используйте эти):
```bash
export AWS_ACCESS_KEY_ID=AKIAY6QVYZH2ESZQQ6CV
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1
```

### Шаг 1: Inline Policy для assume роли

```bash
# 1.1 Проверить роль существует
aws iam get-role --role-name cmtr-4n6e9j62-iam-ar-iam_role-assume

# 1.2 Создать inline policy
aws iam put-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-assume \
    --policy-name AssumeReadOnlyRolePolicy \
    --policy-document file://assume-role-policy.json

# 1.3 Проверить policy создан
aws iam get-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-assume \
    --policy-name AssumeReadOnlyRolePolicy
```

#### assume-role-policy.json:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly"
    }
  ]
}
```

### Шаг 2: Attach ReadOnlyAccess

```bash
# 2.1 Проверить роль существует
aws iam get-role --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly

# 2.2 Присоединить managed policy
aws iam attach-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly \
    --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# 2.3 Проверить policy attached
aws iam list-attached-role-policies \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly
```

### Шаг 3: Trust Policy

```bash
# 3.1 Обновить trust policy
aws iam update-assume-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly \
    --policy-document file://trust-policy.json

# 3.2 Проверить trust policy
aws iam get-role --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly
```

#### trust-policy.json:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-assume"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Время: ~10 минут

---

## Метод 3: AWS Management Console 🖱️

### Шаг 1: Inline Policy для assume роли

1. Перейти в IAM → Roles
2. Найти `cmtr-4n6e9j62-iam-ar-iam_role-assume`
3. Permissions → Add inline policy
4. JSON:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly"
    }
  ]
}
```
5. Review policy → Name: `AssumeReadOnlyRolePolicy`
6. Create policy

### Шаг 2: Attach ReadOnlyAccess

1. Перейти в IAM → Roles
2. Найти `cmtr-4n6e9j62-iam-ar-iam_role-readonly`
3. Permissions → Attach policies
4. Найти `ReadOnlyAccess`
5. Attach policy

### Шаг 3: Trust Policy

1. Оставаться в `cmtr-4n6e9j62-iam-ar-iam_role-readonly`
2. Trust relationships → Edit trust policy
3. JSON:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-assume"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
4. Update policy

### Время: ~15 минут

---

## ✅ Верификация

### Policy Simulator

```bash
# Тест 1: AssumeRole (allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-assume \
  --action-names sts:AssumeRole \
  --resource-arns arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly

# Тест 2: Read операции (allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly \
  --action-names ec2:DescribeInstances s3:ListAllMyBuckets

# Тест 3: Write операции (denied)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly \
  --action-names ec2:RunInstances s3:DeleteBucket
```

### Практическое тестирование

```bash
# 1. Получить temporary credentials
aws sts assume-role \
  --role-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly \
  --role-session-name test-session

# 2. Использовать временные credentials (из вывода шага 1)
export AWS_ACCESS_KEY_ID=<AccessKeyId>
export AWS_SECRET_ACCESS_KEY=<SecretAccessKey>
export AWS_SESSION_TOKEN=<SessionToken>

# 3. Тестировать read операции
aws s3 ls  # должно работать ✅
aws ec2 describe-instances  # должно работать ✅

# 4. Тестировать write операции
aws s3 mb s3://test-bucket  # должно DENIED ❌
aws ec2 run-instances ...  # должно DENIED ❌
```

## 📊 Ожидаемые результаты

| Действие | Результат |
|----------|-----------|
| sts:AssumeRole | ✅ allowed |
| ec2:DescribeInstances | ✅ allowed |
| s3:ListAllMyBuckets | ✅ allowed |
| ec2:RunInstances | ❌ implicitDeny |
| s3:DeleteBucket | ❌ implicitDeny |

## 💡 Ключевые концепции

### 1. Identity-based Policy (inline)
- Присоединен к assume роли
- Разрешает действие `sts:AssumeRole`

### 2. Trust Policy
- Определяет WHO может assume роль
- Присоединен к readonly роли

### 3. Managed Policy
- ReadOnlyAccess (AWS managed)
- Дает read-only права

## 🎓 Что изучите

- ✅ Role Assumption
- ✅ Trust Policies vs Identity Policies
- ✅ STS (Security Token Service)
- ✅ Temporary Credentials
- ✅ Inline vs Managed Policies

---

**Сложность:** Средняя  
**Время:** 2-15 минут (в зависимости от метода)
