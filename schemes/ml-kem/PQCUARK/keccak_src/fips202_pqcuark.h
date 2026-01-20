#ifndef FIPS202_H
#define FIPS202_H

#include <stddef.h>
#include <stdint.h>

#define SHAKE128_RATE 168
#define SHAKE256_RATE 136
#define SHA3_256_RATE 136
#define SHA3_512_RATE 72

void shake128_init();
void shake128_squeeze(uint8_t *out, size_t outlen);
void shake128_absorb(unsigned int *pos, const uint8_t *in, size_t inlen);
void shake128_absorb_once(const uint8_t *in, size_t inlen);
void shake128_squeezeblocks(uint8_t *out, size_t nblocks);

void shake256_init();
void shake256_squeeze(uint8_t *out, size_t outlen);
void shake256_absorb(unsigned int *pos, const uint8_t *in, size_t inlen);
void shake256_absorb_once(const uint8_t *in, size_t inlen);
void shake256_squeezeblocks(uint8_t *out, size_t nblocks);

void shake128(uint8_t *out, size_t outlen, const uint8_t *in, size_t inlen);
void shake256(uint8_t *out, size_t outlen, const uint8_t *in, size_t inlen);
void sha3_256(uint8_t h[32], const uint8_t *in, size_t inlen);
void sha3_512(uint8_t h[64], const uint8_t *in, size_t inlen);

void KeccakF1600_StatePermute();

#endif
