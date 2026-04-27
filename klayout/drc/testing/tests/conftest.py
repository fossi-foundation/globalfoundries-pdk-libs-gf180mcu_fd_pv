# SPDX-FileCopyrightText: Copyright 2026 GlobalFoundries PDK Authors
# SPDX-License-Identifier: Apache License 2.0
"""
Pytest configuration and shared fixtures for DRC regression tests.
"""

import logging
from pathlib import Path

import pytest

from drc_runner import DRCRunner, DRCTestCollector


def pytest_addoption(parser):
    parser.addoption(
        "--drc-script-path",
        action="store",
        default="../gf180mcu.drc",
        help="Path to the KLayout DRC script (default: ../gf180mcu.drc)",
    )
    parser.addoption(
        "--unit-dir",
        action="store",
        default="unit",
        help="Flat directory containing test files (default: unit)",
    )
    parser.addoption(
        "--output-dir",
        action="store",
        default="test_output",
        help="Directory for test outputs (default: test_output)",
    )
    parser.addoption(
        "--test-pattern",
        action="store",
        default=None,
        help="Run only tests matching a glob pattern (e.g. 'nwell*')",
    )


@pytest.fixture(scope="session")
def drc_config(request):
    return {
        "drc_script_path": Path(request.config.getoption("--drc-script-path")),
        "unit_dir":        Path(request.config.getoption("--unit-dir")),
        "output_dir":      Path(request.config.getoption("--output-dir")),
        "test_pattern":    request.config.getoption("--test-pattern"),
    }


@pytest.fixture(scope="session")
def drc_runner(drc_config):
    return DRCRunner(
        drc_script_path=drc_config["drc_script_path"],
        output_dir=drc_config["output_dir"],
    )


def pytest_generate_tests(metafunc):
    if "drc_testcase" not in metafunc.fixturenames:
        return

    unit_dir    = Path(metafunc.config.getoption("--unit-dir"))
    test_pattern = metafunc.config.getoption("--test-pattern")

    collector = DRCTestCollector(unit_test_dir=unit_dir)
    testcases = (
        collector.collect_by_pattern(test_pattern) if test_pattern
        else collector.collect_all_tests()
    )

    if not testcases:
        pytest.skip("No DRC test cases found")

    metafunc.parametrize(
        "drc_testcase",
        testcases,
        ids=[str(tc) for tc in testcases],
    )


@pytest.fixture(autouse=True)
def configure_logging():
    logging.basicConfig(level=logging.INFO, format="%(levelname)s - %(message)s")
