# Dockerfile
# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Multi-stage Production Dockerfile
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Builder ─────────────────────────────────────────────────────────
# Install dependencies into a virtual environment to keep the final image clean.
FROM python:3.12-slim AS builder

WORKDIR /build

# Prevents Python from writing pyc files to disk and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install build dependencies if needed (e.g., for psycopg2, numpy)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
# Use a fresh slim image for the final runtime stage.
FROM python:3.12-slim AS runtime

WORKDIR /app

# Copy the virtual environment from the builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set environment variables
ENV APP_VERSION="1.0.0" \
    ENVIRONMENT="production" \
    PYTHONPATH="/app"

# Create a non-privileged user to run the app (Security Best Practice)
RUN groupadd -g 1000 appuser && \
    useradd -r -u 1000 -g appuser appuser && \
    chown appuser:appuser /app

# Copy application source code
COPY --chown=appuser:appuser src/ .

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 8000

# Metadata labels
LABEL maintainer="Bhavishya Raj" \
      project="cd-010-github-actions-cicd"

# Healthcheck to monitor container status (uses python to avoid installing curl)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health').read()" || exit 1

# Launch the FastAPI application using Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
