"""Offline tests for the lite profile (verdict-rules.json `lite`): small builder models run the build on fewer gate
runs, smaller Phase 4 caps and a one-reviewer panel. The profile lives in work/manifest.yaml (`check_gate.py --next
--profile lite`, once) and CSA_PROFILE forces it; the full profile is unchanged.

    python3 -B -m unittest discover -s <skill>/tests -v
"""

from __future__ import annotations

import json
import os
import unittest
from pathlib import Path
from unittest import mock

from helpers import SCRIPTS, TempWorkspace
import gate_common  # noqa: E402  (on sys.path through helpers)

SKILL = SCRIPTS.parent


class ProfileTest(TempWorkspace):
    def manifest(self) -> Path:
        return self.ws / "work" / "manifest.yaml"

    def test_full_unless_the_manifest_or_the_environment_says_lite(self) -> None:
        with mock.patch.dict(os.environ, {"CSA_PROFILE": ""}):
            self.assertEqual(gate_common.profile(self.ws), "full")
            self.manifest().parent.mkdir(parents=True)
            self.manifest().write_text("pairs: []\nprofile: lite  # set once\n")
            self.assertEqual(gate_common.profile(self.ws), "lite")
            self.manifest().write_text("profile: turbo\n")
            self.assertEqual(gate_common.profile(self.ws), "full", "an unknown profile is the full one")
        with mock.patch.dict(os.environ, {"CSA_PROFILE": "lite"}):
            self.assertEqual(gate_common.profile(self.ws), "lite", "the environment forces it")
        self.manifest().write_text("profile: lite\n")
        with mock.patch.dict(os.environ, {"CSA_PROFILE": "full"}):
            self.assertEqual(gate_common.profile(self.ws), "full", "the environment wins over the manifest")

    def test_next_profile_lite_stores_it_once_and_every_later_call_reads_it(self) -> None:
        self.make_build(["gold-01"])
        self.manifest().write_text("pairs:\n  - input: input/a.md\n    reference: input/a.json\n")
        out = self.run_script("check_gate.py", "--next", "--profile", "lite", CSA_PROFILE="")
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertTrue(out.stdout.startswith("PROFILE: lite"), out.stdout)
        text = self.manifest().read_text()
        self.assertIn("pairs:\n  - input: input/a.md\n    reference: input/a.json\n", text, "other lines kept")
        self.assertEqual(text.count("profile: lite"), 1)
        self.assertTrue(self.run_script("check_gate.py", "--next", CSA_PROFILE="").stdout.startswith("PROFILE: lite"))
        self.run_script("check_gate.py", "--next", "--profile", "lite", CSA_PROFILE="")
        self.assertEqual(self.manifest().read_text().count("profile:"), 1, "re-running replaces, never appends")
        self.run_script("check_gate.py", "--next", "--profile", "full", CSA_PROFILE="")
        self.assertNotIn("PROFILE: lite", self.run_script("check_gate.py", "--next", CSA_PROFILE="").stdout)

    def test_profile_goes_with_next(self) -> None:
        self.make_build(["gold-01"])
        out = self.run_script("check_gate.py", "--finish", "--profile", "lite")
        self.assertEqual(out.returncode, 2)
        self.assertIn("--profile goes with --next", out.stderr)


class LiteRulesTest(unittest.TestCase):
    def test_the_numbers_live_in_verdict_rules(self) -> None:
        lite = json.loads((SKILL / "references" / "verdict-rules.json").read_text())["lite"]
        self.assertEqual((lite["runs_per_arm"], lite["max_iterations"], lite["plateau_window"],
                          lite["max_panel_rounds"], lite["panel"]), (2, 3, 2, 2, ["reviewer"]))
        self.assertGreaterEqual(lite["runs_per_arm"], 2, "never a 1-run gate")

    def test_skill_md_names_the_lite_profile_near_the_top(self) -> None:
        lines = (SKILL / "SKILL.md").read_text().splitlines()
        top = next(i for i, line in enumerate(lines) if line.startswith("| Phase |"))
        [line] = [x for x in lines[:top] if "--profile lite" in x]
        self.assertIn("CSA_PROFILE=lite", line)
        self.assertIn("Small or fast model", line)


if __name__ == "__main__":
    unittest.main()
