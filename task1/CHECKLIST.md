# ✅ Чеклист выполнения задачи

## 📋 Предварительная подготовка

- [ ] AWS CLI установлен (`aws --version`)
- [ ] Credentials настроены
- [ ] Доступ к интернету есть
- [ ] Region установлен на `eu-west-1`

## 🎯 Выполнение задачи (2 moves)

### Move 1: Присоединить Identity-Based Policy
- [ ] Выполнена команда `attach-role-policy`
- [ ] Policy ARN: `arn:aws:iam::aws:policy/AmazonS3FullAccess`
- [ ] Role Name: `cmtr-4n6e9j62-iam-peld-iam_role`
- [ ] Команда выполнена успешно (нет ошибок)
- [ ] Проверено через `list-attached-role-policies`

**Команда:**
```bash
aws iam attach-role-policy \
    --role-name cmtr-4n6e9j62-iam-peld-iam_role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

### Move 2: Обновить Resource-Based Policy
- [ ] Создан файл `bucket-policy.json`
- [ ] JSON синтаксис корректен
- [ ] Principal ARN правильный
- [ ] Resource ARN правильный
- [ ] Action указан: `s3:DeleteObject`
- [ ] Effect указан: `Deny`
- [ ] Выполнена команда `put-bucket-policy`
- [ ] Команда выполнена успешно (нет ошибок)
- [ ] Проверено через `get-bucket-policy`

**Команда:**
```bash
aws s3api put-bucket-policy \
    --bucket cmtr-4n6e9j62-iam-peld-bucket-2911738 \
    --policy file://bucket-policy.json
```

## ✅ Верификация

### Проверка через AWS CLI
- [ ] Выполнена команда `simulate-principal-policy`
- [ ] Действие: `s3:DeleteObject`
- [ ] Результат: `"EvalDecision": "explicitDeny"` ✅
- [ ] Проверены другие действия (GetObject, PutObject)
- [ ] Другие действия разрешены (allowed) ✅

**Команда:**
```bash
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::651706749822:role/cmtr-4n6e9j62-iam-peld-iam_role \
  --action-names s3:DeleteObject \
  --resource-arns arn:aws:s3:::cmtr-4n6e9j62-iam-peld-bucket-2911738/test-object
```

### Проверка через Policy Simulator (Web)
- [ ] Открыт https://policysim.aws.amazon.com/
- [ ] Выбрана роль `cmtr-4n6e9j62-iam-peld-iam_role`
- [ ] Выбран сервис Amazon S3
- [ ] Выбрано действие DeleteObject
- [ ] Указан ресурс ARN
- [ ] Запущена симуляция
- [ ] Результат: **Denied** ❌ ✅

### Дополнительные проверки
- [ ] Проверен список присоединенных политик роли
- [ ] Проверена bucket policy
- [ ] Проверены разрешения на GetObject (должно быть allowed)
- [ ] Проверены разрешения на PutObject (должно быть allowed)
- [ ] Проверены разрешения на ListBucket (должно быть allowed)

## 📊 Финальная проверка

### Ожидаемые результаты:

| Действие | Ожидаемый результат | Проверено |
|----------|---------------------|-----------|
| s3:GetObject | ✅ ALLOW | [ ] |
| s3:PutObject | ✅ ALLOW | [ ] |
| s3:ListBucket | ✅ ALLOW | [ ] |
| s3:DeleteObject | ❌ DENY | [ ] |

### Политики на месте:

| Компонент | Политика | Статус |
|-----------|----------|--------|
| IAM Role | AmazonS3FullAccess attached | [ ] |
| S3 Bucket | Deny DeleteObject policy | [ ] |

## 🎯 Итоговая верификация

- [ ] Задача выполнена за **2 moves** (не больше)
- [ ] Роль имеет полный доступ к S3
- [ ] Роль НЕ МОЖЕТ удалять объекты из конкретного bucket
- [ ] Все проверки пройдены успешно
- [ ] Нет ошибок в логах

## 📝 Документация

- [ ] Прочитан README.md
- [ ] Понята концепция Identity-based vs Resource-based policies
- [ ] Понят принцип "Explicit Deny always wins"
- [ ] Изучена Policy Evaluation Logic

## 🎓 Бонусные задания (опционально)

- [ ] Протестировать удаление объекта через AWS Console
- [ ] Создать inline policy на роли (для сравнения)
- [ ] Изучить CloudTrail логи для аудита
- [ ] Попробовать добавить другие restrictions в bucket policy
- [ ] Протестировать с другими AWS сервисами

## 🐛 Troubleshooting (если что-то пошло не так)

### Если команда attach-role-policy не работает:
- [ ] Проверить, существует ли роль
- [ ] Проверить правильность ARN политики
- [ ] Проверить права текущего пользователя
- [ ] Проверить синтаксис команды

### Если команда put-bucket-policy не работает:
- [ ] Проверить синтаксис JSON
- [ ] Проверить правильность ARN роли в Principal
- [ ] Проверить правильность ARN bucket в Resource
- [ ] Проверить, существует ли bucket

### Если Policy Simulator показывает allowed вместо denied:
- [ ] Проверить, применена ли bucket policy
- [ ] Проверить правильность Principal ARN
- [ ] Проверить правильность Resource ARN
- [ ] Проверить, что Action точно совпадает
- [ ] Подождать несколько секунд (может быть задержка)

## 📞 Где искать помощь

- [ ] FAQ.md - часто задаваемые вопросы
- [ ] TESTING.md - troubleshooting секция
- [ ] INSTRUCTIONS.md - детальные инструкции
- [ ] ARCHITECTURE.md - теоретическая база

## 🎉 Завершение

Если все чекбоксы отмечены, поздравляем! 🎊

Вы успешно:
- ✅ Настроили Identity-based policy
- ✅ Настроили Resource-based policy
- ✅ Изучили Policy Evaluation Logic
- ✅ Применили принцип Explicit Deny
- ✅ Проверили результат через Policy Simulator

---

**Время выполнения:** ~2-5 минут  
**Сложность:** Средняя  
**Moves использовано:** 2 из 2  
**Статус:** ✅ COMPLETED
