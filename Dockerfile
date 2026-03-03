FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# install deps first (better layer caching)
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# copy project
COPY . .

# non-root user
RUN useradd -m appuser
USER appuser

CMD ["dbt", "run"]