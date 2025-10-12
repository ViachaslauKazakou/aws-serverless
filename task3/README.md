# AWS IAM Task 3 - Role Assumption

## 📚 Навигация

> 💡 **Полный указатель документации:** [INDEX.md](INDEX.md)

- 🚀 [**QUICKSTART.md**](QUICKSTART.md) - Быстрое выполнение за 30 секунд
- ✅ [**CHECKLIST.md**](CHECKLIST.md) - Детальный чеклист
- 📖 [**INSTRUCTIONS.md**](INSTRUCTIONS.md) - Пошаговые инструкции  
- 🏗️ [**ARCHITECTURE.md**](ARCHITECTURE.md) - Архитектура и теория
- 💻 [**commands.sh**](commands.sh) - Готовые команды
- 📋 [**PROJECT_SUMMARY.md**](PROJECT_SUMMARY.md) - Итоговая сводка

---

## 🚀 Быстрый старт

### Вариант 1: Автоматический скрипт (рекомендуется)
```bash
cd task3
chmod +x setup-iam-task3.sh
./setup-iam-task3.sh
```

### Вариант 2: Команды AWS CLI
См. файл `commands.sh` с готовыми командами

---

## 🎯 Суть задачи

**Три шага:**
1. ✅ Дать assume роли право принимать readonly роль (`sts:AssumeRole`)
2. ✅ Присоединить `ReadOnlyAccess` к readonly роли
3. ✅ Обновить Trust Policy readonly роли (разрешить assume от первой роли)

**Результат:** Роль assume может принять readonly роль, которая имеет read-only доступ ко всем сервисам AWS! 🔐

---

## 📊 Ожидаемый результат

| Действие | Результат | Почему? |
|----------|-----------|---------|
| sts:AssumeRole | ✅ allowed | Inline policy + Trust policy |
| ec2:DescribeInstances | ✅ allowed | ReadOnlyAccess policy |
| s3:ListAllMyBuckets | ✅ allowed | ReadOnlyAccess policy |
| ec2:RunInstances | ❌ implicitDeny | Нет Allow для write |
| s3:DeleteBucket | ❌ implicitDeny | Нет Allow для write |

---

## 🏗️ Архитектура

```
┌──────────────────────┐         ┌──────────────────────┐
│   Assume Role        │         │   ReadOnly Role      │
│                      │         │                      │
│  Inline Policy:      │         │  Managed Policy:     │
│  ✅ sts:AssumeRole   │───────▶ │  ✅ ReadOnlyAccess   │
│                      │         │                      │
│                      │         │  Trust Policy:       │
│                      │◀────────│  ✅ Allow assume     │
└──────────────────────┘         └──────────────────────┘
```

---

## 💡 Ключевые концепции

### Role Assumption
Процесс получения временных credentials через `sts:AssumeRole`.

### Trust Policy
Определяет **WHO** может assume роль (на readonly роли).

### Inline Policy
Определяет **WHAT** роль может делать (на assume роли).

---

## ✅ Проверка

### Policy Simulator
```bash
export AWS_ACCESS_KEY_ID=AKIAY6QVYZH2ESZQQ6CV
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# Тест 1: AssumeRole - allowed
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-assume \
  --action-names sts:AssumeRole \
  --resource-arns arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly

# Тест 2: Read - allowed
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly \
  --action-names ec2:DescribeInstances

# Тест 3: Write - denied
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly \
  --action-names ec2:RunInstances
```

---

## 📁 Файлы проекта

| Файл | Описание |
|------|----------|
| `setup-iam-task3.sh` | Автоматический скрипт |
| `commands.sh` | CLI команды |
| `assume-role-policy.json` | Inline policy |
| `trust-policy.json` | Trust policy |
| `QUICKSTART.md` | Быстрый старт |
| `INSTRUCTIONS.md` | Инструкции |
| `ARCHITECTURE.md` | Теория |
| `PROJECT_SUMMARY.md` | Сводка |

---

## 🎓 Что изучите

- ✅ Role Assumption (sts:AssumeRole)
- ✅ Trust Policies
- ✅ AWS STS
- ✅ Temporary Credentials
- ✅ Inline vs Managed Policies

---

## Task Resources
Region-specific resources are created in the eu-west-1 region. For more details about regional services, see AWS Services by Region.

The following roles have been created for you:

Assume Role cmtr-4n6e9j62-iam-ar-iam_role-assume: This role should be assumed by any user in your AWS account.
Read-Only Role cmtr-4n6e9j62-iam-ar-iam_role-readonly: This role should be assumed only by the cmtr-4n6e9j62-iam-ar-iam_role-assume role.
Objectives
Your task is to:

Configure proper permissions for the cmtr-4n6e9j62-iam-ar-iam_role-assume role, allowing it to assume the cmtr-4n6e9j62-iam-ar-iam_role-readonly role. Do not grant full administrator access!
Grant full read-only access for the cmtr-4n6e9j62-iam-ar-iam_role-readonly role. Please use an existing AWS policy; do not create your own.
Configure the correct trust policy for the cmtr-4n6e9j62-iam-ar-iam_role-readonly role to allow it to be assumed by the cmtr-4n6e9j62-iam-ar-iam_role-assume role.
One "move" is the creation, updating, or deletion of an AWS resource. Some verification steps may pass without any action, but to complete the task, you must ensure that all the steps are passed.

Task Verification
To make sure everything is set up correctly, use the AWS policy simulator for the roles and check that:

The cmtr-4n6e9j62-iam-ar-iam_role-assume role can assume other roles.
The cmtr-4n6e9j62-iam-ar-iam_role-readonly role can perform read-only actions and is not allowed to perform write actions.
Optionally: Instead of using the AWS policy simulator, you can assume the cmtr-4n6e9j62-iam-ar-iam_role-assume role and then assume the cmtr-4n6e9j62-iam-ar-iam_role-readonly role with this role. Next, try to execute any command that requires read-only access; it should be successful. Then, try to execute a command that requires write access; it should return an error message. 

Deployment Time
It takes up to 2 minutes to deploy task resources.

Sandbox User Credentials
Use the credentials below to access the AWS environment:

AWS Console
Console URL: https://615299729908.signin.aws.amazon.com/console?region=eu-west-1
IAM username: cmtr-4n6e9j62
Password: Ca6&iV1a6cbD4FJY
AWS environment variables
AWS_ACCESS_KEY_ID=AKIAY6QVYZH2ESZQQ6CV
AWS_SECRET_ACCESS_KEY=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
