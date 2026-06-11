"""Unit tests for the Flask application."""

import pytest
from main import app


@pytest.fixture
def client():
    """Create a test client for the Flask app."""
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


class TestIndexEndpoint:
    def test_index_status_code(self, client):
        response = client.get("/")
        assert response.status_code == 200

    def test_index_json(self, client):
        response = client.get("/")
        data = response.get_json()
        assert data["status"] == "ok"
        assert "message" in data
        assert "version" in data


class TestHealthEndpoint:
    def test_health_status_code(self, client):
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_returns_healthy(self, client):
        response = client.get("/health")
        data = response.get_json()
        assert data["status"] == "healthy"
        assert "timestamp" in data


class TestReadyEndpoint:
    def test_ready_status_code(self, client):
        response = client.get("/ready")
        assert response.status_code == 200

    def test_ready_returns_ready(self, client):
        response = client.get("/ready")
        data = response.get_json()
        assert data["status"] == "ready"


class TestMetricsEndpoint:
    def test_metrics_status_code(self, client):
        response = client.get("/metrics")
        assert response.status_code == 200

    def test_metrics_contains_flask_metrics(self, client):
        response = client.get("/metrics")
        assert b"http_requests_total" in response.data


class TestVersionEndpoint:
    def test_version_status_code(self, client):
        response = client.get("/version")
        assert response.status_code == 200

    def test_version_has_version_field(self, client):
        response = client.get("/version")
        data = response.get_json()
        assert "version" in data
        assert "app_name" in data
        assert "environment" in data


class TestErrorHandling:
    def test_404(self, client):
        response = client.get("/nonexistent")
        assert response.status_code == 404
        data = response.get_json()
        assert data["status"] == "error"

    def test_security_headers(self, client):
        response = client.get("/")
        assert response.headers.get("X-Content-Type-Options") == "nosniff"
        assert response.headers.get("X-Frame-Options") == "DENY"


class TestPrometheusIntegration:
    def test_request_count_increments(self, client):
        # Make a request to / to ensure metrics get populated
        client.get("/")
        response = client.get("/metrics")
        assert response.status_code == 200
        assert b"http_requests_total" in response.data

    def test_latency_histogram_exists(self, client):
        client.get("/health")
        response = client.get("/metrics")
        assert b"http_request_duration_seconds" in response.data
