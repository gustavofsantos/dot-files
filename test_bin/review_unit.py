import importlib.util
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path


REVIEW_PATH = Path(__file__).resolve().parents[1] / "bin" / "review"
loader = SourceFileLoader("review_cli", str(REVIEW_PATH))
spec = importlib.util.spec_from_loader(loader.name, loader)
review = importlib.util.module_from_spec(spec)
loader.exec_module(review)


class DisplayRenderingTests(unittest.TestCase):
    def test_open_comment_shows_marked_source_and_note(self):
        record = {
            "id": "r1",
            "status": "pending",
            "file": "app.py",
            "start_line": 2,
            "end_line": 3,
            "code": "two\nthree",
            "comment": "tighten this",
            "author": "tester",
            "lane": "auth",
        }

        output = review.render_display(record)

        self.assertIn("REVIEW LINE r1", output)
        self.assertIn("[PENDING]", output)
        self.assertIn("app.py:2-3", output)
        self.assertIn("> 2 | two", output)
        self.assertIn("> 3 | three", output)
        self.assertIn("tighten this", output)

    def test_display_keeps_every_physical_line_within_80_columns(self):
        record = {
            "id": "r1",
            "status": "pulled",
            "file": "nested/" + ("long_name/" * 10) + "app.py",
            "start_line": 2,
            "end_line": 2,
            "code": "two " + ("wrapped source " * 10),
            "comment": "tighten " + ("this note " * 10),
            "author": "reviewer-" + ("a" * 80),
            "lane": "lane-" + ("b" * 80),
        }

        output = review.render_display(record)

        for line in output.splitlines():
            self.assertLessEqual(len(line), 80, line)


if __name__ == "__main__":
    unittest.main()
