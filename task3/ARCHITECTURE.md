# 🏛️ ARCHITECTURE - Task 3: Role Assumption

## 🎯 Архитектурный обзор

Task 3 демонстрирует механизм **Role Assumption** - фундаментальную концепцию AWS IAM для делегирования доступа.

## 📐 Архитектурные диаграммы

### Диаграмма 1: Общая архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                   AWS Account: 615299729908                 │
│                                                             │
│  ┌──────────────────────┐         ┌──────────────────────┐ │
│  │   Assume Role        │         │   ReadOnly Role      │ │
│  │  cmtr-4n6e9j62-      │         │  cmtr-4n6e9j62-      │ │
│  │  iam-ar-iam_role-    │         │  iam-ar-iam_role-    │ │
│  │  assume              │         │  readonly            │ │
│  │                      │         │                      │ │
│  │  Inline Policy:      │         │  Managed Policy:     │ │
│  │  ✅ sts:AssumeRole   │───────▶ │  ✅ ReadOnlyAccess   │ │
│  │                      │         │                      │ │
│  │                      │         │  Trust Policy:       │ │
│  │                      │◀────────│  ✅ Allow assume role│ │
│  └──────────────────────┘         └──────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Диаграмма 2: Поток Role Assumption

```
┌─────────────────┐
│  Assume Role    │
│  (Initiator)    │
└────────┬────────┘
         │
         │ 1. Request: sts:AssumeRole
         ▼
┌─────────────────────────────────┐
│  AWS STS (Security Token        │
│  Service)                       │
└────────┬────────────────────────┘
         │
         │ 2. Check: Inline Policy
         │    "Can assume role perform sts:AssumeRole?"
         │    ✅ YES
         ▼
┌─────────────────────────────────┐
│  ReadOnly Role                  │
│  (Target)                       │
└────────┬────────────────────────┘
         │
         │ 3. Check: Trust Policy
         │    "Can assume role assume me?"
         │    ✅ YES
         ▼
┌─────────────────────────────────┐
│  STS Returns Temporary          │
│  Credentials                    │
│  - AccessKeyId                  │
│  - SecretAccessKey              │
│  - SessionToken                 │
│  - Expiration                   │
└────────┬────────────────────────┘
         │
         │ 4. Use temporary credentials
         ▼
┌─────────────────────────────────┐
│  AWS Services                   │
│  ✅ Read operations (allowed)   │
│  ❌ Write operations (denied)   │
└─────────────────────────────────┘
```

### Диаграмма 3: Конфигурация компонентов

```
┌───────────────────────────────────────────────────────────────┐
│                         Assume Role                           │
├───────────────────────────────────────────────────────────────┤
│  Inline Policy: AssumeReadOnlyRolePolicy                      │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ {                                                       │ │
│  │   "Effect": "Allow",                                    │ │
│  │   "Action": "sts:AssumeRole",                           │ │
│  │   "Resource": "arn:aws:iam::615299729908:role/...readonly" │
│  │ }                                                       │ │
│  └─────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
                              │
                              │ AssumeRole request
                              ▼
┌───────────────────────────────────────────────────────────────┐
│                        ReadOnly Role                          │
├───────────────────────────────────────────────────────────────┤
│  Trust Policy (WHO can assume)                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ {                                                       │ │
│  │   "Effect": "Allow",                                    │ │
│  │   "Principal": {                                        │ │
│  │     "AWS": "arn:aws:iam::615299729908:role/...assume"  │ │
│  │   },                                                    │ │
│  │   "Action": "sts:AssumeRole"                            │ │
│  │ }                                                       │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  Managed Policy: ReadOnlyAccess (WHAT can do)                 │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ✅ Read operations on all services                      │ │
│  │ ❌ Write operations (implicitDeny)                      │ │
│  └─────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
```

## 🔐 Policy Evaluation Flow

### Для sts:AssumeRole действия:

```
1. Check Assume Role Inline Policy:
   ┌─────────────────────────────────┐
   │ Action: sts:AssumeRole          │
   │ Resource: readonly role ARN     │
   │ Result: ✅ ALLOW                 │
   └─────────────────────────────────┘

2. Check ReadOnly Role Trust Policy:
   ┌─────────────────────────────────┐
   │ Principal: assume role ARN      │
   │ Action: sts:AssumeRole          │
   │ Result: ✅ ALLOW                 │
   └─────────────────────────────────┘

3. Final Decision: ✅ ALLOWED
```

### Для read/write операций через assumed role:

```
1. Check ReadOnlyAccess Policy:
   ┌─────────────────────────────────┐
   │ Read actions: ✅ ALLOW           │
   │ Write actions: (no statement)   │
   └─────────────────────────────────┘

2. Default: Implicit Deny
   ┌─────────────────────────────────┐
   │ Write actions: ❌ IMPLICIT DENY  │
   └─────────────────────────────────┘
```

## 📊 Компоненты системы

| Компонент | Тип | Назначение |
|-----------|-----|------------|
| Assume Role | IAM Role | Может принимать другие роли |
| ReadOnly Role | IAM Role | Целевая роль с read-only доступом |
| Inline Policy | Identity-based | Разрешает sts:AssumeRole |
| Trust Policy | Trust relationship | Определяет WHO может assume |
| ReadOnlyAccess | AWS Managed Policy | Определяет WHAT можно делать |

## 🎯 Три столпа конфигурации

### 1. Identity-based Policy (Inline)
```
WHO: Assume Role
WHAT: sts:AssumeRole
WHERE: ReadOnly Role ARN
```

### 2. Trust Policy
```
WHO: Assume Role (Principal)
CAN DO: AssumeRole action
ON: ReadOnly Role
```

### 3. Permissions Policy (Managed)
```
WHO: ReadOnly Role
WHAT: Read operations
WHERE: All services
```

## 💡 Ключевые концепции

### Role Assumption
- **Определение:** Процесс получения временных credentials другой роли
- **Сервис:** AWS STS (Security Token Service)
- **Действие:** `sts:AssumeRole`
- **Результат:** Временные credentials (AccessKeyId, SecretAccessKey, SessionToken)

### Trust Policy
- **Определение:** Policy, определяющий кто может assume роль
- **Тип:** Trust relationship (не identity-based и не resource-based)
- **Формат:** JSON с Principal и Action

### Temporary Credentials
- **Срок действия:** Настраиваемый (по умолчанию 1 час)
- **Компоненты:** AccessKeyId, SecretAccessKey, SessionToken
- **Безопасность:** Автоматическая ротация, ограниченное время жизни

## 🔄 Сравнение типов policies

| Тип Policy | Где находится | Определяет |
|------------|---------------|------------|
| Identity-based (Inline) | На assume роли | Что может делать assume роль |
| Trust Policy | На readonly роли | Кто может assume readonly роль |
| Permissions Policy | На readonly роли | Что может делать readonly роль |

## 🛡️ Безопасность

### Преимущества Role Assumption:

1. **Временные credentials** - автоматическая ротация
2. **Least privilege** - минимальные необходимые права
3. **Аудит** - CloudTrail логирует все assume операции
4. **Разделение ответственности** - разные роли для разных задач

### Best Practices:

- ✅ Использовать MFA для критичных ролей
- ✅ Ограничивать время сессии
- ✅ Проверять через Policy Simulator
- ✅ Минимизировать количество principals в trust policy

## 📈 Use Cases

1. **Cross-account access** - доступ между аккаунтами
2. **Service roles** - роли для AWS сервисов (Lambda, EC2)
3. **Federation** - SSO с корпоративным IdP
4. **Temporary elevated access** - временное повышение прав

## 🎓 Сравнение с Task 1 и Task 2

| Task | Фокус | Key Policy Type |
|------|-------|-----------------|
| Task 1 | Explicit Deny | Resource-based (Bucket Policy) |
| Task 2 | Inline + Implicit Deny | Identity-based (Inline Policy) |
| Task 3 | Role Assumption | Trust Policy + STS |

---

**Сложность:** Средняя  
**Ключевая концепция:** Trust Policies и Role Assumption
