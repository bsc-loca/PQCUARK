###############################################################################
# Compiler Environment
###############################################################################
ARCH=$(shell uname -m)

SCP = scp
TARGET_IP 	=fpgalogin1.bsc.es
TARGET_USER =bsc018333
TARGET_DIR  =~/binaries

RM = /bin/rm

TEST ?=
GCC = $(GCC_PQCUARK)
ifdef GCC
	ifndef GCC15 
	$(error Please set environment variable for GCC15 toolchain compiler)
	endif

	CC=$(GCC15)/bin/riscv64-unknown-elf-gcc
	CC_DEV=$(GCC15)/bin/riscv64-unknown-elf-gcc
	CC_OBJDUMP=$(GCC15)/bin/riscv64-unknown-elf-objdump
	CC_OBJCOPY=$(GCC15)/bin/riscv64-unknown-elf-objcopy
else
	ifndef EPI_TOOLCHAIN_REL
	$(error Please set environment variable for EPI_TOOLCHAIN_REL toolchain compiler)
	endif
	ifndef EPI_TOOLCHAIN_DEV
	$(error Please set environment variable for EPI_TOOLCHAIN_DEV toolchain compiler)
	endif
	ifndef RISCV 
	$(error Please set environment variable for RISCV toolchain compiler)
	endif
	CC=$(EPI_TOOLCHAIN_REL)/bin/clang
	CC_DEV=$(EPI_TOOLCHAIN_DEV)/bin/clang

	ifeq ($(ARCH), riscv64)
		CC_OBJDUMP=$(RISCV)/bin/llvm-objdump
		CC_OBJCOPY=$(RISCV)/bin/llvm-objcopy
	else
		ifdef LINUX
			CC_OBJDUMP=$(RISCV)/bin/riscv64-unknown-elf-objdump
			CC_OBJCOPY=$(RISCV)/bin/riscv64-unknown-elf-objcopy
		else
			CC_OBJDUMP=$(RISCV)/bin/riscv64-unknown-elf-objdump
			CC_OBJCOPY=$(RISCV)/bin/riscv64-unknown-elf-objcopy
		endif
	endif
endif

COMMON_SYS_DIR = ../../../common/sargantana_standalone
COMMONDIR 		= ../../common
KECCAKDIR		= ../../sha3
UTILSDIR = ../../../utils
OBJDIR = ./obj

###############################################################################
# Flags 
###############################################################################
ifdef LINUX
	TARGET = riscv64-linux-gnu
	ABI = lp64d
else
	TARGET = riscv64-unknown-elf
	ifdef SPIKE
		ABI = lp64d
	else 
		ABI = lp64
	endif
endif

VREPORT=-Rpass-analysis=loop-vectorize  -Rpass-analysis=inline #-Rpass=loop-vectorize -Rpass-missed=loop-vectorize

ifdef FPGA 
OPTIONS += -DFPGA
endif
ifdef LINUX
	OPTIONS  += -DLINUX 
	ifdef SDV
		OPTIONS  += -DSDV $(SDV_TRACE_INCL) -I./sdv_tools 
	endif
else 
	OPTIONS   += -static 
endif

MARCH_RV64IM	= -march=rv64g -mabi=$(ABI) -mcmodel=medany
MARCH_RV64IMV	= -march=rv64gvzvl128b -mabi=$(ABI) -mcmodel=medany -mno-autovec-segment
MARCH_RV64IMB	= -march=rv64g_zba_zbb -mabi=$(ABI) -mcmodel=medany

CFLAGS_COMMON 	= -std=gnu99 -DPREALLOCATE=1 \
				  -Wall -Wno-implicit-function-declaration  \
				  -fno-builtin-printf -fno-builtin -fomit-frame-pointer \
				  -ffreestanding -ffast-math -fno-common \
				  -I$(COMMONDIR) -I$(KECCAKDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. \
				  -DDILITHIUM_COUNT_REJ_NUM $(OPTIONS)

ifdef DEBUG
	CFLAGS_COMMON += -g
endif

CFLAGS_RV64IM 	= $(CFLAGS_COMMON) -O3 $(MARCH_RV64IM) -DREF_IMPL
CFLAGS_RV64IMB 	= $(CFLAGS_COMMON) -O3 $(MARCH_RV64IMB) -DREF_IMPL
CFLAGS_RV64IMV 	= $(CFLAGS_COMMON) -O3 $(MARCH_RV64IMV) -DVECTOR128 -DREF_IMPL 

ifndef LINUX
	LD_FLAGS=-fno-builtin-printf -fno-builtin -ffreestanding
	LD_FLAGS+=-nostdlib -nostartfiles -lgcc
	LD_FLAGS+=-Wl,-T
	ifdef FPGA
		LD_FLAGS+= $(COMMON_SYS_DIR)/test_fpga.ld
	else
		LD_FLAGS+= $(COMMON_SYS_DIR)/test.ld
	endif
endif

ifdef SDV
	SDV_LINK = -lm $(SDV_TRACE_C_LINK)   
endif

###############################################################################
# Sources and Headers
###############################################################################
ifdef LINUX 
	COMMON_SYS:= 
else
	COMMON_SYS:=$(COMMON_SYS_DIR)/syscalls.c $(COMMON_SYS_DIR)/crt.S
	ifdef FPGA
		COMMON_SYS:=$(COMMON_SYS_DIR)/syscalls_fpga.c $(COMMON_SYS_DIR)/crt_fpga.S $(COMMON_SYS_DIR)/uart.c
	endif
endif

SOURCES_RAND 	= $(UTILSDIR)/randombytes.c
HEADERS_RAND 	= $(UTILSDIR)/randombytes.h
SOURCES_COMMON 	= $(UTILSDIR)/cpu_perf.c $(KECCAKDIR)/fips202_ref.c $(UTILSDIR)/print_metric.c $(UTILSDIR)/memcmp.c $(UTILSDIR)/qsort.c
HEADERS_COMMON 	= $(UTILSDIR)/cpu_perf.h $(KECCAKDIR)/fips202.h $(KECCAKDIR)/fips202x.h $(UTILSDIR)/print_metric.h $(UTILSDIR)/memcmp.h $(UTILSDIR)/qsort.h

OBJECTS_COMMON_SYS := $(patsubst $(COMMON_SYS_DIR)/%.c,$(OBJDIR)/common/%.o,$(filter %.c,$(COMMON_SYS)))
OBJECTS_COMMON_SYS += $(patsubst $(COMMON_SYS_DIR)/%.S,$(OBJDIR)/common/%.o,$(filter %.S,$(COMMON_SYS)))

SOURCES 		= $(SOURCES_COMMON) $(SOURCES_RAND) sign.c packing.c polyvec.c poly.c ntt.c reduce.c rounding.c symmetric-shake.c
HEADERS 		= $(HEADERS_COMMON) $(HEADERS_RAND) config.h params.h api.h sign.h packing.h polyvec.h poly.h ntt.h reduce.h rounding.h symmetric.h
SOURCES_VECTOR 	= $(SOURCES_COMMON) sign.c packing.c polyvec.c poly.c ntt.c reduce.c rounding.c symmetric-shake.c
HEADERS_VECTOR 	= $(HEADERS_COMMON) config.h params.h api.h sign.h packing.h polyvec.h poly.h ntt.h reduce.h rounding.h symmetric.h

###############################################################################
# Compile rules
###############################################################################

.PHONY: all speed run_speed run_gen_vectors clean

all: \
	out/test_dilithium2_rv64im 		\
	out/test_dilithium3_rv64im		out/test_dilithium5_rv64im 	\
	out/test_dilithium2_rv64imb 	\
	out/test_dilithium3_rv64imb		out/test_dilithium5_rv64imb \
	out/test_dilithium2_rv64imv 	\
	out/test_dilithium3_rv64imv		out/test_dilithium5_rv64imv \
	out/test_dilithium2_rv64imbv 	\
	out/test_dilithium3_rv64imbv	out/test_dilithium5_rv64imbv 

speed: \
	out/test_speed2_rv64im 		out/test_speed3_rv64im			out/test_speed5_rv64im 		\
	out/test_speed2_rv64imb 		out/test_speed3_rv64imb			out/test_speed5_rv64imb 		\
	out/test_speed2_rv64imv 		out/test_speed3_rv64imv			out/test_speed5_rv64imv	

setup: 
	mkdir -p out
ifdef FPGA
bin: 
		$(CC_OBJDUMP) -Dshx $(TEST) > $(TEST).dump
		$(CC_OBJCOPY) -O binary $(TEST) $(TEST).bin
		@echo "BIN Generated"
		$(SCP) $(TEST).bin $(TARGET_USER)@$(TARGET_IP):$(TARGET_DIR)/
else 
bin: 
		$(CC_OBJDUMP) -Dshx $(TEST) > $(TEST).dump
		@echo "ELF Generated"
endif

$(OBJDIR)/common/%.o: $(COMMON_SYS)
	mkdir -p obj/common 
	$(MAKE) -C $(COMMON_SYS_DIR) clean
	$(MAKE) -C $(COMMON_SYS_DIR)
	@for file in $(COMMON_SYS_DIR)/*.o; do \
		mv "$$file" "$(OBJDIR)/common/"; \
	done

	@for file in $(OBJDIR)/common/*.o; do \
		$(CC_OBJDUMP) -Dshx "$$file" > "$$file".dump; \
	done


# For RV64IM

out/test_dilithium2_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map -DDILITHIUM_MODE=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_dilithium3_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DDILITHIUM_MODE=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_dilithium5_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DDILITHIUM_MODE=5 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed2_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_speed_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DDILITHIUM_MODE=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed3_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_speed_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DDILITHIUM_MODE=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed5_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_speed_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DDILITHIUM_MODE=5 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_mul_rv64im: $(COMMONDIR)/test_mul_dilithium.c $(SOURCES) $(SOURCES_RV64IM) $(HEADERS)
	mkdir -p out/
	$(CC) $(CFLAGS_RV64IM) -UDBENCH -DDILITHIUM_MODE=2 \
	  -o $@ $(filter %.c, $^) $(filter %.S, $^)

# For RV64IMB

out/test_dilithium2_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMB) $(COMMONDIR)/test_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DDILITHIUM_MODE=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_dilithium3_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMB) $(COMMONDIR)/test_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DDILITHIUM_MODE=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_dilithium5_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMB) $(COMMONDIR)/test_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DDILITHIUM_MODE=5 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed2_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMB) $(COMMONDIR)/test_speed_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DDILITHIUM_MODE=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed3_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMB) $(COMMONDIR)/test_speed_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DDILITHIUM_MODE=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed5_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMB) $(COMMONDIR)/test_speed_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DDILITHIUM_MODE=5 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_mul_rv64imb: $(COMMONDIR)/test_mul_dilithium.c $(SOURCES) $(SOURCES_RV64IMB) $(HEADERS)
	mkdir -p out/
	$(CC) $(CFLAGS_RV64IMB) -UDBENCH -DDILITHIUM_MODE=2 \
	  -o $@ $(filter %.c, $^) $(filter %.S, $^)

# For RV64IMV

out/test_dilithium2_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IMV) $(HEADERS) $(COMMONDIR)/test_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DDILITHIUM_MODE=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_dilithium3_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IMV) $(HEADERS) $(COMMONDIR)/test_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DDILITHIUM_MODE=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_dilithium5_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IMV) $(HEADERS) $(COMMONDIR)/test_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DDILITHIUM_MODE=5 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed2_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMV) $(COMMONDIR)/test_speed_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DDILITHIUM_MODE=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed3_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMV) $(COMMONDIR)/test_speed_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DDILITHIUM_MODE=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed5_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMV) $(COMMONDIR)/test_speed_dilithium.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DDILITHIUM_MODE=5 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

# For RV64IMBV

out/test_dilithium2_rv64imbv: $(COMMONDIR)/test_dilithium.c $(SOURCES) $(SOURCES_RV64IMBV) $(HEADERS)
	mkdir -p out/
	$(CC) $(CFLAGS_RV64IMBV) -DDILITHIUM_MODE=2 \
	  -o $@ $(filter %.c, $^) $(filter %.S, $^)

out/test_dilithium3_rv64imbv: $(COMMONDIR)/test_dilithium.c $(SOURCES) $(SOURCES_RV64IMBV) $(HEADERS)
	$(CC) $(CFLAGS_RV64IMBV) -DDILITHIUM_MODE=3 \
	  -o $@ $(filter %.c, $^) $(filter %.S, $^)

out/test_dilithium5_rv64imbv: $(COMMONDIR)/test_dilithium.c $(SOURCES) $(SOURCES_RV64IMBV) $(HEADERS)
	$(CC) $(CFLAGS_RV64IMBV) -DDILITHIUM_MODE=5 \
	  -o $@ $(filter %.c, $^) $(filter %.S, $^)

out/test_speed2_rv64imbv: $(COMMONDIR)/test_speed_dilithium.c $(SOURCES) $(SOURCES_RV64IMBV) $(HEADERS)
	mkdir -p out/
	$(CC) $(CFLAGS_RV64IMBV) -DDILITHIUM_MODE=2 \
	  -o $@ $(filter %.c, $^) $(filter %.S, $^)

out/test_speed3_rv64imbv: $(COMMONDIR)/test_speed_dilithium.c $(SOURCES) $(SOURCES_RV64IMBV) $(HEADERS)
	$(CC) $(CFLAGS_RV64IMBV) -DDILITHIUM_MODE=3 \
	  -o $@ $(filter %.c, $^) $(filter %.S, $^)

out/test_speed5_rv64imbv: $(COMMONDIR)/test_speed_dilithium.c $(SOURCES) $(SOURCES_RV64IMBV) $(HEADERS)
	$(CC) $(CFLAGS_RV64IMBV) -DDILITHIUM_MODE=5 \
	  -o $@ $(filter %.c, $^) $(filter %.S, $^)

out/test_mul_rv64imbv: $(COMMONDIR)/test_mul_dilithium.c $(SOURCES) $(SOURCES_RV64IMBV) $(HEADERS)
	mkdir -p out/
	$(CC) $(CFLAGS_RV64IMBV) -UDBENCH -DDILITHIUM_MODE=2 \
	  -o $@ $(filter %.c, $^) $(filter %.S, $^)

clean:
	-$(RM) -rf out/