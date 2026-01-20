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

ifdef GCC
	ifndef GCC_PQCUARK 
	$(error Please set environment variable for GCC_PQCUARK toolchain compiler)
	endif

	CC=$(GCC_PQCUARK)/bin/riscv64-unknown-elf-gcc
	CC_DEV=$(GCC_PQCUARK)/bin/riscv64-unknown-elf-gcc
	CC_OBJDUMP=$(GCC_PQCUARK)/bin/riscv64-unknown-elf-objdump
	CC_OBJCOPY=$(GCC_PQCUARK)/bin/riscv64-unknown-elf-objcopy
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

# PLATFORM ?= C908

# CC 		= riscv64-unknown-elf-gcc
# OBJDUMP = riscv64-unknown-elf-objdump

# COMMONDIR 		= ../../common
# KECCAKDIR		= ../../sha3
COMMON_SYS_DIR = ../../../common/sargantana_standalone
COMMONDIR 		= ../../common
KECCAKDIR		= ../../sha3
NTTDIR			= ../../ntt/kyber
UTILSDIR = ../../../utils
OBJDIR = ./obj

###############################################################################
# Flags 
###############################################################################

# CFLAGS_COMMON 	= -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
#   				  -Wshadow -Wpointer-arith -O3 -fomit-frame-pointer -static \
# 				  -I$(COMMONDIR) -I$(KECCAKDIR) -I. -DREF_IMPL

# CFLAGS_RV32IM 	= $(CFLAGS_COMMON) -march=rv32imac -mabi=ilp32 -DRV32=1
# CFLAGS_RV32IMB 	= $(CFLAGS_COMMON) -march=rv32imac_zbb -mabi=ilp32 -DRV32=1
# CFLAGS_RV32IMV 	= $(CFLAGS_COMMON) -march=rv32imacv -mabi=ilp32 -DRV32=1
# CFLAGS_RV32IMBV = $(CFLAGS_COMMON) -march=rv32imacv_zbb -mabi=ilp32 -DRV32=1
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
MARCH_RV64IMV	= -march=rv64gvzvl128b -mabi=$(ABI) -mcmodel=medany
MARCH_RV64IMB	= -march=rv64g_zba_zbb_zbs_zbkx_zbkb -mabi=$(ABI) -mcmodel=medany

CFLAGS_RV64IM = $(MARCH_RV64IM) -std=gnu99 -O3 \
				-DPREALLOCATE=1 -Wall \
				-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin \
				-ffreestanding -ffast-math -fno-common -DRV64 $(OPTIONS) \
				-I$(COMMONDIR) -I$(KECCAKDIR) -I$(NTTDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 

CFLAGS_RV64IMV = $(MARCH_RV64IMV) -std=gnu99 -O3 \
				-DPREALLOCATE=1 -Wall \
				-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin -fno-tree-vectorize \
				-funroll-all-loops -ffreestanding -ffast-math -fno-common -DVECTOR128 $(OPTIONS) \
				-I$(COMMONDIR) -I$(KECCAKDIR) -I$(NTTDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 

CFLAGS_RV64IMB = $(MARCH_RV64IMB) -std=gnu99 -O3 \
				-DPREALLOCATE=1 -Wall \
				-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin \
				-ffreestanding -ffast-math -fno-common -DRV64 -DBITMAN $(OPTIONS) \
				-I$(COMMONDIR) -I$(KECCAKDIR) -I$(NTTDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 


ifdef DEBUG
    CFLAGS_RV64IM += -g
		CFLAGS_RV64IMV += -g
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

SOURCES_RAND 	= $(UTILSDIR)/randombytes.c
HEADERS_RAND 	= $(UTILSDIR)/randombytes.h
SOURCES_COMMON 	= $(UTILSDIR)/cpu_perf.c $(KECCAKDIR)/fips202_rv64.c $(UTILSDIR)/print_metric.c $(UTILSDIR)/memcmp.c $(UTILSDIR)/qsort.c
HEADERS_COMMON 	= $(UTILSDIR)/cpu_perf.h $(KECCAKDIR)/fips202.h $(KECCAKDIR)/fips202x.h $(UTILSDIR)/print_metric.h $(UTILSDIR)/memcmp.h $(UTILSDIR)/qsort.h

SOURCES_RV64IM	= $(KECCAKDIR)/fips202_rv64im.S $(NTTDIR)/ntt_singleissue_plant_rv64im.S
SOURCES_RV64IMV	= $(KECCAKDIR)/fips202_rv64im.S $(NTTDIR)/ntt_rvv_m1.S $(NTTDIR)/consts.c $(NTTDIR)/ntt_singleissue_plant_rv64im.S
SOURCES_RV64IMB	= $(KECCAKDIR)/fips202_rv64imb.S $(NTTDIR)/ntt_singleissue_plant_rv64im.S

OBJECTS_COMMON_SYS := $(patsubst $(COMMON_SYS_DIR)/%.c,$(OBJDIR)/common/%.o,$(filter %.c,$(COMMON_SYS)))
OBJECTS_COMMON_SYS += $(patsubst $(COMMON_SYS_DIR)/%.S,$(OBJDIR)/common/%.o,$(filter %.S,$(COMMON_SYS)))

SOURCES 		= $(SOURCES_COMMON) $(SOURCES_RAND) kem.c indcpa.c polyvec.c poly.c ntt.c cbd.c reduce.c verify.c symmetric-shake.c
HEADERS 		= $(HEADERS_COMMON) $(HEADERS_RAND) params.h kem.h indcpa.h polyvec.h poly.h ntt.h cbd.h reduce.h verify.h symmetric.h
SOURCES_VECTOR 	= $(OBJECTS_COMMON_SYS) $(SOURCES_COMMON) kem.c indcpa.c polyvec.c poly.c ntt.c cbd.c reduce.c verify.c symmetric-shake.c
HEADERS_VECTOR 	= $(HEADERS_COMMON) params.h kem.h indcpa.h polyvec.h poly.h ntt.h cbd.h reduce.c verify.h symmetric.h

###############################################################################
# Compile rules
###############################################################################
.PHONY: all speed run_speed run_gen_vectors clean

all: \
	out/test_kyber512_rv64im	 out/test_kyber768_rv64im		out/test_kyber1024_rv64im  		\
  out/test_vectors512_rv64im 	 out/test_vectors768_rv64im		out/test_vectors1024_rv64im 	\
	out/test_kyber512_rv64imb	 out/test_kyber768_rv64imb		out/test_kyber1024_rv64imb  	\
  out/test_vectors512_rv64imb  out/test_vectors768_rv64imb	out/test_vectors1024_rv64imb	\
	out/test_kyber512_rv64imv	 out/test_kyber768_rv64imv		out/test_kyber1024_rv64imv  	\
  out/test_vectors512_rv64imv  out/test_vectors768_rv64imv	out/test_vectors1024_rv64imv	\
	out/test_kyber512_rv64imbv	 out/test_kyber768_rv64imbv		out/test_kyber1024_rv64imbv  	\
  out/test_vectors512_rv64imbv out/test_vectors768_rv64imbv 	out/test_vectors1024_rv64imbv	

spike: \
	out/test_kyber512_rv64im_spike	 out/test_kyber512_rv64imv_spike		out/test_kyber512_rv64imb_spike

speed: \
	out/test_speed512_rv64im	out/test_speed768_rv64im	out/test_speed1024_rv64im 			\
	out/test_speed512_rv64imb	out/test_speed768_rv64imb	out/test_speed1024_rv64imb			\
	out/test_speed512_rv64imv	out/test_speed768_rv64imv	out/test_speed1024_rv64imv 			\
	#out/test_speed512_rv64imbv	out/test_speed768_rv64imbv	out/test_speed1024_rv64imbv

run_speed: out/scp_test_speed
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./test_speed512_rv64im; ./test_speed768_rv64im; ./test_speed1024_rv64im" > results_rv64im.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./test_speed512_rv64imb; ./test_speed768_rv64imb; ./test_speed1024_rv64imb" > results_rv64imb.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./test_speed512_rv64imv; ./test_speed768_rv64imv; ./test_speed1024_rv64imv" > results_rv64imv.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./test_speed512_rv64imbv; ./test_speed768_rv64imbv; ./test_speed1024_rv64imbv" > results_rv64imbv.txt

out/scp_test_speed:	\
	out/test_speed512_rv64im	out/test_speed768_rv64im	out/test_speed1024_rv64im 	\
	out/test_speed512_rv64imb	out/test_speed768_rv64imb	out/test_speed1024_rv64imb	\
	out/test_speed512_rv64imv	out/test_speed768_rv64imv	out/test_speed1024_rv64imv 	\
	out/test_speed512_rv64imbv	out/test_speed768_rv64imbv	out/test_speed1024_rv64imbv
	$(SCP) $^ $(TARGET_USER)@$(TARGET_IP):$(TARGET_DIR)/
	@echo 1 > $@
	
out/scp_test:	\
	out/test_kyber512_rv64im	 out/test_kyber768_rv64im		out/test_kyber1024_rv64im  		\
    out/test_vectors512_rv64im 	 out/test_vectors768_rv64im		out/test_vectors1024_rv64im 	\
	out/test_kyber512_rv64imb	 out/test_kyber768_rv64imb		out/test_kyber1024_rv64imb  	\
    out/test_vectors512_rv64imb  out/test_vectors768_rv64imb	out/test_vectors1024_rv64imb	\
	out/test_kyber512_rv64imv	 out/test_kyber768_rv64imv		out/test_kyber1024_rv64imv  	\
    out/test_vectors512_rv64imv  out/test_vectors768_rv64imv	out/test_vectors1024_rv64imv	\
	out/test_kyber512_rv64imbv	 out/test_kyber768_rv64imbv		out/test_kyber1024_rv64imbv  	\
    out/test_vectors512_rv64imbv out/test_vectors768_rv64imbv 	out/test_vectors1024_rv64imbv
	$(SCP) $^ $(TARGET_USER)@$(TARGET_IP):$(TARGET_DIR)/
	@echo 1 > $@
# out/test_kyber512_rv32im 	 out/test_kyber768_rv32im 		out/test_kyber1024_rv32im 		\
# out/test_vectors512_rv32im 	 out/test_vectors768_rv32im 	out/test_vectors1024_rv32im 	\
# out/test_kyber512_rv32imb 	 out/test_kyber768_rv32imb 		out/test_kyber1024_rv32imb 		\
# out/test_vectors512_rv32imb  out/test_vectors768_rv32imb 	out/test_vectors1024_rv32imb	\
# out/test_kyber512_rv32imv	 out/test_kyber768_rv32imv		out/test_kyber1024_rv32imv		\
# out/test_vectors512_rv32imv	 out/test_vectors768_rv32imv	out/test_vectors1024_rv32imv	\
# out/test_kyber512_rv32imbv 	 out/test_kyber768_rv32imbv 	out/test_kyber1024_rv32imbv 	\
# out/test_vectors512_rv32imbv out/test_vectors768_rv32imbv 	out/test_vectors1024_rv32imbv	\

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

out/test_kyber512_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -Wl,-Map=$@.map -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_kyber768_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber1024_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_vectors512_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES_VECTOR) $(SOURCES_RV64IM) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_vectors768_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES_VECTOR) $(SOURCES_RV64IM) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_vectors1024_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES_VECTOR) $(SOURCES_RV64IM) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed512_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed768_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed1024_rv64im: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

# for RV64IMB

out/test_kyber512_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMB) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber768_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMB) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber1024_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMB) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_vectors512_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(SOURCES_RV64IMB) $(COMMONDIR)/test_vectors_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_vectors768_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(SOURCES_RV64IMB) $(COMMONDIR)/test_vectors_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_vectors1024_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(SOURCES_RV64IMB) $(COMMONDIR)/test_vectors_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed512_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMB) $(COMMONDIR)/test_speed_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed768_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMB) $(COMMONDIR)/test_speed_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed1024_rv64imb: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMB) $(COMMONDIR)/test_speed_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

# for RV64IMV

out/test_kyber512_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IMV) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber768_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IMV) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber1024_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(SOURCES_RV64IMV) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_vectors512_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES_VECTOR) $(SOURCES_RV64IMV) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
	mkdir -p out
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_vectors768_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES_VECTOR) $(SOURCES_RV64IMV) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_vectors1024_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES_VECTOR) $(SOURCES_RV64IMV) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed512_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMV) $(COMMONDIR)/test_speed_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed768_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMV) $(COMMONDIR)/test_speed_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed1024_rv64imv: setup $(OBJECTS_COMMON_SYS) $(SOURCES) $(HEADERS) $(SOURCES_RV64IMV) $(COMMONDIR)/test_speed_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

################################
# SPIKE TESTS
################################
out/hello: setup $(COMMONDIR)/hello.c
	$(CC_DEV) $(CFLAGS_RV64IM) $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ 
	$(MAKE) bin TEST=$@

out/test_kyber512_rv64im_spike: setup $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IM) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@
	$(MAKE) bin TEST=$@ 

out/test_kyber512_rv64imv_spike: setup $(SOURCES) $(SOURCES_RV64IMV) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMV) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@
	$(MAKE) bin TEST=$@ 

out/test_kyber512_rv64imb_spike: setup $(SOURCES) $(SOURCES_RV64IMB) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMB) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@
	$(MAKE) bin TEST=$@ 

out/test_kyber768_rv64im_spike: setup $(SOURCES) $(SOURCES_RV64IM) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IM) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@
	$(MAKE) bin TEST=$@ 

out/test_kyber768_rv64imv_spike: setup $(SOURCES) $(SOURCES_RV64IMV) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMV) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@
	$(MAKE) bin TEST=$@ 

out/test_kyber768_rv64imb_spike: setup $(SOURCES) $(SOURCES_RV64IMB) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC_DEV) $(CFLAGS_RV64IMB) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@
	$(MAKE) bin TEST=$@ 
# for RV64IMBV

# out/test_kyber512_rv64imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	$(CC_DEV) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
# 	$(MAKE) bin TEST=$@

# out/test_kyber768_rv64imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	$(CC_DEV) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
# 	$(MAKE) bin TEST=$@

# out/test_kyber1024_rv64imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	$(CC_DEV) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
# 	$(MAKE) bin TEST=$@

# out/test_vectors512_rv64imbv: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	$(CC_DEV) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
# 	$(MAKE) bin TEST=$@

# out/test_vectors768_rv64imbv: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	$(CC_DEV) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
# 	$(MAKE) bin TEST=$@

# out/test_vectors1024_rv64imbv: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	$(CC_DEV) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
# 	$(MAKE) bin TEST=$@

# out/test_speed512_rv64imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	$(CC_DEV) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
# 	$(MAKE) bin TEST=$@

# out/test_speed768_rv64imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	$(CC_DEV) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
# 	$(MAKE) bin TEST=$@

# out/test_speed1024_rv64imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	$(CC_DEV) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
# 	$(MAKE) bin TEST=$@

# for RV32IM

# out/test_kyber512_rv32im: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	mkdir -p out
# 	$(CC) $(CFLAGS_RV32IM) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_kyber768_rv32im: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	$(CC) $(CFLAGS_RV32IM) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_kyber1024_rv32im: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	$(CC) $(CFLAGS_RV32IM) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_vectors512_rv32im: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	mkdir -p out
# 	$(CC) $(CFLAGS_RV32IM) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_vectors768_rv32im: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	$(CC) $(CFLAGS_RV32IM) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_vectors1024_rv32im: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	$(CC) $(CFLAGS_RV32IM) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_speed512_rv32im: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	mkdir -p out
# 	$(CC) $(CFLAGS_RV32IM) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_speed768_rv32im: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	$(CC) $(CFLAGS_RV32IM) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_speed1024_rv32im: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	$(CC) $(CFLAGS_RV32IM) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# # for RV32IMB

# out/test_kyber512_rv32imb: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	mkdir -p out
# 	$(CC) $(CFLAGS_RV32IMB) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_kyber768_rv32imb: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	$(CC) $(CFLAGS_RV32IMB) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_kyber1024_rv32imb: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	$(CC) $(CFLAGS_RV32IMB) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_vectors512_rv32imb: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	mkdir -p out
# 	$(CC) $(CFLAGS_RV32IMB) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_vectors768_rv32imb: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	$(CC) $(CFLAGS_RV32IMB) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_vectors1024_rv32imb: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	$(CC) $(CFLAGS_RV32IMB) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_speed512_rv32imb: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	mkdir -p out
# 	$(CC) $(CFLAGS_RV32IMB) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_speed768_rv32imb: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	$(CC) $(CFLAGS_RV32IMB) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_speed1024_rv32imb: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	$(CC) $(CFLAGS_RV32IMB) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# # for RV32IMV

# out/test_kyber512_rv32imv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	mkdir -p out
# 	$(CC) $(CFLAGS_RV32IMV) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_kyber768_rv32imv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	$(CC) $(CFLAGS_RV32IMV) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_kyber1024_rv32imv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	$(CC) $(CFLAGS_RV32IMV) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_vectors512_rv32imv: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	mkdir -p out
# 	$(CC) $(CFLAGS_RV32IMV) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_vectors768_rv32imv: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	$(CC) $(CFLAGS_RV32IMV) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_vectors1024_rv32imv: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	$(CC) $(CFLAGS_RV32IMV) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_speed512_rv32imv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	mkdir -p out
# 	$(CC) $(CFLAGS_RV32IMV) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_speed768_rv32imv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	$(CC) $(CFLAGS_RV32IMV) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_speed1024_rv32imv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	$(CC) $(CFLAGS_RV32IMV) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# # for RV32IMBV

# out/test_kyber512_rv32imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	mkdir -p out
# 	$(CC) $(CFLAGS_RV32IMBV) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_kyber768_rv32imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	$(CC) $(CFLAGS_RV32IMBV) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_kyber1024_rv32imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
# 	$(CC) $(CFLAGS_RV32IMBV) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_vectors512_rv32imbv: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	mkdir -p out
# 	$(CC) $(CFLAGS_RV32IMBV) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_vectors768_rv32imbv: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	$(CC) $(CFLAGS_RV32IMBV) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_vectors1024_rv32imbv: setup $(SOURCES_VECTOR) $(HEADERS_VECTOR) $(COMMONDIR)/test_vectors_kyber.c
# 	$(CC) $(CFLAGS_RV32IMBV) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_speed512_rv32imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	mkdir -p out
# 	$(CC) $(CFLAGS_RV32IMBV) -DKYBER_K=2 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_speed768_rv32imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	$(CC) $(CFLAGS_RV32IMBV) -DKYBER_K=3 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

# out/test_speed1024_rv32imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
# 	$(CC) $(CFLAGS_RV32IMBV) -DKYBER_K=4 $(filter %.o, $^) $(filter %.c, $^) $(filter %.S, $^) -o $@

clean:
	-$(RM) -rf out/
