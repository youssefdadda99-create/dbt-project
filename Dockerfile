# stage 1 — builder: install Python deps into /opt/python
FROM python:3.11-slim AS builder

ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1

# install minimal build tools (removed later)
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc g++ make curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src

# copy only lock/files needed to install deps (speeds layer cache)
COPY pyproject.toml poetry.lock* requirements.txt* ./

# install to an isolated target folder to copy only runtime files later
# prefer binary wheels to avoid compiling from source where possible
RUN pip install --upgrade pip setuptools wheel && \
    if [ -f requirements.txt ]; then \
      pip install --target=/opt/python --requirement requirements.txt --prefer-binary; \
    else \
      pip install --target=/opt/python dbt-core dbt-bigquery --prefer-binary; \
    fi

# stage 2 — final: small runtime image with only runtime bits + app
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# create non-root user
RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /app

# copy runtime python packages from builder
COPY --from=builder /opt/python /usr/local

# copy app code
COPY . .

# drop unneeded files (if any were left)
RUN find /usr/local -name "__pycache__" -exec rm -rf {} + || true

# set non-root user
USER app

EXPOSE 8080

# default command (adjust for dbt)
CMD ["dbt", "run"]