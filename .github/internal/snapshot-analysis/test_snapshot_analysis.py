import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import prepare
import publish


class PrepareTests(unittest.TestCase):
    def write_result(self, results_dir, name, branch_name, results):
        path = results_dir / name
        path.write_text(
            json.dumps(
                {
                    "gha_branch_name": name.removesuffix(".json"),
                    "branch_name": branch_name,
                    "results": results,
                }
            )
        )
        return path

    def test_latest_main_run_snapshot_failures_are_selected(self):
        with tempfile.TemporaryDirectory() as tmp:
            results_dir = Path(tmp) / "__test_results"
            results_dir.mkdir()
            self.write_result(
                results_dir,
                "gha-aaaaaaa-2026_07_03_05_00-4.6-Linux.json",
                "main",
                [{"app_name": "old", "status": "fail", "result": "old failure"}],
            )
            self.write_result(
                results_dir,
                "gha-bbbbbbb-2026_07_06_05_00-4.6-Linux.json",
                "main",
                [
                    {
                        "app_name": "snap-app",
                        "status": "fail",
                        "result": "Snapshot of `file` has changed.",
                    },
                    {
                        "app_name": "install-app",
                        "status": "can_not_install",
                        "result": "package install failed",
                    },
                ],
            )
            self.write_result(
                results_dir,
                "gha-ccccccc-2026_07_07_05_00-4.6-Linux.json",
                "feature",
                [{"app_name": "ignored", "status": "fail", "result": "Snapshot changed"}],
            )

            context = prepare.build_context(results_dir)

            self.assertEqual(context["date"], "2026-07-06")
            self.assertEqual(context["dashboard_path"], "2026/07/06")
            self.assertEqual(context["base_sha"], "bbbbbbb")
            self.assertEqual(context["failure_count"], 2)
            self.assertEqual(context["snapshot_failure_count"], 1)
            self.assertEqual(context["snapshot_failures"][0]["app_name"], "snap-app")
            self.assertEqual(context["snapshot_failures"][0]["snapshot_gate"], "snapshot_changed")

    def test_result_name_accepts_extra_key_after_sha(self):
        info = prepare.parse_result_name("gha-abc1234extra-2026_07_06_05_00-4.6-Linux.json")

        self.assertEqual(info["sha"], "abc1234extra")
        self.assertEqual(info["date"], "2026-07-06")

    def test_unparseable_and_non_main_files_are_ignored(self):
        with tempfile.TemporaryDirectory() as tmp:
            results_dir = Path(tmp) / "__test_results"
            results_dir.mkdir()
            self.write_result(
                results_dir,
                "not-a-result-file.json",
                "main",
                [{"app_name": "ignored-bad-name", "status": "fail", "result": "Snapshot changed"}],
            )
            self.write_result(
                results_dir,
                "gha-ccccccc-2026_07_07_05_00-4.6-Linux.json",
                "feature",
                [{"app_name": "ignored-non-main", "status": "fail", "result": "Snapshot changed"}],
            )
            self.write_result(
                results_dir,
                "gha-bbbbbbb-2026_07_06_05_00-4.6-Linux.json",
                "main",
                [{"app_name": "kept", "status": "pass", "result": "ok"}],
            )

            context = prepare.build_context(results_dir)

            self.assertEqual(context["date"], "2026-07-06")
            self.assertEqual(context["failure_count"], 0)

    def test_prompt_skips_fix_snaps_when_there_are_no_snapshot_failures(self):
        context = {
            "date": "2026-07-06",
            "base_sha": "bbbbbbb",
            "failure_count": 1,
            "snapshot_failure_count": 0,
            "snapshot_failures": [],
            "failures": [],
        }

        prompt = prepare.build_prompt(context)

        self.assertIn("do not run fix_snaps", prompt)
        self.assertIn("No snapshot-related failures", prompt)


class PublishTests(unittest.TestCase):
    def test_execution_summary_reads_cost_duration_and_result(self):
        with tempfile.TemporaryDirectory() as tmp:
            log_path = Path(tmp) / "claude.json"
            log_path.write_text(
                json.dumps(
                    [
                        {"type": "assistant", "message": {"content": [{"type": "text", "text": "draft"}]}},
                        {
                            "type": "result",
                            "result": "## Summary\nMinute changes accepted.",
                            "total_cost_usd": 0.123456,
                            "duration_ms": 65000,
                            "num_turns": 4,
                        },
                    ]
                )
            )

            summary = publish.read_claude_execution(log_path)

            self.assertEqual(summary["report"], "## Summary\nMinute changes accepted.")
            self.assertEqual(summary["cost_usd"], 0.123456)
            self.assertEqual(summary["duration_seconds"], 65)
            self.assertEqual(summary["num_turns"], 4)

    def test_dashboard_card_injection_is_idempotent(self):
        html = "<html><body><h1>Dashboard</h1></body></html>"
        first = publish.inject_dashboard_card(html, "<section>first</section>")
        second = publish.inject_dashboard_card(first, "<section>second</section>")

        self.assertIn("<section>second</section>", second)
        self.assertNotIn("<section>first</section>", second)
        self.assertEqual(second.count(publish.CARD_BEGIN), 1)
        self.assertEqual(second.count(publish.CARD_END), 1)


if __name__ == "__main__":
    unittest.main()
