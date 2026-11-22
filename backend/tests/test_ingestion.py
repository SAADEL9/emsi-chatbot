import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch

import numpy as np
from PIL import Image

from app import ingestion


class _ImageFile:
    def __init__(self, image):
        self.image = image


class _Page:
    def __init__(self, text="", images=()):
        self._text = text
        self.images = list(images)

    def extract_text(self):
        return self._text


class _Reader:
    def __init__(self, pages):
        self.pages = pages


class PdfIngestionTest(unittest.TestCase):
    def _ingest(self, pages, describe=None, existing=()):
        with tempfile.TemporaryDirectory() as tmp, \
             patch.object(ingestion, "PdfReader", return_value=_Reader(pages)), \
             patch.object(ingestion, "IMAGES_DIR", tmp), \
             patch.object(ingestion, "CAPTION_DELAY", 0), \
             patch.object(ingestion, "embed_text",
                          side_effect=lambda texts: np.zeros((len(texts), 1024))), \
             patch.object(ingestion, "embed_image",
                          side_effect=lambda paths: np.zeros((len(paths), 512))), \
             patch.object(ingestion, "describe_image",
                          side_effect=describe or (lambda path: "a caption")), \
             patch.object(ingestion.client, "retrieve", return_value=list(existing)), \
             patch.object(ingestion.client, "upsert") as upsert:
            count = ingestion.ingest_pdf("Brochure.pdf")
            return count, upsert.call_args_list

    def test_text_images_and_captions_are_indexed(self):
        page = _Page("hello world", [
            _ImageFile(Image.new("RGB", (50, 50))),    # too small: skipped
            _ImageFile(Image.new("RGBA", (200, 100))),  # indexed and captioned
        ])
        count, calls = self._ingest([page])

        self.assertEqual(count, 3)  # one text chunk, one image, one caption
        self.assertEqual([c.args[0] for c in calls], ["texts", "images", "texts"])
        image_payload = calls[1].args[1][0].payload
        self.assertEqual(image_payload["page"], 1)
        self.assertEqual(image_payload["source"], "Brochure.pdf")
        self.assertTrue(image_payload["path"].endswith("-p1-1.jpg"))

    def test_failed_caption_keeps_the_image(self):
        page = _Page("hello", [_ImageFile(Image.new("RGB", (200, 100)))])

        def boom(path):
            raise RuntimeError("VLM down")

        count, calls = self._ingest([page], describe=boom)

        self.assertEqual(count, 2)  # text chunk + image, no caption
        self.assertEqual([c.args[0] for c in calls], ["texts", "images"])

    def test_existing_caption_is_not_recaptioned(self):
        page = _Page("hello", [_ImageFile(Image.new("RGB", (200, 100)))])
        existing = [SimpleNamespace(id=ingestion.point_id("Brochure.pdf", 1, "img", 0))]

        count, calls = self._ingest([page], existing=existing)

        self.assertEqual(count, 2)  # text chunk + image, caption already indexed
        self.assertEqual([c.args[0] for c in calls], ["texts", "images"])


if __name__ == "__main__":
    unittest.main()
