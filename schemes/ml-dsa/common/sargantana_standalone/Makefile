###############################################################################
# Compiler & Flags
###############################################################################
CC=$(GCC_PQCUARK)/bin/riscv64-unknown-elf-gcc

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

crt_fpga: crt_fpga.S 
	$(CC) $(CC_FLAGS) $(MARCH) -O2 -c crt_fpga.S -o crt_fpga.o

sys: syscalls.c encoding.h util.h
	$(CC) $(CC_FLAGS) $(MARCH) -O0 -S syscalls.c
	$(CC) $(CC_FLAGS) $(MARCH) -O0 -c syscalls.c -o syscalls.o
	
sys_fpga: syscalls_fpga.c encoding.h util.h
	$(CC) $(CC_FLAGS) $(MARCH) -O2 -S syscalls_fpga.c
	$(CC) $(CC_FLAGS) $(MARCH) -O0 -c syscalls_fpga.c -o syscalls_fpga.o

uart: uart.c encoding.h util.h
	$(CC) $(CC_FLAGS) $(MARCH) -O2 -S uart.c
	$(CC) $(CC_FLAGS) $(MARCH) -O0 -c uart.c -o uart.o

clean:
	rm -rf *.o *.s

.PHONY: sys sys_fpga uart clean crt crt_fpga