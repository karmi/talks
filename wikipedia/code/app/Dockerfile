# NOTE: The image is build via Docker Compose by default
#
# Cf. <https://testdriven.io/blog/docker-best-practices>

FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install system packages
#
RUN apt-get update && \
  apt-get install --yes --no-install-recommends gcc curl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install Python packages
#
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Cache the Sentence Transformer models during build
#
ENV HF_HOME="/app/cache/huggingface"
ENV SENTENCE_TRANSFORMERS_HOME="/app/cache/torch/sentence_transformers"
ARG MODEL_IDS='intfloat/multilingual-e5-small'

# NOTE: Heredoc syntax not working on Google Cloud Build
RUN echo "import sentence_transformers" >> download_models.py && \
  echo "for model_name in '${MODEL_IDS}'.split(','):" >> download_models.py && \
  echo "  print('Downloading', model_name)" >> download_models.py && \
  echo "  sentence_transformers.SentenceTransformer(model_name)" >> download_models.py && \
  python3 download_models.py

# Copy application source code
#
COPY search.* /app/

ENV PORT=${PORT:-8080}

# https://cloud.google.com/run/docs/tips/python#optimize_gunicorn
#
ENTRYPOINT /usr/local/bin/gunicorn --bind 0.0.0.0:$PORT --workers 1 --threads 8 --timeout 0 --access-logfile - 'search:app'
