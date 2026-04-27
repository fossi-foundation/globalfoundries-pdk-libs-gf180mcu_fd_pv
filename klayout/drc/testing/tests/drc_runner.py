# SPDX-FileCopyrightText: Copyright 2026 GlobalFoundries PDK Authors
# SPDX-License-Identifier: Apache License 2.0
"""
Lightweight pytest-based DRC testing framework — flat layout.

Unit test directory contains .gds / .lyrdb / .yaml files side-by-side::

    unit/
      nwell.gds
      nwell.lyrdb        ← golden reference
      nwell.yaml         ← optional switches
      metal1.gds
      metal1.lyrdb
      ...

KLayout is invoked once per test; its output .lyrdb is compared against the
golden file. Any difference in rule names or violation counts fails the test.
"""

import logging
import os
import subprocess
import xml.etree.ElementTree as ET
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List

import yaml

default_switches: Dict[str, str] = {
    "variant": "C",
    "run_mode": "flat",
}


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------


@dataclass
class DRCTestCase:
    """Represents a single DRC test case."""

    test_name: str          # stem of the layout file, e.g. "nwell.3a"
    layout_file: Path       # .gds or .gds.gz
    golden_lyrdb: Path      # golden reference .lyrdb
    switches: Dict[str, str] = field(default_factory=dict)

    def __str__(self) -> str:
        return self.test_name

    @property
    def deck_name(self) -> str:
        """Filename stem with the trailing dash-segment removed.

        Examples::

            "comp"      -> "comp"
            "antenna-1" -> "antenna"
            "nwell-3a"  -> "nwell"
        """
        return self.test_name.rsplit("-", 1)[0]

    def get_switches_str(self) -> str:
        return " ".join(f"-rd {k}={v}" for k, v in self.switches.items())


# ---------------------------------------------------------------------------
# Result parsing
# ---------------------------------------------------------------------------

# Type alias: cell -> rule -> sorted tuple of polygon value strings
LyrdbData = Dict[str, Dict[str, List[str]]]


def _parse_lyrdb(lyrdb_path: str) -> LyrdbData:
    """
    Parse a KLayout .lyrdb and return a nested structure::

        {
            cell_name: {
                rule_name: [polygon_value, ...],   # sorted, order-independent
                ...
            },
            ...
        }

    Rules that ran but produced zero violations appear with an empty list.
    The top-level cell recorded in <categories> is used as a sentinel so
    zero-violation rules are still visible in the diff.
    """
    tree = ET.parse(lyrdb_path)
    root = tree.getroot()

    # Collect all rule names that ran (may have zero violations)
    all_rules: List[str] = []
    for category in root.find("categories"):
        name_el = category.find("name")
        if name_el is not None and name_el.text:
            all_rules.append(name_el.text.strip())

    # Top cell name — used as the cell for zero-violation rules
    top_cell_el = root.find("top-cell")
    top_cell = top_cell_el.text.strip() if top_cell_el is not None and top_cell_el.text else "__top__"

    # Seed every rule with an empty list under the top cell
    data: LyrdbData = defaultdict(lambda: defaultdict(list))
    for rule in all_rules:
        data[top_cell][rule]  # touch to ensure the key exists

    # Fill in actual violations
    items_el = root.find("items")
    if items_el is not None:
        for item in items_el:
            rule_el  = item.find("category")
            cell_el  = item.find("cell")
            values_el = item.find("values")

            if rule_el is None or rule_el.text is None:
                continue

            rule_name = rule_el.text.strip().replace("'", "")
            cell_name = (
                cell_el.text.strip()
                if cell_el is not None and cell_el.text
                else top_cell
            )

            polygons: List[str] = []
            if values_el is not None:
                for value_el in values_el:
                    if value_el.text:
                        polygons.append(value_el.text.strip())

            data[cell_name][rule_name].extend(polygons)

    # Sort polygon lists so comparison is order-independent
    for cell in data:
        for rule in data[cell]:
            data[cell][rule].sort()

    return {cell: dict(rules) for cell, rules in data.items()}


def _diff_lyrdb(actual: LyrdbData, golden: LyrdbData) -> List[str]:
    """
    Compare two parsed lyrdb structures at the polygon level.

    Checks per (cell, rule):
      - rules present in one report but not the other
      - one-to-one polygon match (order-independent)

    Returns a list of human-readable difference strings; empty means identical.
    """
    diffs: List[str] = []

    all_cells = sorted(set(actual) | set(golden))
    for cell in all_cells:
        if cell not in actual:
            rules = sorted(golden[cell])
            diffs.append(f"[{cell}] cell missing in output (golden has {len(rules)} rule(s): {', '.join(rules)})")
            continue
        if cell not in golden:
            rules = sorted(actual[cell])
            diffs.append(f"[{cell}] unexpected cell in output ({len(rules)} rule(s): {', '.join(rules)})")
            continue

        all_rules = sorted(set(actual[cell]) | set(golden[cell]))
        for rule in all_rules:
            a_polys = actual[cell].get(rule)
            g_polys = golden[cell].get(rule)

            if a_polys is None:
                diffs.append(f"[{cell}][{rule}] rule missing in output (golden has {len(g_polys)} violation(s))")
            elif g_polys is None:
                diffs.append(f"[{cell}][{rule}] unexpected rule in output ({len(a_polys)} violation(s))")
            elif a_polys != g_polys:
                # Both exist — report count mismatch and differing polygons
                a_set = set(a_polys)
                g_set = set(g_polys)
                only_in_actual = sorted(a_set - g_set)
                only_in_golden = sorted(g_set - a_set)
                diffs.append(
                    f"[{cell}][{rule}] violation mismatch "
                    f"(actual={len(a_polys)}, golden={len(g_polys)})"
                )
                for p in only_in_golden:
                    diffs.append(f"    missing in output : {p}")
                for p in only_in_actual:
                    diffs.append(f"    unexpected in output: {p}")

    return diffs


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------


class DRCRunner:
    """Handles DRC execution and golden-file comparison."""

    def __init__(self, drc_script_path: Path, output_dir: Path):
        self.drc_script_path = Path(drc_script_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def run_drc(self, testcase: DRCTestCase) -> Dict:
        """
        Run KLayout DRC for *testcase* and compare against the golden .lyrdb.

        Returns a dict with keys:
            passed      bool
            diffs       list[str]   human-readable differences (empty if passed)
            log         str         combined stdout/stderr from klayout
            report_path str         path of the produced .lyrdb
            command     str         klayout command that was run
        """
        report_file = os.path.abspath(self.output_dir / f"{testcase.test_name}.lyrdb")
        log_file = self.output_dir / f"{testcase.test_name}.log"

        call_str = (
            f"klayout -b -r {self.drc_script_path} "
            f"-rd input={testcase.layout_file} "
            f"-rd report={report_file} "
            f"-rd decks={testcase.deck_name} "
            f"{testcase.get_switches_str()}"
        )
        logging.info("Running: %s", call_str)

        result = {
            "passed": False,
            "diffs": [],
            "log": "",
            "report_path": report_file,
            "command": call_str,
        }

        ret = subprocess.run(
            call_str,
            shell=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )

        result["log"] = ret.stdout
        log_file.write_text(ret.stdout)

        if ret.returncode != 0:
            logging.error("✗ %s — klayout returned exit code %d", testcase, ret.returncode)
            result["diffs"] = [f"klayout exited with code {ret.returncode}"]
            return result

        if not os.path.exists(report_file):
            logging.error("✗ %s — no .lyrdb produced", testcase)
            result["diffs"] = [f"Output .lyrdb not found: {report_file}"]
            return result

        try:
            actual = _parse_lyrdb(report_file)
            golden = _parse_lyrdb(str(testcase.golden_lyrdb))
        except ET.ParseError as exc:
            result["diffs"] = [f"XML parse error: {exc}"]
            return result

        result["diffs"] = _diff_lyrdb(actual, golden)
        result["passed"] = len(result["diffs"]) == 0

        if result["passed"]:
            logging.info("✓ %s passed", testcase)
        else:
            logging.error("✗ %s — %d difference(s)", testcase, len(result["diffs"]))

        return result


# ---------------------------------------------------------------------------
# Collector
# ---------------------------------------------------------------------------


class DRCTestCollector:
    """
    Discovers DRC test cases from a flat directory.

    For each .gds / .gds.gz file a matching .lyrdb is required; a .yaml is
    optional.  The YAML file contains switches as a flat key-value mapping::

        variant: C
        run_mode: flat
        select_decks: nwell
    """

    def __init__(self, unit_test_dir: Path):
        self.unit_test_dir = Path(unit_test_dir)

    def _load_switches(self, yaml_file: Path) -> Dict[str, str]:
        with open(yaml_file) as f:
            data = yaml.safe_load(f) or {}
        switches = default_switches.copy()
        switches.update({str(k): str(v) for k, v in data.items()})
        return switches

    def collect_all_tests(self) -> List[DRCTestCase]:
        testcases: List[DRCTestCase] = []

        for layout_file in sorted(self.unit_test_dir.glob("*.gds*")):
            test_name = layout_file.stem
            if test_name.endswith(".gds"):          # handle .gds.gz
                test_name = Path(test_name).stem

            golden_file = self.unit_test_dir / f"{test_name}.lyrdb"
            if not golden_file.exists():
                logging.warning("No golden .lyrdb for %s — skipping", test_name)
                continue

            yaml_file = self.unit_test_dir / f"{test_name}.yaml"
            switches = (
                self._load_switches(yaml_file) if yaml_file.exists()
                else default_switches.copy()
            )

            testcases.append(
                DRCTestCase(
                    test_name=test_name,
                    layout_file=layout_file,
                    golden_lyrdb=golden_file,
                    switches=switches,
                )
            )

        return testcases

    def collect_by_pattern(self, pattern: str) -> List[DRCTestCase]:
        from fnmatch import fnmatch
        return [tc for tc in self.collect_all_tests() if fnmatch(tc.test_name, pattern)]
