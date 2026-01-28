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

#ifndef POLYVEC_H
#define POLYVEC_H

#include <stdint.h>

#include "params.h"
#include "poly.h"

typedef struct {
    poly vec[KYBER_K];
} polyvec;

void polyvec_gen_eta1_skpv_e(polyvec *skpv, polyvec *e,
                             const uint8_t *noiseseed);
void polyvec_gen_eta1_sp_eta2_ep_epp(polyvec *sp, polyvec *ep, poly *epp,
                                     const uint8_t coins[KYBER_SYMBYTES]);

void polyvec_compress(uint8_t r[KYBER_POLYVECCOMPRESSEDBYTES],
                      const polyvec *a);
void polyvec_decompress(polyvec *r,
                        const uint8_t a[KYBER_POLYVECCOMPRESSEDBYTES]);
void polyvec_tobytes(uint8_t r[KYBER_POLYVECBYTES], const polyvec *a);
void polyvec_frombytes(polyvec *r, const uint8_t a[KYBER_POLYVECBYTES]);
void polyvec_ntt(polyvec *r);
void polyvec_intt(polyvec *r);
void polyvec_reduce(polyvec *r);
void polyvec_add(polyvec *r, const polyvec *a, const polyvec *b);

#if defined(VECTOR128)

typedef struct {
    poly_half vec[KYBER_K];
} polyvec_half;

void polyvec_basemul_acc_cache_init(poly *r, const polyvec *a, const polyvec *b,
                                    polyvec_half *b_cache);
void polyvec_basemul_acc_cached(poly *r, const polyvec *a, const polyvec *b,
                                polyvec_half *b_cache);
void polyvec_basemul_acc(poly *r, const polyvec *a, const polyvec *b);

#elif defined(RV64)

typedef struct {
    poly_half vec[KYBER_K];
} polyvec_half;

void polyvec_basemul_acc_cache_init(poly *r, const polyvec *a, const polyvec *b,
                                    polyvec_half *b_cache);
void polyvec_basemul_acc_cached(poly *r, const polyvec *a, const polyvec *b,
                                polyvec_half *b_cache);
void polyvec_basemul_acc(poly *r, const polyvec *a, const polyvec *b);

#else

void polyvec_basemul_acc(poly *r, const polyvec *a, const polyvec *b);

#endif

#endif
