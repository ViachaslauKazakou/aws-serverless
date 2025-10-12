# AWS IAM Task 2 - Решение

## 📚 Навигация

> 💡 **Полный указатель документации:** [INDEX.md](INDEX.md)

- 🚀 [**QUICKSTART.md**](QUICKSTART.md) - Начните отсюда! Быстрое выполнение за 30 секунд
- ✅ [**CHECKLIST.md**](CHECKLIST.md) - Подробный чеклист для отслеживания прогресса
- 📖 [**INSTRUCTIONS.md**](INSTRUCTIONS.md) - Подробные инструкции (CLI, Console, скрипт)
- 🏗️ [**ARCHITECTURE.md**](ARCHITECTURE.md) - Визуальные схемы и теория
- 📊 [**DIAGRAMS.md**](DIAGRAMS.md) - Mermaid диаграммы
- 🧪 [**TESTING.md**](TESTING.md) - Как проверить результат
- ❓ [**FAQ.md**](FAQ.md) - Ответы на частые вопросы
- 💻 [**commands.sh**](commands.sh) - Готовые команды для копирования

---

## 🚀 Быстрый старт

### Вариант 1: Автоматический скрипт (рекомендуется)
```bash
chmod +x setup-iam-task2.sh
./setup-iam-task2.sh
```

### Вариант 2: Команды AWS CLI
Смотрите файл `commands.sh` с готовыми командами

### Вариант 3: AWS Console
Откройте `INSTRUCTIONS.md` для пошаговой инструкции через веб-интерфейс

---

## 🎯 Суть задачи

**Два шага (moves):**
1. ✅ Создать inline policy для роли (разрешает ListAllMyBuckets)
2. ✅ Создать bucket policy для bucket-1 (разрешает GetObject, PutObject, ListBucket)

**Результат:** Роль может:
- ✅ Просматривать список ВСЕХ buckets
- ✅ Работать с объектами ТОЛЬКО в bucket-1
- ❌ НЕ может работать с объектами в bucket-2

**Принцип:** Комбинация Identity-based (inline) и Resource-based (bucket) политик! 🛡️

---

## Lab Description
The goals of this task are to explore the process of evaluating policies and to configure both an identity-based policy and a resource-based policy for a specific role.

Task Resources
Region-specific resources are created in the eu-west-1 region. For more details about regional services, see AWS Services by Region.

In this task, you will work with the following resources:

IAM Role cmtr-4n6e9j62-iam-pela-iam_role: You will grant specific permissions to this role and verify that they are applied successfully.
S3 Bucket cmtr-4n6e9j62-iam-pela-bucket-1-162653: A bucket with a default configuration and one object inside. A resource-based S3 bucket policy should be created for this bucket.
S3 Bucket cmtr-4n6e9j62-iam-pela-bucket-2-162653: An empty bucket used solely for task verification purposes. Do not attach any policies to this bucket or change its configuration.
Objectives
In two moves, you must:

Create and attach an inline identity-based policy to the cmtr-4n6e9j62-iam-pela-iam_role role that allows all buckets to be listed.
Create a resource-based S3 bucket policy that allows to get and put an object as well as list the objects in the cmtr-4n6e9j62-iam-pela-bucket-1-162653 bucket. The cmtr-4n6e9j62-iam-pela-iam_role role must be allowed to perform all of these actions for the cmtr-4n6e9j62-iam-pela-bucket-1-162653 bucket only; do not allow access to all principals.
One move is to create, update, or delete an AWS resource. Some verification steps may pass without any action, but to complete the task, you must ensure that all the steps are passed.

Task Verification
To make sure everything has been done correctly, use the AWS policy simulator for the cmtr-4n6e9j62-iam-pela-iam_role role and check that:

You can list all the buckets.
You can list, get, and put objects only in the cmtr-4n6e9j62-iam-pela-bucket-1-162653 bucket.
You can't list, get, or put objects in the cmtr-4n6e9j62-iam-pela-bucket-2-162653 bucket.
Optionally: Instead of using the AWS policy simulator, you can assume the role and perform the required checks.

Deployment Time
It should take about 2 minutes to deploy the task resources.

Sandbox User Credentials
Use the credentials below to access the AWS environment:

AWS Console
Console URL: https://863518426750.signin.aws.amazon.com/console?region=eu-west-1
IAM username: cmtr-4n6e9j62
Password: Zj3!PVitYLNgG7U8
AWS environment variables
AWS_ACCESS_KEY_ID=AKIA4SDNVQZ7K5LP7AXA
AWS_SECRET_ACCESS_KEY=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