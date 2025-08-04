Чтобы минимизировать размер Docker-образа и сохранить производительность при установке всех необходимых зависимостей для n8n, включая ваши кастомные зависимости (numpy, scikit-learn, librosa, и npm-пакеты), мы можем оптимизировать Dockerfile, используя Alpine Linux и избегая ненужных или тяжёлых зависимостей, таких как numba и llvmlite, если они не критичны. Также мы можем применить многоступенчатую сборку (multi-stage build), чтобы уменьшить итоговый размер образа, сохранив только необходимые артефакты.
Стратегия оптимизации

Оставаться на Alpine Linux: Alpine значительно меньше, чем Debian-based образы (10–100 МБ против 500+ МБ для node:18-bullseye).
Исключить numba и llvmlite: Если numba не требуется для ваших задач с librosa, его можно исключить, так как он тянет тяжёлый llvmlite и LLVM.
Многоступенчатая сборка: Использовать промежуточный образ для компиляции и установки зависимостей, а затем копировать только необходимые файлы в итоговый образ.
Минимизация зависимостей: Устанавливать только необходимые пакеты и очищать кэш.
Оптимизация npm-пакетов: Убедиться, что npm-пакеты устанавливаются эффективно.

Предположения

Вы хотите сохранить numpy, scikit-learn, librosa и npm-пакеты (fluent-ffmpeg, typescript, @qdrant/js-client-rest, @langchain/community).
numba и llvmlite не критичны для ваших задач с librosa. Если это не так, уточните, и я предложу альтернативу.
Производительность важна, поэтому минимизируем ресурсоёмкие зависимости и компиляцию.

Оптимизированный Dockerfile
Этот Dockerfile использует многоступенчатую сборку на основе Alpine, исключает numba и минимизирует размер образа:
dockerfile# Этап 1: Сборка зависимостей
FROM docker.n8n.io/n8nio/n8n:latest AS builder

# Переключаемся на root для установки пакетов
USER root

# Обновляем пакеты и устанавливаем зависимости для компиляции
RUN apk update && apk add --no-cache \
    python3 \
    py3-pip \
    build-base \
    python3-dev \
    musl-dev \
    linux-headers \
    pkgconf \
    libsndfile \
    ffmpeg \
    && rm -rf /var/cache/apk/*

# Создаём виртуальную среду
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Обновляем pip
RUN pip install --no-cache-dir --upgrade pip

# Устанавливаем Python-библиотеки (без numba)
RUN pip install --no-cache-dir numpy
RUN pip install --no-cache-dir scikit-learn
RUN pip install --no-cache-dir --no-deps librosa
RUN pip install --no-cache-dir audioread soundfile resampy

# Устанавливаем npm-пакеты глобально
RUN npm install -g \
    fluent-ffmpeg \
    typescript \
    @qdrant/js-client-rest \
    @langchain/community

# Этап 2: Итоговый минималистичный образ
FROM docker.n8n.io/n8nio/n8n:latest

# Переключаемся на root для настройки
USER root

# Устанавливаем минимальные runtime-зависимости
RUN apk update && apk add --no-cache \
    python3 \
    libsndfile \
    ffmpeg \
    tzdata \
    && rm -rf /var/cache/apk/*

# Копируем виртуальную среду из builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Копируем глобальные npm-пакеты
COPY --from=builder /usr/lib/node_modules /usr/lib/node_modules
COPY --from=builder /usr/bin/fluent-ffmpeg /usr/bin/fluent-ffmpeg
COPY --from=builder /usr/bin/tsc /usr/bin/tsc

# Создаём группу docker и добавляем пользователя node
RUN addgroup -S docker || true \
    && addgroup node docker

# Настраиваем права для папки данных n8n
RUN chown -R node:node /home/node/.n8n \
    && chmod -R 755 /home/node/.n8n

# Переключаемся на пользователя node
USER node

# Указываем переменные окружения
ENV GENERIC_TIMEZONE=Europe/Moscow \
    TZ=Europe/Moscow

# Команда для запуска n8n
CMD ["n8n", "start"]