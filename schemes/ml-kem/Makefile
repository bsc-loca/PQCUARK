###############################################################################
# Compiler Environment 
###############################################################################
ARCH=$(shell uname -m)
GCC = $(GCC_PQCUARK)

#SCP = scp
#TARGET_IP 	=
#TARGET_USER =
#TARGET_DIR  =

RM = /bin/rm

TEST ?=

ifndef GCC 
$(error Please set environment variable for CC toolchain compiler)
endif

CC=$(GCC)/bin/riscv64-unknown-elf-gcc
CC_DEV=$(GCC)/bin/riscv64-unknown-elf-gcc
CC_OBJDUMP=$(GCC)/bin/riscv64-unknown-elf-objdump
CC_OBJCOPY=$(GCC)/bin/riscv64-unknown-elf-objcopy


COMMON_DIR = ./common/sargantana_standalone
UTILS_DIR = ./utils
OBJ_DIR = ./out/obj
BIN_DIR = ./out/bin
TESTS_DIR = ./tests

SRC_DIR ?=
NTT_DIR ?= 
KECCAK_DIR ?= 

NIST_SRC_DIR = ./NIST/src
PQRV_SRC_DIR = ./PQRV/Kyber/RV64
PQCUARK_SRC_DIR = ./PQCUARK/src
NIST_NTT_DIR = $(NIST_SRC_DIR)
PQRV_NTT_DIR = ./PQRV/ntt/kyber
PQCUARK_NTT_DIR = ./PQCUARK/ntt_src
NIST_KECCAK_DIR = $(NIST_SRC_DIR)
PQRV_KECCAK_DIR = ./PQRV/sha3
PQCUARK_KECCAK_DIR = ./PQCUARK/keccak_src


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

MARCH	= -march=rv64g_zba_zbb_zbs_zbkx_zbkb -mabi=$(ABI) -mcmodel=medany
CFLAGS = $(MARCH) -std=gnu99 -O3 \
				-DPREALLOCATE=1 -Wall \
				-Wno-implicit-function-declaration -fno-builtin-printf -fno-builtin \
				-ffreestanding -ffast-math -fno-common $(OPTIONS) \
				-I$(COMMON_DIR) -I$(UTILS_DIR) -I$(NTT_DIR) -I$(KECCAK_DIR) -I$(SRC_DIR) -I.

ifdef FPGA 
CFLAGS+= -DFPGA
endif
ifdef LINUX
	CFLAGS+= -DLINUX
	ifdef SDV
		CFLAGS+= -DSDV $(SDV_TRACE_INCL) -I./sdv_tools 
	endif
else 
	CFLAGS += -static 
endif

CONF ?= 

ifeq ($(CONF),ntt)
	CFLAGS += -DBASEMUL_ACC
endif

ifndef LINUX
	LD_FLAGS=-fno-builtin-printf -fno-builtin -ffreestanding
	LD_FLAGS+=-nostdlib -nostartfiles -lgcc
	LD_FLAGS+=-Wl,-T
	ifdef FPGA
		LD_FLAGS+= $(COMMON_DIR)/test_fpga.ld
	else
		LD_FLAGS+= $(COMMON_DIR)/test.ld
	endif
endif

ifdef SDV
	SDV_LINK = -lm $(SDV_TRACE_C_LINK)   
endif

# Sources and Headers
ifdef CINCORANCH 
	COMMON:=$(COMMON_DIR)/syscalls.c $(COMMON_DIR)/crt.S
	ifdef FPGA
		COMMON:=$(COMMON_DIR)/syscalls.c $(COMMON_DIR)/crt.S $(COMMON_DIR)/uart.c
	endif
else ifdef LINUX 
	COMMON:=
else
	COMMON:=$(COMMON_DIR)/syscalls.c $(COMMON_DIR)/crt.S
	ifdef FPGA
		COMMON:=$(COMMON_DIR)/syscalls_fpga.c $(COMMON_DIR)/crt_fpga.S $(COMMON_DIR)/uart.c
	endif
endif

# PQRV by default
SOURCES ?= reduce.c poly.c polyvec.c indcpa.c cbd.c verify.c kem.c symmetric-shake.c
SOURCESKECCAK ?= fips202_rv64.c fips202_rv64imb.S
SOURCESNTT ?= ntt.c ntt_dualissue_plant_rv64im.S
HEADERS := params.h kem.h indcpa.h polyvec.h poly.h cbd.h reduce.h verify.h symmetric.h randombytes.h sdv_env.h
HEADERSKECCAK := fips202.h
HEADERSNTT ?= ntt.h
UTILS := memcmp.c randombytes.c qsort.c 
ifndef LINUX
UTILS += cpu_perf.c print_metric.c
endif

override SOURCES := $(addprefix $(SRC_DIR)/, $(SOURCES))
override SOURCESKECCAK := $(addprefix $(KECCAK_DIR)/, $(SOURCESKECCAK))
override SOURCESNTT := $(addprefix $(NTT_DIR)/, $(SOURCESNTT))
override HEADERS := $(addprefix $(SRC_DIR)/, $(HEADERS))
override HEADERSKECCAK := $(addprefix $(KECCAK_DIR)/, $(HEADERSKECCAK))
override HEADERSNTT := $(addprefix $(NTT_DIR)/, $(HEADERSNTT))
UTILS := $(addprefix $(UTILS_DIR)/, $(UTILS))

OBJECTSKECCAK_512  := $(SOURCESKECCAK:$(KECCAK_DIR)/%.c=$(OBJ_DIR)/kyber512/%.o)
OBJECTSKECCAK_768  := $(SOURCESKECCAK:$(KECCAK_DIR)/%.c=$(OBJ_DIR)/kyber768/%.o)
OBJECTSKECCAK_1024 := $(SOURCESKECCAK:$(KECCAK_DIR)/%.c=$(OBJ_DIR)/kyber1024/%.o)
OBJECTSNTT_512  := $(SOURCESNTT:$(NTT_DIR)/%.c=$(OBJ_DIR)/kyber512/%.o)
OBJECTSNTT_768  := $(SOURCESNTT:$(NTT_DIR)/%.c=$(OBJ_DIR)/kyber768/%.o)
OBJECTSNTT_1024 := $(SOURCESNTT:$(NTT_DIR)/%.c=$(OBJ_DIR)/kyber1024/%.o)
OBJECTSCOMMON := $(patsubst $(COMMON_DIR)/%.c,$(OBJ_DIR)/common/%.o,$(filter %.c,$(COMMON)))
OBJECTSCOMMON += $(patsubst $(COMMON_DIR)/%.S,$(OBJ_DIR)/common/%.o,$(filter %.S,$(COMMON)))
OBJECTSUTILS  := $(UTILS:$(UTILS_DIR)/%.c=$(OBJ_DIR)/utils/%.o)

OBJECTS_512  := $(SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/kyber512/%.o) $(OBJECTSKECCAK_512) $(OBJECTSNTT_512) $(OBJECTSUTILS) $(OBJECTSCOMMON)
OBJECTS_768  := $(SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/kyber768/%.o) $(OBJECTSKECCAK_768) $(OBJECTSNTT_768) $(OBJECTSUTILS) $(OBJECTSCOMMON)
OBJECTS_1024 := $(SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/kyber1024/%.o) $(OBJECTSKECCAK_1024) $(OBJECTSNTT_1024) $(OBJECTSUTILS) $(OBJECTSCOMMON)
  
.PHONY: all speed shared clean

all: kyber speed

kyber: kyber_nist kyber_pqrv_rv64im kyber_pqrv_rv64imb \
	kyber_ntt kyber_keccak kyber_pqcuark

speed: speed_nist speed_pqrv_rv64im speed_pqrv_rv64imb \
	speed_ntt speed_keccak speed_pqcuark

kyber_nist: \
 test_kyber512_nist \
 test_kyber768_nist \
 test_kyber1024_nist 

kyber_pqrv_rv64im: \
 test_kyber512_pqrv_rv64im \
 test_kyber768_pqrv_rv64im \
 test_kyber1024_pqrv_rv64im
kyber_pqrv_rv64imb: \
 test_kyber512_pqrv_rv64imb \
 test_kyber768_pqrv_rv64imb \
 test_kyber1024_pqrv_rv64imb

kyber_ntt: \
 test_kyber512_ntt \
 test_kyber768_ntt \
 test_kyber1024_ntt  
kyber_keccak: \
 test_kyber512_keccak \
 test_kyber768_keccak \
 test_kyber1024_keccak  
kyber_pqcuark: \
 test_kyber512_pqcuark \
 test_kyber768_pqcuark \
 test_kyber1024_pqcuark  

speed_nist: \
 test_speed512_nist \
 test_speed768_nist \
 test_speed1024_nist
speed_pqrv_rv64im: \
 test_speed512_pqrv_rv64im \
 test_speed768_pqrv_rv64im \
 test_speed1024_pqrv_rv64im
speed_pqrv_rv64imb: \
 test_speed512_pqrv_rv64imb \
 test_speed768_pqrv_rv64imb \
 test_speed1024_pqrv_rv64imb

speed_ntt: \
 test_speed512_ntt \
 test_speed768_ntt \
 test_speed1024_ntt
speed_keccak: \
 test_speed512_keccak \
 test_speed768_keccak \
 test_speed1024_keccak
speed_pqcuark: \
 test_speed512_pqcuark \
 test_speed768_pqcuark \
 test_speed1024_pqcuark


$(OBJ_DIR)/common/%.o: $(COMMON)
	mkdir -p $(OBJ_DIR)/common 
	$(MAKE) -C $(COMMON_DIR) clean
	$(MAKE) -C $(COMMON_DIR)
	@for file in $(COMMON_DIR)/*.o; do \
		mv "$$file" "$(OBJ_DIR)/common/"; \
	done

	@for file in $(OBJ_DIR)/common/*.o; do \
		$(CC_OBJDUMP) -Dshx "$$file" > "$$file".dump; \
	done

$(OBJ_DIR)/utils/%.o: $(UTILS_DIR)/%.c
	mkdir -p $(OBJ_DIR)/utils 
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/kyber512/%.o: $(SRC_DIR)/%.c
	mkdir -p $(OBJ_DIR)/kyber512 
	$(CC) $(CFLAGS) -DKYBER_K=2 -c $< -o $@

$(OBJ_DIR)/kyber768/%.o: $(SRC_DIR)/%.c 
	mkdir -p $(OBJ_DIR)/kyber768 
	$(CC) $(CFLAGS) -DKYBER_K=3 -c $< -o $@

$(OBJ_DIR)/kyber1024/%.o: $(SRC_DIR)/%.c 
	mkdir -p $(OBJ_DIR)/kyber1024 
	$(CC) $(CFLAGS) -DKYBER_K=4 -c $< -o $@

$(OBJ_DIR)/kyber512/%.o: $(KECCAK_DIR)/%.c
	mkdir -p $(OBJ_DIR)/kyber512 
	$(CC) $(CFLAGS) -DKYBER_K=2 -c $< -o $@

$(OBJ_DIR)/kyber768/%.o: $(KECCAK_DIR)/%.c 
	mkdir -p $(OBJ_DIR)/kyber768 
	$(CC) $(CFLAGS) -DKYBER_K=3 -c $< -o $@

$(OBJ_DIR)/kyber1024/%.o: $(KECCAK_DIR)/%.c 
	mkdir -p $(OBJ_DIR)/kyber1024 
	$(CC) $(CFLAGS) -DKYBER_K=4 -c $< -o $@

$(OBJ_DIR)/kyber512/%.o: $(KECCAK_DIR)/%.S
	mkdir -p $(OBJ_DIR)/kyber512 
	$(CC) $(CFLAGS) -DKYBER_K=2 -c $< -o $@

$(OBJ_DIR)/kyber768/%.o: $(KECCAK_DIR)/%.S
	mkdir -p $(OBJ_DIR)/kyber768 
	$(CC) $(CFLAGS) -DKYBER_K=3 -c $< -o $@

$(OBJ_DIR)/kyber1024/%.o: $(KECCAK_DIR)/%.S
	mkdir -p $(OBJ_DIR)/kyber1024 
	$(CC) $(CFLAGS) -DKYBER_K=4 -c $< -o $@

$(OBJ_DIR)/kyber512/%.o: $(NTT_DIR)/%.c 
	mkdir -p $(OBJ_DIR)/kyber512 
	$(CC) $(CFLAGS) -DKYBER_K=2 -c $< -o $@

$(OBJ_DIR)/kyber768/%.o: $(NTT_DIR)/%.c
	mkdir -p $(OBJ_DIR)/kyber768 
	$(CC) $(CFLAGS) -DKYBER_K=3 -c $< -o $@

$(OBJ_DIR)/kyber1024/%.o: $(NTT_DIR)/%.c
	mkdir -p $(OBJ_DIR)/kyber1024 
	$(CC) $(CFLAGS) -DKYBER_K=4 -c $< -o $@

$(OBJ_DIR)/kyber512/%.o: $(NTT_DIR)/%.S 
	mkdir -p $(OBJ_DIR)/kyber512 
	$(CC) $(CFLAGS) -DKYBER_K=2 -c $< -o $@

$(OBJ_DIR)/kyber768/%.o: $(NTT_DIR)/%.S
	mkdir -p $(OBJ_DIR)/kyber768 
	$(CC) $(CFLAGS) -DKYBER_K=3 -c $< -o $@

$(OBJ_DIR)/kyber1024/%.o: $(NTT_DIR)/%.S
	mkdir -p $(OBJ_DIR)/kyber1024 
	$(CC) $(CFLAGS) -DKYBER_K=4 -c $< -o $@

$(OBJ_DIR)/kyber512/%.o: $(KECCAK_DIR)/%.S 
	mkdir -p $(OBJ_DIR)/kyber512 
	$(CC) $(CFLAGS) -DKYBER_K=2 -c $< -o $@

$(OBJ_DIR)/kyber768/%.o: $(KECCAK_DIR)/%.S
	mkdir -p $(OBJ_DIR)/kyber768 
	$(CC) $(CFLAGS) -DKYBER_K=3 -c $< -o $@

$(OBJ_DIR)/kyber1024/%.o: $(KECCAK_DIR)/%.S
	mkdir -p $(OBJ_DIR)/kyber1024 
	$(CC) $(CFLAGS) -DKYBER_K=4 -c $< -o $@


$(OBJ_DIR)/test_kyber512.o: $(TESTS_DIR)/test_kyber.c
	$(CC) $(CFLAGS) -DKYBER_K=2 -c $(TESTS_DIR)/test_kyber.c -o $@

$(OBJ_DIR)/test_kyber768.o: $(TESTS_DIR)/test_kyber.c
	$(CC) $(CFLAGS) -DKYBER_K=3 -c $(TESTS_DIR)/test_kyber.c -o $@

$(OBJ_DIR)/test_kyber1024.o: $(TESTS_DIR)/test_kyber.c
	$(CC) $(CFLAGS) -DKYBER_K=4 -c $(TESTS_DIR)/test_kyber.c -o $@

test_kyber512_nist: setup
	$(MAKE) out/$@  SRC_DIR=$(NIST_SRC_DIR) NTT_DIR=$(NIST_NTT_DIR) KECCAK_DIR=$(NIST_KECCAK_DIR) \
	SOURCESNTT=ntt.c \
	SOURCESKECCAK="fips202.c" \
	OPTIONS="-DNIST" \
	CONF=nist
test_kyber768_nist: setup
	$(MAKE) out/$@  SRC_DIR=$(NIST_SRC_DIR) NTT_DIR=$(NIST_NTT_DIR) KECCAK_DIR=$(NIST_KECCAK_DIR) \
	SOURCESNTT=ntt.c \
	SOURCESKECCAK="fips202.c" \
	OPTIONS="-DNIST" \
	CONF=nist
test_kyber1024_nist: setup
	$(MAKE) out/$@  SRC_DIR=$(NIST_SRC_DIR) NTT_DIR=$(NIST_NTT_DIR) KECCAK_DIR=$(NIST_KECCAK_DIR) \
	SOURCESNTT=ntt.c \
	SOURCESKECCAK="fips202.c" \
	OPTIONS="-DNIST" \
	CONF=nist

test_kyber512_pqrv_rv64im: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	SOURCESKECCAK="fips202_rv64.c fips202_rv64im.S" \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64im
test_kyber768_pqrv_rv64im: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	SOURCESKECCAK="fips202_rv64.c fips202_rv64im.S" \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64im
test_kyber1024_pqrv_rv64im: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	SOURCESKECCAK="fips202_rv64.c fips202_rv64im.S" \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64im

test_kyber512_pqrv_rv64imb: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64imb
test_kyber768_pqrv_rv64imb: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64imb
test_kyber1024_pqrv_rv64imb: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64imb


test_kyber512_pqcuark: setup
	$(MAKE) out/$@ SRC_DIR=$(PQCUARK_SRC_DIR) NTT_DIR=$(PQCUARK_NTT_DIR) KECCAK_DIR=$(PQCUARK_KECCAK_DIR) \
	SOURCES="reduce.c poly.c polyvec.c indcpa_pqcuark.c cbd.c verify.c kem.c symmetric-shake-pqcuark.c" \
	SOURCESKECCAK="fips202_pqcuark.c" \
	SOURCESNTT="ntt_pqcuark.c ntt_pqcuark.S" \
	CONF=pqcuark \
	OPTIONS="-DBASEMUL_ACC -DBFU -DKECCAK"

test_kyber768_pqcuark: setup
	$(MAKE) out/$@ SRC_DIR=$(PQCUARK_SRC_DIR) NTT_DIR=$(PQCUARK_NTT_DIR) KECCAK_DIR=$(PQCUARK_KECCAK_DIR) \
	SOURCES="reduce.c poly.c polyvec.c indcpa_pqcuark.c cbd.c verify.c kem.c symmetric-shake-pqcuark.c" \
	SOURCESKECCAK="fips202_pqcuark.c" \
	SOURCESNTT="ntt_pqcuark.c ntt_pqcuark.S" \
	CONF=pqcuark \
	OPTIONS="-DBASEMUL_ACC -DBFU -DKECCAK"

test_kyber1024_pqcuark: setup
	$(MAKE) out/$@ SRC_DIR=$(PQCUARK_SRC_DIR) NTT_DIR=$(PQCUARK_NTT_DIR) KECCAK_DIR=$(PQCUARK_KECCAK_DIR) \
	SOURCES="reduce.c poly.c polyvec.c indcpa_pqcuark.c cbd.c verify.c kem.c symmetric-shake-pqcuark.c" \
	SOURCESKECCAK="fips202_pqcuark.c" \
	SOURCESNTT="ntt_pqcuark.c ntt_pqcuark.S" \
	CONF=pqcuark \
	OPTIONS="-DBASEMUL_ACC -DBFU -DKECCAK"

out/test_kyber512_$(CONF): setup $(OBJECTS_512) $(OBJ_DIR)/test_kyber512.o
	$(CC) $(CFLAGS) $(LD_FLAGS) $(OBJECTS_512) $(OBJ_DIR)/test_kyber512.o -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber768_$(CONF): setup $(OBJECTS_768) $(OBJ_DIR)/test_kyber768.o
	$(CC) $(CFLAGS) $(LD_FLAGS) $(OBJECTS_768) $(OBJ_DIR)/test_kyber768.o -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_kyber1024_$(CONF): setup $(OBJECTS_1024) $(OBJ_DIR)/test_kyber1024.o
	$(CC) $(CFLAGS) $(LD_FLAGS) $(OBJECTS_1024) $(OBJ_DIR)/test_kyber1024.o -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

test_speed512_nist: setup
	$(MAKE) out/$@  SRC_DIR=$(NIST_SRC_DIR) NTT_DIR=$(NIST_NTT_DIR) KECCAK_DIR=$(NIST_KECCAK_DIR) \
	SOURCESNTT=ntt.c \
	SOURCESKECCAK="fips202.c" \
	OPTIONS="-DNIST" \
	CONF=nist
test_speed768_nist: setup
	$(MAKE) out/$@  SRC_DIR=$(NIST_SRC_DIR) NTT_DIR=$(NIST_NTT_DIR) KECCAK_DIR=$(NIST_KECCAK_DIR) \
	SOURCESNTT=ntt.c \
	SOURCESKECCAK="fips202.c" \
	OPTIONS="-DNIST" \
	CONF=nist
test_speed1024_nist: setup
	$(MAKE) out/$@  SRC_DIR=$(NIST_SRC_DIR) NTT_DIR=$(NIST_NTT_DIR) KECCAK_DIR=$(NIST_KECCAK_DIR) \
	SOURCESNTT=ntt.c \
	SOURCESKECCAK="fips202.c" \
	OPTIONS="-DNIST" \
	CONF=nist

test_speed512_pqrv_rv64im: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	SOURCESKECCAK="fips202_rv64.c fips202_rv64im.S" \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64im
test_speed768_pqrv_rv64im: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	SOURCESKECCAK="fips202_rv64.c fips202_rv64im.S" \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64im
test_speed1024_pqrv_rv64im: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	SOURCESKECCAK="fips202_rv64.c fips202_rv64im.S" \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64im

test_speed512_pqrv_rv64imb: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64imb
test_speed768_pqrv_rv64imb: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64imb
test_speed1024_pqrv_rv64imb: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64imb

test_speed512_pqcuark: setup
	$(MAKE) out/$@ SRC_DIR=$(PQCUARK_SRC_DIR) NTT_DIR=$(PQCUARK_NTT_DIR) KECCAK_DIR=$(PQCUARK_KECCAK_DIR) \
	SOURCES="reduce.c poly.c polyvec.c indcpa_pqcuark.c cbd.c verify.c kem.c symmetric-shake-pqcuark.c" \
	SOURCESKECCAK="fips202_pqcuark.c" \
	SOURCESNTT="ntt_pqcuark.c ntt_pqcuark.S" \
	CONF=pqcuark \
	OPTIONS="-DBASEMUL_ACC -DPQCUARK"

test_speed768_pqcuark: setup
	$(MAKE) out/$@ SRC_DIR=$(PQCUARK_SRC_DIR) NTT_DIR=$(PQCUARK_NTT_DIR) KECCAK_DIR=$(PQCUARK_KECCAK_DIR) \
	SOURCES="reduce.c poly.c polyvec.c indcpa_pqcuark.c cbd.c verify.c kem.c symmetric-shake-pqcuark.c" \
	SOURCESKECCAK="fips202_pqcuark.c" \
	SOURCESNTT="ntt_pqcuark.c ntt_pqcuark.S" \
	CONF=pqcuark \
	OPTIONS="-DBASEMUL_ACC -DPQCUARK"

test_speed1024_pqcuark: setup
	$(MAKE) out/$@ SRC_DIR=$(PQCUARK_SRC_DIR) NTT_DIR=$(PQCUARK_NTT_DIR) KECCAK_DIR=$(PQCUARK_KECCAK_DIR) \
	SOURCES="reduce.c poly.c polyvec.c indcpa_pqcuark.c cbd.c verify.c kem.c symmetric-shake-pqcuark.c" \
	SOURCESKECCAK="fips202_pqcuark.c" \
	SOURCESNTT="ntt_pqcuark.c ntt_pqcuark.S" \
	CONF=pqcuark \
	OPTIONS="-DBASEMUL_ACC -DPQCUARK"

$(OBJ_DIR)/test_speed512.o: $(TESTS_DIR)/test_speed.c
	$(CC) $(CFLAGS) -DKYBER_K=2 -c $(TESTS_DIR)/test_speed.c -o $@

$(OBJ_DIR)/test_speed768.o: $(TESTS_DIR)/test_speed.c
	$(CC) $(CFLAGS) -DKYBER_K=3 -c $(TESTS_DIR)/test_speed.c -o $@

$(OBJ_DIR)/test_speed1024.o: $(TESTS_DIR)/test_speed.c
	$(CC) $(CFLAGS) -DKYBER_K=4 -c $(TESTS_DIR)/test_speed.c -o $@

out/test_speed512_$(CONF): setup $(OBJECTS_512) $(OBJ_DIR)/test_speed512.o
	$(CC) $(CFLAGS) $(LD_FLAGS) $(OBJECTS_512) $(OBJ_DIR)/test_speed512.o -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed768_$(CONF): setup $(OBJECTS_768) $(OBJ_DIR)/test_speed768.o
	$(CC) $(CFLAGS) $(LD_FLAGS) $(OBJECTS_768) $(OBJ_DIR)/test_speed768.o -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed1024_$(CONF): setup $(OBJECTS_1024) $(OBJ_DIR)/test_speed1024.o
	$(CC) $(CFLAGS) $(LD_FLAGS) $(OBJECTS_1024) $(OBJ_DIR)/test_speed1024.o -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

ifdef FPGA
bin: 
		$(CC_OBJDUMP) -d $(TEST) > $(TEST).dump
		$(CC_OBJCOPY) -O binary $(TEST) $(TEST).bin
		@echo "BIN Generated"
#$(SCP) $(TEST).bin $(TARGET_USER)@$(TARGET_IP):$(TARGET_DIR)/
else 
bin: 
		$(CC_OBJDUMP) -d $(TEST) > $(TEST).dump
		@echo "ELF Generated"
endif

setup:
	@rm -rf obj
	@mkdir -p out

clean:
	-$(RM) -rf out 
	-$(RM) -rf *.gcno *.gcda *.lcov *.o *.so *.dump


