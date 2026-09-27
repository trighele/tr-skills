from fastapi.testclient import TestClient

from api.main import ROUTE_PREFIX, app

client = TestClient(app)


def test_the_health_endpoint_answers_under_the_route_prefix():
    response = client.get(f"{ROUTE_PREFIX}/healthz")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
