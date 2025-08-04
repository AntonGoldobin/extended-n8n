FROM docker.n8n.io/n8nio/n8n:1.3.1 AS builder

# Switch to root for package installation
USER root

# Install build dependencies
RUN apk update && apk add --no-cache \
    python3 \
    py3-pip \
    build-base \
    python3-dev \
    musl-dev \
    linux-headers \
    pkgconf \
    libsndfile-dev \
    ffmpeg \
    g++ \
    && rm -rf /var/cache/apk/*

# Create virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip

# Install Python packages (without scikit-learn, numba, or llvmlite)
RUN pip install --no-cache-dir numpy==1.26.4
RUN pip install --no-cache-dir --no-deps librosa==0.10.2
RUN pip install --no-cache-dir audioread==3.0.1
RUN pip install --no-cache-dir soundfile==0.12.1

# Install global npm packages
RUN npm install -g \
    fluent-ffmpeg \
    typescript \
    @qdrant/js-client-rest \
    @langchain/community

# Stage 2: Final minimal image
FROM docker.n8n.io/n8nio/n8n:1.3.1

# Switch to root for setup
USER root

# Install minimal runtime dependencies
RUN apk update && apk add --no-cache \
    python3 \
    libsndfile \
    ffmpeg \
    tzdata \
    && rm -rf /var/cache/apk/*

# Copy virtual environment
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy global npm packages
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin/tsc /usr/local/bin/tsc

# Create docker group and add node user
RUN addgroup -S docker || true \
    && addgroup node docker

# Set permissions for n8n data folder
RUN chown -R node:node /home/node/.n8n \
    && chmod -R 755 /home/node/.n8n

# Switch to node user
USER node

# Set environment variables
ENV GENERIC_TIMEZONE=Europe/Moscow \
    TZ=Europe/Moscow

# Command to start n8n
CMD ["n8n", "start"]