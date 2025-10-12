# QUICKSTART - Быстрое выполнение Task 2

## ⚡ Самый быстрый способ (30 секунд)

```bash
# 1. Перейдите в директорию task2
cd task2

# 2. Сделайте скрипт исполняемым
chmod +x setup-iam-task2.sh

# 3. Запустите скрипт
./setup-iam-task2.sh

# 4. Готово! ✅
```

## 📋 Что делает скрипт?

1. ✅ Настраивает AWS credentials
2. ✅ Создает inline policy `ListAllBucketsPolicy` для роли
3. ✅ Создает bucket policy для bucket-1
4. ✅ Запускает автоматические тесты

## 🎯 Ожидаемый результат

После выполнения скрипта роль `cmtr-4n6e9j62-iam-pela-iam_role`:

### ✅ МОЖЕТ (Allowed):
- Просматривать список всех S3 buckets
- Получать объекты из bucket-1 (GetObject)
- Загружать объекты в bucket-1 (PutObject)
- Просматривать объекты в bucket-1 (ListBucket)

### ❌ НЕ МОЖЕТ (Denied):
- Получать объекты из bucket-2
- Загружать объекты в bucket-2
- Просматривать объекты в bucket-2

## ✅ Проверка результата

### Автоматическая проверка (включена в скрипт)
Скрипт автоматически запустит 5 тестов через Policy Simulator

### Ручная проверка через Web UI:
1. Откройте: https://policysim.aws.amazon.com/
2. Выберите роль: `cmtr-4n6e9j62-iam-pela-iam_role`

**Тест bucket-1 (должен быть allowed):**
- Action: `s3:ListBucket`
- Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653`
- Результат: ✅ **Allowed**

**Тест bucket-2 (должен быть denied):**
- Action: `s3:GetObject`
- Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-2-162653/*`
- Результат: ❌ **Denied**

### Ручная проверка через AWS CLI:
```bash
export AWS_ACCESS_KEY_ID=AKIA4SDNVQZ7K5LP7AXA
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# Тест 1: ListAllMyBuckets (должен быть allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:ListAllMyBuckets

# Тест 2: GetObject для bucket-1 (должен быть allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653/test

# Тест 3: GetObject для bucket-2 (должен быть implicitDeny)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-2-162653/test
```

## 📚 Дополнительные ресурсы

| Файл | Для чего |
|------|----------|
| `INSTRUCTIONS.md` | Подробные инструкции (3 способа) |
| `ARCHITECTURE.md` | Визуальные схемы и теория |
| `TESTING.md` | Примеры тестирования |
| `CHECKLIST.md` | Чеклист выполнения |
| `FAQ.md` | Часто задаваемые вопросы |
| `commands.sh` | Готовые команды для копирования |

## 🆘 Проблемы?

### Скрипт не запускается
```bash
# Проверьте AWS CLI
aws --version

# Если нет, установите (macOS)
brew install awscli

# Проверьте права
chmod +x setup-iam-task2.sh
```

### Ошибка доступа
```bash
# Проверьте credentials
aws sts get-caller-identity
```

### Нужна помощь
Откройте `INSTRUCTIONS.md` или `FAQ.md`

## 💡 Ключевая концепция

```
Inline Policy (на роли)
    → Разрешает ListAllMyBuckets (для всех buckets)
              +
Bucket Policy (на bucket-1)
    → Разрешает GetObject, PutObject, ListBucket
              =
Роль может видеть все buckets,
но работать только с bucket-1 ✅
```

## 🎓 Что вы изучите

- ✅ Inline policies vs Managed policies
- ✅ Identity-based policies
- ✅ Resource-based policies (bucket policies)
- ✅ Комбинирование политик
- ✅ Granular access control
- ✅ AWS Policy Simulator

---

**Время выполнения:** ~2 минуты  
**Сложность:** Средняя  
**Требования:** AWS CLI
