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

#ifndef PACKING_H
#define PACKING_H

#include <stdint.h>

#include "params.h"
#include "polyvec.h"

void pack_pk(uint8_t pk[CRYPTO_PUBLICKEYBYTES], const uint8_t rho[SEEDBYTES],
             const polyveck *t1);
void pack_sk(uint8_t sk[CRYPTO_SECRETKEYBYTES], const uint8_t rho[SEEDBYTES],
             const uint8_t tr[SEEDBYTES], const uint8_t key[SEEDBYTES],
             const polyveck *t0, const polyvecl *s1, const polyveck *s2);
void pack_sig(uint8_t sig[CRYPTO_BYTES], const uint8_t c[SEEDBYTES],
              const polyvecl *z, const polyveck *h);
void unpack_pk(uint8_t rho[SEEDBYTES], polyveck *t1,
               const uint8_t pk[CRYPTO_PUBLICKEYBYTES]);
void unpack_sk(uint8_t rho[SEEDBYTES], uint8_t tr[SEEDBYTES],
               uint8_t key[SEEDBYTES], polyveck *t0, polyvecl *s1, polyveck *s2,
               const uint8_t sk[CRYPTO_SECRETKEYBYTES]);
int unpack_sig(uint8_t c[SEEDBYTES], polyvecl *z, polyveck *h,
               const uint8_t sig[CRYPTO_BYTES]);

#endif
