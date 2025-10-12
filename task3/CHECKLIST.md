# ✅ Чеклист Task 3 - Role Assumption

## 📋 Предварительная подготовка

- [ ] AWS CLI установлен
- [ ] Credentials настроены
- [ ] Region: eu-west-1

## 🎯 Выполнение (3 шага)

### Шаг 1: Inline Policy для assume роли
- [ ] Создан `assume-role-policy.json`
- [ ] Action: `sts:AssumeRole`
- [ ] Resource: ARN readonly роли
- [ ] Выполнена команда `put-role-policy`
- [ ] Проверено

```bash
aws iam put-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-assume \
    --policy-name AssumeReadOnlyRolePolicy \
    --policy-document file://assume-role-policy.json
```

### Шаг 2: Attach ReadOnlyAccess
- [ ] Policy ARN правильный
- [ ] Выполнена команда `attach-role-policy`
- [ ] Проверено

```bash
aws iam attach-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly \
    --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
```

### Шаг 3: Trust Policy
- [ ] Создан `trust-policy.json`
- [ ] Principal: assume роль ARN
- [ ] Выполнена команда `update-assume-role-policy`
- [ ] Проверено

```bash
aws iam update-assume-role-policy \
    --role-name cmtr-4n6e9j62-iam-ar-iam_role-readonly \
    --policy-document file://trust-policy.json
```

## ✅ Верификация

### Тест 1: AssumeRole (allowed)
- [ ] Выполнена симуляция
- [ ] Action: `sts:AssumeRole`
- [ ] Результат: allowed ✅

### Тест 2: Read операции (allowed)
- [ ] Протестированы: DescribeInstances, ListBuckets
- [ ] Результат: allowed ✅

### Тест 3: Write операции (denied)
- [ ] Протестированы: RunInstances, CreateBucket
- [ ] Результат: implicitDeny ❌ ✅

## 📊 Матрица проверки

| Компонент | Статус |
|-----------|--------|
| Assume Role: Inline Policy | [ ] |
| ReadOnly Role: ReadOnlyAccess | [ ] |
| ReadOnly Role: Trust Policy | [ ] |

## 🎯 Итог

- [ ] 3 шага выполнены
- [ ] Assume роль может принять readonly роль
- [ ] Readonly роль имеет read-only доступ
- [ ] Все тесты пройдены

---

**Статус:** ✅ COMPLETED
