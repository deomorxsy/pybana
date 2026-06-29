# Use the original n8n image as the basis
FROM n8nio/n8n:latest

# Install additional packages as needed
USER root
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 py3-pip curl ffmpeg python3-dev
RUN pip3 install --break-system-packages --no-cache --upgrade psycopg2-binary
USER node

