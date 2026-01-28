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

# =============================================================================
# PQCUARK – Scheme build + Verilator run helpers
# =============================================================================

.ONESHELL:
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

PROJECT_DIR ?= $(abspath .)

SCHEMES_DIR = $(PROJECT_DIR)/schemes
ML_KEM_DIR = $(SCHEMES_DIR)/ml-kem
ML_DSA_DIR = $(SCHEMES_DIR)/ml-dsa

ML_KEM_TEST ?= test_kyber512
ML_KEM_CONF ?= pqcuark
ML_DSA_TEST ?= test_dilithium2
ML_DSA_CONF ?= pqcuark

ML_KEM_TARGET = $(ML_KEM_TEST)_$(ML_KEM_CONF)
ML_DSA_TARGET = $(ML_DSA_TEST)_$(ML_DSA_CONF)
ML_KEM_BIN = $(ML_KEM_DIR)/out/$(ML_KEM_TARGET)
ML_DSA_BIN = $(ML_DSA_DIR)/out/$(ML_DSA_TARGET)

SETUP_FILE = $(PROJECT_DIR)/schemes/ml-kem/.setup


.PHONY: \
  schemes-all schemes-clean \
  ml-kem-all ml-kem-bin ml-kem-clean \
  ml-dsa-all ml-dsa-bin ml-dsa-clean \
  core-sim verilator-ml-kem verilator-ml-dsa

schemes-all: ml-kem-all ml-dsa-all

schemes-clean: ml-kem-clean ml-dsa-clean

ml-kem-all: setup
	$(MAKE) -C $(ML_KEM_DIR) all

ml-kem-bin: setup
	$(MAKE) -C $(ML_KEM_DIR) $(ML_KEM_TARGET)

ml-kem-clean: setup
	$(MAKE) -C $(ML_KEM_DIR) clean

ml-dsa-all: setup
	$(MAKE) -C $(ML_DSA_DIR) all

ml-dsa-bin: setup
	$(MAKE) -C $(ML_DSA_DIR) $(ML_DSA_TARGET)

ml-dsa-clean: setup
	$(MAKE) -C $(ML_DSA_DIR) clean

$(SETUP_FILE): $(PROJECT_DIR)/schemes/ml-kem/set-env.sh
	source $(PROJECT_DIR)/schemes/ml-kem/set-env.sh && touch $(SETUP_FILE)

setup: $(SETUP_FILE)