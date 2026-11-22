import unittest
from unittest.mock import patch

import numpy as np
from openai import OpenAIError

from app import agent as agent_module
from app.agent import _image_urls
from app.errors import LLMUnavailable


class _Message:
    def __init__(self, type, content):
        self.type = type
        self.content = content


class _Agent:
    def __init__(self, result=None, error=None):
        self.result, self.error = result, error

    def invoke(self, *args, **kwargs):
        if self.error:
            raise self.error
        return self.result


class ImageUrlsTest(unittest.TestCase):
    def test_only_current_turn_is_used_and_duplicates_removed(self):
        messages = [
            _Message("human", "old question"),
            _Message("tool", "/images/old.jpg"),
            _Message("ai", "old answer"),
            _Message("human", "new question"),
            _Message("tool", "/images/new.jpg (Brochure.pdf p.2)\n/images/new.jpg"),
            _Message("ai", "see `/images/new.jpg`."),
        ]

        self.assertEqual(_image_urls(messages), ["/images/new.jpg"])

    def test_at_most_six_images(self):
        messages = [_Message("human", "q")] + [
            _Message("tool", f"/images/{i}.jpg") for i in range(10)]

        self.assertEqual(len(_image_urls(messages)), 6)


class _Point:
    def __init__(self, payload):
        self.payload = payload


class _Hit:
    def __init__(self, payload, score=0.5):
        self.payload, self.score = payload, score


class _Response:
    def __init__(self, points):
        self.points = points


class PageImageTest(unittest.TestCase):
    def _page_image(self, query):
        points = [
            _Point({"source": "Brochure.pdf", "page": 5,
                    "content": "LE MOT DE MOHAMMED EL RHABI Directeur Général"}),
            _Point({"source": "Brochure.pdf", "page": 9,
                    "content": "This image shows a woman in an office"}),
        ]
        image = _Hit({"path": "data/images/p5-0.jpg",
                      "source": "Brochure.pdf", "page": 5}, 0.3)
        with patch.object(agent_module.client, "scroll", return_value=(points, None)), \
             patch.object(agent_module, "embed_text", return_value=np.zeros((1, 1024))), \
             patch.object(agent_module, "search",
                          return_value=[_Hit({"source": "Brochure.pdf", "page": 5}, 0.6)]), \
             patch.object(agent_module, "embed_text_for_image_search",
                          return_value=np.zeros(512)), \
             patch.object(agent_module.client, "query_points",
                          return_value=_Response([image])):
            return agent_module._page_image(query)

    def test_person_name_uses_the_page_that_names_them(self):
        hit = self._page_image("Mohammed El Rhabi")
        self.assertEqual(hit.payload["path"], "data/images/p5-0.jpg")

    def test_role_uses_the_page_that_names_the_role(self):
        hit = self._page_image("directeur général")
        self.assertEqual(hit.payload["page"], 5)

    def test_general_query_is_not_page_grounded(self):
        self.assertIsNone(self._page_image("filières de l'EMSI"))

    def test_page_rank_uses_best_chunk_score_not_last(self):
        """Same name on two pages: later weak chunks must not beat an earlier strong one."""
        points = [
            _Point({"source": "Brochure.pdf", "page": 5,
                    "content": "Mohammed El Rhabi Directeur Général"}),
            _Point({"source": "Brochure.pdf", "page": 9,
                    "content": "Mohammed El Rhabi Directeur adjoint"}),
        ]
        # Last-write-wins would keep page 5=0.1 and page 9=0.4, so 9 would win.
        search_hits = [
            _Hit({"source": "Brochure.pdf", "page": 5}, 0.9),
            _Hit({"source": "Brochure.pdf", "page": 9}, 0.2),
            _Hit({"source": "Brochure.pdf", "page": 5}, 0.1),
            _Hit({"source": "Brochure.pdf", "page": 9}, 0.4),
        ]
        chosen = {"page": None}

        def query_points(**kwargs):
            page = kwargs["query_filter"].must[1].match.value
            if chosen["page"] is None:
                chosen["page"] = page
            image = _Hit({"path": f"data/images/p{page}-0.jpg",
                          "source": "Brochure.pdf", "page": page})
            return _Response([image])

        with patch.object(agent_module.client, "scroll", return_value=(points, None)), \
             patch.object(agent_module, "embed_text", return_value=np.zeros((1, 1024))), \
             patch.object(agent_module, "search", return_value=search_hits), \
             patch.object(agent_module, "embed_text_for_image_search",
                          return_value=np.zeros(512)), \
             patch.object(agent_module.client, "query_points", side_effect=query_points):
            hit = agent_module._page_image("Mohammed El Rhabi Directeur")

        self.assertEqual(chosen["page"], 5)
        self.assertEqual(hit.payload["page"], 5)


class FallbackTest(unittest.TestCase):
    def test_ask_uses_the_next_key_when_the_first_fails(self):
        agents = [("groq key 1", _Agent(error=OpenAIError("down"))),
                  ("groq key 2", _Agent(result={"messages": [_Message("ai", "hello")]}))]
        with patch.object(agent_module, "agents", agents):
            self.assertEqual(agent_module.ask("hi"), ("hello", []))

    def test_ask_raises_when_every_key_fails(self):
        agents = [("groq key 1", _Agent(error=OpenAIError("down"))),
                  ("openrouter", _Agent(error=OpenAIError("down")))]
        with patch.object(agent_module, "agents", agents):
            with self.assertRaises(LLMUnavailable):
                agent_module.ask("hi")


if __name__ == "__main__":
    unittest.main()
