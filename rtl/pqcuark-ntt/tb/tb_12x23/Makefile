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

# ============================================================================
# Makefile for Cocotb with both Questa and Verilator
# ============================================================================
# Usage Examples:
#  1) make SIM=questa SIGNED_MODE=1
#  2) make SIM=verilator SIGNED_MODE=0
#  3) make SIM=questa clean
#
# By default, SIM=questa. Change or override via "make SIM=verilator" as needed.
# If you want to force a specific test file, set MODULE=<test_module_name>.
# If your test is distributed among multiple .py files, Cocotb autodiscovers them.
# ============================================================================

# Default simulator
SIM ?= questa

# Language
TOPLEVEL_LANG ?= verilog

# Location of your RTL sources
SRC_TOP = ../../src/
VERILOG_SOURCES = $(SRC_TOP)/rtl/multiplier/mul_12x23bit.sv 

# Top-level module name in the SystemVerilog
TOPLEVEL = mul_12x23bit

# Cocotb 'MODULE' is the name(s) of your test .py file(s) (without the .py extension).
# If you have a single test file: MODULE = test_mul_12x23bit
# If you have two separate test files, you can set this from the command line.
MODULE ?= test_mul_12x23bit

# ----------------------------------------------------------------------------
# Extra arguments to pass to simulators
# ----------------------------------------------------------------------------
# We'll define two sets of arguments: one for Questa/ModelSim, one for Verilator.

# For Questa
ifeq ($(SIM),questa)
	# Provide 64-bit, etc.
	VSIM_ARGS += -64
	# Link Cocotb's ModelSim/Questa VPI library
	VSIM_ARGS += -pli "$(shell cocotb-config --lib-dir)/libcocotbvpi_modelsim.so"
	# If user specifies SIGNED_MODE, we pass it as a generics override: -gSIGNED_MODE=<val>
	ifneq ($(SIGNED_MODE),)
		VSIM_ARGS += -gSIGNED_MODE=$(SIGNED_MODE)
	endif
endif

# For Verilator
ifeq ($(SIM),verilator)
	# Some typical warnings; enable tracing if desired
	VERILATOR_ARGS += -Wall --trace
	# If user specifies SIGNED_MODE, we define it with -D
	ifneq ($(SIGNED_MODE),)
	VERILATOR_ARGS += -DSIGNED_MODE=$(SIGNED_MODE)
endif
	# This is how we pass extra args to Verilator
	EXTRA_ARGS += $(VERILATOR_ARGS)
endif

# ----------------------------------------------------------------------------
# Now include Cocotb's standard simulator rules
# ----------------------------------------------------------------------------
include $(shell cocotb-config --makefiles)/Makefile.sim

# ----------------------------------------------------------------------------
# Optional convenience targets
# ----------------------------------------------------------------------------

# "make clean" will remove build artifacts
clean::
	rm -rf __pycache__ cvc.log sim_build/ \
	obj_dir/  *.vcd *.log  \
	*.pyc *.xml .pytest_cache
