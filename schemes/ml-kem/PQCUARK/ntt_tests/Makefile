###############################################################################
# Compiler Environment
###############################################################################
ARCH=$(shell uname -m)
GCC = $(GCC_PQCUARK)

SCP=scp
TARGET_IP=fpgalogin1.bsc.es
TARGET_USER=bsc018333
TARGET_DIR=~/binaries

RM = /bin/rm

TEST ?=

ifndef GCC 
$(error Please set environment variable for CC toolchain compiler)
endif

CC=$(GCC)/bin/riscv64-unknown-elf-gcc
CC_DEV=$(GCC)/bin/riscv64-unknown-elf-gcc
CC_OBJDUMP=$(GCC)/bin/riscv64-unknown-elf-objdump
CC_OBJCOPY=$(GCC)/bin/riscv64-unknown-elf-objcopy


# COMMONDIR 		= ../../common
# KECCAKDIR		= ../../sha3
COMMON_SYS_DIR = ../../../common/sargantana_standalone
UTILSDIR = ../../../utils
OBJDIR = ./obj
NTT_DIR = ../ntt_src

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

MARCH_RV64IM	= -march=rv64g_zbkx_zbkb -mabi=$(ABI) -mcmodel=medany

CFLAGS_RV64IM = $(MARCH_RV64IM) -std=gnu99 -O3 -DPQCUARK \
				-DPREALLOCATE=1 -Wall \
				-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin \
				-ffreestanding -ffast-math -fno-common -DRV64 $(OPTIONS) \
				-I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. -I../src -I$(NTT_DIR) 


ifdef DEBUG
    CFLAGS_RV64IM += -g
endif

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


OBJECTS_COMMON_SYS := $(patsubst $(COMMON_SYS_DIR)/%.c,$(OBJDIR)/common/%.o,$(filter %.c,$(COMMON_SYS)))
OBJECTS_COMMON_SYS += $(patsubst $(COMMON_SYS_DIR)/%.S,$(OBJDIR)/common/%.o,$(filter %.S,$(COMMON_SYS)))

SOURCES_UTILS 	= $(UTILSDIR)/cpu_perf.c $(UTILSDIR)/print_metric.c $(UTILSDIR)/memcmp.c $(UTILSDIR)/qsort.c
HEADERS_UTILS 	= $(UTILSDIR)/cpu_perf.h $(UTILSDIR)/print_metric.h $(UTILSDIR)/memcmp.h $(UTILSDIR)/qsort.h
###############################################################################
# Compile rules
###############################################################################
.PHONY: all speed run_speed run_gen_vectors clean

all: out/test_bfnttk \
	 out/test_bfnttd \
	 out/test_bfinttk \
	 out/test_bfinttd \
	 out/test_speed_bfnttk \
	 out/test_speed_bfnttd \
	 test_ntt

test_ntt: out/test_ntt_kyber \
	 out/test_ntt_kyber_unroll2 \
	 out/test_ntt_kyber_unroll3 \
	 out/test_ntt_kyber_unroll4 \
	 out/test_ntt_kyber_asm \
	 out/test_ntt_kyber_asm_opt \
	 out/test_ntt_kyber_asm_fqmul \
	 out/test_ntt_kyber_asm_pack_fqmul
setup: 
	mkdir -p out

ifdef FPGA
bin: 
		$(CC_OBJDUMP) -d $(TEST) > $(TEST).dump
		$(CC_OBJCOPY) -O binary $(TEST) $(TEST).bin
		@echo "BIN Generated"
		$(SCP) $(TEST).bin $(TARGET_USER)@$(TARGET_IP):$(TARGET_DIR)/
else 
bin: 
		$(CC_OBJDUMP) -d $(TEST) > $(TEST).dump
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
		$(CC_OBJDUMP) -d "$$file" > "$$file".dump; \
	done

# for RV64IM

out/test_bfnttk: setup $(OBJECTS_COMMON_SYS) test_bfnttk.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_bfnttd: setup $(OBJECTS_COMMON_SYS) test_bfnttd.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_bfinttk: setup $(OBJECTS_COMMON_SYS) test_bfinttk.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_bfinttd: setup $(OBJECTS_COMMON_SYS) test_bfinttd.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_bffqmul16: setup $(OBJECTS_COMMON_SYS) test_bffqmul16.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_xperm8: setup $(OBJECTS_COMMON_SYS) test_xperm8.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_xperm8_simple: setup $(OBJECTS_COMMON_SYS) test_xperm8_simple.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_pack: setup $(OBJECTS_COMMON_SYS) test_pack.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed_bfnttk: setup $(OBJECTS_COMMON_SYS) $(SOURCES_UTILS) $(HEADERS_UTILS) test_speed_bfnttk.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_speed_bfnttd: setup $(OBJECTS_COMMON_SYS) $(SOURCES_UTILS) $(HEADERS_UTILS) test_speed_bfnttd.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_ntt_kyber: setup $(OBJECTS_COMMON_SYS) $(SOURCES_UTILS) $(HEADERS_UTILS) $(NTT_DIR)/ntt.h test_ntt_kyber.c $(NTT_DIR)/ntt_nounroll.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_ntt_kyber_unroll2: setup $(OBJECTS_COMMON_SYS) $(SOURCES_UTILS) $(HEADERS_UTILS) $(NTT_DIR)/ntt.h test_ntt_kyber.c $(NTT_DIR)/ntt_unroll2.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_ntt_kyber_unroll3: setup $(OBJECTS_COMMON_SYS) $(SOURCES_UTILS) $(HEADERS_UTILS) $(NTT_DIR)/ntt.h test_ntt_kyber.c $(NTT_DIR)/ntt_unroll3.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_ntt_kyber_unroll4: setup $(OBJECTS_COMMON_SYS) $(SOURCES_UTILS) $(HEADERS_UTILS) $(NTT_DIR)/ntt.h test_ntt_kyber.c $(NTT_DIR)/ntt_unroll4.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_ntt_kyber_asm: setup $(OBJECTS_COMMON_SYS) $(SOURCES_UTILS) $(HEADERS_UTILS) $(NTT_DIR)/ntt.h test_ntt_kyber.c $(NTT_DIR)/ntt.S
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_ntt_kyber_asm_opt: setup $(OBJECTS_COMMON_SYS) $(SOURCES_UTILS) $(HEADERS_UTILS)$(NTT_DIR)/ntt.h $(NTT_DIR)/ntt_opt.c $(NTT_DIR)/ntt_opt.S test_ntt_kyber.c 
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_ntt_kyber_asm_fqmul: setup $(OBJECTS_COMMON_SYS) $(SOURCES_UTILS) $(HEADERS_UTILS) $(NTT_DIR)/ntt.h $(NTT_DIR)/ntt_pack_fqmul.c $(NTT_DIR)/ntt_fqmul.S test_ntt_kyber.c 
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_ntt_kyber_asm_pack_fqmul: setup $(OBJECTS_COMMON_SYS) $(SOURCES_UTILS) $(HEADERS_UTILS) $(NTT_DIR)/ntt.h $(NTT_DIR)/ntt_pack_fqmul.c $(NTT_DIR)/ntt_pack_fqmul.S test_ntt_kyber.c ../src/reduce.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

clean:
	-$(RM) -rf out/ obj/
