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


# Repository URLs
SARGANTANA_TILE_REPO = https://github.com/bsc-loca/core_tile.git
PQCUARK_REPO = https://github.com/bsc-loca/PQCUARK.git

# Directory paths
SARGANTANA_TILE_DIR = $(PROJECT_DIR)/external/core_tile
SARGANTANA_DIR = $(PROJECT_DIR)/external/core_tile/rtl/core/sargantana
SARGANTANA_CLONED = $(SARGANTANA_TILE_DIR)/.cloned

# Patch files
PATCH_DIR = $(PROJECT_DIR)/patches/sargantana
PATCH_PQCUARK = $(PATCH_DIR)/0001-pqcuark.patch
PATCH_CSR = $(PATCH_DIR)/0001-csr.patch

# Initialize Sargantana: clone repos, update submodules, and apply patches
$(SARGANTANA_CLONED): 
	mkdir -p external
# Clone the Sargantana tile repository
	git clone $(SARGANTANA_TILE_REPO) $(SARGANTANA_TILE_DIR) --recurse-submodules
# Update submodules
	git -C $(SARGANTANA_DIR) submodule update --init --recursive
# Apply PQCUARK patch with validation
	git -C $(SARGANTANA_DIR) apply -p1 --check $(PATCH_PQCUARK) || (echo "PQCUARK patch cannot be applied cleanly" && exit 1)
	git -C $(SARGANTANA_DIR) apply -p1 $(PATCH_PQCUARK)
# Apply CSR patch with validation
	git -C $(SARGANTANA_DIR)/rtl/csr apply -p1 --check $(PATCH_CSR) || (echo "CSR patch cannot be applied cleanly" && exit 1)
	git -C $(SARGANTANA_DIR)/rtl/csr apply -p1 $(PATCH_CSR)
# Clone PQCUARK repository
	git clone $(PQCUARK_REPO) $(SARGANTANA_DIR)/rtl/datapath/rtl/exe_stage/rtl/pqcuark
	touch $(SARGANTANA_CLONED)

.PHONY: sargantana-init
sargantana-init: $(SARGANTANA_CLONED)

# Run simulation
core-sim:
	$(MAKE) -C $(SARGANTANA_TILE_DIR) sim -j4

# Clean up Sargantana directory
clean-sargantana:
	rm -rf $(SARGANTANA_TILE_DIR)
