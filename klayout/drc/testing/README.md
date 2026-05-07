# DRC Testing Framework

Lightweight pytest-based framework for DRC testing with automatic test discovery and flexible configuration.

The tests are autodetected from the `unit` directory. Each file found there is DRC checked, running the file deck specified by its filename, before the first `-` (e.g: `antenna-1` -> run `antenna` tag)
The resulting `.lyrdb` file is then compared to its "golden" file, also stored in the `unit` directory.
The comparison happens on xml level, and checks that each rule success or violation happen in both files using the geometric marker (`polygon`, `edge`, ...)
The `.yaml` files defines extra configuration option to pass to `gf180mcu.drc` for this test.

## Quick Start

```bash
# Install dependencies
pip install pytest pytest-xdist # pytest-xdist is optional

# Run all tests
pytest

# Run with parallel execution
pytest -n auto
```

## Directory Structure

```
project_root/
├── tests/
│   ├── conftest.py              # Pytest configuration
│   ├── test_drc_designs.py      # Test definitions
│   └── drc_runner.py            # Core logic
├── unit/                        # Test data
│   │ 
│   ├── antenna-1.gds.gz
│   ├── antenna-1.lyrdb
│   ├── antenna-1.yaml
│   └── ...
└── pytest.ini                   # Pytest settings
```

## Configuration

### Command-Line Options

```bash
# Specify directories
pytest --unit-dir=unit --drc-script-path=myfile.drc --output-dir=results

# Filter by pattern
pytest -k "well" # All tests containing the "nwell" substring

# Parallel execution
pytest -n auto              # Use all CPUs
pytest -n 4                 # Use 4 workers
```

## Usage Examples

### Run All Tests
```bash
pytest -n auto
```

### Test Single Device
```bash
pytest -k "npn_00p54x02p00"
```

### Verbose Output
```bash
pytest tests/ -vv
```

### Stop on First Failure
```bash
pytest -x
```

### Re-run Failed Tests
```bash
pytest --lf
```
