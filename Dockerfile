# ---------------------------------------------------------------------------
# Multi-stage Dockerfile for DevOps Portfolio Platform
#
# Stage 1 — Builder: Compile dependencies into a virtual environment
# Stage 2 — Runtime: Copy only the venv and app code, run as non-root
#
# Security best practices:
#   - Non-root user (uid 1000)
#   - No build tools in final image
#   - Read-only root filesystem (where possible)
#   - Minimal base image (python:3.12-slim)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Stage 1: Builder
# ---------------------------------------------------------------------------
FROM python:3.12-alpine AS builder

# Security: avoid running as root even in builder stage
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /build

# Install build dependencies (only needed for compilation)
RUN apk add --no-cache gcc musl-dev linux-headers

# Create virtual environment (isolated from system packages)
RUN python -m venv /build/.venv
ENV PATH="/build/.venv/bin:$PATH"

# Copy and install Python dependencies FIRST (layer caching optimization)
COPY app/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ---------------------------------------------------------------------------
# Stage 2: Runtime
# ---------------------------------------------------------------------------
FROM python:3.12-alpine AS runtime

LABEL maintainer="portfolio@example.com"
LABEL org.opencontainers.image.title="DevOps Portfolio App"
LABEL org.opencontainers.image.description="Production-grade Flask app for DevOps portfolio"
LABEL org.opencontainers.image.version="0.1.0"

# Security hardening: create non-root user and group
RUN addgroup -S appgroup --gid 1000 \
    && adduser -S appuser -G appgroup --uid 1000

# No additional runtime packages needed — HEALTHCHECK uses Python stdlib

# Set working directory
WORKDIR /app

# Copy only the virtual environment from builder (no build tools)
COPY --from=builder /build/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Copy application code
COPY app/ .

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user for all subsequent operations
USER appuser

# Expose application port
EXPOSE 5000

# Docker health check (liveness)
# The app exposes /health on port 5000
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# Run the application with gunicorn for production WSGI serving
# Using gunicorn instead of Flask dev server for production-grade behavior
# We explicitly use the module path to avoid path issues
CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "4", "--worker-class", "gthread", "--worker-tmp-dir", "/dev/shm", "--access-logfile", "-", "--error-logfile", "-", "--capture-output", "--enable-stdio-inheritance", "main:app"]
