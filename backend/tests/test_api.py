import unittest
from unittest.mock import patch

import jwt
from fastapi.testclient import TestClient

from app.errors import LLMUnavailable
from app.main import app


class ChatResponseTest(unittest.TestCase):
    def test_chat_returns_image_urls(self):
        with patch("app.main.ask", return_value=("hello", ["/images/a.jpg"])):
            response = TestClient(app).post("/chat", json={"message": "hi"})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(),
                         {"answer": "hello", "images": ["/images/a.jpg"]})

    def test_chat_without_images_defaults_to_empty_list(self):
        with patch("app.main.ask", return_value=("hello", [])):
            response = TestClient(app).post("/chat", json={"message": "hi"})

        self.assertEqual(response.json(), {"answer": "hello", "images": []})

    def test_all_llm_keys_failing_returns_a_clear_message(self):
        with patch("app.main.ask", side_effect=LLMUnavailable("all keys failed")):
            response = TestClient(app).post("/chat", json={"message": "hi"})

        self.assertEqual(response.status_code, 503)
        self.assertIn("LLM is not working", response.json()["detail"])


class AuthTest(unittest.TestCase):
    def test_chat_is_open_when_jwt_secret_is_unset(self):
        with patch("app.main.ask", return_value=("hello", [])):
            response = TestClient(app).post("/chat", json={"message": "hi"})
        self.assertEqual(response.status_code, 200)

    def test_chat_requires_a_bearer_token_when_jwt_secret_is_set(self):
        with patch("app.config.SUPABASE_JWT_SECRET", "test-secret"):
            response = TestClient(app).post("/chat", json={"message": "hi"})
        self.assertEqual(response.status_code, 401)

    def test_chat_uses_the_supabase_user_id_as_the_session(self):
        token = jwt.encode(
            {"sub": "user-42", "aud": "authenticated", "role": "authenticated"},
            "test-secret",
            algorithm="HS256",
        )
        with patch("app.config.SUPABASE_JWT_SECRET", "test-secret"), \
             patch("app.main.ask", return_value=("hello", [])) as ask:
            response = TestClient(app).post(
                "/chat",
                json={"message": "hi", "session_id": "spoofed"},
                headers={"Authorization": f"Bearer {token}"},
            )
        self.assertEqual(response.status_code, 200)
        ask.assert_called_once_with("hi", "user-42")


if __name__ == "__main__":
    unittest.main()
