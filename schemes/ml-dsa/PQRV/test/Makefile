###############################################################################
# Compiler Environment
###############################################################################
ARCH=$(shell uname -m)

ifdef GCC
	ifndef GCC14 
	$(error Please set environment variable for GCC14 toolchain compiler)
	endif

	CC=$(GCC14)/bin/riscv64-unknown-linux-gnu-gcc
	CC_OBJDUMP=$(GCC14)/bin/riscv64-unknown-linux-gnu-objdump
	CC_OBJCOPY=$(GCC14)/bin/riscv64-unknown-linux-gnu-objcopy
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
			CC_OBJDUMP=$(RISCV)/bin/riscv64-unknown-linux-gnu-objdump
			CC_OBJCOPY=$(RISCV)/bin/riscv64-unknown-linux-gnu-objcopy
		else
			CC_OBJDUMP=$(RISCV)/bin/riscv64-unknown-elf-objdump
			CC_OBJCOPY=$(RISCV)/bin/riscv64-unknown-elf-objcopy
		endif
	endif
endif

COMMONDIR 		= ../../common
UTILSDIR = ../../utils
KYBERNTTDIR		= ../ntt/kyber
DILITHIUMNTTDIR	= ../ntt/dilithium

###############################################################################
# Flags 
###############################################################################
ifdef LINUX
	TARGET = riscv64-linux-gnu
	ABI = lp64d
else
	TARGET = riscv64-unknown-elf
	ABI = lp64
endif

ifdef GCC
#	CFLAGS = -O3 -fomit-frame-pointer -static -flax-vector-conversions \
			-march=rv64imafdv_zba_zbb -mabi=lp64d -I$(COMMONDIR) -I$(KYBERNTTDIR) -I.
	CFLAGS_RV64IM 	= -O3 -fomit-frame-pointer -static -flax-vector-conversions \
			-march=rv64ima -mabi=lp64 -DRV64=1 -I$(COMMONDIR) -I$(DILITHIUMNTTDIR) -I.
#	CFLAGS_RV64IMBV = -O3 -fomit-frame-pointer -static -flax-vector-conversions \
			-march=rv64imav_zba_zbb -mabi=lp64 -DVECTOR128 -DRV64=1 -I$(COMMONDIR) -I$(DILITHIUMNTTDIR) -I.
else 
#	CFLAGS = -O3 -fomit-frame-pointer -static -flax-vector-conversions \
			-march=rv64imafdv_zba_zbb -mabi=$(ABI) -I$(COMMONDIR) -I$(KYBERNTTDIR) -I.
	CFLAGS_RV64IM 	= -O3 --target=$(TARGET) -fomit-frame-pointer -flax-vector-conversions \
			-march=rv64g -mabi=$(ABI) -mcmodel=medany -DRV64=1 -I$(COMMONDIR) -I$(KYBERNTTDIR) -I$(DILITHIUMNTTDIR) -I$(UTILSDIR) -I.
#	CFLAGS_RV64IMBV = -O3 -fomit-frame-pointer -static -flax-vector-conversions \
			-march=rv64imav_zba_zbb -mabi=$(ABI) -DVECTOR128 -DRV64=1 -I$(COMMONDIR) -I$(DILITHIUMNTTDIR) -I.
endif

ifndef LINUX
	LD_FLAGS=-fno-builtin-printf -fno-builtin -ffreestanding
	LD_FLAGS+=-nostdlib -nostartfiles -lgcc
	LD_FLAGS+=-Wl,-T
	ifdef FPGA
		LD_FLAGS+= $(COMMONDIR)/test_fpga.ld
	else
		LD_FLAGS+= $(COMMONDIR)/test.ld
	endif
endif

RM = /bin/rm

SOURCES = $(COMMONDIR)/cpu_perf.c $(COMMONDIR)/print_metric.c
HEADERS = $(COMMONDIR)/cpu_perf.h $(COMMONDIR)/print_metric.h

.PHONY: all results clean

all: \
	out/test_ntt_rv64im
# out/test_add

# out/test_dilithium_mont_rv32imv
# out/test_kyber_ntt_rvv
# out/test_dilithium_mont_rv32imv
# out/test_dilithium_mont_rv64imv
# out/test_dilithium_singleissue_plant_ntt_rv64 out/test_dilithium_dualissue_plant_ntt_rv64
# out/test_kyber_hybrid_ntt_rv32v
# out/test_kyber_mont_ntt_rv32
# out/test_add64 out/test_dilithium_ntt
# out/test_add  out/test_mul out/test_ntt out/test_ntt_rv32 out/test_hybrido ut/test_plantard out/test_plantard_rv64 out/test_ntt_rv32im out/test_ntt_rv64im

objdump:
	$(CC_OBJDUMP) -D out/test_add > out/test_add.S

out/test_kyber_ntt_rvv: test_kyber_ntt_rvv.c $(COMMONDIR)/cpu_perf.c $(COMMONDIR)/print_metric.c $(KYBERNTTDIR)/ntt_rvv.S $(KYBERNTTDIR)/consts.c $(KYBERNTTDIR)/consts.h
	mkdir -p out
	$(CC) -I$(KYBERNTTDIR) $(CFLAGS_RV32IMBV) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/test_dilithium_mont_rv64imv: test_dilithium_mont_rvv.c $(COMMONDIR)/cpu_perf.c $(COMMONDIR)/print_metric.c $(DILITHIUMNTTDIR)/ntt_rvv.S $(DILITHIUMNTTDIR)/consts.c $(DILITHIUMNTTDIR)/consts.h
	mkdir -p out
	$(CC) -I$(DILITHIUMNTTDIR) $(CFLAGS_RV64IMBV) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/test_dilithium_singleissue_plant_ntt_rv64: test_dilithium_plant_ntt_rv64.c $(COMMONDIR)/cpu_perf.c $(COMMONDIR)/print_metric.c $(DILITHIUMNTTDIR)/ntt_8l_singleissue_plant_rv64im.S
	mkdir -p out
	$(CC) $(CFLAGS_RV64IM) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/test_dilithium_dualissue_plant_ntt_rv64: test_dilithium_plant_ntt_rv64.c $(COMMONDIR)/cpu_perf.c $(COMMONDIR)/print_metric.c $(DILITHIUMNTTDIR)/ntt_8l_dualissue_plant_rv64im.S
	mkdir -p out
	$(CC) $(CFLAGS_RV64IM) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/test_add: $(SOURCES) $(HEADERS)
	mkdir -p out
	$(CC) $(CFLAGS) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/test_mul: vmul.c vmul.S
	$(CC) $(CFLAGS) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/test_ntt: $(KYBERNTTDIR)/ntt_rvv.S ntt.c $(KYBERNTTDIR)/consts.c $(KYBERNTTDIR)/consts.h $(COMMONDIR)/cpu_perf.c $(COMMONDIR)/print_metric.c
	mkdir -p out
	$(CC) $(CFLAGS) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/test_plantard_rv64: $(KYBERNTTDIR)/ntt_singleissue_plant_rv64im.S test_plantard_rv64.c $(COMMONDIR)/cpu_perf.c $(COMMONDIR)/print_metric.c
	mkdir -p out
	$(CC) $(CFLAGS) $(filter %.c, $^) $(filter %.S, $^) -o $@

out/test_ntt_rv64im: $(KYBERNTTDIR)/ntt_singleissue_plant_rv64im.S test_ntt_rv64im.c
	mkdir -p out
	$(CC) $(CFLAGS_RV64IM) $(LD_FLAGS) $(filter %.c, $^) $(filter %.S, $^) -o $@
	$(CC_OBJDUMP) -Dshx $@ > $@.dump

clean:
	-$(RM) -rf out/
