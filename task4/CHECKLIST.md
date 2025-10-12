# ✅ Чеклист Task 4 - KMS Encryption

## 📋 Предварительная подготовка

- [ ] AWS CLI установлен
- [ ] Credentials настроены
- [ ] Region: eu-west-1

## 🎯 Выполнение (3 шага)

### Шаг 1: KMS Policy для роли
- [ ] Создан `kms-policy.json`
- [ ] Actions: Encrypt, Decrypt, GenerateDataKey, DescribeKey
- [ ] Resource: KMS key ARN
- [ ] Выполнена команда `put-role-policy`
- [ ] Проверено

```bash
aws iam put-role-policy \
    --role-name cmtr-4n6e9j62-iam-sewk-iam_role \
    --policy-name KMSAccessPolicy \
    --policy-document file://kms-policy.json
```

### Шаг 2: Bucket Encryption
- [ ] Bucket-2 существует
- [ ] SSEAlgorithm: aws:kms
- [ ] KMSMasterKeyID: правильный ARN
- [ ] Выполнена команда `put-bucket-encryption`
- [ ] Проверено

```bash
aws s3api put-bucket-encryption \
    --bucket cmtr-4n6e9j62-iam-sewk-bucket-695267-2 \
    --server-side-encryption-configuration ...
```

### Шаг 3: Копирование файла
- [ ] Файл существует в bucket-1
- [ ] Выполнена команда `s3 cp` с KMS параметрами
- [ ] Файл появился в bucket-2
- [ ] Файл зашифрован KMS
- [ ] Проверено

```bash
aws s3 cp s3://bucket-1/confidential_credentials.csv \
    s3://bucket-2/confidential_credentials.csv \
    --server-side-encryption aws:kms \
    --ssekms-key-id <KMS_KEY_ARN>
```

---

## ✅ Верификация

### Тест 1: KMS Policy (на роли)
- [ ] Policy существует
- [ ] Имеет все необходимые Actions
- [ ] Resource указывает на правильный KMS key

### Тест 2: Bucket Encryption (на bucket-2)
- [ ] Server-side encryption включен
- [ ] Использует aws:kms алгоритм
- [ ] KMS key ARN правильный

### Тест 3: File Encryption (confidential_credentials.csv)
- [ ] Файл существует в bucket-2
- [ ] ServerSideEncryption: aws:kms
- [ ] SSEKMSKeyId: правильный ARN

---

## 📊 Матрица проверки

| Компонент | Статус |
|-----------|--------|
| IAM Role: KMS Policy | [ ] |
| Bucket-2: Server-Side Encryption | [ ] |
| File: KMS Encrypted | [ ] |

---

## 🎯 Итог

- [ ] 3 шага выполнены
- [ ] Роль может работать с KMS ключом
- [ ] Bucket-2 шифрует все объекты
- [ ] Файл скопирован и зашифрован
- [ ] Все тесты пройдены

---

**Статус:** ✅ COMPLETED
