#!/usr/bin/env python3
"""End-to-end tests for the bundled Causality CLI using a temporary model."""

import json
import os
import sqlite3
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("causality")

MODEL = '''
[[phenomena]]
id = "platform.deployment"
kind = "event"
domain = "platform"
description = "A production deployment."
aliases = ["deploy"]

[[phenomena]]
id = "platform.latency"
kind = "signal"
domain = "platform"
description = "Request latency."
aliases = ["slow requests"]

[[phenomena]]
id = "finance.revenue"
kind = "derived"
domain = "finance"
description = "Recognized revenue."

[[phenomena]]
id = "hr.employee_birthday"
kind = "event"
domain = "hr"
description = "An employee birthday."

[[relations]]
id = "rel.deployment.latency"
from = ["platform.deployment"]
to = ["platform.latency"]
kind = "causal"
effect = "increase"
status = "supported"
temporal_mode = "asynchronous"
min_lag = "0s"
max_lag = "2h"
description = "Deployments can increase latency."

[[relations]]
id = "rel.latency.revenue"
from = ["platform.latency"]
to = ["finance.revenue"]
kind = "causal"
effect = "decrease"
status = "hypothesis"
temporal_mode = "asynchronous"
min_lag = "1m"
max_lag = "1d"
description = "Latency can reduce revenue."

[[bindings]]
id = "binding.latency.current"
concept = "platform.latency"
role = "canonical"
schema = "analytics_gold"
table = "request_metrics"
time_column = "event_ts"
entity_key = "service_id"
grain_entity = "service"
grain_time = "5m"
valid_from = "2026-01-01"
estimated_rows = 8400000000
estimated_bytes = 4200000000000
partition_keys = ["event_date"]
cluster_keys = ["service_id"]
require_partition_filter = true
recommended_time_window = "7d"
query_ref = "queries/platform_latency.sql"

[bindings.null_rates]
service_id = 0.001

[[bindings]]
id = "binding.latency.legacy"
concept = "platform.latency"
role = "legacy"
schema = "legacy"
table = "latency_daily"
grain_entity = "service"
grain_time = "day"
valid_until = "2025-12-31"

[[evidence]]
id = "evidence.deployment.latency"
relation = "rel.deployment.latency"
type = "incident"
source = "INC-1"
description = "Latency followed a deployment."

[[tests]]
kind = "path_exists"
from = "platform.deployment"
to = "finance.revenue"
max_depth = 3

[[tests]]
kind = "no_path"
from = "hr.employee_birthday"
to = "platform.latency"
max_depth = 3

[[tests]]
kind = "binding_exists"
concept = "platform.latency"
role = "canonical"
'''


class CausalityTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "model").mkdir()
        (self.root / "model" / "demo.causal.toml").write_text(MODEL)
        (self.root / "causality.toml").write_text('''
model_dir = "model"
proposals_dir = "proposals"
investigations_dir = "investigations"
sqlite_path = ".generated/causality.sqlite"
default_neighborhood_depth = 1
default_path_limit = 20
default_result_limit = 50
[safety]
large_table_rows = 100000000
large_table_bytes = 100000000000
''')
        self.run_cli("compile")

    def tearDown(self):
        self.tmp.cleanup()

    def run_cli(self, *args, expected=0):
        result = subprocess.run([str(SCRIPT), *args], cwd=self.root, text=True, capture_output=True)
        self.assertEqual(expected, result.returncode, result.stderr or result.stdout)
        stream = result.stdout if expected == 0 else result.stderr
        return json.loads(stream)

    def test_validate_test_compile_and_sqlite(self):
        self.assertTrue(self.run_cli("validate")["ok"])
        self.assertEqual(3, self.run_cli("test")["data"]["passed"])
        result = self.run_cli("compile")
        database = Path(result["data"]["sqlite_path"])
        self.assertTrue(database.is_file())
        with sqlite3.connect(database) as con:
            self.assertEqual(4, con.execute("select count(*) from phenomena").fetchone()[0])
            self.assertEqual("ok", con.execute("pragma integrity_check").fetchone()[0])

    def test_resolve_neighborhood_paths_and_query_plan(self):
        self.assertEqual("platform.latency", self.run_cli("resolve", "slow requests")["data"]["candidates"][0]["id"])
        hood = self.run_cli("neighborhood", "finance.revenue", "--direction", "upstream", "--depth", "2")
        self.assertEqual({"finance.revenue", "platform.latency", "platform.deployment"}, {n["id"] for n in hood["data"]["nodes"]})
        paths = self.run_cli("paths", "platform.deployment", "finance.revenue")
        self.assertEqual(["platform.deployment", "platform.latency", "finance.revenue"], paths["data"]["paths"][0]["nodes"])
        plan = self.run_cli("query-plan", "platform.latency", "--from", "2026-08-01", "--to", "2026-08-02")
        self.assertTrue(plan["data"]["safety"]["require_partition_filter"])
        self.assertFalse(plan["data"]["safety"]["safe_to_query"])
        self.assertEqual("PARTITION_PREDICATE_REQUIRED", plan["data"]["safety"]["blockers"][0]["code"])
        safe_plan = self.run_cli("query-plan", "platform.latency", "--from", "2026-08-01", "--to", "2026-08-02", "--partition-key", "event_date")
        self.assertTrue(safe_plan["data"]["safety"]["safe_to_query"])
        historical = self.run_cli("binding", "platform.latency", "--to", "2025-12-01")
        self.assertEqual("binding.latency.legacy", historical["data"]["bindings"][0]["id"])

    def test_investigation_persists_refutation_without_mutating_model(self):
        self.run_cli("investigate", "start", "--id", "latency-incident", "--effect", "platform.latency", "--direction", "increase", "--from", "2026-08-20T08:00:00+00:00", "--to", "2026-08-20T12:00:00+00:00")
        self.run_cli("investigate", "candidate", "add", "latency-incident", "--id", "deploy-path", "--path", "platform.deployment,platform.latency")
        self.run_cli("investigate", "evidence", "add", "latency-incident", "--candidate", "deploy-path", "--type", "query_result", "--source", "query-1.json", "--summary", "No deployment occurred.")
        self.run_cli("investigate", "refute", "latency-incident", "deploy-path", "--reason", "No deployment occurred in the window.")
        status = self.run_cli("investigate", "status", "latency-incident")
        self.assertEqual("deploy-path", status["data"]["candidates"]["refuted"][0]["id"])
        self.assertIn('status = "supported"', (self.root / "model" / "demo.causal.toml").read_text())

    def test_proposals_are_excluded_by_default(self):
        self.run_cli("propose", "relation", "--id", "proposal.birthday.revenue", "--from", "hr.employee_birthday", "--to", "finance.revenue", "--kind", "causal", "--effect", "increase")
        normal = self.run_cli("paths", "hr.employee_birthday", "finance.revenue")
        self.run_cli("compile")
        proposed = self.run_cli("paths", "hr.employee_birthday", "finance.revenue", "--include-proposed")
        self.assertEqual([], normal["data"]["paths"])
        self.assertEqual(1, len(proposed["data"]["paths"]))
        self.assertFalse((self.root / "model" / "proposal.birthday.revenue.causal.toml").exists())

    def test_invalid_model_does_not_replace_compiled_database(self):
        self.run_cli("compile")
        database = self.root / ".generated" / "causality.sqlite"
        before = database.read_bytes()
        with (self.root / "model" / "demo.causal.toml").open("a") as handle:
            handle.write('\n[[relations]]\nid="rel.bad"\nfrom=["missing"]\nto=["platform.latency"]\nkind="causal"\neffect="increase"\nstatus="supported"\ntemporal_mode="unknown"\n')
        failure = self.run_cli("compile", expected=3)
        self.assertEqual("VALIDATION_FAILED", failure["error"]["code"])
        self.assertEqual(before, database.read_bytes())

    def test_invalid_proposal_is_reported_without_breaking_trusted_index(self):
        self.run_cli("propose", "relation", "--id", "proposal.invalid", "--from", "unknown.concept", "--to", "finance.revenue", "--kind", "causal", "--effect", "increase")
        compiled = self.run_cli("compile")
        self.assertEqual("INVALID", compiled["data"]["proposals"][0]["status"])
        hood = self.run_cli("neighborhood", "finance.revenue", "--direction", "upstream")
        self.assertEqual("finance.revenue", hood["data"]["root"])

    def test_retrieval_uses_compiled_index_not_current_source_files(self):
        path = self.root / "model" / "demo.causal.toml"
        path.write_text(path.read_text() + '\n[[relations]]\nid = "rel.uncompiled.bad"\nfrom = ["missing"]\nto = ["platform.latency"]\nkind = "causal"\neffect = "increase"\nstatus = "candidate"\ntemporal_mode = "unknown"\ndescription = "Not in the index."\n')
        result = self.run_cli("neighborhood", "platform.latency", "--direction", "upstream")
        self.assertEqual("platform.latency", result["data"]["root"])

    def test_binding_requires_full_window_and_accepts_datetimes(self):
        split = self.run_cli("binding", "platform.latency", "--from", "2025-12-30T08:00:00-03:00", "--to", "2026-01-02T08:00:00-03:00")
        self.assertEqual("SPLIT_REQUIRED", split["data"]["resolution"])
        plan = self.run_cli("query-plan", "platform.latency", "--from", "2025-12-30T08:00:00-03:00", "--to", "2026-01-02T08:00:00-03:00")
        self.assertEqual("BINDING_SPLIT_REQUIRED", plan["data"]["safety"]["blockers"][0]["code"])
        dated = self.run_cli("query-plan", "platform.latency", "--from", "2026-08-20T08:00:00-03:00", "--to", "2026-08-20T12:00:00-03:00")
        self.assertEqual("COVERED", dated["data"]["binding_resolution"])

    def test_query_plan_blocks_large_unpartitioned_and_missing_window(self):
        path = self.root / "model" / "demo.causal.toml"
        path.write_text(path.read_text().replace('partition_keys = ["event_date"]\n', "").replace("require_partition_filter = true\n", ""))
        self.run_cli("compile")
        plan = self.run_cli("query-plan", "platform.latency", "--from", "2026-08-01", "--to", "2026-08-02")
        self.assertIn("LARGE_UNPARTITIONED_TABLE", {x["code"] for x in plan["data"]["safety"]["blockers"]})
        plan = self.run_cli("query-plan", "platform.latency")
        self.assertIn("BOUNDED_TIME_WINDOW_REQUIRED", {x["code"] for x in plan["data"]["safety"]["blockers"]})

    def test_validator_rejects_zero_lag_cycle_and_conjunction_but_allows_positive_lag_cycle(self):
        path = self.root / "model" / "demo.causal.toml"
        path.write_text(path.read_text() + '''
[[relations]]
id = "rel.latency.deployment"
from = ["platform.latency"]
to = ["platform.deployment"]
kind = "causal"
effect = "increase"
status = "supported"
temporal_mode = "asynchronous"
min_lag = "1m"
max_lag = "1h"
description = "Feedback later."
''')
        self.assertTrue(self.run_cli("validate")["ok"])
        path.write_text(path.read_text().replace('max_lag = "2h"', 'max_lag = "0s"').replace('min_lag = "1m"\nmax_lag = "1h"', 'min_lag = "0s"\nmax_lag = "0s"'))
        self.assertEqual("VALIDATION_FAILED", self.run_cli("validate", expected=3)["error"]["code"])
        path.write_text(path.read_text().replace('from = ["platform.latency"]\nto = ["platform.deployment"]', 'from = ["platform.latency", "finance.revenue"]\nto = ["platform.deployment"]'))
        self.assertEqual("VALIDATION_FAILED", self.run_cli("validate", expected=3)["error"]["code"])

    def test_validator_rejects_contradictions_and_canonical_validity_overlap(self):
        path = self.root / "model" / "demo.causal.toml"
        path.write_text(path.read_text() + '''
[[relations]]
id = "rel.deployment.latency.opposite"
from = ["platform.deployment"]
to = ["platform.latency"]
kind = "causal"
effect = "decrease"
status = "supported"
temporal_mode = "asynchronous"
min_lag = "1m"
max_lag = "1h"
description = "Contradictory effect."
''')
        self.assertEqual("VALIDATION_FAILED", self.run_cli("validate", expected=3)["error"]["code"])
        path.write_text(MODEL + '''
[[bindings]]
id = "binding.latency.overlap"
concept = "platform.latency"
role = "canonical"
schema = "analytics_gold"
table = "request_metrics_v2"
grain_entity = "service"
grain_time = "5m"
valid_from = "2026-06-01"
''')
        self.assertEqual("VALIDATION_FAILED", self.run_cli("validate", expected=3)["error"]["code"])

    def test_candidate_path_is_graph_checked_and_evidence_is_required_for_verdict(self):
        self.run_cli("investigate", "start", "--id", "latency-incident", "--effect", "platform.latency", "--direction", "increase", "--from", "2026-08-20T08:00:00+00:00", "--to", "2026-08-20T12:00:00+00:00")
        self.run_cli("investigate", "candidate", "add", "latency-incident", "--id", "bad-path", "--path", "finance.revenue,platform.latency", expected=5)
        self.run_cli("investigate", "candidate", "add", "latency-incident", "--id", "deploy-path", "--path", "platform.deployment,platform.latency")
        self.run_cli("investigate", "support", "latency-incident", "deploy-path", "--reason", "Looks plausible.", expected=5)
        self.run_cli("investigate", "evidence", "add", "latency-incident", "--candidate", "deploy-path", "--type", "query_result", "--source", "query-1.json", "--summary", "Deployment preceded latency.")
        self.run_cli("investigate", "support", "latency-incident", "deploy-path", "--reason", "Observed temporal ordering.")

    def test_neighborhood_never_exceeds_limit(self):
        path = self.root / "model" / "demo.causal.toml"
        additions = []
        for i in range(5):
            additions.append(f'''\n[[phenomena]]\nid = "platform.child{i}"\nkind = "signal"\ndomain = "platform"\ndescription = "Child {i}."\n\n[[relations]]\nid = "rel.latency.child{i}"\nfrom = ["platform.latency"]\nto = ["platform.child{i}"]\nkind = "causal"\neffect = "increase"\nstatus = "candidate"\ntemporal_mode = "unknown"\ndescription = "Fan-out."\n''')
        path.write_text(path.read_text() + "".join(additions))
        self.run_cli("compile")
        hood = self.run_cli("neighborhood", "platform.latency", "--direction", "downstream", "--limit", "3")
        self.assertLessEqual(len(hood["data"]["nodes"]), 3)


if __name__ == "__main__":
    unittest.main()
