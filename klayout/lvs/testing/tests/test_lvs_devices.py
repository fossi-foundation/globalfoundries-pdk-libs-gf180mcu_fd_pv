# SPDX-FileCopyrightText: Copyright 2026 GlobalFoundries PDK Authors
# SPDX-License-Identifier: Apache License 2.0
"""
Main LVS test file.
"""

import pytest
import logging


def test_device_lvs(lvs_testcase, lvs_runner):
    """
    Test LVS for a single test case.

    This test is automatically parametrized by pytest_generate_tests
    in conftest.py to run for each discovered test case.
    """
    # Run LVS
    result = lvs_runner.run_lvs(lvs_testcase)

    # Log information
    logging.info(f"Testing: {lvs_testcase}")
    logging.info(f"Layout: {lvs_testcase.layout_file}")
    logging.info(f"Netlist: {lvs_testcase.netlist_file}")

    if lvs_testcase.switches:
        logging.info(f"Switches: {lvs_testcase.switches}")

    # Assert test passed
    assert result['passed'], (
        f"LVS failed for {lvs_testcase}\n"
        f"Report: {result['report_path']}\n"
        f"Log excerpt:\n{result['log'][-1000:]}"  # Last 1000 chars
    )
