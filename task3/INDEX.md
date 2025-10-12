# 📚 INDEX - Навигация по Task 3

## 🎯 С чего начать?

```
1. README.md          → Общий обзор
2. QUICKSTART.md      → Выполнить за 30 сек
3. CHECKLIST.md       → Отслеживать прогресс
4. setup-iam-task3.sh → Запустить скрипт
5. Проверить          → Policy Simulator
```

## 📋 Все файлы

| Файл | Описание |
|------|----------|
| **README.md** | Главная страница |
| **QUICKSTART.md** | Быстрый старт |
| **INDEX.md** | Этот файл |
| **INSTRUCTIONS.md** | Детальные инструкции |
| **CHECKLIST.md** | Чеклист выполнения |
| **ARCHITECTURE.md** | Теория и схемы |
| **PROJECT_SUMMARY.md** | Итоговая сводка |
| **setup-iam-task3.sh** | Автоматический скрипт |
| **commands.sh** | Готовые команды |
| **assume-role-policy.json** | Inline policy |
| **trust-policy.json** | Trust policy |

## 🎯 Краткий обзор

### Задача
Настроить role assumption - одна роль принимает другую роль.

### Три компонента
1. **Assume Role** - может принимать другие роли
2. **ReadOnly Role** - read-only доступ
3. **Trust Policy** - кто может принять роль

### Результат
- ✅ Assume роль может принять readonly роль
- ✅ Readonly роль имеет read-only доступ
- ❌ Readonly роль НЕ может писать

## 💡 Ключевые концепции

- **sts:AssumeRole** - действие принятия роли
- **Trust Policy** - кто может assume роль
- **ReadOnlyAccess** - AWS Managed Policy
- **Role Session** - временные credentials

---

**Создано:** October 2025
