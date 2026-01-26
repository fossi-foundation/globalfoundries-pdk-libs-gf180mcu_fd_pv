# Copyright 2022 GlobalFoundries PDK Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Path to regression
KLAYOUT_DRC_TESTS := klayout/drc/testing/

KLAYOUT_LVS_TESTS := klayout/lvs/testing/

# Lint python code
lint_python:
	flake8 .

# Lint ruby code
lint_ruby:
	rubocop .

################################################################################
## DRC Regression section
################################################################################
#=================================
# ----- test-DRC_regression ------
#=================================
test-DRC-main:
	python3 $(KLAYOUT_DRC_TESTS)/run_regression.py

test-DRC-%:
	python3 $(KLAYOUT_DRC_TESTS)/run_regression.py --table=$*

#=================================
# -------- test-DRC-switch -------
#=================================
test-DRC-switch:
	klayout -v

################################################################################
## LVS Regression section
################################################################################
#=================================
# ----- test-LVS_regression ------
#=================================
test-LVS: | $(CONDA_ENV_PYTHON)
	cd $(KLAYOUT_LVS_TESTS) && pytest
