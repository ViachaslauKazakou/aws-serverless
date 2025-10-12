# AWS IA## 📚 Навигация

> 💡 **Полный указатель документации:** [INDEX.md](INDEX.md)

- 🚀 [**QUICKSTART.md**](QUICKSTART.md) - Начните отсюда! Быстрое выполнение за 30 секунд
- ✅ [**CHECKLIST.md**](CHECKLIST.md) - Подробный чеклист для отслеживания прогресса
- 📖 [**INSTRUCTIONS.md**](INSTRUCTIONS.md) - Подробные инструкции (CLI, Console, скрипт)
- 🏗️ [**ARCHITECTURE.md**](ARCHITECTURE.md) - Визуальные схемы и теория
- 📊 [**DIAGRAMS.md**](DIAGRAMS.md) - Mermaid диаграммы
- 🧪 [**TESTING.md**](TESTING.md) - Как проверить результат
- ❓ [**FAQ.md**](FAQ.md) - Ответы на частые вопросы
- 💻 [**commands.sh**](commands.sh) - Готовые команды для копирования
- 📋 [**PROJECT_SUMMARY.md**](PROJECT_SUMMARY.md) - Итоговая информация Решение

## Task description
Lab Description
The goal of this task is to explore the process of evaluating policies and to configure both identity-based policy and resource-based policy for a specific role.

---

## � Навигация

- 🚀 [**QUICKSTART.md**](QUICKSTART.md) - Начните отсюда! Быстрое выполнение за 30 секунд
- 📖 [**INSTRUCTIONS.md**](INSTRUCTIONS.md) - Подробные инструкции (CLI, Console, скрипт)
- 🏗️ [**ARCHITECTURE.md**](ARCHITECTURE.md) - Визуальные схемы и теория
- 🧪 [**TESTING.md**](TESTING.md) - Как проверить результат
- ❓ [**FAQ.md**](FAQ.md) - Ответы на частые вопросы
- 💻 [**commands.sh**](commands.sh) - Готовые команды для копирования

---

## �🚀 Быстрый старт

Для выполнения задачи у вас есть **3 варианта**:

### Вариант 1: Автоматический скрипт (рекомендуется)
```bash
chmod +x setup-iam-task.sh
./setup-iam-task.sh
```

### Вариант 2: Команды AWS CLI
Смотрите файл `commands.sh` с готовыми командами

### Вариант 3: AWS Console
Откройте `INSTRUCTIONS.md` для пошаговой инструкции через веб-интерфейс

---

## 📁 Созданные файлы (всего 13)

| Файл | Описание |
|------|----------|
| `INDEX.md` | 📚 Полный указатель всей документации |
| `QUICKSTART.md` | ⚡ Самый быстрый способ выполнить задачу (30 сек) |
| `CHECKLIST.md` | ✅ Подробный чеклист выполнения задачи |
| `setup-iam-task.sh` | 🤖 Автоматический скрипт для выполнения всей задачи |
| `INSTRUCTIONS.md` | 📖 Подробная пошаговая инструкция (3 варианта) |
| `ARCHITECTURE.md` | 🏗️ Визуальные схемы и объяснение логики политик |
| `DIAGRAMS.md` | 📊 Mermaid диаграммы для визуализации |
| `TESTING.md` | 🧪 Примеры тестирования и проверки результата |
| `FAQ.md` | ❓ Часто задаваемые вопросы и ответы (30+ вопросов) |
| `PROJECT_SUMMARY.md` | 📋 Итоговая информация о проекте |
| `commands.sh` | 💻 Готовые команды AWS CLI для копирования |
| `bucket-policy.json` | 📄 JSON политика для S3 bucket |
| `.gitignore` | 🔒 Файлы для игнорирования Git |

---

## 🎯 Суть задачи

**Два шага (moves):**
1. ✅ Присоединить AWS Managed Policy `AmazonS3FullAccess` к роли
2. ✅ Обновить bucket policy для запрета удаления объектов

**Результат:** Роль имеет полный доступ к S3, НО не может удалять объекты из конкретного bucket.

**Принцип:** Explicit DENY всегда побеждает ALLOW! 🛡️

---

Task Resources
Region-specific resources are created in the eu-west-1 region. For more details about regional services, see AWS Services by Region.

In this task, you will work with the following resources:

IAM Role cmtr-4n6e9j62-iam-peld-iam_role: You will grant specific permissions for this role and check to make sure they are applied successfully.
S3 Bucket cmtr-4n6e9j62-iam-peld-bucket-2911738: A bucket with an existing policy.
Objectives
In two moves, you must:

Grant full access to the Amazon S3 service for the cmtr-4n6e9j62-iam-peld-iam_role role. Please use an existing AWS policy; do not create your own.
Update the resource-based S3 bucket policy to prohibit the deletion of any objects inside the cmtr-4n6e9j62-iam-peld-bucket-2911738 bucket specifically for the cmtr-4n6e9j62-iam-peld-iam_role role.
One move is to create, update, or delete an AWS resource. Some verification steps may pass without any action, but to complete the task, you must ensure that all the steps are passed.

Task Verification
To ensure everything has been done correctly, use the policy simulator for the cmtr-4n6e9j62-iam-peld-iam_role role and check to make sure you cannot delete objects in the cmtr-4n6e9j62-iam-peld-bucket-2911738 bucket.

Deployment Time
It should take about 2 minutes to deploy the task resources.

Sandbox User Credentials
Use the credentials below to access the AWS environment:

AWS Console
Console URL: https://651706749822.signin.aws.amazon.com/console?region=eu-west-1
IAM username: cmtr-4n6e9j62
Password: Ka9#yGgVDBMPqLi1
AWS environment variables
AWS_ACCESS_KEY_ID=AKIAZPPF72N7EHDWSCFI
AWS_SECRET_ACCESS_KEY=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