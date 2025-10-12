# QUICKSTART - Task 4: KMS Encryption

## ⚡ Самый быстрый способ (30 секунд)

```bash
cd task4
chmod +x setup-iam-task4.sh
./setup-iam-task4.sh
```

## 📋 Что делает скрипт?

1. ✅ Присоединяет KMS policy к роли (Encrypt, Decrypt, GenerateDataKey)
2. ✅ Включает server-side encryption для bucket-2 с KMS ключом
3. ✅ Копирует файл из bucket-1 в bucket-2 с KMS encryption
4. ✅ Запускает автоматические тесты

## 🎯 Ожидаемый результат

### IAM Role:
- ✅ Имеет KMS permissions для указанного ключа

### Bucket-2:
- ✅ Server-side encryption включен
- ✅ Использует указанный KMS ключ
- ✅ Файл `confidential_credentials.csv` зашифрован

---

## ✅ Быстрая проверка

```bash
export AWS_ACCESS_KEY_ID=AKIAXTORPMOMXL3LT7RQ
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# Проверка 1: KMS policy на роли
aws iam get-role-policy \
    --role-name cmtr-4n6e9j62-iam-sewk-iam_role \
    --policy-name KMSAccessPolicy

# Проверка 2: Bucket encryption
aws s3api get-bucket-encryption \
    --bucket cmtr-4n6e9j62-iam-sewk-bucket-695267-2

# Проверка 3: File encryption
aws s3api head-object \
    --bucket cmtr-4n6e9j62-iam-sewk-bucket-695267-2 \
    --key confidential_credentials.csv
```

---

## 💡 Ключевые концепции

```
IAM Role → KMS Policy → KMS Key
    ↓
Bucket-2 → Server-Side Encryption → KMS
    ↓
File Upload → Автоматическое шифрование ✅
```

---

## 📚 Дополнительно

| Файл | Описание |
|------|----------|
| `INSTRUCTIONS.md` | Подробные инструкции |
| `CHECKLIST.md` | Чеклист выполнения |
| `ARCHITECTURE.md` | Теория KMS encryption |
| `commands.sh` | Команды для копирования |

---

## 🎓 Что изучите

- ✅ AWS KMS (Key Management Service)
- ✅ Server-Side Encryption (SSE-KMS)
- ✅ KMS Permissions
- ✅ Bucket Encryption Configuration
- ✅ Encrypted S3 Copy

---

**Время:** ~2 минуты  
**Сложность:** Средняя
