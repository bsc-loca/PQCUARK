
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
	ifndef GCC14 
	$(error Please set environment variable for GCC14 toolchain compiler)
	endif

	CC=$(GCC14)/bin/riscv64-unknown-linux-gnu-gcc
	CC_DEV=$(GCC14)/bin/riscv64-unknown-linux-gnu-gcc
	OBJDUMP=$(GCC14)/bin/riscv64-unknown-linux-gnu-objdump
	OBJCOPY=$(GCC14)/bin/riscv64-unknown-linux-gnu-objcopy
else
	ifndef EPI_TOOLCHAIN_REL
	$(error Please set environment variable for EPI_TOOLCHAIN_REL toolchain compiler)
	endif
	ifndef 
	$(error Please set environment variable for  toolchain compiler)
	endif
	ifndef RISCV 
	$(error Please set environment variable for RISCV toolchain compiler)
	endif
	CC=$(EPI_TOOLCHAIN_REL)/bin/clang
	CC_DEV=$()/bin/clang

	ifeq ($(ARCH), riscv64)
		OBJDUMP=$(RISCV)/bin/llvm-objdump
		OBJCOPY=$(RISCV)/bin/llvm-objcopy
	else
		ifdef LINUX
			OBJDUMP=$(RISCV)/bin/riscv64-unknown-linux-gnu-objdump
			OBJCOPY=$(RISCV)/bin/riscv64-unknown-linux-gnu-objcopy
		else
			OBJDUMP=$(RISCV)/bin/riscv64-unknown-elf-objdump
			OBJCOPY=$(RISCV)/bin/riscv64-unknown-elf-objcopy
		endif
	endif
endif

COMMON_SYS_DIR = ../../common/sargantana_standalone
UTILSDIR = ../../utils
OBJDIR = ./obj

COMMONDIR 		= ../common
KYBERNTTDIR		= ./kyber
DILITHIUMNTTDIR = ./dilithium

###############################################################################
# Flags 
###############################################################################
# CFLAGS_COMMON 	= -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
#   				  -Wshadow -Wpointer-arith -O3 -fomit-frame-pointer -static \
# 				  -I$(COMMONDIR) -I.

# CFLAGS_RV32IM 	= $(CFLAGS_COMMON) -march=rv32imac -mabi=ilp32 -DRV32=1
# CFLAGS_RV32IMB 	= $(CFLAGS_COMMON) -march=rv32imac_zbb -mabi=ilp32 -DRV32=1 -DBIT_INTERLEAVING
# CFLAGS_RV32IMV 	= $(CFLAGS_COMMON) -march=rv32imacv -mabi=ilp32 -DRV32=1 -DVECTOR128
# CFLAGS_RV32IMBV = $(CFLAGS_COMMON) -march=rv32imacv_zbb -mabi=ilp32 -DRV32=1 -DBIT_INTERLEAVING -DVECTOR128
# CFLAGS_RV64IM 	= $(CFLAGS_COMMON) -march=rv64g -mabi=lp64 -DRV64=1
# CFLAGS_RV64IMB 	= $(CFLAGS_COMMON) -march=rv64g_zba_zbb -mabi=lp64 -DRV64=1
# CFLAGS_RV64IMV 	= $(CFLAGS_COMMON) -march=rv64gv -mabi=lp64 -DVECTOR128 -DRV64=1
# CFLAGS_RV64IMBV = $(CFLAGS_COMMON) -march=rv64gv_zba_zbb -mabi=lp64 -DVECTOR128 -DRV64=1

ifdef LINUX
	TARGET = riscv64-linux-gnu
	ABI = lp64d
else
	TARGET = riscv64-unknown-elf
	ABI = lp64
endif

VREPORT=-Rpass-analysis=loop-vectorize  -Rpass-analysis=inline #-Rpass=loop-vectorize -Rpass-missed=loop-vectorize

OPTIONS = -DRV64=1
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

ifdef GCC 
MARCH_RV64IM	= -march=rv64g -mabi=$(ABI) -mcmodel=medany
MARCH_RV64IMV	= -march=rv64gvzvl128b -mabi=$(ABI) -mcmodel=medany
MARCH_RV64IMB	= -march=rv64g_zba_zbb -mabi=$(ABI) -mcmodel=medany

CFLAGS_RV64IM = $(MARCH_RV64IM) -std=gnu99 -O3 -DPREALLOCATE=1  -Wall\
				-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin \
				-ffreestanding -ffast-math -fno-common $(OPTIONS) \
				-I$(COMMONDIR) -I$(KECCAKDIR) -I$(NTTDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 

CFLAGS_RV64IMV = $(MARCH_RV64IMV) -std=gnu99 -O3 -DPREALLOCATE=1 \
				-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin -fno-tree-vectorize \
				-funroll-all-loops -ffreestanding -ffast-math -fno-common -DVECTOR128 $(OPTIONS) \
				-I$(COMMONDIR) -I$(KECCAKDIR) -I$(NTTDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 

CFLAGS_RV64IMB = $(MARCH_RV64IMB) -std=gnu99 -O2 -DPREALLOCATE=1  -Wall\
				-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin \
				-ffreestanding -ffast-math -fno-common $(OPTIONS) \
				-I$(COMMONDIR) -I$(KECCAKDIR) -I$(NTTDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 

else
MARCH_RV64IM 	= -march=rv64g --target=$(TARGET) -mabi=$(ABI) -mcmodel=medany
MARCH_RV64IMV 	= -march=rv64gv --target=$(TARGET) -mabi=$(ABI) -mcmodel=medany
MARCH_RV64IMB	= -march=rv64g_zba_zbb --target=$(TARGET) -mabi=$(ABI) -mcmodel=medany

CFLAGS_RV64IM = $(MARCH_RV64IM) -std=gnu99 -O3 -DPREALLOCATE=1 -Wall \
				-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin \
				-ffreestanding -ffast-math -fno-common $(OPTIONS) \
				-I$(COMMONDIR) -I$(KECCAKDIR) -I$(NTTDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 
CFLAGS_RV64IMV = $(MARCH_RV64IMV) -std=gnu99 -O2 -DPREALLOCATE=1 $(VREPORT) \
				-Wno-implicit-function-declaration -fno-tree-vectorize -fno-builtin-printf \
				-fno-builtin -ffreestanding -ffast-math -fno-common -DVECTOR128 $(OPTIONS) \
				-I$(COMMONDIR) -I$(KECCAKDIR) -I$(NTTDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 
CFLAGS_RV64IMB = $(MARCH_RV64IMB) -std=gnu99 -O3 -DPREALLOCATE=1  -Wall\
				-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin \
				-ffreestanding -ffast-math -fno-common $(OPTIONS) \
				-I$(COMMONDIR) -I$(KECCAKDIR) -I$(NTTDIR) -I$(UTILSDIR) -I$(COMMON_SYS_DIR) -I. 

endif

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

SOURCES_COMMON 	= $(UTILSDIR)/cpu_perf.c $(UTILSDIR)/print_metric.c $(UTILSDIR)/memcmp.c $(UTILSDIR)/qsort.c
HEADERS_COMMON 	= $(UTILSDIR)/cpu_perf.h $(UTILSDIR)/print_metric.h $(UTILSDIR)/memcmp.h $(UTILSDIR)/qsort.h

SOURCES			= speed_ntt.c

.PHONY: all run_all clean

all: \
	out/speed_singleissue_kyber_plantard_ntt_rv32	\
	out/speed_dualissue_kyber_plantard_ntt_rv32		\
	out/speed_singleissue_kyber_plantard_ntt_rv64	\
	out/speed_dualissue_kyber_plantard_ntt_rv64		\
	out/speed_dualissue_kyber_plantard_l32_ntt_rv64	\
	out/speed_singleissue_dilithium_mont_ntt_rv32	\
	out/speed_dualissue_dilithium_mont_ntt_rv32		\
	out/speed_dualissue_dilithium_plant_ntt_rv64		\
	out/speed_dualissue_kyber_mont_ntt_rv32			\
	out/speed_dualissue_kyber_mont_ntt_rvv			\
	out/speed_dualissue_dilithium_mont_ntt_rvv		\
	out/scp_speed

run_all: out/scp_speed
	@echo "speed_singleissue_kyber_plantard_ntt_rv32:" > speed_ntt.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./speed_singleissue_kyber_plantard_ntt_rv32" >> speed_ntt.txt
	@echo "\nspeed_dualissue_kyber_plantard_ntt_rv32:" >> speed_ntt.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./speed_dualissue_kyber_plantard_ntt_rv32" >> speed_ntt.txt
	@echo "\nspeed_singleissue_kyber_plantard_ntt_rv64:" >> speed_ntt.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./speed_singleissue_kyber_plantard_ntt_rv64" >> speed_ntt.txt
	@echo "\nspeed_dualissue_kyber_plantard_ntt_rv64:" >> speed_ntt.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./speed_dualissue_kyber_plantard_ntt_rv64" >> speed_ntt.txt
	@echo "\nspeed_dualissue_kyber_plantard_l32_ntt_rv64:" >> speed_ntt.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./speed_dualissue_kyber_plantard_l32_ntt_rv64" >> speed_ntt.txt
	@echo "\nspeed_dualissue_kyber_mont_ntt_rv32:" >> speed_ntt.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./speed_dualissue_kyber_mont_ntt_rv32" >> speed_ntt.txt
	@echo "\nspeed_dualissue_kyber_mont_ntt_rvv:" >> speed_ntt.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./speed_dualissue_kyber_mont_ntt_rvv" >> speed_ntt.txt
	@echo "\nspeed_singleissue_dilithium_mont_ntt_rv32:" >> speed_ntt.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./speed_singleissue_dilithium_mont_ntt_rv32" >> speed_ntt.txt
	@echo "\nspeed_dualissue_dilithium_mont_ntt_rv32:" >> speed_ntt.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./speed_dualissue_dilithium_mont_ntt_rv32" >> speed_ntt.txt
	@echo "\nspeed_dualissue_dilithium_plant_ntt_rv64:" >> speed_ntt.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./speed_dualissue_dilithium_plant_ntt_rv64" >> speed_ntt.txt
	@echo "\nspeed_dualissue_dilithium_mont_ntt_rvv:" >> speed_ntt.txt
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_DIR) && ./speed_dualissue_dilithium_mont_ntt_rvv" >> speed_ntt.txt

out/scp_speed:	\
	out/speed_singleissue_kyber_plantard_ntt_rv32	\
	out/speed_dualissue_kyber_plantard_ntt_rv32		\
	out/speed_singleissue_kyber_plantard_ntt_rv64	\
	out/speed_dualissue_kyber_plantard_ntt_rv64		\
	out/speed_dualissue_kyber_plantard_l32_ntt_rv64	\
	out/speed_singleissue_dilithium_mont_ntt_rv32	\
	out/speed_dualissue_dilithium_mont_ntt_rv32		\
	out/speed_dualissue_dilithium_plant_ntt_rv64		\
	out/speed_dualissue_kyber_mont_ntt_rv32			\
	out/speed_dualissue_kyber_mont_ntt_rvv			\
	out/speed_dualissue_dilithium_mont_ntt_rvv
	$(SCP) $^ $(TARGET_USER)@$(TARGET_IP):$(TARGET_DIR)/
	@echo 1 > $@

out/speed_singleissue_kyber_plantard_ntt_rv32: $(SOURCES_COMMON) $(SOURCES) $(HEADERS_COMMON) $(KYBERNTTDIR)/ntt_singleissue_plant_rv32im.S
	mkdir -p out
	$(CC) $(CFLAGS_RV32IM) -I$(KYBERNTTDIR) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/speed_dualissue_kyber_plantard_ntt_rv32: $(SOURCES_COMMON) $(SOURCES) $(HEADERS_COMMON) $(KYBERNTTDIR)/ntt_dualissue_plant_rv32im.S
	mkdir -p out
	$(CC) $(CFLAGS_RV32IM) -I$(KYBERNTTDIR) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/speed_singleissue_kyber_plantard_ntt_rv64: $(SOURCES_COMMON) $(SOURCES) $(HEADERS_COMMON) $(KYBERNTTDIR)/ntt_singleissue_plant_rv64im.S
	mkdir -p out
	$(CC) $(CFLAGS_RV64IM) -I$(KYBERNTTDIR) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/speed_dualissue_kyber_plantard_ntt_rv64: $(SOURCES_COMMON) $(SOURCES) $(HEADERS_COMMON) $(KYBERNTTDIR)/ntt_dualissue_plant_rv64im.S
	mkdir -p out
	$(CC) $(CFLAGS_RV64IM) -I$(KYBERNTTDIR) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/speed_dualissue_kyber_plantard_l32_ntt_rv64: $(SOURCES_COMMON) $(SOURCES) $(HEADERS_COMMON) $(KYBERNTTDIR)/ntt_dualissue_l32_plant_rv64im.S
	mkdir -p out
	$(CC) $(CFLAGS_RV64IM) -I$(KYBERNTTDIR) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/speed_singleissue_dilithium_mont_ntt_rv32: $(SOURCES_COMMON) $(SOURCES) $(HEADERS_COMMON) $(DILITHIUMNTTDIR)/ntt_8l_singleissue_mont_rv32im.S $(DILITHIUMNTTDIR)/ntt_6l_singleissue_mont_rv32im.S
	mkdir -p out
	$(CC) $(CFLAGS_RV32IM) -I$(DILITHIUMNTTDIR) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/speed_dualissue_dilithium_mont_ntt_rv32: $(SOURCES_COMMON) $(SOURCES) $(HEADERS_COMMON) $(DILITHIUMNTTDIR)/ntt_8l_dualissue_mont_rv32im.S $(DILITHIUMNTTDIR)/ntt_6l_dualissue_mont_rv32im.S
	mkdir -p out
	$(CC) $(CFLAGS_RV32IM) -I$(DILITHIUMNTTDIR) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/speed_dualissue_dilithium_plant_ntt_rv64: $(SOURCES_COMMON) $(SOURCES) $(HEADERS_COMMON) $(DILITHIUMNTTDIR)/ntt_8l_dualissue_plant_rv64im.S
	mkdir -p out
	$(CC) $(CFLAGS_RV64IM) -I$(DILITHIUMNTTDIR) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/speed_dualissue_kyber_mont_ntt_rv32: $(SOURCES_COMMON) $(SOURCES) $(HEADERS_COMMON) $(KYBERNTTDIR)/ntt_dualissue_mont_rv32im.S
	mkdir -p out
	$(CC) $(CFLAGS_RV32IM) -I$(KYBERNTTDIR) -DKYBER_RV32_MONT $(filter %.c, $^) $(filter %.S, $^) -o $@

out/speed_dualissue_kyber_mont_ntt_rvv: $(SOURCES_COMMON) $(SOURCES) $(HEADERS_COMMON) $(KYBERNTTDIR)/ntt_rvv.S $(KYBERNTTDIR)/consts.c
	mkdir -p out
	$(CC) $(CFLAGS_RV32IMV) -I$(KYBERNTTDIR) -DRVV $(filter %.c, $^) $(filter %.S, $^) -o $@

out/speed_dualissue_dilithium_mont_ntt_rvv: $(SOURCES_COMMON) $(SOURCES) $(HEADERS_COMMON) $(DILITHIUMNTTDIR)/ntt_rvv.S $(DILITHIUMNTTDIR)/basemul_acc_double.S $(DILITHIUMNTTDIR)/consts.c
	mkdir -p out
	$(CC) $(CFLAGS_RV32IMV) -I$(DILITHIUMNTTDIR) -DRVV $(filter %.c, $^) $(filter %.S, $^) -o $@

clean:
	rm -rf out/
