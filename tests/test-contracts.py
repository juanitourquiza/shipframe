import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/check-contracts.py"
SPEC = importlib.util.spec_from_file_location("check_contracts", SCRIPT)
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)


class ContractTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "skills/demo").mkdir(parents=True)
        (self.root / "agents").mkdir()
        self.write("skills/demo/SKILL.md", "---\nname: demo\ndescription: Demo skill\n---\n")
        self.write("agents/demo-agent.md", "---\nname: demo-agent\ndescription: Demo agent\nmodel: opus\ntools:\n  - Read\n---\n")
        self.write("routing.json", json.dumps({
            "schemaVersion": 2,
            "intents": {"demo": "demo"},
            "aliases": {"demo": ["demo-agent"]},
            "host_variants": {"demo": {"agents": "demo-agent", "expands_to": "demo"}},
            "qa_gate": {"tokens": ["qa-gate"]},
        }))

    def tearDown(self):
        self.temp.cleanup()

    def write(self, path, body):
        target = self.root / path
        target.write_text(body, encoding="utf-8")
        return target

    def test_accepts_consistent_skill_and_agent_metadata(self):
        self.write("skills/demo/SKILL.md", "---\nname: demo\ndescription: Demo skill\n---\n")
        self.write("agents/demo-agent.md", "---\nname: demo-agent\ndescription: Demo agent\nmodel: opus\ntools:\n  - Read\n---\n")
        self.assertEqual([], CHECKER.validate(self.root))

    def test_reports_missing_skill_metadata_at_file(self):
        path = self.write("skills/demo/SKILL.md", "---\nname: demo\n---\n")
        errors = CHECKER.validate(self.root)
        self.assertTrue(any(str(path.relative_to(self.root)) in error and "description" in error for error in errors), errors)

    def test_reports_inconsistent_name_at_file(self):
        path = self.write("skills/demo/SKILL.md", "---\nname: other\ndescription: Demo\n---\n")
        errors = CHECKER.validate(self.root)
        self.assertTrue(any(str(path.relative_to(self.root)) in error and "expected one of demo" in error for error in errors), errors)

    def test_reports_malformed_frontmatter(self):
        path = self.write("agents/broken.md", "# no metadata\n")
        errors = CHECKER.validate(self.root)
        self.assertTrue(any(str(path.relative_to(self.root)) in error and "frontmatter" in error for error in errors), errors)

    def test_rejects_unknown_routing_targets_and_schema(self):
        data = json.loads((self.root / "routing.json").read_text(encoding="utf-8"))
        data["schemaVersion"] = 1
        data["intents"]["demo"] = "missing-skill"
        data["aliases"]["demo"] = ["missing-agent"]
        data["host_variants"]["demo"] = {"agents": "missing-agent"}
        (self.root / "routing.json").write_text(json.dumps(data), encoding="utf-8")
        errors = CHECKER.validate(self.root)
        self.assertTrue(any("schemaVersion must be 2" in error for error in errors), errors)
        self.assertTrue(any("missing-agent" in error for error in errors), errors)
        self.assertTrue(any("missing-skill" in error for error in errors), errors)
        data["aliases"]["demo"] = [[]]
        (self.root / "routing.json").write_text(json.dumps(data), encoding="utf-8")
        errors = CHECKER.validate(self.root)
        self.assertTrue(any("not a known agent" in error for error in errors), errors)

    def test_small_is_qa_depth_only_with_risk_exclusions_and_mandatory_review(self):
        root = SCRIPT.parents[1]
        qa = (root / "agents/quality-assurance.md").read_text(encoding="utf-8")
        reviewer = (root / "agents/reviewer-agent.md").read_text(encoding="utf-8")
        for exclusion in ("public API", "authentication/secrets", "migration", "CI"):
            self.assertIn(exclusion, qa)
        self.assertIn("Small is a reduced QA-depth path only", qa)
        self.assertIn("TASK_SIZE classification", qa)
        self.assertIn("mandatory for every task", reviewer)


if __name__ == "__main__":
    unittest.main()
