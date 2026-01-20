PROJECT_DIR = $(abspath .)

SARGANTANA_TILE_DIR = $(PROJECT_DIR)/external/core_tile

RUN_VERILATOR = $(PROJECT_DIR)/scripts/run_verilator.sh
RUN_VERILATOR_OPTS ?=

include scripts/toolchain.mk 

include scripts/sargantana.mk

include scripts/schemes.mk

verilator-ml-kem: sargantana-init core-sim ml-kem-bin
	cd $(SARGANTANA_TILE_DIR) && $(RUN_VERILATOR) $(ML_KEM_BIN) $(RUN_VERILATOR_OPTS)

verilator-ml-dsa: sargantana-init core-sim ml-dsa-bin
	cd $(SARGANTANA_TILE_DIR) && $(RUN_VERILATOR) $(ML_DSA_BIN) $(RUN_VERILATOR_OPTS)

.PHONY: clean
clean: clean-toolchain clean-sargantana schemes-clean
	rm -rf external
	rm -rf toolchain
