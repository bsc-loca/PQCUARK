# Copyright 2026 Barcelona Supercomputing Center (BSC)
#
# Licensed under the Solderpad Hardware License v 2.1 (the "License");
# you may not use this file except in compliance with the License, or,
# at your option, the Apache License version 2.0.
# You may obtain a copy of the License at
#
#     https://solderpad.org/licenses/SHL-2.1/
#
# Unless required by applicable law or agreed to in writing, any work
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

PROJECT_DIR = $(abspath .)

SARGANTANA_TILE_DIR = $(PROJECT_DIR)/external/core_tile

RUN_VERILATOR = $(PROJECT_DIR)/scripts/run_verilator.sh
RUN_VERILATOR_OPTS ?=

include scripts/toolchain.mk 

include scripts/sargantana.mk

include scripts/schemes.mk

verilator-ml-kem: sargantana-init core-sim ml-kem-bin
	chmod u+x $(RUN_VERILATOR)
	cd $(SARGANTANA_TILE_DIR) && $(RUN_VERILATOR) $(ML_KEM_BIN) $(RUN_VERILATOR_OPTS)

verilator-ml-dsa: sargantana-init core-sim ml-dsa-bin
	chmod u+x $(RUN_VERILATOR)
	cd $(SARGANTANA_TILE_DIR) && $(RUN_VERILATOR) $(ML_DSA_BIN) $(RUN_VERILATOR_OPTS)

.PHONY: clean
clean: clean-toolchain clean-sargantana schemes-clean
	rm -rf external
	rm -rf toolchain
