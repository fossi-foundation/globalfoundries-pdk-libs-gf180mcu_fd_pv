# SPDX-FileCopyrightText: Copyright 2026 GlobalFoundries PDK Authors
# SPDX-License-Identifier: Apache License 2.0
"""
Lightweight pytest-based LVS testing framework.

Core functionality for LVS test execution and discovery.
"""

import os
import glob
import logging
import subprocess
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional, Dict, List
import yaml

default_switches = {
    "combine": "true",
    "top_lvl_pins": "true",
    "run_mode": "deep",
}


@dataclass
class LVSTestCase:
    """Represents a single LVS test case with optional custom configuration."""
    category: str           # e.g., "bjt_devices", "mimcap_devices"
    test_name: str          # e.g., "npn_00p54x02p00", "cap_mim_1f0_m2m3_noshield"
    layout_file: Path       # Path to .gds or .gds.gz file
    netlist_file: Path      # Path to netlist file (.cdl or .spice)
    switches: Dict[str, str] = field(default_factory=dict)  # klayout -rd switches
    config_name: str = "default"

    def __str__(self):
        return f"{self.category}/{self.test_name}"

    def get_switches_str(self) -> str:
        """Convert switches dict to klayout command line arguments."""
        return " ".join(f"-rd {k}={v}" for k, v in self.switches.items())


class LVSRunner:
    """Handles LVS execution and result parsing."""

    def __init__(self, lvs_script_path: Path, output_dir: Path):
        self.lvs_script_path = Path(lvs_script_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def run_lvs(self, testcase: LVSTestCase) -> Dict[str, any]:
        """
        Execute LVS for a single test case.

        Returns:
            Dictionary with keys: 'passed', 'log', 'report_path', 'extracted_netlist'
        """
        # Prepare output paths
        category_output_dir = self.output_dir / testcase.category
        category_output_dir.mkdir(parents=True, exist_ok=True)

        test_name = testcase.test_name
        log_file = os.path.abspath(category_output_dir / f"{test_name}.log")
        report_file = os.path.abspath(category_output_dir / f"{test_name}.lvsdb")
        extracted_netlist = os.path.abspath(category_output_dir / f"{test_name}_extracted.cir")
        netlist_file = os.path.abspath(testcase.netlist_file)

        # Build switches string from testcase configuration
        custom_switches = testcase.get_switches_str()
        call_str = (
            f"klayout -b -r {self.lvs_script_path} "
            f"-rd input={testcase.layout_file} "
            f"-rd schematic={netlist_file} "
            f"-rd report={report_file} "
            f"-rd target_netlist={extracted_netlist} "
            f"{custom_switches}"
        )
        print(call_str)

        result = {
            'passed': False,
            'log': '',
            'report_path': report_file,
            'extracted_netlist': extracted_netlist,
            'command': call_str
        }

        # Execute klayout
        ret = subprocess.run(
            call_str,
            shell=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT)

        logging.info(ret.stdout)

        with open(log_file, "w") as f:
            f.write(ret.stdout)

        result['log'] = ret.stdout
        if ret.returncode != 0:
            result['passed'] = False
            logging.error(f"✗ {testcase} failed, non-zero return code from klayout")
        # Check for success
        elif "Congratulations! Netlists match" in ret.stdout:
            result['passed'] = True
            logging.info(f"✓ {testcase} passed")
        else:
            logging.error(f"✗ {testcase} failed")

        return result


class LVSTestCollector:
    """Discovers and collects LVS test cases from directory structure."""

    def __init__(self, unit_test_dir: Path, test_config_path: Optional[Path] = None):
        self.unit_test_dir = Path(unit_test_dir)

    def _load_category_configs(self, category_dir: Path) -> Dict[str, Dict]:

        """
        Returns:
            {
              "default": {test_name -> switches},
              "custom_name": {test_name -> switches},
            }
        """
        config_dir = category_dir / "config"
        configs = {"default": default_switches}

        if not config_dir.exists():
            logging.warning("Did not find " + str(config_dir))
            return configs

        default_cfg = config_dir / "default.yaml"
        if not default_cfg.exists():
            raise RuntimeError(
                f"{config_dir} exists but default.yaml is missing"
            )

        for cfg_file in sorted(config_dir.glob("*.yaml")):
            name = cfg_file.stem

            with open(cfg_file) as f:
                data = yaml.safe_load(f) or {}

            devices = data.get("test_switches", {})
            cfg_devices = {}

            for device_name, device_overrides in devices.items():
                # start from per-device defaults
                device_cfg = default_switches.copy()

                # override defaults with device-specific values
                device_cfg.update(device_overrides or {})

                cfg_devices[device_name] = device_cfg

            configs[name] = cfg_devices

        return configs

    def collect_all_tests(self) -> List[LVSTestCase]:
        """Collect all LVS test cases from unit directory."""
        testcases = []

        # Iterate through each device category
        for category_dir in sorted(self.unit_test_dir.iterdir()):
            if not category_dir.is_dir():
                continue

            category_name = category_dir.name
            layout_dir = category_dir / "layout"
            netlist_dir = category_dir / "netlist"

            if not layout_dir.exists() or not netlist_dir.exists():
                logging.warning(f"Skipping {category_name}: missing layout or netlist directory")
                continue

            category_configs = self._load_category_configs(category_dir)

            # Match layout files with netlist files
            for layout_file in sorted(layout_dir.glob("*.gds*")):
                test_name = layout_file.stem

                # Handle .gds.gz case
                if test_name.endswith('.gds'):
                    test_name = Path(test_name).stem

                # Find corresponding netlist
                netlist_file_cdl = netlist_dir / f"{test_name}.cdl"
                netlist_file_spice = netlist_dir / f"{test_name}.spice"

                if (not netlist_file_cdl.exists()) and (not netlist_file_spice.exists()):
                    logging.warning(f"No netlist found for {test_name} in {category_name}")
                    continue
                elif (netlist_file_cdl.exists()) and (netlist_file_spice.exists()):
                    logging.warning(f"Two netlist found for the same test for {test_name} in {category_name}")
                    continue
                elif netlist_file_cdl.exists():
                    netlist_file = netlist_file_cdl
                else:
                    netlist_file = netlist_file_spice

                for cfg_name, cfg_switches in category_configs.items():
                    if (cfg_name != "default") and (test_name not in cfg_switches):
                        continue

                    switch = cfg_switches[test_name] if test_name in cfg_switches.keys() else default_switches
                    logging.warning("Appending test " + str(test_name) + " with switches: " + str(switch))
                    testcases.append(
                        LVSTestCase(
                            category=category_name,
                            test_name=test_name,
                            layout_file=layout_file,
                            netlist_file=netlist_file,
                            switches=switch,
                            config_name=cfg_name,
                        )
                    )

        return testcases

    def collect_by_category(self, category: str) -> List[LVSTestCase]:
        """Collect test cases for a specific category."""
        all_tests = self.collect_all_tests()
        return [tc for tc in all_tests if tc.category == category]

    def collect_by_pattern(self, pattern: str) -> List[LVSTestCase]:
        """Collect test cases matching a pattern (glob-style)."""
        from fnmatch import fnmatch
        all_tests = self.collect_all_tests()
        return [tc for tc in all_tests if fnmatch(tc.test_name, pattern)]
