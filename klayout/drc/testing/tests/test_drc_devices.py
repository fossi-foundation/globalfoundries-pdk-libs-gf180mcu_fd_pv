# SPDX-FileCopyrightText: Copyright 2026 GlobalFoundries PDK Authors
# SPDX-License-Identifier: Apache License 2.0
"""
Main DRC test file.

Tests are automatically parametrized by pytest_generate_tests in conftest.py.
"""

import logging

import pytest


def test_device_drc(drc_testcase, drc_runner):
    """
    Run DRC for a single test case and assert the output matches the golden .lyrdb.
    """
    logging.info("Testing : %s", drc_testcase)
    logging.info("Layout  : %s", drc_testcase.layout_file)
    logging.info("Golden  : %s", drc_testcase.golden_lyrdb)

    if drc_testcase.switches:
        logging.info("Switches: %s", drc_testcase.switches)

    result = drc_runner.run_drc(drc_testcase)

    assert result["passed"], (
        f"DRC output differs from golden for {drc_testcase}\n"
        f"Report : {result['report_path']}\n"
        f"Command: {result['command']}\n"
        f"Differences:\n" + "\n".join(result["diffs"]) + "\n"
        f"\nLog (last 1000 chars):\n{result['log'][-1000:]}"
    )
