// See LICENSE for license details.

#ifndef DEVICE_MAP_H
#define DEVICE_MAP_H

// Boot on-chip BRAM
#define BRAM_BASE 0x00000000u

// DDR RAM (maximal 1GB)
#define DDR_RAM_BASE 0x80000000u
// Hyperram base
#define HYPERRAM_BASE 0xC0000000u
// SDRAM base
#define SDRAM_BASE 0xE0000000u

// IO Space
#define IO_SPACE_BASE 0x40000000u

// Periferials Bases
#define UART_SPACE_BASE     0x40000000u
#define SPI_SPACE_BASE      0x40010000u
#define VGA_SPACE_BASE      0x40160000u
#define TIMER_SPACE_BASE    0x40170000u

// get r[p]
#define GetBit(r, p) (((r) & (1 <<p)) >> p)

#endif
