################################################################################################
# Copyright 2023 GlobalFoundries PDK Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################################

#=========================================================================
# ---------------------------------- LVS ---------------------------------
#=========================================================================

.PHONY: all test-main test-switch

all: test-main

#=================================
# ----- test-LVS_regression ------
#=================================

test-main: testcase-MOS  testcase-BJT  testcase-DIODE  testcase-RES  testcase-MIMCAP  testcase-MOSCAP  testcase-MOS_SAB

testcase-%:
	@echo "========== LVS-$* testing =========="
	python3 run_regression.py --device_name=$*

#=================================
# -------- test-LVS-switch -------
#=================================

test-switch:
	@echo "========== LVS-Switch testing =========="
	python3 ../run_lvs.py --layout=testcases/extraction_checking/sample_nfet_03v3.gds --netlist=testcases/extraction_checking/sample_nfet_03v3.spice --variant=A
	python3 ../run_lvs.py --layout=testcases/extraction_checking/sample_nfet_03v3.gds --netlist=testcases/extraction_checking/sample_nfet_03v3.spice --variant=B
	python3 ../run_lvs.py --layout=testcases/extraction_checking/sample_nfet_03v3.gds --netlist=testcases/extraction_checking/sample_nfet_03v3.spice --variant=C
	python3 ../run_lvs.py --layout=testcases/extraction_checking/sample_nfet_03v3.gds --netlist=testcases/extraction_checking/sample_nfet_03v3.spice --variant=D
