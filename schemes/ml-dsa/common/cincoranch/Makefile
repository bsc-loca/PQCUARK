###############################################################################
# Compiler & Flags
###############################################################################
ifndef EPI_TOOLCHAIN_REL
$(error Please set environment variable for EPI toolchain compiler)
endif
CC=$(EPI_TOOLCHAIN_REL)/bin/clang

# Flags
MARCH=-march=rv64g -mcmodel=medany

CC_FLAGS=-std=gnu99 -Wall $(MARCH)
CC_FLAGS+=-Wno-implicit-function-declaration -static -fno-builtin-printf -fno-builtin -ffreestanding -mabi=lp64

###############################################################################
# Compile rules
###############################################################################
all: sys sys_fpga uart crt crt_fpga

crt: crt.S 
	$(CC) $(CC_FLAGS) $(MARCH) -O2 -c crt.S -o crt.o

sys: syscalls.c encoding.h util.h
	$(CC) $(CC_FLAGS) $(MARCH) -O2 -S syscalls.c
	$(CC) $(CC_FLAGS) $(MARCH) -O2 -c syscalls.c -o syscalls.o
	
uart: uart.c encoding.h util.h
	$(CC) $(CC_FLAGS) $(MARCH) -O2 -S uart.c
	$(CC) $(CC_FLAGS) $(MARCH) -O0 -c uart.c -o uart.o

clean:
	rm -rf *.o *.s

.PHONY: sys sys_fpga uart clean crt crt_fpga