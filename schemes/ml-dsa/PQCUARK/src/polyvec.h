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
    poly vec[L];
} polyvecl;

typedef struct {
    poly vec[K];
} polyveck;

void polyvecl_uniform_eta(polyvecl *v, const uint8_t seed[CRHBYTES],
                          uint16_t nonce);
void polyvecl_uniform_gamma1(polyvecl *v, const uint8_t seed[CRHBYTES],
                             uint16_t nonce);
void polyvecl_reduce(polyvecl *v);
void polyvecl_add(polyvecl *w, const polyvecl *u, const polyvecl *v);
int polyvecl_chknorm(const polyvecl *v, int32_t B);

void polyveck_uniform_eta(polyveck *v, const uint8_t seed[CRHBYTES],
                          uint16_t nonce);
void polyveck_reduce(polyveck *v);
void polyveck_caddq(polyveck *v);
void polyveck_add(polyveck *w, const polyveck *u, const polyveck *v);
void polyveck_sub(polyveck *w, const polyveck *u, const polyveck *v);
void polyveck_shiftl(polyveck *v);
int polyveck_chknorm(const polyveck *v, int32_t B);
void polyveck_power2round(polyveck *v1, polyveck *v0, const polyveck *v);
void polyveck_decompose(polyveck *v1, polyveck *v0, const polyveck *v);
unsigned int polyveck_make_hint(polyveck *h, const polyveck *v0,
                                const polyveck *v1);
void polyveck_use_hint(polyveck *w, const polyveck *v, const polyveck *h);
void polyveck_pack_w1(uint8_t r[K * POLYW1_PACKEDBYTES],
                      const polyveck *w1);
void polyvec_matrix_expand(polyvecl mat[K], const uint8_t rho[SEEDBYTES]);
void polyveclk_uniform_eta(polyvecl *v_l, polyveck *v_k,
                           const uint8_t seed[CRHBYTES], uint16_t nonce_l,
                           uint16_t nonce_k);

void polyvecl_ntt(polyvecl *v);
void polyvecl_intt(polyvecl *v);
void polyveck_ntt(polyveck *v);
void polyveck_intt(polyveck *v);
void polyvecl_pointwise_poly(polyvecl *r, const poly *a,
                             const polyvecl *v);
void polyveck_pointwise_poly(polyveck *r, const poly *a,
                             const polyveck *v);
void polyvecl_pointwise_acc(poly *w, const polyvecl *u, const polyvecl *v);
void polyvec_matrix_pointwise(polyveck *t, const polyvecl mat[K],
                              const polyvecl *v);

// todo: 6-layer ntt

#endif
