import importlib.util
import unittest
from pathlib import Path
from unittest.mock import call, patch


SCRIPT = Path(__file__).parents[1] / "templates/pr-review/sf_pr_review.py"
spec = importlib.util.spec_from_file_location("sf_pr_review", SCRIPT)
reviewer = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(reviewer)


class GitLabCommentTests(unittest.TestCase):
    def test_posts_comment_with_private_token_when_no_review_exists(self):
        with patch.object(reviewer, "http_json", return_value=[]) as request:
            reviewer.publish_gitlab_comment(
                "https://gitlab.example/api/v4", "42", "7", "secret-token",
                "abcdef1234567890", "glm5.3-flash", "Verdict: approved",
            )

        self.assertEqual(request.call_count, 2)
        get_call, post_call = request.call_args_list
        self.assertEqual(get_call.args[:3], (
            "https://gitlab.example/api/v4/projects/42/merge_requests/7/notes?per_page=100&page=1",
            "GET", "",
        ))
        self.assertEqual(get_call.kwargs["extra_headers"], {"PRIVATE-TOKEN": "secret-token"})
        self.assertEqual(post_call.args[:3], (
            "https://gitlab.example/api/v4/projects/42/merge_requests/7/notes", "POST", "",
        ))
        self.assertIn(reviewer.MARKER, post_call.args[3]["body"])
        self.assertIn("abcdef123456", post_call.args[3]["body"])

    def test_updates_existing_shipframe_note_instead_of_adding_another(self):
        existing = [{"id": 17, "body": f"{reviewer.MARKER}\nold review"}]
        with patch.object(reviewer, "http_json", side_effect=[existing, {}]) as request:
            reviewer.publish_gitlab_comment(
                "https://gitlab.example/api/v4", "42", "7", "secret-token",
                "abcdef1234567890", "glm5.3-flash", "Verdict: changes needed",
            )

        self.assertEqual(request.call_count, 2)
        self.assertEqual(request.call_args_list[1].args[1], "PUT")
        self.assertTrue(request.call_args_list[1].args[0].endswith("/notes/17"))

    def test_rejects_unexpected_notes_response(self):
        with patch.object(reviewer, "http_json", return_value={"message": "bad"}):
            with self.assertRaisesRegex(RuntimeError, "Unexpected GitLab notes response"):
                reviewer.publish_gitlab_comment(
                    "https://gitlab.example/api/v4", "42", "7", "secret-token",
                    "abcdef1234567890", "glm5.3-flash", "Verdict: approved",
                )


if __name__ == "__main__":
    unittest.main()
