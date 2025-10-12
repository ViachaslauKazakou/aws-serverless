# ✅ Чеклист выполнения Task 2

## 📋 Предварительная подготовка

- [ ] AWS CLI установлен (`aws --version`)
- [ ] Credentials настроены
- [ ] Доступ к интернету есть
- [ ] Region установлен на `eu-west-1`
- [ ] jq установлен (опционально, для форматирования JSON)

## 🎯 Выполнение задачи (2 moves)

### Move 1: Создать Inline Policy для роли
- [ ] Создан файл `inline-policy.json`
- [ ] JSON синтаксис корректен
- [ ] Action: `s3:ListAllMyBuckets`
- [ ] Resource: `*`
- [ ] Effect: `Allow`
- [ ] Выполнена команда `put-role-policy`
- [ ] Policy Name: `ListAllBucketsPolicy`
- [ ] Role Name: `cmtr-4n6e9j62-iam-pela-iam_role`
- [ ] Команда выполнена успешно (нет ошибок)
- [ ] Проверено через `list-role-policies`

**Команда:**
```bash
aws iam put-role-policy \
    --role-name cmtr-4n6e9j62-iam-pela-iam_role \
    --policy-name ListAllBucketsPolicy \
    --policy-document file://inline-policy.json
```

### Move 2: Создать Bucket Policy для bucket-1
- [ ] Создан файл `bucket-policy.json`
- [ ] JSON синтаксис корректен
- [ ] Principal ARN правильный
- [ ] Actions указаны: `GetObject`, `PutObject`, `ListBucket`
- [ ] Resource ARN для bucket указан (без /*)
- [ ] Resource ARN для объектов указан (с /*)
- [ ] Effect: `Allow`
- [ ] Выполнена команда `put-bucket-policy`
- [ ] Bucket Name: `cmtr-4n6e9j62-iam-pela-bucket-1-162653`
- [ ] Команда выполнена успешно (нет ошибок)
- [ ] Проверено через `get-bucket-policy`
- [ ] **Bucket-2 НЕ ТРОГАЛИ** ⚠️

**Команда:**
```bash
aws s3api put-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-pela-bucket-1-162653 \
    --policy file://bucket-policy.json
```

## ✅ Верификация

### Проверка 1: ListAllMyBuckets (должен быть allowed)
- [ ] Выполнена симуляция через CLI или Web UI
- [ ] Action: `s3:ListAllMyBuckets`
- [ ] Результат: `"EvalDecision": "allowed"` ✅

**Команда:**
```bash
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::863518426750:role/cmtr-4n6e9j62-iam-pela-iam_role \
  --action-names s3:ListAllMyBuckets
```

### Проверка 2: ListBucket для bucket-1 (должен быть allowed)
- [ ] Выполнена симуляция
- [ ] Action: `s3:ListBucket`
- [ ] Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653`
- [ ] Результат: `"EvalDecision": "allowed"` ✅

### Проверка 3: GetObject для bucket-1 (должен быть allowed)
- [ ] Выполнена симуляция
- [ ] Action: `s3:GetObject`
- [ ] Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653/*`
- [ ] Результат: `"EvalDecision": "allowed"` ✅

### Проверка 4: PutObject для bucket-1 (должен быть allowed)
- [ ] Выполнена симуляция
- [ ] Action: `s3:PutObject`
- [ ] Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-1-162653/*`
- [ ] Результат: `"EvalDecision": "allowed"` ✅

### Проверка 5: ListBucket для bucket-2 (должен быть implicitDeny)
- [ ] Выполнена симуляция
- [ ] Action: `s3:ListBucket`
- [ ] Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-2-162653`
- [ ] Результат: `"EvalDecision": "implicitDeny"` ❌ ✅

### Проверка 6: GetObject для bucket-2 (должен быть implicitDeny)
- [ ] Выполнена симуляция
- [ ] Action: `s3:GetObject`
- [ ] Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-2-162653/*`
- [ ] Результат: `"EvalDecision": "implicitDeny"` ❌ ✅

### Проверка 7: PutObject для bucket-2 (должен быть implicitDeny)
- [ ] Выполнена симуляция
- [ ] Action: `s3:PutObject`
- [ ] Resource: `arn:aws:s3:::cmtr-4n6e9j62-iam-pela-bucket-2-162653/*`
- [ ] Результат: `"EvalDecision": "implicitDeny"` ❌ ✅

## 📊 Финальная проверка

### Матрица разрешений:

| Действие | Bucket-1 | Bucket-2 | Проверено |
|----------|----------|----------|-----------|
| s3:ListAllMyBuckets | ✅ ALLOW | ✅ ALLOW | [ ] |
| s3:ListBucket | ✅ ALLOW | ❌ DENY | [ ] |
| s3:GetObject | ✅ ALLOW | ❌ DENY | [ ] |
| s3:PutObject | ✅ ALLOW | ❌ DENY | [ ] |

### Политики на месте:

| Компонент | Политика | Статус |
|-----------|----------|--------|
| IAM Role | Inline Policy: ListAllBucketsPolicy | [ ] |
| S3 Bucket-1 | Bucket Policy: Allow Get/Put/List | [ ] |
| S3 Bucket-2 | NO POLICY (оставить пустым!) | [ ] |

## 🎯 Итоговая верификация

- [ ] Задача выполнена за **2 moves** (не больше)
- [ ] Роль может просматривать список всех buckets
- [ ] Роль может работать с объектами в bucket-1
- [ ] Роль НЕ МОЖЕТ работать с объектами в bucket-2
- [ ] Bucket-2 не имеет никаких политик
- [ ] Все проверки пройдены успешно
- [ ] Нет ошибок в логах

## 📝 Дополнительные проверки

- [ ] Inline policy отображается в консоли IAM
- [ ] Bucket policy отображается в консоли S3
- [ ] Bucket-2 НЕ имеет политики (проверено)
- [ ] Policy Simulator показывает правильные результаты

## 🐛 Troubleshooting (если что-то пошло не так)

### Если команда put-role-policy не работает:
- [ ] Проверить JSON синтаксис (`cat inline-policy.json | jq '.'`)
- [ ] Проверить существование роли
- [ ] Проверить правильность имени роли
- [ ] Проверить права текущего пользователя

### Если команда put-bucket-policy не работает:
- [ ] Проверить JSON синтаксис
- [ ] Проверить оба Resource ARN (с /* и без /*)
- [ ] Проверить Principal ARN
- [ ] Проверить существование bucket
- [ ] Убедиться, что это bucket-1, а не bucket-2!

### Если Policy Simulator показывает неожиданные результаты:
- [ ] Подождать 1-2 минуты (политики могут применяться с задержкой)
- [ ] Проверить правильность Resource ARN
- [ ] Проверить правильность Action name
- [ ] Очистить кэш браузера (для Web UI)
- [ ] Повторить тест

### Если проверка для bucket-2 показывает allowed:
- [ ] **ПРОБЛЕМА!** Bucket-2 не должен быть доступен
- [ ] Проверить, не создали ли политику для bucket-2 по ошибке
- [ ] Удалить политику из bucket-2, если создана
- [ ] Проверить, что Principal ARN в bucket policy указывает только на bucket-1

## 📞 Где искать помощь

- [ ] FAQ.md - часто задаваемые вопросы
- [ ] TESTING.md - troubleshooting секция
- [ ] INSTRUCTIONS.md - детальные инструкции
- [ ] ARCHITECTURE.md - теоретическая база

## 🎓 Понимание концепций

- [ ] Понимаю разницу между Inline и Managed policies
- [ ] Понимаю, когда использовать Inline policy
- [ ] Понимаю, как работает Bucket Policy
- [ ] Понимаю разницу между Resource ARN с /* и без /*
- [ ] Понимаю концепцию Implicit Deny
- [ ] Понимаю, как комбинируются Identity и Resource policies

## 🎉 Завершение

Если все чекбоксы отмечены, поздравляем! 🎊

Вы успешно:
- ✅ Создали Inline Policy для роли
- ✅ Создали Bucket Policy для bucket-1
- ✅ Настроили гранулярный контроль доступа
- ✅ Изучили комбинирование политик
- ✅ Проверили результат через Policy Simulator

---

**Время выполнения:** ~2-5 минут  
**Сложность:** Средняя-Высокая  
**Moves использовано:** 2 из 2  
**Статус:** ✅ COMPLETED
