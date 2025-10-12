# 📊 PROJECT SUMMARY - Task 3: Role Assumption

## 🎯 Краткое описание

Task 3 демонстрирует конфигурацию **Role Assumption** - механизм, при котором одна IAM роль (`assume`) может временно принять права другой роли (`readonly`) с read-only доступом ко всем AWS сервисам.

## 📋 Задача

Настроить роль `cmtr-4n6e9j62-iam-ar-iam_role-assume`, которая может:
- ✅ Выполнить `sts:AssumeRole` для роли `cmtr-4n6e9j62-iam-ar-iam_role-readonly`
- ✅ Получить временные credentials с read-only правами
- ❌ НЕ может выполнять write операции

## 🏗️ Архитектура решения

```
Assume Role (inline policy: sts:AssumeRole)
    ↓
AWS STS (проверяет inline policy + trust policy)
    ↓
ReadOnly Role (trust policy + ReadOnlyAccess)
    ↓
Temporary Credentials (read-only доступ)
```

## 🔧 Реализация

### Три компонента конфигурации:

1. **Inline Policy** на assume роли
   - Action: `sts:AssumeRole`
   - Resource: readonly role ARN
   - Файл: `assume-role-policy.json`

2. **ReadOnlyAccess Policy** на readonly роли
   - Type: AWS Managed Policy
   - ARN: `arn:aws:iam::aws:policy/ReadOnlyAccess`
   - Права: read-only для всех сервисов

3. **Trust Policy** на readonly роли
   - Principal: assume role ARN
   - Action: `sts:AssumeRole`
   - Файл: `trust-policy.json`

## 📁 Структура файлов

```
task3/
├── README.md                    # Главная страница
├── QUICKSTART.md                # 30-секундный старт
├── INDEX.md                     # Навигация
├── INSTRUCTIONS.md              # Детальные инструкции
├── CHECKLIST.md                 # Чеклист выполнения
├── ARCHITECTURE.md              # Теория и диаграммы
├── PROJECT_SUMMARY.md           # Этот файл
├── setup-iam-task3.sh          # Автоматический скрипт
├── commands.sh                  # Готовые команды
├── assume-role-policy.json     # Inline policy
└── trust-policy.json           # Trust policy
```

## 🎯 Результаты

### Что настроено:

| Роль | Конфигурация | Результат |
|------|-------------|-----------|
| **Assume Role** | Inline Policy | ✅ Может assume readonly роль |
| **ReadOnly Role** | Trust Policy + ReadOnlyAccess | ✅ Read-only доступ ко всем сервисам |

### Policy Evaluation:

| Действие | Результат | Причина |
|----------|-----------|---------|
| sts:AssumeRole | ✅ allowed | Inline policy + Trust policy |
| ec2:DescribeInstances | ✅ allowed | ReadOnlyAccess policy |
| s3:ListAllMyBuckets | ✅ allowed | ReadOnlyAccess policy |
| ec2:RunInstances | ❌ implicitDeny | Нет Allow statement |
| s3:DeleteBucket | ❌ implicitDeny | Нет Allow statement |

## 💡 Ключевые концепции

### 1. Role Assumption
- **Что:** Процесс получения временных credentials другой роли
- **Как:** Через действие `sts:AssumeRole`
- **Зачем:** Делегирование доступа, temporary elevated privileges

### 2. Trust Policy
- **Что:** Policy, определяющий WHO может assume роль
- **Где:** На целевой роли (readonly)
- **Формат:** Principal + Action (sts:AssumeRole)

### 3. Temporary Credentials
- **Что:** Временные AccessKeyId, SecretAccessKey, SessionToken
- **Срок:** Настраиваемый (по умолчанию 1 час)
- **Безопасность:** Автоматическая ротация

## 📊 AWS компоненты

| Ресурс | Type | ARN |
|--------|------|-----|
| Assume Role | IAM Role | `arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-assume` |
| ReadOnly Role | IAM Role | `arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly` |
| ReadOnlyAccess | Managed Policy | `arn:aws:iam::aws:policy/ReadOnlyAccess` |

## ✅ Тестирование

### Policy Simulator:
```bash
# AssumeRole - allowed
aws iam simulate-principal-policy \
  --policy-source-arn <assume-role-arn> \
  --action-names sts:AssumeRole \
  --resource-arns <readonly-role-arn>

# Read - allowed
aws iam simulate-principal-policy \
  --policy-source-arn <readonly-role-arn> \
  --action-names ec2:DescribeInstances

# Write - denied
aws iam simulate-principal-policy \
  --policy-source-arn <readonly-role-arn> \
  --action-names ec2:RunInstances
```

### Практическое тестирование:
```bash
# 1. Assume role
aws sts assume-role \
  --role-arn <readonly-role-arn> \
  --role-session-name test

# 2. Export temporary credentials
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...

# 3. Test read - OK
aws s3 ls

# 4. Test write - DENIED
aws s3 mb s3://test-bucket
```

## 🎓 Что изучено

- ✅ Role Assumption через sts:AssumeRole
- ✅ Trust Policies
- ✅ Временные credentials
- ✅ Inline vs Managed Policies
- ✅ ReadOnlyAccess AWS managed policy
- ✅ Policy Simulator
- ✅ Implicit Deny для write операций

## 🔄 Сравнение с другими задачами

| Task | Фокус | Ключевая концепция |
|------|-------|-------------------|
| **Task 1** | Explicit Deny | Resource-based policy (Bucket Policy) |
| **Task 2** | Inline Policy + Implicit Deny | Identity-based policy + Granular access |
| **Task 3** | Role Assumption | Trust Policy + STS + Temporary Credentials |

## 📈 Метрики

| Параметр | Значение |
|----------|----------|
| Количество ролей | 2 |
| Количество policies | 3 (1 inline + 1 managed + 1 trust) |
| Время выполнения | 2-15 минут |
| Сложность | Средняя |
| AWS сервисы | IAM, STS |

## 🛡️ Безопасность

### Преимущества:
- ✅ Временные credentials (auto-rotation)
- ✅ Least privilege (read-only)
- ✅ CloudTrail audit trail
- ✅ Разделение ответственности

### Best Practices:
- ✅ Минимизировать principals в trust policy
- ✅ Ограничивать время сессии
- ✅ Использовать MFA для критичных ролей
- ✅ Тестировать через Policy Simulator

## 🎯 Use Cases в реальном мире

1. **Cross-account access** - доступ между аккаунтами AWS
2. **Service roles** - Lambda, EC2, ECS используют assume role
3. **Federation** - SSO интеграция с корпоративным IdP
4. **Temporary elevated access** - DevOps получают временный доступ
5. **Automation** - CI/CD pipelines assume roles для deployment

## 📚 Дополнительные материалы

- [AWS IAM Roles Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)
- [AWS STS AssumeRole API](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)
- [IAM Policy Evaluation Logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html)

## 🚀 Быстрый старт

```bash
cd task3
./setup-iam-task3.sh
```

---

**Account:** 615299729908  
**Region:** eu-west-1  
**Status:** ✅ COMPLETED
