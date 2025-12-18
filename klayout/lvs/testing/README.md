# LVS Testing Framework

Lightweight pytest-based framework for LVS testing with automatic test discovery and flexible configuration.

## Quick Start

```bash
# Install dependencies
pip install pytest pytest-xdist # pytest-xdist is optional

# Run all tests
pytest tests/

# Run with parallel execution
pytest tests/ -n auto
```

## Directory Structure

```
project_root/
├── tests/
│   ├── conftest.py              # Pytest configuration
│   ├── test_lvs_devices.py      # Test definitions
│   └── lvs_runner.py            # Core logic
├── unit/                        # Test data
│   ├── bjt_devices/
│   │   ├── layout/*.gds.gz
│   │   └── netlist/*.cdl
│   └── ...
├── test_config.yaml             # Optional: device- or category- specific switches
└── pytest.ini                   # Pytest settings
```

## Configuration

### Test-Specific Switches

`test_config.yaml` defines if special switches should be forwarded the lvs script.
For example:

```yaml
# Test-specific switches (override category)
test_switches:
  cap_mim_1f0_m2m3_noshield:
    mim_option: "A"
  cap_mim_2f0_m2m3_noshield:
    mim_option: "B"
```

If you would like to use a different config file than the toplevel one, you can
specify like so:
```bash
pytest tests/ --test-config=my_custom_test_config.yaml
```

### Command-Line Options

```bash
# Specify directories
pytest tests/ --unit-dir=unit --lvs-script-dir=lvs --output-dir=results

# Filter by category
pytest tests/ --category=mimcap_devices

# Filter by pattern
pytest tests/ -k "cap_mim_"
pytest tests/ -k "03v3"

# Parallel execution
pytest tests/ -n auto              # Use all CPUs
pytest tests/ -n 4                 # Use 4 workers
```

## Usage Examples

### Run All Tests
```bash
pytest tests/ -n auto
```

### Test Single Device
```bash
pytest tests/ -k "npn_00p54x02p00"
```

### Test Specific Category
```bash
pytest tests/ --category=bjt_devices -n 4
```

### Test with Custom Config
```bash
pytest tests/ --test-config=my_config.yaml --category=mimcap_devices
```

### Verbose Output
```bash
pytest tests/ -vv
```

### Stop on First Failure
```bash
pytest tests/ -x
```

### Re-run Failed Tests
```bash
pytest tests/ --lf
```

## How It Works

1. **Test Discovery**: Framework scans `unit/` directory and automatically creates a test for each layout/netlist pair
2. **Configuration**: Loads test-specific switches from `test_config.yaml` (optional)
3. **Execution**: Runs klayout with proper switches for each test
4. **Validation**: Checks for "Congratulations! Netlists match" in output
5. **Reporting**: Pytest provides detailed pass/fail status
