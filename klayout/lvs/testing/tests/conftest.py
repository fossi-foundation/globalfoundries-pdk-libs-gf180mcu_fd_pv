"""
Pytest configuration and shared fixtures.
"""

import pytest
import logging
from pathlib import Path
from lvs_runner import LVSRunner, LVSTestCollector


def pytest_addoption(parser):
    """Add custom command line options."""
    parser.addoption(
        "--lvs-script-path",
        action="store",
        default="../gf180mcu.lvs",
        help="Directory containing LVS scripts (default: ../gf180mcu.lvs)"
    )
    parser.addoption(
        "--unit-dir",
        action="store",
        default="unit",
        help="Directory containing unit tests (default: unit)"
    )
    parser.addoption(
        "--output-dir",
        action="store",
        default="test_output",
        help="Directory for test outputs (default: test_output)"
    )
    parser.addoption(
        "--test-config",
        action="store",
        default="test_config.yaml",
        help="YAML file with test-specific configuration (default: test_config.yaml)"
    )
    parser.addoption(
        "--category",
        action="store",
        default=None,
        help="Run only tests from specific category"
    )
    parser.addoption(
        "--test-pattern",
        action="store",
        default=None,
        help="Run only tests matching pattern (e.g., 'nfet_*', 'cap_mim_*')"
    )


@pytest.fixture(scope="session")
def lvs_config(request):
    """Session-wide LVS configuration."""
    return {
        'lvs_script_path': Path(request.config.getoption("--lvs-script-path")),
        'unit_dir': Path(request.config.getoption("--unit-dir")),
        'output_dir': Path(request.config.getoption("--output-dir")),
        'test_config': Path(request.config.getoption("--test-config")),
        'category_filter': request.config.getoption("--category"),
        'test_pattern': request.config.getoption("--test-pattern"),
    }


@pytest.fixture(scope="session")
def lvs_runner(lvs_config):
    """Create LVS runner instance."""
    return LVSRunner(
        lvs_script_path=lvs_config['lvs_script_path'],
        output_dir=lvs_config['output_dir']
    )


@pytest.fixture(scope="session")
def test_collector(lvs_config):
    """Create test collector instance."""
    test_config_path = lvs_config['test_config'] if lvs_config['test_config'].exists() else None
    return LVSTestCollector(
        unit_dir=lvs_config['unit_dir'],
        test_config_path=test_config_path
    )


def pytest_generate_tests(metafunc):
    """
    Automatically discover and parametrize LVS tests.
    """
    if "lvs_testcase" not in metafunc.fixturenames:
        return

    # Get configuration
    unit_dir = Path(metafunc.config.getoption("--unit-dir"))
    test_config_path = Path(metafunc.config.getoption("--test-config"))
    category_filter = metafunc.config.getoption("--category")
    test_pattern = metafunc.config.getoption("--test-pattern")

    # Collect test cases
    test_config = test_config_path if test_config_path.exists() else None
    collector = LVSTestCollector(unit_dir, test_config)

    if category_filter:
        testcases = collector.collect_by_category(category_filter)
    elif test_pattern:
        testcases = collector.collect_by_pattern(test_pattern)
    else:
        testcases = collector.collect_all_tests()

    if not testcases:
        pytest.skip("No test cases found")

    # Parametrize tests with readable IDs
    metafunc.parametrize(
        "lvs_testcase",
        testcases,
        ids=[str(tc) for tc in testcases]
    )


@pytest.fixture(autouse=True)
def configure_logging():
    """Configure logging for each test."""
    logging.basicConfig(
        level=logging.INFO,
        format='%(levelname)s - %(message)s'
    )
