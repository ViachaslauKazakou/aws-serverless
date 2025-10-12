# 📚 INDEX - Навигация по документации Task 2

## 🎯 С чего начать?

```
1. README.md        → Общий обзор задачи
2. QUICKSTART.md    → Быстрое выполнение (30 сек)
3. CHECKLIST.md     → Отслеживание прогресса
4. Выполните задачу → setup-iam-task2.sh или commands.sh
5. TESTING.md       → Проверьте результат
```

## 📋 Быстрая навигация

| Если вам нужно... | Откройте этот файл |
|-------------------|-------------------|
| Быстро выполнить задачу | `QUICKSTART.md` или `setup-iam-task2.sh` |
| Пошаговые инструкции | `INSTRUCTIONS.md` |
| Понять теорию | `ARCHITECTURE.md` |
| Проверить результат | `TESTING.md` |
| Найти ответ на вопрос | `FAQ.md` |
| Скопировать команды | `commands.sh` |
| Отслеживать прогресс | `CHECKLIST.md` |
| Визуальные схемы | `DIAGRAMS.md` |

## 📖 Полная документация

### 🚀 Начало работы
- **[README.md](README.md)** - Главная страница с описанием задачи
- **[QUICKSTART.md](QUICKSTART.md)** ⚡ - Самый быстрый способ (30 секунд)

### 📋 Выполнение задачи
- **[INSTRUCTIONS.md](INSTRUCTIONS.md)** 📖 - Три способа выполнения (CLI, Console, скрипт)
  - Вариант 1: Автоматический скрипт
  - Вариант 2: AWS CLI команды
  - Вариант 3: AWS Console (веб-интерфейс)
- **[CHECKLIST.md](CHECKLIST.md)** ✅ - Подробный чеклист для отслеживания прогресса

### 🛠️ Скрипты и файлы
- **[setup-iam-task2.sh](setup-iam-task2.sh)** 🤖 - Автоматический скрипт выполнения
- **[commands.sh](commands.sh)** 💻 - Готовые команды AWS CLI
- **[inline-policy.json](inline-policy.json)** 📄 - Inline policy для роли
- **[bucket-policy.json](bucket-policy.json)** 📄 - Bucket policy для bucket-1

### 🏗️ Архитектура и теория
- **[ARCHITECTURE.md](ARCHITECTURE.md)** 🏗️ - Визуальные схемы и объяснение логики
  - Policy Evaluation Logic
  - Матрица разрешений
  - Отличия от Task 1
- **[DIAGRAMS.md](DIAGRAMS.md)** 📊 - Mermaid диаграммы для визуализации

### 🧪 Тестирование
- **[TESTING.md](TESTING.md)** 🧪 - Примеры тестирования и проверки результата
  - Тесты через Policy Simulator
  - Тесты через AWS CLI
  - Troubleshooting

### ❓ Справка
- **[FAQ.md](FAQ.md)** ❓ - Часто задаваемые вопросы и ответы
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** 📋 - Итоговая информация о проекте

## 🎯 Краткий обзор задачи

### Цель
Настроить комбинацию inline и bucket политик для гранулярного контроля доступа к S3.

### Два шага (moves)
1. **Move 1**: Создать inline policy → разрешает `s3:ListAllMyBuckets`
2. **Move 2**: Создать bucket policy → разрешает `GetObject`, `PutObject`, `ListBucket` для bucket-1

### Результат
- ✅ Роль может просматривать ВСЕ buckets
- ✅ Роль может работать с объектами ТОЛЬКО в bucket-1
- ❌ Роль НЕ может работать с bucket-2

## 📊 Статистика проекта

- **Всего файлов**: 13
- **Документация (MD)**: 10 файлов
- **Скрипты (SH)**: 2 файла
- **JSON файлы**: 2 файла
- **Общий объем**: ~65 KB
- **Язык**: Русский

## 🗺️ Карта быстрого доступа

| Файл | За 10 секунд |
|------|-------------|
| README.md | Описание задачи и навигация |
| QUICKSTART.md | Самый быстрый способ (30 сек) |
| INSTRUCTIONS.md | 3 способа выполнения |
| CHECKLIST.md | Чеклист для отслеживания |
| ARCHITECTURE.md | Теория + схемы |
| DIAGRAMS.md | Визуальные диаграммы |
| TESTING.md | 10+ способов проверки |
| FAQ.md | 30+ вопросов с ответами |
| PROJECT_SUMMARY.md | Полная сводка |
| setup-iam-task2.sh | Автоматическое выполнение |
| commands.sh | Копировать → Вставить |
| inline-policy.json | JSON для inline policy |
| bucket-policy.json | JSON для bucket policy |

## 🎓 Рекомендуемый путь изучения

### Для начинающих:
1. README.md → Общий обзор
2. QUICKSTART.md → Быстрый старт
3. ARCHITECTURE.md → Понять теорию
4. Запустить `setup-iam-task2.sh`
5. TESTING.md → Проверить результат
6. FAQ.md → Углубить знания

### Для опытных:
1. QUICKSTART.md → Понять суть
2. commands.sh → Выполнить команды
3. TESTING.md → Проверить
4. ARCHITECTURE.md → Детали (если интересно)

### Для изучающих IAM:
1. README.md → Контекст задачи
2. ARCHITECTURE.md → Теория политик
3. DIAGRAMS.md → Визуализация
4. INSTRUCTIONS.md → Пошаговое выполнение
5. TESTING.md → Практика проверки
6. FAQ.md → Ответы на вопросы

## 🔗 Связь между файлами

```
README.md (главная)
    ├─→ QUICKSTART.md (быстрый старт)
    ├─→ INSTRUCTIONS.md (детали)
    │       ├─→ setup-iam-task2.sh
    │       ├─→ commands.sh
    │       ├─→ inline-policy.json
    │       └─→ bucket-policy.json
    ├─→ ARCHITECTURE.md (теория)
    │       └─→ DIAGRAMS.md (визуализация)
    ├─→ TESTING.md (проверка)
    ├─→ CHECKLIST.md (прогресс)
    ├─→ FAQ.md (вопросы)
    └─→ PROJECT_SUMMARY.md (итог)
```

## 💡 Ключевые концепции

- **Inline Policy**: Встроенная в роль политика
- **Bucket Policy**: Resource-based политика на bucket
- **ListAllMyBuckets**: Глобальное разрешение просмотра buckets
- **Granular Access**: Точечный контроль доступа
- **Implicit Deny**: По умолчанию всё запрещено

## 🌟 Особенности Task 2

| Аспект | Task 1 | Task 2 |
|--------|--------|--------|
| Identity Policy | Managed Policy | **Inline Policy** |
| Bucket Policy | Deny (запрет) | **Allow (разрешение)** |
| Buckets | 1 bucket | **2 buckets** |
| Логика | Explicit Deny | **Комбинация Allow** |
| Сложность | Средняя | **Средняя-Высокая** |

---

**Создано**: October 2025  
**Версия**: 1.0  
**Язык**: Русский
