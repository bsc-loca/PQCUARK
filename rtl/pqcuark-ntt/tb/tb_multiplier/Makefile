# Makefile

# defaults
SIM ?= questa 
TOPLEVEL_LANG ?= verilog
INCLUDE ?= ../../includes
SRC_TOP = ../../src/
VERILOG_SOURCES += $(INCLUDE)/pqcuark-common/pipe_queue.sv \
									 $(SRC_TOP)/multiplier/multiplier.sv \
									 $(SRC_TOP)/multiplier/bfu_multiplier.sv \
# use VHDL_SOURCES for VHDL files
VSIM_ARGS += -pli "$(shell cocotb-config --lib-dir)/libcocotbvpi_modelsim.so"
VSIM_ARGS += -64
# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = bfu_multiplier
TOPLEVEL=bfu_multiplier

ifeq ($(SIM), "verilator")
EXTRA_ARGS += --trace 
SIM_ARGS += +trace_file=dump.vcd
endif

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
MODULE = test_bfu_multiplier

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: clean

clean::
	rm -rf __pycache__ modelsim.ini results.xml transcript vsim.wlf vsim_stacktrace.vstf sim_build dump.vcd