// Copyright 2026 Barcelona Supercomputing Center (BSC)
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License");
// you may not use this file except in compliance with the License, or,
// at your option, the Apache License version 2.0.
// You may obtain a copy of the License at
//
//     https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef SYMMETRIC_H
#define SYMMETRIC_H

#include <stddef.h>
#include <stdint.h>


#include "params.h"

#define XOF_BLOCKBYTES SHAKE128_RATE

#define hash_h(OUT, IN, INBYTES) sha3_256(OUT, IN, INBYTES)
#define hash_g(OUT, IN, INBYTES) sha3_512(OUT, IN, INBYTES)
#define prf(OUT, OUTBYTES, KEY, NONCE) \
    kyber_shake256_prf(OUT, OUTBYTES, KEY, NONCE)
#define kdf(OUT, IN, INBYTES) shake256(OUT, KYBER_SSBYTES, IN, INBYTES)

void kyber_shake256_prf(uint8_t *out, size_t outlen,
                            const uint8_t key[KYBER_SYMBYTES], uint8_t nonce);

#if defined(KECCAK) || defined(PQCUARK)
    #include "fips202_pqcuark.h"
    void kyber_shake128_absorb(const uint8_t seed[KYBER_SYMBYTES],
                            uint8_t x, uint8_t y);

    #define xof_absorb(SEED, X, Y) kyber_shake128_absorb(SEED, X, Y)
    #define xof_squeezeblocks(OUT, OUTBLOCKS) \
        shake128_squeezeblocks(OUT, OUTBLOCKS)

#else
    #include "fips202.h"
    typedef keccak_state xof_state;

    void kyber_shake128_absorb(keccak_state *s, const uint8_t seed[KYBER_SYMBYTES],
                            uint8_t x, uint8_t y);

    #define xof_absorb(STATE, SEED, X, Y) kyber_shake128_absorb(STATE, SEED, X, Y)
    #define xof_squeezeblocks(OUT, OUTBLOCKS, STATE) \
        shake128_squeezeblocks(OUT, OUTBLOCKS, STATE)
   
#endif

#endif /* SYMMETRIC_H */