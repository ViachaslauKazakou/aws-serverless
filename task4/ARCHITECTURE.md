# 🏛️ ARCHITECTURE - Task 4: KMS Encryption

## 🎯 Архитектурный обзор

Task 4 демонстрирует **Server-Side Encryption с AWS KMS** - механизм автоматического шифрования данных в S3 используя управляемые криптографические ключи.

## 📐 Архитектурные диаграммы

### Диаграмма 1: Общая архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                   AWS Account: 522814710681                 │
│                                                             │
│  ┌──────────────────────┐         ┌──────────────────────┐ │
│  │   IAM Role           │         │   KMS Key            │ │
│  │  cmtr-4n6e9j62-      │         │  cac96933-72ff-...   │ │
│  │  iam-sewk-iam_role   │         │                      │ │
│  │                      │         │  Permissions:        │ │
│  │  Inline Policy:      │───────▶ │  ✅ Used for         │ │
│  │  ✅ kms:Encrypt      │         │     encryption       │ │
│  │  ✅ kms:Decrypt      │         │  ✅ Bucket-2 only    │ │
│  │  ✅ GenerateDataKey  │         │                      │ │
│  │  ✅ DescribeKey      │         │                      │ │
│  └──────────────────────┘         └──────────┬───────────┘ │
│                                               │             │
│                                               │ Encrypts    │
│                                               ▼             │
│  ┌──────────────────────┐         ┌──────────────────────┐ │
│  │   Bucket-1           │         │   Bucket-2           │ │
│  │  bucket-695267-1     │         │  bucket-695267-2     │ │
│  │                      │         │                      │ │
│  │  confidential_       │────────▶│  confidential_       │ │
│  │  credentials.csv     │  Copy   │  credentials.csv     │ │
│  │  (no encryption)     │         │  ✅ KMS encrypted    │ │
│  │                      │         │                      │ │
│  │                      │         │  Encryption:         │ │
│  │                      │         │  SSE-KMS enabled     │ │
│  └──────────────────────┘         └──────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Диаграмма 2: Поток шифрования (Envelope Encryption)

```
┌─────────────────┐
│  S3 PutObject   │
│  Request        │
└────────┬────────┘
         │
         │ 1. Request data key from KMS
         ▼
┌─────────────────────────────────┐
│  AWS KMS                        │
│  Key: cac96933-72ff...          │
└────────┬────────────────────────┘
         │
         │ 2. Generate Data Key
         │    - Plaintext Data Key
         │    - Encrypted Data Key
         ▼
┌─────────────────────────────────┐
│  S3 Service                     │
│  - Encrypts object with         │
│    Plaintext Data Key           │
│  - Stores Encrypted Data Key    │
│    with object metadata         │
└────────┬────────────────────────┘
         │
         │ 3. Store encrypted object
         ▼
┌─────────────────────────────────┐
│  S3 Bucket-2                    │
│  - Object (encrypted)           │
│  - Metadata (Encrypted Data Key)│
└─────────────────────────────────┘

При чтении (GetObject):
┌─────────────────┐
│  S3 GetObject   │
└────────┬────────┘
         │ 4. Retrieve Encrypted Data Key
         ▼
┌─────────────────────────────────┐
│  AWS KMS                        │
│  - Decrypt Data Key             │
└────────┬────────────────────────┘
         │ 5. Return Plaintext Data Key
         ▼
┌─────────────────────────────────┐
│  S3 Service                     │
│  - Decrypt object with          │
│    Plaintext Data Key           │
│  - Return to client             │
└─────────────────────────────────┘
```

### Диаграмма 3: Конфигурация компонентов

```
┌───────────────────────────────────────────────────────────────┐
│                         IAM Role                              │
├───────────────────────────────────────────────────────────────┤
│  Inline Policy: KMSAccessPolicy                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ {                                                       │ │
│  │   "Effect": "Allow",                                    │ │
│  │   "Action": [                                           │ │
│  │     "kms:Encrypt",                                      │ │
│  │     "kms:Decrypt",                                      │ │
│  │     "kms:ReEncrypt*",                                   │ │
│  │     "kms:GenerateDataKey*",                             │ │
│  │     "kms:DescribeKey"                                   │ │
│  │   ],                                                    │ │
│  │   "Resource": "arn:aws:kms:...:key/cac96933..."        │ │
│  │ }                                                       │ │
│  └─────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
                              │
                              │ Uses KMS key
                              ▼
┌───────────────────────────────────────────────────────────────┐
│                        Bucket-2                               │
├───────────────────────────────────────────────────────────────┤
│  Server-Side Encryption Configuration                         │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ {                                                       │ │
│  │   "Rules": [                                            │ │
│  │     {                                                   │ │
│  │       "ApplyServerSideEncryptionByDefault": {           │ │
│  │         "SSEAlgorithm": "aws:kms",                      │ │
│  │         "KMSMasterKeyID": "arn:aws:kms:..."            │ │
│  │       },                                                │ │
│  │       "BucketKeyEnabled": true                          │ │
│  │     }                                                   │ │
│  │   ]                                                     │ │
│  │ }                                                       │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  Objects:                                                     │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ confidential_credentials.csv                            │ │
│  │ - ServerSideEncryption: aws:kms                         │ │
│  │ - SSEKMSKeyId: arn:aws:kms:...:key/cac96933...          │ │
│  │ - Encrypted: YES ✅                                      │ │
│  └─────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
```

## 🔐 Encryption Flow

### При загрузке файла (PutObject):

```
1. Client → S3: PutObject request
   ↓
2. S3 → KMS: GenerateDataKey(KeyId=cac96933...)
   ↓
3. KMS → S3: Returns {PlaintextKey, EncryptedKey}
   ↓
4. S3: Encrypts object with PlaintextKey
   ↓
5. S3: Stores encrypted object + EncryptedKey in metadata
   ↓
6. S3: Deletes PlaintextKey from memory
   ↓
7. S3 → Client: Success response
```

### При чтении файла (GetObject):

```
1. Client → S3: GetObject request
   ↓
2. S3: Retrieves EncryptedKey from object metadata
   ↓
3. S3 → KMS: Decrypt(EncryptedKey)
   ↓
4. KMS: Checks permissions (kms:Decrypt)
   ↓
5. KMS → S3: Returns PlaintextKey
   ↓
6. S3: Decrypts object with PlaintextKey
   ↓
7. S3 → Client: Returns decrypted object
   ↓
8. S3: Deletes PlaintextKey from memory
```

## 📊 Компоненты системы

| Компонент | Тип | Назначение |
|-----------|-----|------------|
| IAM Role | Identity | Определяет кто может использовать KMS ключ |
| KMS Key | Encryption Key | Master key для envelope encryption |
| Inline Policy | Identity-based | Разрешает KMS операции для роли |
| Bucket-2 | S3 Bucket | Хранит зашифрованные объекты |
| SSE Configuration | Bucket Setting | Автоматическое шифрование новых объектов |

## 🎯 Три столпа конфигурации

### 1. IAM Policy (KMS Permissions)
```
WHO: IAM Role
WHAT: kms:Encrypt, kms:Decrypt, kms:GenerateDataKey
WHERE: Specific KMS Key ARN
```

### 2. Bucket Encryption Configuration
```
WHAT: Server-Side Encryption
HOW: aws:kms algorithm
WHICH KEY: Specific KMS Key ARN
```

### 3. Object Encryption
```
WHEN: Object upload
HOW: Automatic via bucket configuration
RESULT: Encrypted object + metadata
```

## 💡 Ключевые концепции

### Server-Side Encryption (SSE-KMS)
- **Определение:** S3 автоматически шифрует объекты при загрузке используя KMS ключ
- **Прозрачность:** Клиент не видит процесс шифрования/дешифрования
- **Требования:** IAM permissions на KMS операции

### Envelope Encryption
- **Определение:** Двухуровневое шифрование (Data Key + Master Key)
- **Data Key:** Уникальный ключ для каждого объекта (генерируется KMS)
- **Master Key:** KMS ключ шифрует Data Keys
- **Преимущество:** Производительность + безопасность

### KMS Permissions
- **kms:Encrypt** - шифрование данных
- **kms:Decrypt** - дешифрование данных
- **kms:GenerateDataKey** - генерация data key для envelope encryption
- **kms:ReEncrypt** - перешифрование без plaintext в памяти
- **kms:DescribeKey** - получение информации о ключе

### Bucket Key
- **Определение:** Временный ключ для уменьшения KMS requests
- **Преимущество:** Снижение стоимости + производительность
- **Срок действия:** Ограниченное время

## 🔄 Сравнение методов шифрования

| Метод | Master Key | Data Key | Performance |
|-------|------------|----------|-------------|
| SSE-S3 | AWS managed | AWS managed | High |
| SSE-KMS | KMS (customer) | KMS generated | Medium |
| SSE-C | Customer provided | Customer provided | High |
| CSE | Customer managed | Customer managed | Medium |

## 🛡️ Безопасность

### Преимущества SSE-KMS:

1. **Централизованное управление** - все ключи в KMS
2. **Автоматическая ротация** - опциональная ротация master keys
3. **Audit trail** - CloudTrail логирует все KMS операции
4. **Least privilege** - гранулярные IAM permissions
5. **Compliance** - соответствие стандартам (PCI-DSS, HIPAA)

### Best Practices:

- ✅ Использовать отдельные KMS keys для разных окружений
- ✅ Включать Bucket Key для снижения стоимости
- ✅ Минимизировать KMS permissions (только необходимые Actions)
- ✅ Мониторить KMS usage через CloudWatch
- ✅ Включать KMS key rotation

## 📈 Use Cases

1. **Compliance** - данные должны быть зашифрованы (регуляторные требования)
2. **Sensitive data** - персональные данные, финансовая информация
3. **Multi-tenant** - изоляция данных разных клиентов через разные KMS keys
4. **Audit** - необходимость логирования доступа к данным

## 🎓 Сравнение с предыдущими задачами

| Task | Фокус | Key Security Mechanism |
|------|-------|------------------------|
| Task 1 | Explicit Deny | Resource-based Policy (Bucket) |
| Task 2 | Inline + Implicit Deny | Identity-based Policy |
| Task 3 | Role Assumption | Trust Policy + STS |
| Task 4 | Encryption | KMS + Server-Side Encryption |

## 💰 Cost Considerations

### KMS Pricing (приблизительно):
- Master key: ~$1/month
- API requests: ~$0.03 per 10,000 requests
- Bucket Key: Снижает requests на ~99%

### Пример:
- Без Bucket Key: 1M uploads = $3.00
- С Bucket Key: 1M uploads = ~$0.03

## 📊 Performance

| Операция | Без Bucket Key | С Bucket Key |
|----------|----------------|--------------|
| PutObject | 1 KMS request | 1 KMS request per time window |
| GetObject | 1 KMS request | 1 KMS request per time window |
| Latency | +10-30ms | +1-5ms (cached) |

## 🔍 Troubleshooting

### Ошибка: Access Denied при upload
**Причина:** Нет kms:GenerateDataKey permission  
**Решение:** Добавить в IAM policy

### Ошибка: Access Denied при download
**Причина:** Нет kms:Decrypt permission  
**Решение:** Добавить в IAM policy

### Ошибка: Invalid KMS key
**Причина:** Неправильный ARN или key не существует  
**Решение:** Проверить ARN через `aws kms describe-key`

---

**Сложность:** Средняя  
**Ключевая концепция:** Server-Side Encryption + Envelope Encryption
