# Stage 1: Build and dependency installation
FROM python:3.11-slim-bookworm AS builder

SHELL ["sh", "-exc"]

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8 \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_PYTHON=python3.11 \
    UV_PROJECT_ENVIRONMENT=/app/.venv

# Install system dependencies such as git, curl etc.
RUN apt-get update -qy \
    && apt-get install -qyy \
        -o APT::Install-Recommends=false \
        -o APT::Install-Suggests=false \
        git \
        curl \
        usbip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install UV
ADD https://astral.sh/uv/${UV_VERSION}/install.sh /uv-installer.sh
RUN chmod -R 655 /uv-installer.sh && /uv-installer.sh && rm /uv-installer.sh
ENV PATH="/root/.local/bin/:$PATH"

COPY pyproject.toml /app/pyproject.toml
COPY README.md /app/README.md

WORKDIR /app
COPY src/. /app/src
# Install the engine-runtime dependencies
RUN --mount=type=cache,target=/root/.cache \
    --mount=type=bind,source=uv.lock,target=/app/uv.lock \
    uv venv /app/.venv \
    && uv sync \
    --frozen \
    --compile-bytecode \
    --no-dev \
    --no-install-project

COPY data/. /app/data

CMD ["/app/.venv/bin/python", "src/main.py"]