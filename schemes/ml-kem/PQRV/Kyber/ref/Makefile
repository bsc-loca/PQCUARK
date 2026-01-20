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

ifndef GCC_PQCUARK 
$(error Please set environment variable for GCC15 toolchain compiler)
endif

# GCC15=$(GCC15)
CC=$(GCC15)/bin/riscv64-unknown-elf-gcc
CC_DEV=$(GCC15)/bin/riscv64-unknown-elf-gcc
CC_OBJDUMP=$(GCC15)/bin/riscv64-unknown-elf-objdump
CC_OBJCOPY=$(GCC15)/bin/riscv64-unknown-elf-objcopy


# PLATFORM ?= C908

# CC 		= riscv64-unknown-elf-gcc
# OBJDUMP = riscv64-unknown-elf-objdump

# COMMONDIR 		= ../../common
# KECCAKDIR		= ../../sha3
COMMON_SYS_DIR = ../../../common/sargantana_standalone
COMMONDIR 		= ../../common
KECCAKDIR		= ../../sha3
UTILSDIR = ../../../utils

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
	ABI = lp64
endif

VREPORT=-Rpass-analysis=loop-vectorize  -Rpass-analysis=inline #-Rpass=loop-vectorize -Rpass-missed=loop-vectorize

OPTIONS = -DREF_IMPL
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

MARCH_RV64IM 		= -march=rv64g -mabi=$(ABI) -mcmodel=medany
MARCH_RV64IMV 	= -march=rv64gvzvl128b -mabi=$(ABI) -mcmodel=medany -mno-autovec-segment
MARCH_RV64IMB		= -march=rv64g_zba_zbb -mabi=$(ABI) -mcmodel=medany
MARCH_RV64IMBV		= -march=rv64gvzvl128b_zba_zbb -mabi=$(ABI) -mcmodel=medany

CFLAGS_RV64IM =  $(MARCH_RV64IM) -std=gnu99 -O3 -DPREALLOCATE=1 \
									-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin \
									-ffreestanding -ffast-math -fno-common $(OPTIONS) \
									-I$(COMMONDIR) -I$(KECCAKDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 

CFLAGS_RV64IMV =  $(MARCH_RV64IMV) -std=gnu99 -O3 -DPREALLOCATE=1 \
										-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin \
										-funroll-all-loops -ffreestanding -ffast-math -fno-common $(OPTIONS) \
										-I$(COMMONDIR) -I$(KECCAKDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 

CFLAGS_RV64IMB = $(MARCH_RV64IMB) -std=gnu99 -O3 -DPREALLOCATE=1 -Wall \
										-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin \
										-ffreestanding -ffast-math -fno-common -DRV64 -DBITMAN $(OPTIONS) \
										-I$(COMMONDIR) -I$(KECCAKDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 

CFLAGS_RV64IMBV = $(MARCH_RV64IMBV) -std=gnu99 -O3 -DPREALLOCATE=1 -Wall \
										-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin \
										-ffreestanding -ffast-math -fno-common -DRV64 -DVBITMAN $(OPTIONS) \
										-I$(COMMONDIR) -I$(KECCAKDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 


ifdef DEBUG
    CFLAGS_RV64IM += -g
		CFLAGS_RV64IMV += -g
		CFLAGS_RV64IMB += -g
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
SOURCES_COMMON 	= $(COMMON_SYS) $(UTILSDIR)/cpu_perf.c $(KECCAKDIR)/fips202_ref.c $(UTILSDIR)/print_metric.c $(UTILSDIR)/memcmp.c $(UTILSDIR)/qsort.c
HEADERS_COMMON 	= $(COMMON_SYS) $(UTILSDIR)/cpu_perf.h $(KECCAKDIR)/fips202.h $(UTILSDIR)/print_metric.h $(UTILSDIR)/memcmp.h $(UTILSDIR)/qsort.h

SOURCES 		= $(SOURCES_COMMON) $(SOURCES_RAND) kem.c indcpa.c polyvec.c poly.c ntt.c cbd.c reduce.c verify.c symmetric-shake.c
HEADERS 		= $(HEADERS_COMMON) $(HEADERS_RAND) params.h kem.h indcpa.h polyvec.h poly.h ntt.h cbd.h reduce.h verify.h symmetric.h
SOURCES_VECTOR 	= $(SOURCES_COMMON) kem.c indcpa.c polyvec.c poly.c ntt.c cbd.c reduce.c verify.c symmetric-shake.c
HEADERS_VECTOR 	= $(HEADERS_COMMON) params.h kem.h indcpa.h polyvec.h poly.h ntt.h cbd.h reduce.c verify.h symmetric.h

###############################################################################
# Compile rules
###############################################################################
.PHONY: all speed run_speed run_gen_vectors clean

all: \
	out/test_kyber512_rv64im	 out/test_kyber768_rv64im		out/test_kyber1024_rv64im  		\
	out/test_kyber512_rv64imb	 out/test_kyber768_rv64imb		out/test_kyber1024_rv64imb  	\
	out/test_kyber512_rv64imv	 out/test_kyber768_rv64imv		out/test_kyber1024_rv64imv  	\
	out/test_kyber512_rv64imbv	 out/test_kyber768_rv64imbv		out/test_kyber1024_rv64imbv  	

speed: \
	out/test_speed512_rv64im	out/test_speed768_rv64im	out/test_speed1024_rv64im 			\
	out/test_speed512_rv64imv	out/test_speed768_rv64imv	out/test_speed1024_rv64imv 			\
	out/test_speed512_rv64imb	out/test_speed768_rv64imb	out/test_speed1024_rv64imb 			


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

# for RV64IM

out/test_kyber512_rv64im: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=2 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@ 

out/test_kyber768_rv64im: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=3 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber1024_rv64im: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=4 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed512_rv64im: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=2 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed768_rv64im: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=3 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed1024_rv64im: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) -DKYBER_K=4 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

# for RV64IMB

out/test_kyber512_rv64imb: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=2 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber768_rv64imb: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=3 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber1024_rv64imb: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=4 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed512_rv64imb: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=2 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed768_rv64imb: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=3 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed1024_rv64imb: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC) $(CFLAGS_RV64IMB) $(LD_FLAGS) -DKYBER_K=4 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

# for RV64IMV

out/test_kyber512_rv64imv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=2 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber768_rv64imv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=3 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber1024_rv64imv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=4 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed512_rv64imv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=2 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed768_rv64imv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=3 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed1024_rv64imv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC) $(CFLAGS_RV64IMV) $(LD_FLAGS) -DKYBER_K=4 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

# for RV64IMBV

out/test_kyber512_rv64imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=2 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber768_rv64imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=3 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber1024_rv64imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_kyber.c
	$(CC) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=4 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed512_rv64imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=2 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed768_rv64imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=3 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed1024_rv64imbv: setup $(SOURCES) $(HEADERS) $(COMMONDIR)/test_speed_kyber.c
	$(CC) $(CFLAGS_RV64IMBV) $(LD_FLAGS) -DKYBER_K=4 $(filter %.c, $^) $(filter %.S, $^) -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

clean:
	-$(RM) -rf out/
