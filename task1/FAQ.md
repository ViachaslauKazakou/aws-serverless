# FAQ - Часто задаваемые вопросы

## Общие вопросы

### Q: Что такое "один move" в задаче?
**A:** "Один move" - это одно действие по созданию, обновлению или удалению AWS ресурса. В нашей задаче:
- **Move 1**: Присоединение AWS Managed Policy к роли
- **Move 2**: Обновление bucket policy

### Q: Почему именно эти два шага?
**A:** Задача демонстрирует взаимодействие двух типов политик:
1. **Identity-based policy** - политика, присоединенная к IAM сущности (роли)
2. **Resource-based policy** - политика, присоединенная к ресурсу (S3 bucket)

### Q: Можно ли решить задачу другим способом?
**A:** Теоретически да, но задание требует:
- Использовать **существующую** AWS Managed Policy (не создавать свою)
- Обновить **bucket policy** (а не создавать inline policy на роли)

## Технические вопросы

### Q: Почему используется `AmazonS3FullAccess`, а не другая политика?
**A:** Задание требует предоставить "full access to the Amazon S3 service". `AmazonS3FullAccess` - стандартная AWS Managed Policy для полного доступа к S3.

### Q: Что произойдет, если не добавить Deny в bucket policy?
**A:** Роль сможет удалять объекты, так как `AmazonS3FullAccess` разрешает все операции S3, включая `s3:DeleteObject`.

### Q: Почему Deny побеждает Allow?
**A:** Это фундаментальный принцип AWS IAM Policy Evaluation Logic:
```
1. По умолчанию все запрещено (implicit deny)
2. Если есть explicit deny - запрос отклонен
3. Если есть allow и нет deny - запрос разрешен
4. Если нет allow - запрос отклонен (implicit deny)
```

### Q: Можно ли использовать inline policy вместо bucket policy?
**A:** Технически да, но:
- Задание требует обновить **bucket policy**
- Resource-based политика демонстрирует другой подход к управлению доступом
- Это позволяет управлять доступом на стороне ресурса, а не identity

## Вопросы по Policy Simulator

### Q: Где находится Policy Simulator?
**A:** Есть два способа:
1. **Web UI**: https://policysim.aws.amazon.com/
2. **AWS CLI**: `aws iam simulate-principal-policy`

### Q: Что показывает Policy Simulator?
**A:** Симулятор показывает:
- Будет ли действие разрешено или запрещено
- Какие политики повлияли на решение
- Причину разрешения/запрета

### Q: Какие действия нужно тестировать?
**A:** Обязательно:
- ✅ `s3:DeleteObject` - должно быть **denied**

Опционально (для полноты картины):
- ✅ `s3:GetObject` - должно быть **allowed**
- ✅ `s3:PutObject` - должно быть **allowed**
- ✅ `s3:ListBucket` - должно быть **allowed**

## Вопросы по AWS CLI

### Q: Как установить AWS CLI?
**A:** 
```bash
# macOS (Homebrew)
brew install awscli

# macOS (официальный установщик)
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Проверка
aws --version
```

### Q: Как настроить credentials?
**A:** Два способа:

**Вариант 1: Переменные окружения (временно)**
```bash
export AWS_ACCESS_KEY_ID=AKIAZPPF72N7EHDWSCFI
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1
```

**Вариант 2: AWS Configure (постоянно)**
```bash
aws configure
# Введите Access Key ID, Secret Access Key, region
```

### Q: Как проверить, что credentials работают?
**A:**
```bash
aws sts get-caller-identity
```

Должно вернуть информацию о пользователе.

## Вопросы по безопасности

### Q: Безопасно ли хранить credentials в скрипте?
**A:** 
- ❌ **НЕТ** для production
- ✅ **ДА** для учебных целей (sandbox environment)
- В production используйте IAM roles, AWS Secrets Manager, или переменные окружения

### Q: Как защитить данные от удаления в production?
**A:** Несколько уровней защиты:
1. **Bucket Policy с Deny** (как в задаче)
2. **S3 Object Lock** - физическая защита от удаления
3. **S3 Versioning** - сохранение версий объектов
4. **MFA Delete** - требование MFA для удаления
5. **Backup** - регулярные резервные копии

### Q: Что такое AWS Sandbox Environment?
**A:** Изолированная учебная среда AWS с ограниченным временем жизни и ресурсами. Безопасна для экспериментов.

## Вопросы по bucket policy

### Q: Что означает `/*` в Resource ARN?
**A:**
```
arn:aws:s3:::bucket-name/*
                         ^^
                         |
         Все объекты внутри bucket
```

Без `/*` политика применялась бы к самому bucket, а не к объектам внутри.

### Q: Можно ли запретить удаление для всех ролей?
**A:** Да:
```json
{
  "Effect": "Deny",
  "Principal": "*",
  "Action": "s3:DeleteObject",
  "Resource": "arn:aws:s3:::bucket-name/*"
}
```

### Q: Можно ли разрешить удаление только для определенных объектов?
**A:** Да, используя условия:
```json
{
  "Effect": "Deny",
  "Action": "s3:DeleteObject",
  "Resource": "arn:aws:s3:::bucket-name/*",
  "Condition": {
    "StringNotEquals": {
      "s3:prefix": "deletable/"
    }
  }
}
```

## Troubleshooting

### Q: Ошибка "An error occurred (NoSuchBucket)"
**A:** Проверьте:
- Правильность имени bucket
- Регион (bucket находится в eu-west-1)
- Существование bucket:
```bash
aws s3api list-buckets | grep iam-peld
```

### Q: Ошибка "An error occurred (AccessDenied)"
**A:** Проверьте:
- Правильность credentials
- Права текущего пользователя
- Bucket policy не блокирует вас

### Q: Ошибка "Policy document should not specify a principal"
**A:** Эта ошибка возникает, если вы пытаетесь использовать bucket policy syntax для inline policy роли. Bucket policy **должна** содержать Principal, inline policy - **не должна**.

### Q: Симулятор показывает "allowed", но ожидается "denied"
**A:** Проверьте:
- Bucket policy действительно применена
- Правильный ARN роли в Principal
- Правильный ARN ресурса в Resource
- Action точно совпадает (s3:DeleteObject)

## Концептуальные вопросы

### Q: В чем разница между Identity-based и Resource-based policy?
**A:**

| Аспект | Identity-based | Resource-based |
|--------|----------------|----------------|
| Присоединена к | IAM identity (user/role/group) | AWS Resource (S3/SQS/etc) |
| Может указывать Principal? | ❌ Нет | ✅ Да |
| Пример | IAM Policy на роли | S3 Bucket Policy |
| Управление | Через IAM | Через сервис ресурса |

### Q: Что такое Policy Evaluation Logic?
**A:** Алгоритм, который AWS использует для определения, разрешено ли действие:

```
START
  ↓
Default: DENY
  ↓
Есть Explicit DENY? → YES → DENY ❌
  ↓ NO
Есть ALLOW? → YES → ALLOW ✅
  ↓ NO
DENY ❌ (implicit)
```

### Q: Когда использовать Bucket Policy, а когда IAM Policy?
**A:**

**Bucket Policy:**
- ✅ Управление доступом к bucket для разных аккаунтов
- ✅ Публичный доступ к bucket
- ✅ Условия на уровне ресурса

**IAM Policy:**
- ✅ Управление доступом для пользователей/ролей
- ✅ Ограничения на уровне identity
- ✅ Centralized управление правами

## Дополнительные материалы

### Q: Где можно узнать больше о IAM?
**A:** 
- 📚 [AWS IAM Documentation](https://docs.aws.amazon.com/iam/)
- 📚 [AWS Policy Evaluation Logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html)
- 📚 [S3 Bucket Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-policies.html)

### Q: Какие еще AWS Managed Policies существуют для S3?
**A:**
- `AmazonS3FullAccess` - полный доступ
- `AmazonS3ReadOnlyAccess` - только чтение
- `AmazonS3ObjectLambdaExecutionRolePolicy` - для Lambda с S3
- `AWSBackupServiceRolePolicyForS3Backup` - для бэкапов
- `AWSBackupServiceRolePolicyForS3Restore` - для восстановления

### Q: Как посмотреть содержимое AWS Managed Policy?
**A:**
```bash
# Получить ARN и версию
aws iam get-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Получить содержимое
aws iam get-policy-version \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
    --version-id v1
```
