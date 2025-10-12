# QUICKSTART - Task 3: Role Assumption

## ⚡ Самый быстрый способ (30 секунд)

```bash
cd task3
chmod +x setup-iam-task3.sh
./setup-iam-task3.sh
```

## 📋 Что делает скрипт?

1. ✅ Создает inline policy для assume роли (разрешает `sts:AssumeRole`)
2. ✅ Присоединяет `ReadOnlyAccess` к readonly роли
3. ✅ Обновляет Trust Policy readonly роли
4. ✅ Запускает автоматические тесты

## 🎯 Ожидаемый результат

### Роль `cmtr-4n6e9j62-iam-ar-iam_role-assume`:
- ✅ Может принять роль `cmtr-4n6e9j62-iam-ar-iam_role-readonly`

### Роль `cmtr-4n6e9j62-iam-ar-iam_role-readonly`:
- ✅ Имеет read-only доступ ко всем AWS сервисам
- ❌ НЕ может выполнять write операции
- ✅ Может быть принята assume ролью

## ✅ Проверка через Policy Simulator

```bash
export AWS_ACCESS_KEY_ID=AKIAY6QVYZH2ESZQQ6CV
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

# Тест 1: AssumeRole (должен быть allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-assume \
  --action-names sts:AssumeRole \
  --resource-arns arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly

# Тест 2: Read операции (allowed)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly \
  --action-names ec2:DescribeInstances

# Тест 3: Write операции (denied)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::615299729908:role/cmtr-4n6e9j62-iam-ar-iam_role-readonly \
  --action-names ec2:RunInstances
```

## 💡 Ключевые концепции

```
Assume Role (может принимать роли)
    ↓ assume
ReadOnly Role (read-only доступ)
    ↓ Trust Policy (разрешает assume)
Доступ разрешен ✅
```

## 📚 Дополнительно

| Файл | Описание |
|------|----------|
| `INSTRUCTIONS.md` | Подробные инструкции |
| `CHECKLIST.md` | Чеклист выполнения |
| `ARCHITECTURE.md` | Теория role assumption |
| `commands.sh` | Команды для копирования |

## 🎓 Что изучите

- ✅ Role Assumption (sts:AssumeRole)
- ✅ Trust Policies
- ✅ Inline vs Managed Policies
- ✅ ReadOnlyAccess policy
- ✅ Cross-role access

---

**Время:** ~2 минуты  
**Сложность:** Средняя
