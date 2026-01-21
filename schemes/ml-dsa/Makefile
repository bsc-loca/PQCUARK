###############################################################################
# Compiler Environment 
###############################################################################
ARCH=$(shell uname -m)
GCC = $(GCC_PQCUARK)

# SCP = scp
# TARGET_IP 	=
# TARGET_USER =
# TARGET_DIR  =

RM = /bin/rm

TEST ?=
 
CURRENT_DIR = $(shell pwd)
ifndef GCC 
$(error Please set environment variable for CC toolchain compiler)
endif

CC=$(GCC)/bin/riscv64-unknown-elf-gcc
CC_OBJDUMP=$(GCC)/bin/riscv64-unknown-elf-objdump
CC_OBJCOPY=$(GCC)/bin/riscv64-unknown-elf-objcopy


COMMON_DIR = $(CURRENT_DIR)/common/sargantana_standalone
UTILS_DIR = $(CURRENT_DIR)/utils
OBJ_DIR = $(CURRENT_DIR)/out/obj
BIN_DIR = $(CURRENT_DIR)/out/bin
TESTS_DIR = $(CURRENT_DIR)/tests

SRC_DIR ?=
NTT_DIR ?= 
KECCAK_DIR ?= 

NIST_SRC_DIR = $(CURRENT_DIR)/NIST
PQRV_SRC_DIR = $(CURRENT_DIR)/PQRV/Dilithium/RV64
PQCUARK_SRC_DIR = $(CURRENT_DIR)/PQCUARK/src
NIST_NTT_DIR = $(NIST_SRC_DIR)
PQRV_NTT_DIR = $(CURRENT_DIR)/PQRV/ntt/dilithium
PQCUARK_NTT_DIR = $(CURRENT_DIR)/PQCUARK/ntt_src
NIST_KECCAK_DIR = $(NIST_SRC_DIR)
PQRV_KECCAK_DIR = $(CURRENT_DIR)/PQRV/sha3
PQCUARK_KECCAK_DIR = $(CURRENT_DIR)/PQCUARK/keccak_src


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
SOURCES ?= reduce.c poly.c polyvec.c sign.c packing.c rounding.c symmetric-shake.c
SOURCESKECCAK ?= fips202_rv64.c fips202_rv64imb.S
SOURCESNTT ?= ntt.c ntt_8l_dualissue_plant_rv64im.S
HEADERS := params.h sign.h polyvec.h poly.h reduce.h randombytes.h symmetric.h sdv_env.h
HEADERSKECCAK := fips202.h
HEADERSNTT ?= ntt.h ntt_rv64im.h
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

OBJECTSKECCAK_2  := $(SOURCESKECCAK:$(KECCAK_DIR)/%.c=$(OBJ_DIR)/dilithium2/%.o)
OBJECTSKECCAK_3  := $(SOURCESKECCAK:$(KECCAK_DIR)/%.c=$(OBJ_DIR)/dilithium3/%.o)
OBJECTSKECCAK_5 := $(SOURCESKECCAK:$(KECCAK_DIR)/%.c=$(OBJ_DIR)/dilithium5/%.o)
OBJECTSNTT_2  := $(SOURCESNTT:$(NTT_DIR)/%.c=$(OBJ_DIR)/dilithium2/%.o)
OBJECTSNTT_3  := $(SOURCESNTT:$(NTT_DIR)/%.c=$(OBJ_DIR)/dilithium3/%.o)
OBJECTSNTT_5 := $(SOURCESNTT:$(NTT_DIR)/%.c=$(OBJ_DIR)/dilithium5/%.o)
OBJECTSCOMMON := $(patsubst $(COMMON_DIR)/%.c,$(OBJ_DIR)/common/%.o,$(filter %.c,$(COMMON)))
OBJECTSCOMMON += $(patsubst $(COMMON_DIR)/%.S,$(OBJ_DIR)/common/%.o,$(filter %.S,$(COMMON)))
OBJECTSUTILS  := $(UTILS:$(UTILS_DIR)/%.c=$(OBJ_DIR)/utils/%.o)

OBJECTS_2  := $(SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/dilithium2/%.o) $(OBJECTSKECCAK_2) $(OBJECTSNTT_2) $(OBJECTSUTILS) $(OBJECTSCOMMON)
OBJECTS_3  := $(SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/dilithium3/%.o) $(OBJECTSKECCAK_3) $(OBJECTSNTT_3) $(OBJECTSUTILS) $(OBJECTSCOMMON)
OBJECTS_5 := $(SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/dilithium5/%.o) $(OBJECTSKECCAK_5) $(OBJECTSNTT_5) $(OBJECTSUTILS) $(OBJECTSCOMMON)
  
.PHONY: all speed shared clean

all: dilithium speed

dilithium: dilithium_nist dilithium_pqrv_rv64im dilithium_pqrv_rv64imb \
	dilithium_ntt dilithium_keccak dilithium_pqcuark

speed: speed_nist speed_pqrv_rv64im speed_pqrv_rv64imb \
	speed_ntt speed_keccak speed_pqcuark

dilithium_nist: \
 test_dilithium2_nist \
 test_dilithium3_nist \
 test_dilithium5_nist 

dilithium_pqrv_rv64im: \
 test_dilithium2_pqrv_rv64im \
 test_dilithium3_pqrv_rv64im \
 test_dilithium5_pqrv_rv64im

dilithium_pqrv_rv64imb: \
 test_dilithium2_pqrv_rv64imb \
 test_dilithium3_pqrv_rv64imb \
 test_dilithium5_pqrv_rv64imb

dilithium_pqcuark: \
 test_dilithium2_pqcuark \
 test_dilithium3_pqcuark \
 test_dilithium5_pqcuark  

speed_nist: \
 test_speed2_nist \
 test_speed3_nist \
 test_speed5_nist
speed_pqrv_rv64im: \
 test_speed2_pqrv_rv64im \
 test_speed3_pqrv_rv64im \
 test_speed5_pqrv_rv64im
speed_pqrv_rv64imb: \
 test_speed2_pqrv_rv64imb \
 test_speed3_pqrv_rv64imb \
 test_speed5_pqrv_rv64imb

speed_ntt: \
 test_speed2_ntt \
 test_speed3_ntt \
 test_speed5_ntt
speed_keccak: \
 test_speed2_keccak \
 test_speed3_keccak \
 test_speed5_keccak
speed_pqcuark: \
 test_speed2_pqcuark \
 test_speed3_pqcuark \
 test_speed5_pqcuark


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

$(OBJ_DIR)/dilithium2/%.o: $(SRC_DIR)/%.c
	mkdir -p $(OBJ_DIR)/dilithium2 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=2 -c $< -o $@

$(OBJ_DIR)/dilithium3/%.o: $(SRC_DIR)/%.c 
	mkdir -p $(OBJ_DIR)/dilithium3 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=3 -c $< -o $@

$(OBJ_DIR)/dilithium5/%.o: $(SRC_DIR)/%.c 
	mkdir -p $(OBJ_DIR)/dilithium5 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=5 -c $< -o $@

$(OBJ_DIR)/dilithium2/%.o: $(KECCAK_DIR)/%.c 
	mkdir -p $(OBJ_DIR)/dilithium2 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=2 -c $< -o $@

$(OBJ_DIR)/dilithium3/%.o: $(KECCAK_DIR)/%.c
	mkdir -p $(OBJ_DIR)/dilithium3 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=3 -c $< -o $@

$(OBJ_DIR)/dilithium5/%.o: $(KECCAK_DIR)/%.c
	mkdir -p $(OBJ_DIR)/dilithium5 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=5 -c $< -o $@

$(OBJ_DIR)/dilithium2/%.o: $(KECCAK_DIR)/%.S 
	mkdir -p $(OBJ_DIR)/dilithium2 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=2 -c $< -o $@

$(OBJ_DIR)/dilithium3/%.o: $(KECCAK_DIR)/%.S
	mkdir -p $(OBJ_DIR)/dilithium3 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=3 -c $< -o $@

$(OBJ_DIR)/dilithium5/%.o: $(KECCAK_DIR)/%.S
	mkdir -p $(OBJ_DIR)/dilithium5 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=5 -c $< -o $@

$(OBJ_DIR)/dilithium2/%.o: $(NTT_DIR)/%.c 
	mkdir -p $(OBJ_DIR)/dilithium2 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=2 -c $< -o $@

$(OBJ_DIR)/dilithium3/%.o: $(NTT_DIR)/%.c
	mkdir -p $(OBJ_DIR)/dilithium3 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=3 -c $< -o $@

$(OBJ_DIR)/dilithium5/%.o: $(NTT_DIR)/%.c
	mkdir -p $(OBJ_DIR)/dilithium5 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=5 -c $< -o $@

$(OBJ_DIR)/dilithium2/%.o: $(NTT_DIR)/%.S 
	mkdir -p $(OBJ_DIR)/dilithium2 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=2 -c $< -o $@

$(OBJ_DIR)/dilithium3/%.o: $(NTT_DIR)/%.S
	mkdir -p $(OBJ_DIR)/dilithium3 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=3 -c $< -o $@

$(OBJ_DIR)/dilithium5/%.o: $(NTT_DIR)/%.S
	mkdir -p $(OBJ_DIR)/dilithium5 
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=5 -c $< -o $@


$(OBJ_DIR)/test_dilithium2.o: $(TESTS_DIR)/test_dilithium.c
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=2 -c $(TESTS_DIR)/test_dilithium.c -o $@

$(OBJ_DIR)/test_dilithium3.o: $(TESTS_DIR)/test_dilithium.c
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=3 -c $(TESTS_DIR)/test_dilithium.c -o $@

$(OBJ_DIR)/test_dilithium5.o: $(TESTS_DIR)/test_dilithium.c
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=5 -c $(TESTS_DIR)/test_dilithium.c -o $@

test_dilithium2_nist: setup
	$(MAKE) out/$@  SRC_DIR=$(NIST_SRC_DIR) NTT_DIR=$(NIST_NTT_DIR) KECCAK_DIR=$(NIST_KECCAK_DIR) \
	SOURCES="reduce.c poly.c polyvec.c sign.c packing.c rounding.c symmetric-shake.c" \
	HEADERS="params.h sign.h polyvec.h poly.h reduce.h randombytes.h symmetric.h" \
	SOURCESNTT=ntt.c \
	SOURCESKECCAK="fips202.c" \
	OPTIONS="-DNIST" \
	CONF=nist
test_dilithium3_nist: setup
	$(MAKE) out/$@  SRC_DIR=$(NIST_SRC_DIR) NTT_DIR=$(NIST_NTT_DIR) KECCAK_DIR=$(NIST_KECCAK_DIR) \
	SOURCES="reduce.c poly.c polyvec.c sign.c packing.c rounding.c symmetric-shake.c" \
	HEADERS="params.h sign.h polyvec.h poly.h reduce.h randombytes.h symmetric.h" \
	SOURCESNTT=ntt.c \
	SOURCESKECCAK="fips202.c" \
	OPTIONS="-DNIST" \
	CONF=nist
test_dilithium5_nist: setup
	$(MAKE) out/$@  SRC_DIR=$(NIST_SRC_DIR) NTT_DIR=$(NIST_NTT_DIR) KECCAK_DIR=$(NIST_KECCAK_DIR) \
	SOURCES="reduce.c poly.c polyvec.c sign.c packing.c rounding.c symmetric-shake.c" \
	HEADERS="params.h sign.h polyvec.h poly.h reduce.h randombytes.h symmetric.h" \
	SOURCESNTT=ntt.c \
	SOURCESKECCAK="fips202.c" \
	OPTIONS="-DNIST" \
	CONF=nist

test_dilithium2_pqrv_rv64im: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	SOURCESKECCAK="fips202_rv64.c fips202_rv64im.S" \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64im
test_dilithium3_pqrv_rv64im: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	SOURCESKECCAK="fips202_rv64.c fips202_rv64im.S" \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64im
test_dilithium5_pqrv_rv64im: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	SOURCESKECCAK="fips202_rv64.c fips202_rv64im.S" \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64im

test_dilithium2_pqrv_rv64imb: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64imb
test_dilithium3_pqrv_rv64imb: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64imb
test_dilithium5_pqrv_rv64imb: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64imb

test_dilithium2_pqcuark: setup
	$(MAKE) out/$@ SRC_DIR=$(PQCUARK_SRC_DIR) NTT_DIR=$(PQCUARK_NTT_DIR) KECCAK_DIR=$(PQCUARK_KECCAK_DIR) \
	SOURCES="reduce.c poly_pqcuark.c polyvec.c sign_pqcuark.c packing.c rounding.c " \
	SOURCESKECCAK="fips202_pqcuark.c" \
	SOURCESNTT="ntt_pqcuark.c ntt_pqcuark.S" \
	CONF=pqcuark \
	OPTIONS="-DBASEMUL_ACC -DBFU -DKECCAK"

test_dilithium3_pqcuark: setup
	$(MAKE) out/$@ SRC_DIR=$(PQCUARK_SRC_DIR) NTT_DIR=$(PQCUARK_NTT_DIR) KECCAK_DIR=$(PQCUARK_KECCAK_DIR) \
	SOURCES="reduce.c poly_pqcuark.c polyvec.c sign_pqcuark.c packing.c rounding.c " \
	SOURCESKECCAK="fips202_pqcuark.c" \
	SOURCESNTT="ntt_pqcuark.c ntt_pqcuark.S" \
	CONF=pqcuark \
	OPTIONS="-DBASEMUL_ACC -DBFU -DKECCAK"

test_dilithium5_pqcuark: setup
	$(MAKE) out/$@ SRC_DIR=$(PQCUARK_SRC_DIR) NTT_DIR=$(PQCUARK_NTT_DIR) KECCAK_DIR=$(PQCUARK_KECCAK_DIR) \
	SOURCES="reduce.c poly_pqcuark.c polyvec.c sign_pqcuark.c packing.c rounding.c " \
	SOURCESKECCAK="fips202_pqcuark.c" \
	SOURCESNTT="ntt_pqcuark.c ntt_pqcuark.S" \
	CONF=pqcuark \
	OPTIONS="-DBASEMUL_ACC -DBFU -DKECCAK"

out/test_dilithium2_$(CONF): setup $(OBJECTS_2) $(OBJ_DIR)/test_dilithium2.o
	$(CC) $(CFLAGS) $(LD_FLAGS) $(OBJECTS_2) $(OBJ_DIR)/test_dilithium2.o -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_dilithium3_$(CONF): setup $(OBJECTS_3) $(OBJ_DIR)/test_dilithium3.o
	$(CC) $(CFLAGS) $(LD_FLAGS) $(OBJECTS_3) $(OBJ_DIR)/test_dilithium3.o -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_dilithium5_$(CONF): setup $(OBJECTS_5) $(OBJ_DIR)/test_dilithium5.o
	$(CC) $(CFLAGS) $(LD_FLAGS) $(OBJECTS_5) $(OBJ_DIR)/test_dilithium5.o -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@


test_speed2_nist: setup
	$(MAKE) out/$@  SRC_DIR=$(NIST_SRC_DIR) NTT_DIR=$(NIST_NTT_DIR) KECCAK_DIR=$(NIST_KECCAK_DIR) \
	SOURCES="reduce.c poly.c polyvec.c sign.c packing.c rounding.c symmetric-shake.c" \
	HEADERS="params.h sign.h polyvec.h poly.h reduce.h randombytes.h symmetric.h" \
	SOURCESNTT=ntt.c \
	SOURCESKECCAK="fips202.c" \
	OPTIONS="-DNIST" \
	CONF=nist
test_speed3_nist: setup
	$(MAKE) out/$@  SRC_DIR=$(NIST_SRC_DIR) NTT_DIR=$(NIST_NTT_DIR) KECCAK_DIR=$(NIST_KECCAK_DIR) \
	SOURCES="reduce.c poly.c polyvec.c sign.c packing.c rounding.c symmetric-shake.c" \
	HEADERS="params.h sign.h polyvec.h poly.h reduce.h randombytes.h symmetric.h" \
	SOURCESNTT=ntt.c \
	SOURCESKECCAK="fips202.c" \
	OPTIONS="-DNIST" \
	CONF=nist
test_speed5_nist: setup
	$(MAKE) out/$@  SRC_DIR=$(NIST_SRC_DIR) NTT_DIR=$(NIST_NTT_DIR) KECCAK_DIR=$(NIST_KECCAK_DIR) \
	SOURCES="reduce.c poly.c polyvec.c sign.c packing.c rounding.c symmetric-shake.c" \
	HEADERS="params.h sign.h polyvec.h poly.h reduce.h randombytes.h symmetric.h" \
	SOURCESNTT=ntt.c \
	SOURCESKECCAK="fips202.c" \
	OPTIONS="-DNIST" \
	CONF=nist

test_speed2_pqrv_rv64im: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	SOURCESKECCAK="fips202_rv64.c fips202_rv64im.S" \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64im
test_speed3_pqrv_rv64im: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	SOURCESKECCAK="fips202_rv64.c fips202_rv64im.S" \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64im
test_speed5_pqrv_rv64im: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	SOURCESKECCAK="fips202_rv64.c fips202_rv64im.S" \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64im

test_speed2_pqrv_rv64imb: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64imb
test_speed3_pqrv_rv64imb: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64imb
test_speed5_pqrv_rv64imb: setup
	$(MAKE) out/$@ SRC_DIR=$(PQRV_SRC_DIR) NTT_DIR=$(PQRV_NTT_DIR) KECCAK_DIR=$(PQRV_KECCAK_DIR) \
	OPTIONS="-DRV64" \
	CONF=pqrv_rv64imb

test_speed2_pqcuark: setup
	$(MAKE) out/$@ SRC_DIR=$(PQCUARK_SRC_DIR) NTT_DIR=$(PQCUARK_NTT_DIR) KECCAK_DIR=$(PQCUARK_KECCAK_DIR) \
	SOURCES="reduce.c poly_pqcuark.c polyvec.c sign_pqcuark.c packing.c rounding.c " \
	SOURCESKECCAK="fips202_pqcuark.c" \
	SOURCESNTT="ntt_pqcuark.c ntt_pqcuark.S" \
	CONF=pqcuark \
	OPTIONS="-DBASEMUL_ACC -DPQCUARK"

test_speed3_pqcuark: setup
	$(MAKE) out/$@ SRC_DIR=$(PQCUARK_SRC_DIR) NTT_DIR=$(PQCUARK_NTT_DIR) KECCAK_DIR=$(PQCUARK_KECCAK_DIR) \
	SOURCES="reduce.c poly_pqcuark.c polyvec.c sign_pqcuark.c packing.c rounding.c " \
	SOURCESKECCAK="fips202_pqcuark.c" \
	SOURCESNTT="ntt_pqcuark.c ntt_pqcuark.S" \
	CONF=pqcuark \
	OPTIONS="-DBASEMUL_ACC -DPQCUARK"

test_speed5_pqcuark: setup
	$(MAKE) out/$@ SRC_DIR=$(PQCUARK_SRC_DIR) NTT_DIR=$(PQCUARK_NTT_DIR) KECCAK_DIR=$(PQCUARK_KECCAK_DIR) \
	SOURCES="reduce.c poly_pqcuark.c polyvec.c sign_pqcuark.c packing.c rounding.c " \
	SOURCESKECCAK="fips202_pqcuark.c" \
	SOURCESNTT="ntt_pqcuark.c ntt_pqcuark.S" \
	CONF=pqcuark \
	OPTIONS="-DBASEMUL_ACC -DPQCUARK"


$(OBJ_DIR)/test_speed2.o: $(TESTS_DIR)/test_speed_dilithium.c
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=2 -c $(TESTS_DIR)/test_speed_dilithium.c -o $@

$(OBJ_DIR)/test_speed3.o: $(TESTS_DIR)/test_speed_dilithium.c
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=3 -c $(TESTS_DIR)/test_speed_dilithium.c -o $@

$(OBJ_DIR)/test_speed5.o: $(TESTS_DIR)/test_speed_dilithium.c
	$(CC) $(CFLAGS) -DDILITHIUM_MODE=5 -c $(TESTS_DIR)/test_speed_dilithium.c -o $@

out/test_speed2_$(CONF): setup $(OBJECTS_2) $(OBJ_DIR)/test_speed2.o
	$(CC) $(CFLAGS) $(LD_FLAGS) $(OBJECTS_2) $(OBJ_DIR)/test_speed2.o -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed3_$(CONF): setup $(OBJECTS_3) $(OBJ_DIR)/test_speed3.o
	$(CC) $(CFLAGS) $(LD_FLAGS) $(OBJECTS_3) $(OBJ_DIR)/test_speed3.o -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

out/test_speed5_$(CONF): setup $(OBJECTS_5) $(OBJ_DIR)/test_speed5.o
	$(CC) $(CFLAGS) $(LD_FLAGS) $(OBJECTS_5) $(OBJ_DIR)/test_speed5.o -o $@ $(SDV_LINK)
	$(MAKE) bin TEST=$@

ifdef FPGA
bin: 
		$(CC_OBJDUMP) -d $(TEST) > $(TEST).dump
		$(CC_OBJCOPY) -O binary $(TEST) $(TEST).bin
		@echo "BIN Generated"
# 		$(SCP) $(TEST).bin $(TARGET_USER)@$(TARGET_IP):$(TARGET_DIR)/
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
