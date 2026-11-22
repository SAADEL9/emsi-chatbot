import tempfile
import unittest
from unittest.mock import patch

from openai import OpenAIError

from app import vlm


class _Model:
    def __init__(self, error=None):
        self.error = error

    def invoke(self, messages):
        if self.error:
            raise self.error
        return type("Response", (), {"content": "a caption"})()


class CaptionFallbackTest(unittest.TestCase):
    def test_falls_back_to_the_next_key(self):
        with tempfile.NamedTemporaryFile(suffix=".jpg") as image:
            with patch.object(vlm, "vlms", [_Model(OpenAIError("down")), _Model()]):
                self.assertEqual(vlm.describe_image(image.name), "a caption")


if __name__ == "__main__":
    unittest.main()
