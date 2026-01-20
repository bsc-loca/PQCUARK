# Makefile

# defaults
SIM ?= questa 
TOPLEVEL_LANG ?= verilog
INCLUDE ?= ../../includes
SRC_TOP = ../../src
VERILOG_SOURCES +=  $(SRC_TOP)/mont_reduction/montgomery_kyber.sv \
					$(SRC_TOP)/mont_reduction/montgomery_dilithium.sv \
					$(SRC_TOP)/mont_reduction/bfu_modred.sv \
					$(SRC_TOP)/barrett_reduction/barrett_reduce.sv \
					$(SRC_TOP)/barrett_reduction/bfu_barrett.sv \
					$(SRC_TOP)/multiplier/multiplier.sv \
					$(SRC_TOP)/multiplier/bfu_multiplier.sv \
					$(INCLUDE)/pqcuark-common/pipe_queue.sv \
					$(SRC_TOP)/twiddle_factor_rom/zetas_sram.sv \
					$(SRC_TOP)/twiddle_factor_rom/IN22FDX_S1P_BFRG_W00320B032M08C128.v \
					$(SRC_TOP)/twiddle_factor_rom/MBH_MSBL_IN22FDX_S1P_BFRG_W00320B032M08C128.v \
					$(SRC_TOP)/twiddle_factor_rom/MBH_ZSBL_IN22FDX_S1P_BFRG_W00320B032M08C128.v \
					$(SRC_TOP)/add_sub_32bit.sv \
					$(SRC_TOP)/bfu_top.sv

ZETAS_ROM_FILE=$(SRC_TOP)/rtl/twiddle_factor_rom/zetas.hex
ZETAS_KYBER_ROM_FILE=$(SRC_TOP)/rtl/twiddle_factor_rom/zetas_kyber.hex
ZETAS_DILITHIUM_ROM_FILE=$(SRC_TOP)/rtl/twiddle_factor_rom/zetas_dilithium.hex

# use VHDL_SOURCES for VHDL files
VSIM_ARGS += -pli "$(shell cocotb-config --lib-dir)/libcocotbvpi_modelsim.so"
VSIM_ARGS += -64
# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = bfu_top
TOPLEVEL=bfu_top

ifeq ($(SIM), verilator)
VERILOG_SOURCES += $(SRC_TOP)/rtl/twiddle_factor_rom/zetas_rom.sv
EXTRA_ARGS += --trace -DZETAS_KYBER_ROM_FILE="\"$(ZETAS_KYBER_ROM_FILE)\"" -DZETAS_DILITHIUM_ROM_FILE="\"$(ZETAS_DILITHIUM_ROM_FILE)\"" 
SIM_ARGS += +trace_file=dump.vcd
else
EXTRA_ARGS += +define+ZETAS_ROM_FILE="\"$(ZETAS_ROM_FILE)\"" +define+ZETAS_SRAM
VSIM_ARGS += -pli "$(shell cocotb-config --lib-dir)/libcocotbvpi_modelsim.so"
VSIM_ARGS += -64 
endif

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
MODULE = test_bfu_top

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: clean

clean::
	rm -rf __pycache__ modelsim.ini results.xml transcript vsim.wlf vsim_stacktrace.vstf sim_build dump.vcd test_in_C
