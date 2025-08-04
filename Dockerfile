ARG tag=latest
FROM n8nio/n8n:$tag
USER root
RUN apk update
RUN apk add ffmpeg
USER node