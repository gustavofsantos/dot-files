import importlib.util
import subprocess
import tempfile
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path


REVIEW_PATH = Path(__file__).resolve().parents[1] / "bin" / "review"
loader = SourceFileLoader("review_cli", str(REVIEW_PATH))
spec = importlib.util.spec_from_loader(loader.name, loader)
review = importlib.util.module_from_spec(spec)
loader.exec_module(review)


class DisplayRenderingTests(unittest.TestCase):
    def test_submitted_review_sheet_keeps_ordered_evidence_blocks(self):
        submitted = {
            "id": "rv1",
            "status": "pending",
            "author": "tester",
            "lane": "auth",
            "decision": "request-changes",
            "summary": "The error path must be fixed before merging.",
            "comment_ids": ["r1", "r2"],
        }
        comments = [
            {
                "id": "r1",
                "status": "pending",
                "file": "app.py",
                "start_line": 1,
                "end_line": 1,
                "code": "one",
                "comment": "first finding",
            },
            {
                "id": "r2",
                "status": "pending",
                "file": "app.py",
                "start_line": 2,
                "end_line": 2,
                "code": "two",
                "comment": "second finding",
            },
        ]

        output = review.render_review_display(submitted, comments)

        self.assertIn("REVIEW SHEET rv1", output)
        self.assertIn("[PENDING]", output)
        self.assertIn("REQUEST CHANGES", output)
        self.assertIn("SUMMARY", output)
        self.assertIn("LEDGER", output)
        self.assertIn("EVIDENCE 1", output)
        self.assertIn("EVIDENCE 2", output)
        self.assertLess(output.index("1. r1"), output.index("2. r2"))
        self.assertLess(output.index("EVIDENCE 1"), output.index("EVIDENCE 2"))
        self.assertIn("> 1 | one", output)
        self.assertIn("> 2 | two", output)
        self.assertIn("first finding", output)
        self.assertIn("second finding", output)

        for line in output.splitlines():
            self.assertLessEqual(len(line), 80, line)

    def test_submitted_review_is_complete_when_all_comments_are_terminal(self):
        submitted = {
            "id": "rv1",
            "status": "pulled",
            "decision": "request-changes",
            "summary": "Resolve every finding.",
            "comment_ids": ["r1", "r2"],
        }
        comments = [
            {
                "id": "r1",
                "status": "done",
                "file": "app.py",
                "start_line": 1,
                "end_line": 1,
                "code": "one",
                "comment": "first finding",
            },
            {
                "id": "r2",
                "status": "rejected",
                "file": "app.py",
                "start_line": 2,
                "end_line": 2,
                "code": "two",
                "comment": "second finding",
            },
        ]

        output = review.render_review_display(submitted, comments)

        self.assertIn("[COMPLETE]", output)

    def test_missing_submitted_comment_keeps_the_review_incomplete(self):
        submitted = {
            "id": "rv1",
            "status": "pulled",
            "decision": "request-changes",
            "summary": "The linked finding must remain accountable.",
            "comment_ids": ["r1"],
        }

        output = review.render_review_display(submitted, [])

        self.assertIn("[PULLED]", output)
        self.assertIn("MISSING r1", output)
        self.assertNotIn("[COMPLETE]", output)

    def test_completed_comment_shows_the_snapshot_diff_and_resolution(self):
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory)
            subprocess.run(["git", "-C", directory, "init", "-q"], check=True)
            before = subprocess.run(
                ["git", "-C", directory, "hash-object", "-w", "--stdin"],
                input="one\ntwo\nthree\n",
                text=True,
                capture_output=True,
                check=True,
            ).stdout.strip()
            after = subprocess.run(
                ["git", "-C", directory, "hash-object", "-w", "--stdin"],
                input="one\nchanged-two\nthree-modified\n",
                text=True,
                capture_output=True,
                check=True,
            ).stdout.strip()
            record = {
                "id": "r1",
                "status": "done",
                "workspace": str(workspace),
                "file": "app.py",
                "start_line": 2,
                "end_line": 2,
                "code": "two",
                "comment": "change this",
                "author": "tester",
                "lane": "auth",
                "file_version": before,
                "resolved_file_version": after,
                "resolved_by": "impl-agent",
                "resolution_note": "updated implementation",
            }

            output = review.render_display(record)

        self.assertIn("[DONE]", output)
        self.assertIn("DIFF", output)
        self.assertIn("-two", output)
        self.assertIn("+changed-two", output)
        self.assertIn("-three", output)
        self.assertIn("+three-modified", output)
        self.assertIn("RESOLUTION", output)
        self.assertIn("updated implementation", output)

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
