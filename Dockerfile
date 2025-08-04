# Используем официальный образ n8n как базовый
FROM docker.n8n.io/n8nio/n8n:latest

# Переключаемся на root для установки пакетов
USER root

# Обновляем пакеты и устанавливаем зависимости
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    python3 \
    python3-pip \
    curl \
    wget \
    ca-certificates \
    libva-intel-driver \
    git \
    build-essential \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем Python-библиотеки
RUN pip3 install --no-cache-dir \
    numpy \
    librosa

# Устанавливаем дополнительные NPM-пакеты
RUN npm install -g \
    fluent-ffmpeg \
    typescript \
    @qdrant/js-client-rest \
    @langchain/community

# Создаем группу docker, если она не существует, и добавляем пользователя node
RUN addgroup --system docker || true \
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