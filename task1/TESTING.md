# Примеры тестирования и проверки

## Настройка окружения

```bash
export AWS_ACCESS_KEY_ID=AKIAZPPF72N7EHDWSCFI
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1
```

## 1. Проверка подключения

```bash
aws sts get-caller-identity
```

**Ожидаемый результат:**
```json
{
    "UserId": "AIDAZPPF72N7...",
    "Account": "651706749822",
    "Arn": "arn:aws:iam::651706749822:user/cmtr-4n6e9j62"
}
```

## 2. Проверка присоединенных политик к роли

```bash
aws iam list-attached-role-policies \
    --role-name cmtr-4n6e9j62-iam-peld-iam_role
```

**Ожидаемый результат:**
```json
{
    "AttachedPolicies": [
        {
            "PolicyName": "AmazonS3FullAccess",
            "PolicyArn": "arn:aws:iam::aws:policy/AmazonS3FullAccess"
        }
    ]
}
```

## 3. Проверка bucket policy

```bash
aws s3api get-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738 \
    --query Policy --output text | jq '.'
```

**Ожидаемый результат:**
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

## 4. Симуляция DeleteObject (должна быть запрещена)

```bash
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role \
    --action-names s3:DeleteObject \
    --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test-object
```

**Ожидаемый результат:**
```json
{
    "EvaluationResults": [
        {
            "EvalActionName": "s3:DeleteObject",
            "EvalResourceName": "arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test-object",
            "EvalDecision": "explicitDeny",
            "MatchedStatements": [
                {
                    "SourcePolicyId": "BucketPolicy",
                    "SourcePolicyType": "IAM Policy",
                    "StartPosition": {...},
                    "EndPosition": {...}
                }
            ]
        }
    ]
}
```

✅ **EvalDecision должен быть "explicitDeny"**

## 5. Симуляция GetObject (должна быть разрешена)

```bash
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role \
    --action-names s3:GetObject \
    --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test-object
```

**Ожидаемый результат:**
```json
{
    "EvaluationResults": [
        {
            "EvalActionName": "s3:GetObject",
            "EvalResourceName": "arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test-object",
            "EvalDecision": "allowed",
            "MatchedStatements": [
                {
                    "SourcePolicyId": "AmazonS3FullAccess",
                    "SourcePolicyType": "IAM Policy"
                }
            ]
        }
    ]
}
```

✅ **EvalDecision должен быть "allowed"**

## 6. Симуляция PutObject (должна быть разрешена)

```bash
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role \
    --action-names s3:PutObject \
    --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test-object
```

**Ожидаемый результат:**
```json
{
    "EvaluationResults": [
        {
            "EvalActionName": "s3:PutObject",
            "EvalDecision": "allowed"
        }
    ]
}
```

✅ **EvalDecision должен быть "allowed"**

## 7. Симуляция множества действий одновременно

```bash
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role \
    --action-names s3:GetObject s3:PutObject s3:DeleteObject s3:ListBucket \
    --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test-object
```

**Ожидаемый результат:**
```json
{
    "EvaluationResults": [
        {
            "EvalActionName": "s3:GetObject",
            "EvalDecision": "allowed"
        },
        {
            "EvalActionName": "s3:PutObject",
            "EvalDecision": "allowed"
        },
        {
            "EvalActionName": "s3:DeleteObject",
            "EvalDecision": "explicitDeny"
        },
        {
            "EvalActionName": "s3:ListBucket",
            "EvalDecision": "allowed"
        }
    ]
}
```

✅ **Только DeleteObject должен быть "explicitDeny"**

## 8. Детальная информация о роли

```bash
aws iam get-role --role-name cmtr-4n6e9j62-iam-peld-iam_role
```

## 9. Информация о bucket

```bash
# Локация bucket
aws s3api get-bucket-location --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738

# Версионирование
aws s3api get-bucket-versioning --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738

# ACL
aws s3api get-bucket-acl --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738
```

## 10. Тестирование через AWS Policy Simulator (Web UI)

1. Откройте: https://policysim.aws.amazon.com/
2. Выберите **IAM Role** → `cmtr-4n6e9j62-iam-peld-iam_role`
3. Выберите **Amazon S3** сервис
4. Установите флажок на **DeleteObject**
5. В поле **Simulation Settings**:
   - Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/*`
6. Нажмите **Run Simulation**

**Ожидаемый результат:** ❌ **Permission: Denied**

## Чеклист проверки

- [ ] AWS credentials настроены
- [ ] Подключение к AWS работает
- [ ] AmazonS3FullAccess присоединена к роли
- [ ] Bucket policy содержит Deny для DeleteObject
- [ ] DeleteObject возвращает "explicitDeny"
- [ ] GetObject возвращает "allowed"
- [ ] PutObject возвращает "allowed"
- [ ] ListBucket возвращает "allowed"

## Troubleshooting

### Ошибка: "An error occurred (NoSuchBucket)"
```bash
# Проверьте, что bucket существует и регион правильный
aws s3api list-buckets --query "Buckets[?contains(Name, 'iam-peld')]"
```

### Ошибка: "An error occurred (NoSuchEntity) when calling GetRole"
```bash
# Проверьте, что роль существует
aws iam list-roles --query "Roles[?contains(RoleName, 'iam-peld')]"
```

### Ошибка: "An error occurred (InvalidClientTokenId)"
```bash
# Проверьте AWS credentials
aws sts get-caller-identity
```

### Ошибка: "An error occurred (AccessDenied)"
```bash
# Проверьте права текущего пользователя
aws iam get-user
aws iam list-attached-user-policies --user-name cmtr-4n6e9j62
```

## Полезные команды для отладки

```bash
# Получить все политики, применимые к роли
aws iam get-role-policy --role-name cmtr-4n6e9j62-iam-peld-iam_role --policy-name <policy-name>

# Список inline политик роли
aws iam list-role-policies --role-name cmtr-4n6e9j62-iam-peld-iam_role

# Получить конкретную версию managed policy
aws iam get-policy-version \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
    --version-id v1

# CloudTrail для аудита (если включен)
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=ResourceName,AttributeValue=cmtr-4n6e9j62-iam-peld-bucket-2911738 \
    --max-results 10
```
