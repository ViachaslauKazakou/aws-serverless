# 📋 Итоговая информация о Task 2

## ✅ Что было создано

Полное решение AWS IAM Task 2 с подробной документацией на русском языке.

### Структура проекта

```
task2/
├── README.md              # Основной файл с описанием задачи
├── INDEX.md               # Полный указатель документации  
├── QUICKSTART.md          # ⚡ Быстрый старт (30 секунд)
├── INSTRUCTIONS.md        # 📖 Пошаговые инструкции (3 способа)
├── CHECKLIST.md           # ✅ Подробный чеклист выполнения
├── ARCHITECTURE.md        # 🏗️ Визуальные схемы и теория
├── setup-iam-task2.sh     # 🤖 Автоматический скрипт
├── commands.sh            # 💻 Готовые команды CLI
├── inline-policy.json     # 📄 Inline policy для роли
└── bucket-policy.json     # 📄 Bucket policy для bucket-1
```

## 🎯 Решение задачи

### Move 1: Inline Policy для роли
```bash
aws iam put-role-policy \
    --role-name cmtr-4n6e9j62-iam-pela-iam_role \
    --policy-name ListAllBucketsPolicy \
    --policy-document file://inline-policy.json
```

**Inline Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "AllowListAllBuckets",
    "Effect": "Allow",
    "Action": "s3:ListAllMyBuckets",
    "Resource": "*"
  }]
}
```

### Move 2: Bucket Policy для bucket-1
```bash
aws s3api put-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-pela-bucket-1-162653 \
    --policy file://bucket-policy.json
```

**Bucket Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
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
  }]
}
```

## 🚀 Как использовать

### Самый быстрый способ:
```bash
cd task2
chmod +x setup-iam-task2.sh
./setup-iam-task2.sh
```

### Или читайте документацию:
1. **QUICKSTART.md** - начните с него для быстрого старта
2. **CHECKLIST.md** - отслеживайте прогресс выполнения
3. **INSTRUCTIONS.md** - если нужны детальные инструкции
4. **ARCHITECTURE.md** - для понимания теории

## 📊 Результаты выполнения

### Роль МОЖЕТ (✅ Allowed):
- Просматривать список всех S3 buckets в аккаунте
- Просматривать объекты в bucket-1 (ListBucket)
- Получать объекты из bucket-1 (GetObject)
- Загружать объекты в bucket-1 (PutObject)

### Роль НЕ МОЖЕТ (❌ Denied):
- Просматривать объекты в bucket-2 (ListBucket)
- Получать объекты из bucket-2 (GetObject)
- Загружать объекты в bucket-2 (PutObject)

## 🎓 Ключевые концепции Task 2

### 1. Inline Policy vs Managed Policy

| Тип | Описание | Когда использовать |
|-----|----------|-------------------|
| **Inline** | Встроена в роль | Уникальные права для одной роли |
| **Managed** | Отдельная сущность | Общие права для нескольких ролей |

### 2. Resource ARN в Bucket Policy

Bucket Policy требует **ДВУХ** Resource ARN:
- `arn:aws:s3:::bucket-name` - для ListBucket
- `arn:aws:s3:::bucket-name/*` - для GetObject/PutObject

### 3. Implicit Deny

Bucket-2 демонстрирует **Implicit Deny**:
- Нет Explicit Deny
- Нет Allow
- Результат: доступ запрещен

### 4. Матрица разрешений

| Действие | Bucket-1 | Bucket-2 |
|----------|----------|----------|
| ListAllMyBuckets | ✅ | ✅ |
| ListBucket | ✅ | ❌ |
| GetObject | ✅ | ❌ |
| PutObject | ✅ | ❌ |

## 🔧 Требования

- AWS CLI установлен
- Доступ к интернету
- Bash/Zsh shell
- jq (опционально)

## ✅ Проверка результата

### Через CLI:
```bash
# Тест 1: ListAllMyBuckets (allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:ListAllMyBuckets

# Тест 2: GetObject для bucket-1 (allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653/test

# Тест 3: GetObject для bucket-2 (implicitDeny)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-2-162653/test
```

### Через Web UI:
https://policysim.aws.amazon.com/

## 💡 Отличия от Task 1

| Аспект | Task 1 | Task 2 |
|--------|--------|--------|
| Identity Policy | Managed (AmazonS3FullAccess) | **Inline (custom)** |
| Bucket Policy | Deny (запрет) | **Allow (разрешение)** |
| Buckets | 1 bucket | **2 buckets** |
| Логика | Explicit Deny | **Implicit Deny** |
| Сложность | Средняя | **Средняя-Высокая** |

## 📝 AWS Resources

- **Region**: eu-west-1
- **Account ID**: 863518426750
- **IAM Role**: cmtr-4n6e9j62-iam-pela-iam_role
- **S3 Bucket 1**: cmtr-4n6e9j62-iam-pela-bucket-1-162653 (основной)
- **S3 Bucket 2**: cmtr-4n6e9j62-iam-pela-bucket-2-162653 (для проверки)

### Credentials
```bash
AWS_ACCESS_KEY_ID=AKIA4SDNVQZ7K5LP7AXA
AWS_SECRET_ACCESS_KEY=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
AWS_DEFAULT_REGION=eu-west-1
```

### Console Access
- URL: https://863518426750.signin.aws.amazon.com/console?region=eu-west-1
- Username: cmtr-4n6e9j62
- Password: Zj3!PVitYLNgG7U8

## 🎉 Итог

Проект содержит:
- ✅ 10 файлов (документация + скрипты + политики)
- ✅ Полное решение задачи
- ✅ Подробные объяснения
- ✅ Автоматический скрипт
- ✅ Примеры команд
- ✅ Чеклист выполнения
- ✅ Инструкции на русском языке

**Общий объем документации:** ~40KB  
**Время на выполнение задачи:** ~2-5 минут  
**Сложность:** Средняя-Высокая  

---

**Создано:** October 7, 2025  
**Язык:** Русский  
**Тема:** AWS IAM, Inline Policies, Bucket Policies, Granular Access Control
