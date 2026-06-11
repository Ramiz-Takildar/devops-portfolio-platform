"""
Production-ready Flask application for DevOps Portfolio Platform.

Endpoints:
    /        - Application welcome page
    /health  - Liveness probe
    /ready   - Readiness probe
    /metrics - Prometheus metrics
    /version - Application version
"""

import logging
import os
import sys
import time
from datetime import datetime

from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
APP_NAME = os.getenv("APP_NAME", "devops-portfolio-app")
APP_VERSION = os.getenv("APP_VERSION", "0.1.0")
APP_ENV = os.getenv("APP_ENV", "production")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
BIND_PORT = int(os.getenv("PORT", "5000"))

# ---------------------------------------------------------------------------
# Structured JSON Logging
# ---------------------------------------------------------------------------


class JSONFormatter(logging.Formatter):
    """Custom JSON formatter for structured logging."""

    def format(self, record: logging.LogRecord) -> str:
        import json
        log_obj = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
            "thread": record.thread,
            "app_name": APP_NAME,
            "app_version": APP_VERSION,
            "app_env": APP_ENV,
        }
        if hasattr(record, "props") and isinstance(record.props, dict):
            log_obj.update(record.props)
        return json.dumps(log_obj, default=str)


def setup_logging() -> None:
    """Configure structured JSON logging for production."""
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JSONFormatter())
    handler.setLevel(LOG_LEVEL)

    root_logger = logging.getLogger()
    root_logger.setLevel(LOG_LEVEL)
    root_logger.handlers = [handler]

    # Reduce noisy third-party logs
    logging.getLogger("werkzeug").setLevel(logging.WARNING)


setup_logging()
logger = logging.getLogger(APP_NAME)

# ---------------------------------------------------------------------------
# Prometheus Metrics
# ---------------------------------------------------------------------------

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status_code"],
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
    buckets=[0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
)

ERRORS_TOTAL = Counter(
    "http_errors_total",
    "Total HTTP errors",
    ["method", "endpoint", "exception"],
)

# ---------------------------------------------------------------------------
# Flask Application
# ---------------------------------------------------------------------------

app = Flask(__name__)
app.config["JSON_SORT_KEYS"] = False

# Readiness toggle (for testing / simulating failures)
_ready = True


@app.before_request
def before_request() -> None:
    """Attach request start time for latency tracking."""
    request._start_time = time.time()


@app.after_request
def after_request(response):
    """Record Prometheus metrics after every request."""
    if hasattr(request, "_start_time"):
        latency = time.time() - request._start_time
        REQUEST_LATENCY.labels(method=request.method, endpoint=request.endpoint or "unknown").observe(latency)

    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.endpoint or "unknown",
        status_code=response.status_code,
    ).inc()

    # Add security headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"

    return response


@app.errorhandler(Exception)
def handle_exception(exc: Exception):
    """Global exception handler with structured logging."""
    ERRORS_TOTAL.labels(
        method=request.method,
        endpoint=request.endpoint or "unknown",
        exception=type(exc).__name__,
    ).inc()

    logger.error(
        "Unhandled exception",
        extra={"props": {"error": str(exc), "path": request.path, "method": request.method}},
    )
    return jsonify({"status": "error", "message": "Internal server error"}), 500


@app.errorhandler(404)
def handle_404(exc):
    """Handle 404 with structured logging."""
    logger.warning(
        "Page not found",
        extra={"props": {"path": request.path, "method": request.method}},
    )
    return jsonify({"status": "error", "message": "Not found"}), 404


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.route("/", methods=["GET"])
def index():
    """Welcome endpoint."""
    return jsonify({
        "status": "ok",
        "message": f"Welcome to {APP_NAME}",
        "version": APP_VERSION,
        "environment": APP_ENV,
    })


@app.route("/health", methods=["GET"])
def health():
    """Liveness probe — always returns 200 if process is alive."""
    return jsonify({"status": "healthy", "timestamp": datetime.utcnow().isoformat() + "Z"}), 200


@app.route("/ready", methods=["GET"])
def ready():
    """Readiness probe — returns 200 only when app is ready to serve traffic."""
    if _ready:
        return jsonify({"status": "ready", "timestamp": datetime.utcnow().isoformat() + "Z"}), 200
    return jsonify({"status": "not ready"}), 503


@app.route("/metrics", methods=["GET"])
def metrics():
    """Prometheus metrics endpoint."""
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.route("/version", methods=["GET"])
def version():
    """Application version endpoint."""
    return jsonify({
        "version": APP_VERSION,
        "app_name": APP_NAME,
        "environment": APP_ENV,
    })


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    logger.info(
        "Starting application",
        extra={"props": {"port": BIND_PORT, "version": APP_VERSION, "env": APP_ENV}},
    )
    # Use threaded=True for production-like request handling
    app.run(host="0.0.0.0", port=BIND_PORT, threaded=True)
