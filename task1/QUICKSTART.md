# QUICKSTART - Быстрое выполнение задачи

## ⚡ Самый быстрый способ (30 секунд)

```bash
# 1. Сделайте скрипт исполняемым
chmod +x setup-iam-task.sh

# 2. Запустите скрипт
./setup-iam-task.sh

# 3. Готово! ✅
```

## 📋 Что делает скрипт?

1. ✅ Настраивает AWS credentials
2. ✅ Присоединяет `AmazonS3FullAccess` к роли
3. ✅ Обновляет bucket policy с Deny для DeleteObject
4. ✅ Проверяет результат

## 🎯 Ожидаемый результат

После выполнения скрипта:
- Роль `cmtr-4n6e9j62-iam-peld-iam_role` имеет **полный доступ к S3**
- **НО** не может удалять объекты из bucket `cmtr-4n6e9j62-iam-peld-bucket-2911738`

## ✅ Проверка результата

### Способ 1: Web UI (рекомендуется)
1. Откройте: https://policysim.aws.amazon.com/
2. Выберите роль: `cmtr-4n6e9j62-iam-peld-iam_role`
3. Тест действия: `s3:DeleteObject`
4. Ресурс: `arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/*`
5. Результат должен быть: ❌ **Denied**

### Способ 2: AWS CLI
```bash
export AWS_ACCESS_KEY_ID=AKIAZPPF72N7EHDWSCFI
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role \
  --action-names s3:DeleteObject \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test
```

Должно вернуть: `"EvalDecision": "explicitDeny"` ✅

## 📚 Дополнительные ресурсы

| Файл | Для чего |
|------|----------|
| `INSTRUCTIONS.md` | Подробные инструкции (3 способа) |
| `ARCHITECTURE.md` | Визуальные схемы и теория |
| `TESTING.md` | Примеры тестирования |
| `commands.sh` | Готовые команды для копирования |
| `bucket-policy.json` | JSON политика bucket |

## 🆘 Проблемы?

### Скрипт не запускается
```bash
# Убедитесь, что AWS CLI установлен
aws --version

# Если нет, установите:
# macOS
brew install awscli

# Проверьте права
ls -la setup-iam-task.sh
chmod +x setup-iam-task.sh
```

### Ошибка доступа
```bash
# Проверьте credentials
aws sts get-caller-identity
```

### Нужна помощь
Откройте `INSTRUCTIONS.md` для детальной инструкции

## 💡 Основная концепция

```
Identity-Based Policy (Allow S3 Full Access)
              +
Resource-Based Policy (Deny DeleteObject)
              =
Полный доступ к S3, КРОМЕ удаления объектов ✅
```

**Почему работает?** 
Explicit DENY всегда побеждает ALLOW в AWS IAM! 🛡️

## 🎓 Что вы изучите

- ✅ Identity-based vs Resource-based policies
- ✅ AWS Policy Evaluation Logic
- ✅ Как Deny побеждает Allow
- ✅ Работа с AWS CLI
- ✅ IAM Policy Simulator

---

**Время выполнения:** ~2 минуты  
**Сложность:** Легко  
**Требования:** AWS CLI, jq (опционально)
