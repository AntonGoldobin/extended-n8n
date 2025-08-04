# Используем официальный образ n8n как базовый
FROM docker.n8n.io/n8nio/n8n:latest

# Переключаемся на root для установки пакетов
USER root

# Обновляем пакеты и устанавливаем зависимости
RUN apk update && apk add --no-cache \
    ffmpeg \
    python3 \
    py3-pip \
    curl \
    wget \
    ca-certificates \
    git \
    build-base \
    tzdata \
    && rm -rf /var/cache/apk/*

# Создаём виртуальную среду для Python
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Устанавливаем Python-библиотеки в виртуальной среде
RUN pip install --no-cache-dir \
    numpy \
    librosa

# Устанавливаем дополнительные NPM-пакеты
RUN npm install -g \
    fluent-ffmpeg \
    typescript \
    @qdrant/js-client-rest \
    @langchain/community

# Создаём группу docker, если она не существует, и добавляем пользователя node
RUN addgroup -S docker || true \
    && addgroup node docker

# Настраиваем права для папки данных n8n
RUN chown -R node:node /home/node/.n8n \
    && chmod -R 755 /home/node/.n8n

# Переключаемся обратно на пользователя node
USER node

# Указываем переменные окружения для n8n
ENV GENERIC_TIMEZONE=Europe/Moscow \
    TZ=Europe/Moscow

# Команда для запуска n8n
CMD ["n8n", "start"]