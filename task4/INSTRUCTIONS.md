# 📘 INSTRUCTIONS - Task 4: KMS Encryption

## 🎯 Цель задания

Настроить server-side encryption с AWS KMS для S3 bucket и скопировать зашифрованный файл `confidential_credentials.csv` из bucket-1 в bucket-2.

## 📚 Что такое AWS KMS?

**AWS Key Management Service (KMS)** - это управляемый сервис для создания и контроля криптографических ключей, используемых для шифрования данных.

### Server-Side Encryption (SSE-KMS):
- S3 автоматически шифрует объекты при загрузке
- Использует указанный KMS ключ
- Прозрачное дешифрование при чтении (если есть права)

---

## 🛠️ Три метода выполнения

---

## Метод 1: Автоматический скрипт ⚡

### Шаг 1: Запустить скрипт
```bash
cd task4
chmod +x setup-iam-task4.sh
./setup-iam-task4.sh
```

### Что делает скрипт:
1. ✅ Присоединяет KMS policy к роли
2. ✅ Включает server-side encryption для bucket-2
3. ✅ Копирует файл с KMS encryption
4. ✅ Запускает автоматические тесты

### Время: ~2 минуты

---

## Метод 2: Вручную через AWS CLI 🖥️

### Credentials (используйте эти):
```bash
export AWS_ACCESS_KEY_ID=AKIAXTORPMOMXL3LT7RQ
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1
```

### Переменные:
```bash
ROLE_NAME="cmtr-4n6e9j62-iam-sewk-iam_role"
BUCKET_1="cmtr-4n6e9j62-iam-sewk-bucket-695267-1"
BUCKET_2="cmtr-4n6e9j62-iam-sewk-bucket-695267-2"
KMS_KEY_ARN="arn:aws:kms:eu-west-1:522814710681:key/cac96933-72ff-49e0-8734-753dcd4a0ff5"
FILE_NAME="confidential_credentials.csv"
```

### Шаг 1: KMS Policy для роли

```bash
# 1.1 Проверить роль существует
aws iam get-role --role-name cmtr-4n6e9j62-iam-sewk-iam_role

# 1.2 Создать inline policy для KMS доступа
aws iam put-role-policy \
    --role-name cmtr-4n6e9j62-iam-sewk-iam_role \
    --policy-name KMSAccessPolicy \
    --policy-document file://kms-policy.json

# 1.3 Проверить policy создан
aws iam get-role-policy \
    --role-name cmtr-4n6e9j62-iam-sewk-iam_role \
    --policy-name KMSAccessPolicy
```

#### kms-policy.json:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:eu-west-1:522814710681:key/cac96933-72ff-49e0-8734-753dcd4a0ff5"
    }
  ]
}
```

### Шаг 2: Enable Bucket Encryption

```bash
# 2.1 Проверить bucket существует
aws s3 ls s3://cmtr-4n6e9j62-iam-sewk-bucket-695267-2

# 2.2 Включить server-side encryption с KMS
aws s3api put-bucket-encryption \
    --bucket cmtr-4n6e9j62-iam-sewk-bucket-695267-2 \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "aws:kms",
                    "KMSMasterKeyID": "arn:aws:kms:eu-west-1:522814710681:key/cac96933-72ff-49e0-8734-753dcd4a0ff5"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'

# 2.3 Проверить encryption настроен
aws s3api get-bucket-encryption \
    --bucket cmtr-4n6e9j62-iam-sewk-bucket-695267-2
```

### Шаг 3: Копирование файла с KMS encryption

```bash
# 3.1 Проверить файл существует в bucket-1
aws s3 ls s3://cmtr-4n6e9j62-iam-sewk-bucket-695267-1/confidential_credentials.csv

# 3.2 Скопировать файл с KMS encryption
aws s3 cp \
    s3://cmtr-4n6e9j62-iam-sewk-bucket-695267-1/confidential_credentials.csv \
    s3://cmtr-4n6e9j62-iam-sewk-bucket-695267-2/confidential_credentials.csv \
    --sse aws:kms \
    --sse-kms-key-id arn:aws:kms:eu-west-1:522814710681:key/cac96933-72ff-49e0-8734-753dcd4a0ff5

# 3.3 Проверить файл в bucket-2
aws s3 ls s3://cmtr-4n6e9j62-iam-sewk-bucket-695267-2/confidential_credentials.csv

# 3.4 Проверить encryption файла
aws s3api head-object \
    --bucket cmtr-4n6e9j62-iam-sewk-bucket-695267-2 \
    --key confidential_credentials.csv
```

### Время: ~10 минут

---

## Метод 3: AWS Management Console 🖱️

### Шаг 1: KMS Policy для роли

1. Перейти в IAM → Roles
2. Найти `cmtr-4n6e9j62-iam-sewk-iam_role`
3. Permissions → Add inline policy
4. JSON:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:eu-west-1:522814710681:key/cac96933-72ff-49e0-8734-753dcd4a0ff5"
    }
  ]
}
```
5. Review policy → Name: `KMSAccessPolicy`
6. Create policy

### Шаг 2: Bucket Encryption

1. Перейти в S3 → Buckets
2. Найти `cmtr-4n6e9j62-iam-sewk-bucket-695267-2`
3. Properties → Default encryption → Edit
4. Encryption type: **Server-side encryption with AWS Key Management Service keys (SSE-KMS)**
5. AWS KMS key: **Enter AWS KMS key ARN**
6. ARN: `arn:aws:kms:eu-west-1:522814710681:key/cac96933-72ff-49e0-8734-753dcd4a0ff5`
7. Bucket Key: **Enable**
8. Save changes

### Шаг 3: Копирование файла

**Вариант A: Через Console (download + upload)**

1. Открыть bucket-1: `cmtr-4n6e9j62-iam-sewk-bucket-695267-1`
2. Найти файл `confidential_credentials.csv`
3. Download файл на локальный компьютер
4. Открыть bucket-2: `cmtr-4n6e9j62-iam-sewk-bucket-695267-2`
5. Upload → Add files → Выбрать скачанный файл
6. Server-side encryption settings:
   - Encryption type: **AWS KMS**
   - AWS KMS key: `arn:aws:kms:eu-west-1:522814710681:key/cac96933-72ff-49e0-8734-753dcd4a0ff5`
7. Upload

**Вариант B: Через AWS CLI (рекомендуется)**
```bash
aws s3 cp \
    s3://bucket-1/confidential_credentials.csv \
    s3://bucket-2/confidential_credentials.csv \
    --sse aws:kms \
    --sse-kms-key-id <KMS_KEY_ARN>
```

### Время: ~15 минут

---

## ✅ Верификация

### Проверка 1: KMS Policy на роли
```bash
aws iam get-role-policy \
    --role-name cmtr-4n6e9j62-iam-sewk-iam_role \
    --policy-name KMSAccessPolicy
```

**Ожидаемый результат:** Policy JSON с Actions: Encrypt, Decrypt, GenerateDataKey

### Проверка 2: Bucket Encryption
```bash
aws s3api get-bucket-encryption \
    --bucket cmtr-4n6e9j62-iam-sewk-bucket-695267-2
```

**Ожидаемый результат:**
```json
{
    "ServerSideEncryptionConfiguration": {
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "aws:kms",
                    "KMSMasterKeyID": "arn:aws:kms:..."
                }
            }
        ]
    }
}
```

### Проверка 3: File Encryption
```bash
aws s3api head-object \
    --bucket cmtr-4n6e9j62-iam-sewk-bucket-695267-2 \
    --key confidential_credentials.csv
```

**Ожидаемый результат:**
```json
{
    "ServerSideEncryption": "aws:kms",
    "SSEKMSKeyId": "arn:aws:kms:eu-west-1:522814710681:key/...",
    ...
}
```

---

## 📊 Ожидаемые результаты

| Проверка | Результат |
|----------|-----------|
| KMS Policy на роли | ✅ Существует |
| Bucket-2 encryption | ✅ SSE-KMS включен |
| File encryption | ✅ Зашифрован KMS |
| kms:Encrypt permission | ✅ allowed |
| kms:Decrypt permission | ✅ allowed |

---

## 💡 Ключевые концепции

### 1. AWS KMS
- Централизованное управление ключами
- Автоматическая ротация
- Integration с AWS сервисами
- CloudTrail audit logs

### 2. Server-Side Encryption (SSE-KMS)
- S3 шифрует при загрузке
- S3 дешифрует при чтении
- Прозрачно для приложения
- Требует KMS permissions

### 3. KMS Permissions
- **kms:Encrypt** - шифрование данных
- **kms:Decrypt** - дешифрование данных
- **kms:GenerateDataKey** - генерация data key для envelope encryption
- **kms:DescribeKey** - получение информации о ключе

### 4. Bucket Encryption Configuration
- По умолчанию для всех новых объектов
- Можно переопределить при upload
- Не шифрует существующие объекты

---

## 🎓 Что изучите

- ✅ AWS KMS (Key Management Service)
- ✅ Server-Side Encryption (SSE-KMS)
- ✅ KMS Permissions
- ✅ Bucket Encryption Configuration
- ✅ Envelope Encryption
- ✅ Data Keys vs Master Keys

---

## 🔐 Альтернативные методы копирования

### Метод A: S3 CP (рекомендуется)
```bash
aws s3 cp s3://bucket-1/file s3://bucket-2/file \
    --sse aws:kms \
    --sse-kms-key-id <KMS_KEY_ARN>
```

### Метод B: Download + Upload
```bash
# Download
aws s3 cp s3://bucket-1/file ./file

# Upload с encryption
aws s3 cp ./file s3://bucket-2/file \
    --sse aws:kms \
    --sse-kms-key-id <KMS_KEY_ARN>

# Cleanup
rm ./file
```

### Метод C: S3 Console
Download через browser → Upload с KMS settings

---

**Сложность:** Средняя  
**Время:** 2-15 минут (в зависимости от метода)
