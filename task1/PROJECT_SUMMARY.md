# 📋 Итоговая информация о проекте

## ✅ Что было создано

Полное решение AWS IAM задачи с документацией на русском языке.

### Структура проекта

```
IAM-task/
├── README.md              # Основной файл с описанием задачи
├── QUICKSTART.md          # ⚡ Быстрый старт (30 секунд)
├── INSTRUCTIONS.md        # 📖 Пошаговые инструкции (3 способа)
├── ARCHITECTURE.md        # 🏗️ Визуальные схемы и теория
├── TESTING.md            # 🧪 Примеры тестирования
├── FAQ.md                # ❓ Часто задаваемые вопросы
├── setup-iam-task.sh     # 🤖 Автоматический скрипт
├── commands.sh           # 💻 Готовые команды CLI
└── bucket-policy.json    # 📄 JSON политика bucket
```

## 🎯 Решение задачи

### Move 1: Identity-Based Policy
```bash
aws iam attach-role-policy \
    --role-name cmtr-4n6e9j62-iam-peld-iam_role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

### Move 2: Resource-Based Policy
```bash
aws s3api put-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738 \
    --policy file://bucket-policy.json
```

### Bucket Policy содержимое:
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

## 🚀 Как использовать

### Самый быстрый способ:
```bash
chmod +x setup-iam-task.sh
./setup-iam-task.sh
```

### Или читайте документацию:
1. **QUICKSTART.md** - начните с него для быстрого старта
2. **INSTRUCTIONS.md** - если нужны детальные инструкции
3. **ARCHITECTURE.md** - для понимания теории
4. **TESTING.md** - для проверки результата
5. **FAQ.md** - если возникли вопросы

## 📊 Ключевые концепции

### AWS IAM Policy Evaluation Logic
```
┌───────────────────┐
│  Default: DENY    │
└─────────┬─────────┘
          ↓
┌───────────────────┐
│ Explicit DENY?    │ → YES → ❌ DENY
└─────────┬─────────┘
          ↓ NO
┌───────────────────┐
│    Has ALLOW?     │ → YES → ✅ ALLOW
└─────────┬─────────┘
          ↓ NO
      ❌ DENY
```

### Результат после применения обеих политик

| Действие           | Identity Policy | Bucket Policy | Итог      |
|-------------------|-----------------|---------------|-----------|
| s3:GetObject      | ALLOW ✅        | -             | ALLOW ✅  |
| s3:PutObject      | ALLOW ✅        | -             | ALLOW ✅  |
| s3:ListBucket     | ALLOW ✅        | -             | ALLOW ✅  |
| s3:DeleteObject   | ALLOW ✅        | DENY ❌       | **DENY ❌** |

## 🎓 Что изучается в этой задаче

1. ✅ **Identity-based policies** - политики на IAM сущностях
2. ✅ **Resource-based policies** - политики на AWS ресурсах
3. ✅ **Policy Evaluation Logic** - как AWS оценивает политики
4. ✅ **Explicit Deny precedence** - приоритет явного запрета
5. ✅ **AWS Managed Policies** - использование готовых политик AWS
6. ✅ **S3 Bucket Policies** - управление доступом к S3
7. ✅ **IAM Policy Simulator** - тестирование политик
8. ✅ **AWS CLI** - работа с AWS через командную строку

## 🔧 Требования

- AWS CLI установлен (`aws --version`)
- Доступ к интернету
- Bash/Zsh shell
- jq (опционально, для форматирования JSON)

## ✅ Проверка результата

### Через Web UI:
1. https://policysim.aws.amazon.com/
2. Role: `cmtr-4n6e9j62-iam-peld-iam_role`
3. Action: `s3:DeleteObject`
4. Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/*`
5. Результат: ❌ **Denied**

### Через CLI:
```bash
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role \
  --action-names s3:DeleteObject \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test

# Ожидается: "EvalDecision": "explicitDeny"
```

## 💡 Ключевой принцип

```
┌─────────────────────────────────────┐
│  EXPLICIT DENY ВСЕГДА ПОБЕЖДАЕТ!   │
└─────────────────────────────────────┘

Identity Policy (Allow S3 Full Access)
                +
Resource Policy (Deny DeleteObject)
                =
    Full S3 Access EXCEPT DeleteObject
```

## 📝 Дополнительная информация

### AWS Resources
- **Region**: eu-west-1
- **Account ID**: 651706749822
- **IAM Role**: cmtr-4n6e9j62-iam-peld-iam_role
- **S3 Bucket**: cmtr-4n6e9j62-iam-peld-bucket-2911738

### Credentials
```bash
AWS_ACCESS_KEY_ID=AKIAZPPF72N7EHDWSCFI
AWS_SECRET_ACCESS_KEY=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
AWS_DEFAULT_REGION=eu-west-1
```

### Console Access
- URL: https://651706749822.signin.aws.amazon.com/console?region=eu-west-1
- Username: cmtr-4n6e9j62
- Password: Ka9#yGgVDBMPqLi1

## 🎉 Итог

Проект содержит:
- ✅ 8 документационных файлов
- ✅ 1 автоматический скрипт
- ✅ 1 JSON файл с политикой
- ✅ Полное решение задачи
- ✅ Подробные объяснения
- ✅ Визуальные схемы
- ✅ Примеры команд
- ✅ FAQ с ответами
- ✅ Инструкции на русском языке

**Общий объем документации:** ~50KB  
**Время на выполнение задачи:** ~2-5 минут  
**Сложность:** Легко-Средняя  

---

**Создано:** October 7, 2025  
**Язык:** Русский  
**Тема:** AWS IAM, Identity and Access Management, Policy Evaluation
