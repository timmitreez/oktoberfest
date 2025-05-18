# Stage 1: Build and dependency installation
FROM python:3.11-slim-bookworm AS builder

SHELL ["sh", "-exc"]

ARG UV_INDEX_GITLAB_PASSWORD
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8 \
    UV_VERSION=0.6.0 \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_PYTHON=python3.11 \
    UV_PROJECT_ENVIRONMENT=/app/.venv \
    PATH=/app/scripts:$PATH

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

WORKDIR /app

COPY pyproject.toml /app/pyproject.toml
COPY README.md /app/README.md
# TODO: To be removed
COPY magnum_kpi-0.1.0-cp311-abi3-manylinux_2_34_x86_64.whl /app/magnum_kpi-0.1.0-cp311-abi3-manylinux_2_34_x86_64.whl

# Install the engine-runtime dependencies
RUN --mount=type=cache,target=/root/.cache \
    --mount=type=bind,source=uv.lock,target=/app/uv.lock \
    uv venv /app/.venv \
    && uv sync \
    --frozen \
    --compile-bytecode \
    --no-dev \
    --no-install-project

# Build the engine-runtime wheel
COPY src/. /app/src
# Compile all Python modules to bytecode, this will speed up the startup time but slightly increase the build time
# Remove the original source files, leaving only bytecode, not a must but it will save some space
RUN uv build --wheel && \
    uv pip install dist/*.whl && \
    python -m compileall -b -f -o 2 /app/.venv/lib/python3.11/site-packages/engine_runtime && \
    find /app/.venv/lib/python3.11/site-packages/engine_runtime -name "*.py" -type f -delete && \
    rm -rf /app/src /app/dist

COPY fdm_models/. /app/.venv/lib/python3.11/site-packages/jsbsim/aircraft

# --------------------------------------------------------------------------

# Stage 2: Runtime with no package manager
FROM python:3.11-slim-bookworm AS runner

SHELL ["sh", "-exc"]

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8 \
    PATH=/app/bin:$PATH

WORKDIR /app

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

COPY models/. /app/models
COPY local_exec_configs/. /app/local_exec_configs
COPY --from=builder /app/.venv /app/.venv

ENTRYPOINT ["/app/.venv/bin/python3"]
STOPSIGNAL SIGINT

LABEL org.opencontainers.image.vendor="Data Machine Intelligence Solutions GmbH"
LABEL org.opencontainers.image.title="Engine Runtime"
LABEL org.opencontainers.image.description="This container is used to run the DMI's core simulation engine."
LABEL org.opencontainers.image.authors="Data Machine Intelligence Solutions GmbH"
