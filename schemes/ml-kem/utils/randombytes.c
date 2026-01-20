#include <stdint.h>
#include <stdio.h>
#include "randombytes.h"

// Implementing a simple PRNG (LCG)
void randombytes(uint8_t *out, size_t outlen) {
    unsigned long a = 1664525;     // Multiplier
    unsigned long c = 1013904223;  // Increment
    unsigned long m = 4294967296;  // Modulus (2^32)

    for (size_t i = 0; i < outlen; i++) {
        next = (a * next + c) % m;
        out[i] = (uint8_t)(next % 256);
    }
}

void seed_randombytes(uint8_t *output, int length, unsigned int seed) {
    unsigned long a = 1664525;  // Multiplier used in the LCG
    unsigned long c = 1013904223; // Increment used in the LCG
    unsigned long m = 4294967296; // Modulus used in the LCG (2^32)
    unsigned long x = seed;  // Current state

    for (int i = 0; i < length; i++) {
        x = (a * x + c) % m;
        output[i] = (uint8_t)(x % 256);  // Reduce to byte and store in output
    }

}