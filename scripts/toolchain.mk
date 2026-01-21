# =============================================================================
# PQCUARK – Binutils opcode patch workflow
# =============================================================================

.ONESHELL:
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# -----------------------------------------------------------------------------
# Repositories and paths
# -----------------------------------------------------------------------------
TOOLCHAIN_REPO := https://github.com/riscv-collab/riscv-gnu-toolchain.git
TOOLCHAIN_DIR  := $(PROJECT_DIR)/toolchain/riscv-gnu-toolchain

GCC_PQCUARK_DIR := $(PROJECT_DIR)/toolchain/gcc-pqcuark

BINUTILS_SUBMODULE_PATH := binutils
BINUTILS_PATCH_DIR := $(PROJECT_DIR)/patches/binutils
BINUTILS_PATCH := $(BINUTILS_PATCH_DIR)/pqcuark-riscv-opcodes.patch

# -----------------------------------------------------------------------------
# Phony targets
# -----------------------------------------------------------------------------
.PHONY: \
  clone-toolchain checkout-toolchain-master update-binutils \
  gen-binutils-opcode-patch apply-binutils-opcode-patch \
  clean-patch

# -----------------------------------------------------------------------------
# Clone riscv-gnu-toolchain (if needed)
# -----------------------------------------------------------------------------
clone-toolchain:
	if [ ! -d "$(TOOLCHAIN_DIR)/.git" ]; then
		echo "Cloning riscv-gnu-toolchain..."
		git clone "$(TOOLCHAIN_REPO)" "$(TOOLCHAIN_DIR)"
	fi

# -----------------------------------------------------------------------------
# Checkout latest master HEAD (detached)
# -----------------------------------------------------------------------------
checkout-toolchain-master: clone-toolchain
	cd "$(TOOLCHAIN_DIR)"
	git fetch origin master
	HEAD_SHA="$$(git ls-remote "$(TOOLCHAIN_REPO)" refs/heads/master | awk '{print $$1}')"
	echo "Checking out riscv-gnu-toolchain master HEAD: $$HEAD_SHA"
	git checkout -f "$$HEAD_SHA"

# -----------------------------------------------------------------------------
# Update ONLY the binutils submodule (no --recursive)
# -----------------------------------------------------------------------------
update-binutils: checkout-toolchain-master
	cd "$(TOOLCHAIN_DIR)"
	git submodule sync -- "$(BINUTILS_SUBMODULE_PATH)"
	git submodule update --init "$(BINUTILS_SUBMODULE_PATH)"

# -----------------------------------------------------------------------------
# Apply opcode-only patch to toolchain binutils
# -----------------------------------------------------------------------------
apply-binutils-opcode-patch: $(BINUTILS_PATCH) update-binutils
	echo "Applying PQCUARK opcode patch to toolchain binutils"
	cd "$(TOOLCHAIN_DIR)/binutils"
	git apply -p1 --check "$(BINUTILS_PATCH)"
	git apply -p1 "$(BINUTILS_PATCH)"
	echo "Patch applied successfully"

# -----------------------------------------------------------------------------
# Clean generated patch
# -----------------------------------------------------------------------------
clean-patch:
	rm -f "$(BINUTILS_PATCH)"

# -----------------------------------------------------------------------------
# Default target
# -----------------------------------------------------------------------------
.PHONY: toolchain
toolchain: apply-binutils-opcode-patch
	@echo "PQCUARK binutils opcode patch applied (all done)"
	mkdir -p "$(GCC_PQCUARK_DIR)"
	@echo "Configuring GCC PQCUARK toolchain in $(GCC_PQCUARK_DIR)..."
	cd "$(TOOLCHAIN_DIR)" && \
	$(TOOLCHAIN_DIR)/configure --prefix=$(GCC_PQCUARK_DIR) --with-arch=rv64gv_zba_zbb_zbc_zbkb_zbkx --with-abi=lp64d
	@echo "GCC PQCUARK toolchain configured successfully"
	make -C "$(TOOLCHAIN_DIR)" -j$(nproc)
	@echo "GCC PQCUARK toolchain built successfully and installed to $(GCC_PQCUARK_DIR)"

# -----------------------------------------------------------------------------
# Clean targets
# -----------------------------------------------------------------------------
.PHONY: clean-binutils clean-toolchain

# Reset binutils submodule to pristine state (undo patch)
clean-binutils:
	@echo "Resetting binutils submodule to toolchain state"
	@if [ -d "$(TOOLCHAIN_DIR)/binutils/.git" ]; then \
		cd "$(TOOLCHAIN_DIR)/binutils" && \
		git reset --hard && \
		git clean -fd; \
	else \
		echo "Binutils submodule not initialized, nothing to clean"; \
	fi

# Nuclear option: remove entire toolchain and generated patches
# (you will reclone everything on next make all)
clean-toolchain:
	@echo "Removing toolchain and generated patches"
	rm -rf "$(TOOLCHAIN_DIR)"
	rm -rf "$(BINUTILS_PATCH_DIR)"