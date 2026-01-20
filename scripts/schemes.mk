# =============================================================================
# PQCUARK – Scheme build + Verilator run helpers
# =============================================================================

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


.PHONY: \
  schemes-all schemes-clean \
  ml-kem-all ml-kem-bin ml-kem-clean \
  ml-dsa-all ml-dsa-bin ml-dsa-clean \
  core-sim verilator-ml-kem verilator-ml-dsa

schemes-all: ml-kem-all ml-dsa-all

schemes-clean: ml-kem-clean ml-dsa-clean

ml-kem-all:
	$(MAKE) -C $(ML_KEM_DIR) all

ml-kem-bin:
	$(MAKE) -C $(ML_KEM_DIR) $(ML_KEM_TARGET)

ml-kem-clean:
	$(MAKE) -C $(ML_KEM_DIR) clean

ml-dsa-all:
	$(MAKE) -C $(ML_DSA_DIR) all

ml-dsa-bin:
	$(MAKE) -C $(ML_DSA_DIR) $(ML_DSA_TARGET)

ml-dsa-clean:
	$(MAKE) -C $(ML_DSA_DIR) clean

