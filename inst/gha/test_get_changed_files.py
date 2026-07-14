import json
import os
import tempfile
import unittest
from io import BytesIO
from unittest.mock import MagicMock, mock_open, patch
import importlib.util
import sys
import urllib.error

spec = importlib.util.spec_from_file_location(
    "get_changed_files", "inst/gha/get-changed-files.py"
)
get_changed_files_mod = importlib.util.module_from_spec(spec)
sys.modules["get_changed_files"] = get_changed_files_mod
spec.loader.exec_module(get_changed_files_mod)

get_pull_request_number = get_changed_files_mod.get_pull_request_number
get_changed_files = get_changed_files_mod.get_changed_files
write_output = get_changed_files_mod.write_output
main = get_changed_files_mod.main


def _mock_urlopen_response(payload):
    """Return a context-manager mock whose body is JSON-loadable."""
    response = MagicMock()
    response.__enter__.return_value = BytesIO(
        json.dumps(payload).encode("utf-8")
    )
    response.__exit__.return_value = False
    return response


class TestGetChangedFiles(unittest.TestCase):
    def test_get_pull_request_number(self):
        m = mock_open(read_data=json.dumps({"number": 123}))
        with patch("builtins.open", m):
            self.assertEqual(get_pull_request_number("dummy_path"), 123)

        m = mock_open(read_data=json.dumps({"pull_request": {"number": 456}}))
        with patch("builtins.open", m):
            self.assertEqual(get_pull_request_number("dummy_path"), 456)

        m = mock_open(read_data=json.dumps({}))
        with patch("builtins.open", m):
            self.assertIsNone(get_pull_request_number("dummy_path"))

    @patch("urllib.request.urlopen")
    def test_get_changed_files_single_page(self, mock_urlopen):
        mock_urlopen.return_value = _mock_urlopen_response(
            [{"filename": "file1.txt"}]
        )

        files = get_changed_files(
            "https://api.github.com", "owner/repo", 123, "token"
        )
        self.assertEqual(files, ["file1.txt"])
        self.assertEqual(mock_urlopen.call_count, 1)

    @patch("urllib.request.urlopen")
    def test_get_changed_files_pagination(self, mock_urlopen):
        page1 = [{"filename": f"f{i}.txt"} for i in range(100)]
        page2 = [{"filename": "last.txt"}]
        mock_urlopen.side_effect = [
            _mock_urlopen_response(page1),
            _mock_urlopen_response(page2),
        ]

        files = get_changed_files(
            "https://api.github.com", "owner/repo", 99, "token"
        )
        self.assertEqual(len(files), 101)
        self.assertEqual(files[0], "f0.txt")
        self.assertEqual(files[-1], "last.txt")
        self.assertEqual(mock_urlopen.call_count, 2)

        # Second request should request page=2
        second_request = mock_urlopen.call_args_list[1][0][0]
        self.assertIn("page=2", second_request.full_url)

    @patch("urllib.request.urlopen")
    def test_get_changed_files_empty(self, mock_urlopen):
        mock_urlopen.return_value = _mock_urlopen_response([])
        files = get_changed_files(
            "https://api.github.com", "owner/repo", 1, "token"
        )
        self.assertEqual(files, [])

    @patch("urllib.request.urlopen")
    def test_get_changed_files_http_error(self, mock_urlopen):
        error = urllib.error.HTTPError(
            url="https://api.github.com/repos/o/r/pulls/1/files",
            code=403,
            msg="Forbidden",
            hdrs=None,
            fp=BytesIO(b'{"message":"bad credentials"}'),
        )
        mock_urlopen.side_effect = error
        with self.assertRaises(SystemExit) as ctx:
            get_changed_files("https://api.github.com", "o/r", 1, "token")
        self.assertIn("HTTP 403", str(ctx.exception))

    def test_write_output(self):
        with tempfile.NamedTemporaryFile(
            mode="w+", encoding="utf-8", delete=False
        ) as tmp:
            path = tmp.name
        try:
            write_output(path, ["a/b.R", 'quote"name.txt'])
            with open(path, encoding="utf-8") as f:
                content = f.read().strip()
            self.assertTrue(content.startswith("all="))
            parsed = json.loads(content.split("=", 1)[1])
            self.assertEqual(parsed, ["a/b.R", 'quote"name.txt'])
        finally:
            os.unlink(path)

    @patch.object(get_changed_files_mod, "get_changed_files")
    def test_main_writes_github_output(self, mock_get_files):
        mock_get_files.return_value = ["inst/apps/001/app.R"]
        event = {"number": 42}
        with tempfile.TemporaryDirectory() as tmp:
            event_path = os.path.join(tmp, "event.json")
            output_path = os.path.join(tmp, "output")
            with open(event_path, "w", encoding="utf-8") as f:
                json.dump(event, f)
            with open(output_path, "w", encoding="utf-8"):
                pass

            env = {
                "GITHUB_TOKEN": "tok",
                "GITHUB_OUTPUT": output_path,
                "GITHUB_EVENT_PATH": event_path,
                "GITHUB_REPOSITORY": "rstudio/shinycoreci",
                "GITHUB_API_URL": "https://api.github.com",
            }
            with patch.dict(os.environ, env, clear=False):
                with patch("sys.stdout", new=MagicMock()):
                    main()

            with open(output_path, encoding="utf-8") as f:
                content = f.read().strip()
            parsed = json.loads(content.split("=", 1)[1])
            self.assertEqual(parsed, ["inst/apps/001/app.R"])
            mock_get_files.assert_called_once_with(
                "https://api.github.com",
                "rstudio/shinycoreci",
                42,
                "tok",
            )


if __name__ == "__main__":
    unittest.main()
