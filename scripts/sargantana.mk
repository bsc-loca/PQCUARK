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
SARGANTANA_TILE_REPO = git@gitlab-internal.bsc.es:post-quantum-cryptography/platforms/sargantana/sargantana-tile-pqcuark.git
PQCUARK_REPO = git@gitlab-internal.bsc.es:post-quantum-cryptography/accelerators/pqcuark/pqcuark.git

SARGANTANA_TILE_BRANCH ?= develop
PQCUARK_BRANCH ?= develop

# Directory paths
SARGANTANA_TILE_DIR = $(PROJECT_DIR)/external/core_tile
SARGANTANA_DIR = $(PROJECT_DIR)/external/core_tile/rtl/core/sargantana
SARGANTANA_CLONED = $(SARGANTANA_TILE_DIR)/.cloned

# Initialize Sargantana: clone repos, update submodules, and apply patches
$(SARGANTANA_CLONED):
	mkdir -p external
	if [ ! -d "$(SARGANTANA_TILE_DIR)/.git" ]; then
		# Clone the Sargantana tile repository
		git clone -b $(SARGANTANA_TILE_BRANCH) $(SARGANTANA_TILE_REPO) $(SARGANTANA_TILE_DIR) --recurse-submodules
	fi
	# Update submodules
	git -C $(SARGANTANA_DIR) submodule update --init --recursive
	# Touch pqcuark directory to ensure it exists
	touch $(SARGANTANA_CLONED)

.PHONY: sargantana-init
sargantana-init: $(SARGANTANA_CLONED)

# Run simulation
core-sim: sargantana-init
	$(MAKE) -C $(SARGANTANA_TILE_DIR) sim -j4

# Clean up Sargantana directory
clean-sargantana:
	rm -rf $(SARGANTANA_TILE_DIR)
