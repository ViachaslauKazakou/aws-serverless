# 🚀 Quick Start: Task 5

## ⏱️ Время выполнения: 5 минут

## 🎯 Цель
Настроить Lambda + API Gateway permissions за 5 минут.

## 📋 Pre-requisites

- AWS CLI установлен
- bash shell
- curl (для тестирования)

## 🚀 Шаги

### 1. Setup Credentials (30 секунд)

```bash
export AWS_ACCESS_KEY_ID=AKIAR7HWYB7GGJEF5KH7
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1
```

### 2. Run Setup Script (3 минуты)

```bash
cd task5
chmod +x setup-iam-task5.sh
./setup-iam-task5.sh
```

### 3. Verify (1 минута)

```bash
# Получить API endpoint
API_ENDPOINT=$(aws apigatewayv2 get-apis \
    --query "Items[?Name=='cmtr-4n6e9j62-iam-lp-apigwv2_api'].ApiEndpoint" \
    --output text)

# Test API
curl $API_ENDPOINT
```

**Ожидается:** JSON с списком Lambda функций

## ✅ Success Criteria

Скрипт должен вывести:
```
✅ AWSLambda_ReadOnlyAccess успешно присоединен к роли
✅ Permission для API Gateway добавлен
✅ AWSLambda_ReadOnlyAccess найден на роли
✅ Lambda permission для API Gateway настроен
✅ API успешно отвечает (HTTP 200)
✅ Task 5 выполнен успешно!
```

## 🎉 Готово!

Теперь:
- Lambda может читать список Lambda функций
- API Gateway может вызывать Lambda функцию
- HTTP запросы к API работают

## 📖 Дальше

- **INSTRUCTIONS.md** - подробные инструкции
- **ARCHITECTURE.md** - архитектура решения
- **commands.sh** - все команды для ручного выполнения

## 🆘 Проблемы?

### "Permission already exists"
✅ Это нормально - permission уже был добавлен

### API returns 403
```bash
# Проверить Lambda permission
aws lambda get-policy --function-name cmtr-4n6e9j62-iam-lp-lambda
```

### Lambda не может получить список функций
```bash
# Проверить attached policies
aws iam list-attached-role-policies --role-name cmtr-4n6e9j62-iam-lp-iam_role
```

## 💡 Что происходит внутри

**Шаг 1**: Attach `AWSLambda_ReadOnlyAccess` к execution role
- Даёт Lambda права на `lambda:ListFunctions`

**Шаг 2**: Add Lambda permission для API Gateway
- Разрешает API Gateway вызывать Lambda функцию

**Две разные концепции**:
- **Identity-based** (Шаг 1): что может делать роль
- **Resource-based** (Шаг 2): кто может использовать ресурс

## 🔄 Cleanup

```bash
# Удалить permission
aws lambda remove-permission \
    --function-name cmtr-4n6e9j62-iam-lp-lambda \
    --statement-id AllowAPIGatewayInvoke

# Detach policy
aws iam detach-role-policy \
    --role-name cmtr-4n6e9j62-iam-lp-iam_role \
    --policy-arn arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess
```

---

**Happy Learning! 🎓**
