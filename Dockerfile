# Этап 1: Сборка зависимостей
FROM docker.n8n.io/n8nio/n8n:1.3.1 AS builder

# Переключаемся на root для установки пакетов
USER root

# Устанавливаем зависимости для компиляции
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
FROM docker.n8n.io/n8nio/n8n:1.3.1

# Переключаемся на root для настройки
USER root

# Устанавливаем минимальные runtime-зависимости
RUN apk update && apk add --no-cache \
    python3 \
    libsndfile \
    ffmpeg \
    tzdata \
    && rm -rf /var/cache/apk/*

# Копируем виртуальную среду
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Копируем глобальные npm-пакеты
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin/fluent-ffmpeg /usr/local/bin/fluent-ffmpeg
COPY --from=builder /usr/local/bin/tsc /usr/local/bin/tsc

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