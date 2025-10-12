# Архитектура и концепции Task 2

## Визуальная схема решения

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS ACCOUNT: 863518426750                     │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │              IAM ROLE                                  │     │
│  │    cmtr-4n6e9j62-iam-pela-iam_role                    │     │
│  │                                                        │     │
│  │  ┌──────────────────────────────────────────────┐     │     │
│  │  │  INLINE POLICY                              │     │     │
│  │  │  Name: ListAllBucketsPolicy                 │     │     │
│  │  │                                              │     │     │
│  │  │  Effect: ALLOW                              │     │     │
│  │  │  Action: s3:ListAllMyBuckets                │     │     │
│  │  │  Resource: *                                 │     │     │
│  │  │                                              │     │     │
│  │  │  ✓ Просмотр списка ВСЕХ buckets            │     │     │
│  │  └──────────────────────────────────────────────┘     │     │
│  └────────────────────────────────────────────────────────┘     │
│                              │                                   │
│                              │ Пытается получить доступ         │
│                              ▼                                   │
│  ┌────────────────────────────────────────────────────────┐     │
│  │        S3 BUCKET 1 (основной)                         │     │
│  │    cmtr-4n6e9j62-iam-pela-bucket-1-162653            │     │
│  │                                                        │     │
│  │  ┌──────────────────────────────────────────────┐     │     │
│  │  │  BUCKET POLICY                              │     │     │
│  │  │                                              │     │     │
│  │  │  Effect: ALLOW ✅                            │     │     │
│  │  │  Principal: роль                             │     │     │
│  │  │  Actions:                                    │     │     │
│  │  │    - s3:GetObject                           │     │     │
│  │  │    - s3:PutObject                           │     │     │
│  │  │    - s3:ListBucket                          │     │     │
│  │  │  Resource:                                   │     │     │
│  │  │    - bucket ARN (для ListBucket)            │     │     │
│  │  │    - bucket/* ARN (для Get/Put)             │     │     │
│  │  │                                              │     │     │
│  │  │  ✅ ДОСТУП РАЗРЕШЕН                          │     │     │
│  │  └──────────────────────────────────────────────┘     │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │        S3 BUCKET 2 (для проверки)                     │     │
│  │    cmtr-4n6e9j62-iam-pela-bucket-2-162653            │     │
│  │                                                        │     │
│  │  ┌──────────────────────────────────────────────┐     │     │
│  │  │  NO BUCKET POLICY                           │     │     │
│  │  │                                              │     │     │
│  │  │  ❌ IMPLICIT DENY                            │     │     │
│  │  │  Нет явного разрешения = запрет             │     │     │
│  │  └──────────────────────────────────────────────┘     │     │
│  └────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

## Матрица разрешений

| Действие | Inline Policy | Bucket-1 Policy | Bucket-2 Policy | Результат Bucket-1 | Результат Bucket-2 |
|----------|--------------|-----------------|-----------------|-------------------|-------------------|
| ListAllMyBuckets | ALLOW ✅ | - | - | ALLOW ✅ | ALLOW ✅ |
| ListBucket | - | ALLOW ✅ | - | ALLOW ✅ | DENY ❌ |
| GetObject | - | ALLOW ✅ | - | ALLOW ✅ | DENY ❌ |
| PutObject | - | ALLOW ✅ | - | ALLOW ✅ | DENY ❌ |

## Policy Evaluation Logic для Task 2

```
Запрос: GetObject для bucket-1
    ↓
1. Есть Explicit DENY? → НЕТ
    ↓
2. Есть ALLOW в Identity Policy? → НЕТ (inline policy не покрывает GetObject)
    ↓
3. Есть ALLOW в Resource Policy? → ДА (bucket policy разрешает)
    ↓
РЕЗУЛЬТАТ: ALLOW ✅
```

```
Запрос: GetObject для bucket-2
    ↓
1. Есть Explicit DENY? → НЕТ
    ↓
2. Есть ALLOW в Identity Policy? → НЕТ
    ↓
3. Есть ALLOW в Resource Policy? → НЕТ (bucket policy отсутствует)
    ↓
РЕЗУЛЬТАТ: IMPLICIT DENY ❌
```

## Ключевые концепции

### 1. Inline Policy vs Managed Policy

| Аспект | Inline Policy | Managed Policy |
|--------|--------------|----------------|
| Хранение | Встроена в роль/пользователя | Отдельная сущность |
| Переиспользование | ❌ Нет | ✅ Да |
| Версионирование | ❌ Нет | ✅ Да |
| Когда использовать | Уникальные права для одной роли | Общие права для нескольких ролей |
| Пример в Task 2 | ListAllBucketsPolicy | - |

### 2. Resource ARN в Bucket Policy

**Важно!** Bucket Policy требует ДВУХ Resource ARN:

```json
"Resource": [
  "arn:aws:s3:::bucket-name",      // Для ListBucket
  "arn:aws:s3:::bucket-name/*"     // Для GetObject, PutObject
]
```

**Почему?**
- `ListBucket` - операция на уровне bucket
- `GetObject`, `PutObject` - операции на уровне объектов

### 3. Implicit Deny

В Task 2 bucket-2 демонстрирует концепцию **Implicit Deny**:
- Нет явного запрета (Explicit Deny)
- Нет явного разрешения (Allow)
- Результат: доступ запрещен (Implicit Deny)

### 4. Комбинирование политик

```
Identity-based Policy (Inline)
          +
Resource-based Policy (Bucket)
          =
    Гранулярный контроль доступа
```

## Отличия от Task 1

| Аспект | Task 1 | Task 2 |
|--------|--------|--------|
| **Identity Policy** | AWS Managed | **Inline (custom)** |
| **Тип политики на bucket** | Deny (запрет) | **Allow (разрешение)** |
| **Количество buckets** | 1 | **2** |
| **Логика** | Explicit Deny побеждает | **Implicit Deny при отсутствии Allow** |
| **Цель** | Запретить DeleteObject | **Разрешить доступ к одному bucket** |
| **Сложность** | Средняя | **Средняя-Высокая** |

## Практические применения

### Когда использовать Inline Policy:
- ✅ Уникальные права, специфичные для одной роли
- ✅ Временные разрешения
- ✅ Proof-of-concept проекты
- ✅ Когда политика не будет переиспользоваться

### Когда использовать Bucket Policy:
- ✅ Кросс-аккаунт доступ
- ✅ Разрешения для конкретных Principal
- ✅ Комбинация с Identity-based политиками
- ✅ Публичный доступ к bucket (с осторожностью!)

## Безопасность

### Best Practices:
1. ✅ Используйте принцип минимальных привилегий
2. ✅ Указывайте конкретные Principal (не используйте "*")
3. ✅ Указывайте конкретные Resource ARN
4. ✅ Регулярно проверяйте политики через Policy Simulator
5. ✅ Используйте CloudTrail для аудита

### Распространенные ошибки:
1. ❌ Забыть указать оба Resource ARN в bucket policy
2. ❌ Использовать только bucket/* без bucket ARN
3. ❌ Создать политику для bucket-2 (он должен остаться без политики)
4. ❌ Не проверить результат через Policy Simulator
5. ❌ Перепутать Principal ARN

## Схема потоков

```
ListAllMyBuckets:
User/App → IAM Role (Inline Policy: ALLOW) → S3 Service → SUCCESS ✅

GetObject для bucket-1:
User/App → IAM Role (нет политики) → Bucket-1 (Policy: ALLOW) → SUCCESS ✅

GetObject для bucket-2:
User/App → IAM Role (нет политики) → Bucket-2 (нет policy) → DENIED ❌
```

## Итоговая схема доступа

```
IAM Role
   ├─ Inline Policy: ListAllMyBuckets
   │  └─ Может видеть ВСЕ buckets ✅
   │
   ├─ Bucket-1 Policy: Allow Get/Put/List
   │  └─ Может работать с объектами ✅
   │
   └─ Bucket-2: NO POLICY
      └─ НЕ может работать с объектами ❌
```
