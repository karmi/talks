# NOTE: The image is build via Docker Compose by default
#
# Cf. <https://testdriven.io/blog/docker-best-practices>

FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install system packages
#
RUN apt-get update && \
  apt-get install --yes --no-install-recommends curl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install Python packages
#
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
#
COPY config.yml search.* /app/

ENV PORT=${PORT:-8080}

# https://cloud.google.com/run/docs/tips/python#optimize_gunicorn
#
ENTRYPOINT /usr/local/bin/gunicorn --bind 0.0.0.0:$PORT --workers 1 --threads 8 --timeout 0 --access-logfile - 'search:app'
