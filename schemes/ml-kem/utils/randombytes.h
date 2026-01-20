#ifndef RANDOMBYTES_H
#define RANDOMBYTES_H

#include <stdint.h>
#include <stdio.h>

static unsigned long int next = 1;  // The seed, static to preserve state across calls

void randombytes(uint8_t *out, size_t outlen);
void seed_randombytes(uint8_t *output, int length, unsigned int seed);

#endif
