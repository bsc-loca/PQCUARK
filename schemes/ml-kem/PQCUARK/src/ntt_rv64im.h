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

#ifndef KYBER_NTT_RV64_H
#define KYBER_NTT_RV64_H

#include <stdint.h>

extern void ntt_rv64im(int16_t *, uint32_t *);
extern void intt_rv64im(int16_t *, uint32_t *);
extern void poly_plantard_rdc_rv64im(int16_t *r);
extern void poly_toplant_rv64im(int16_t *r);

extern void poly_basemul_acc_rv64im(int32_t *r, const int16_t *a,
                                    const int16_t *b, uint32_t *zetas);
extern void poly_basemul_acc_end_rv64im(int16_t *r, const int16_t *a,
                                        const int16_t *b, uint32_t *zetas,
                                        int32_t *r_double);
extern void poly_basemul_cache_init_rv64im(int32_t *r, const int16_t *a,
                                           const int16_t *b, int16_t *b_cache,
                                           uint32_t *zetas);
extern void poly_basemul_acc_cache_init_rv64im(int32_t *r, const int16_t *a,
                                               const int16_t *b,
                                               int16_t *b_cache,
                                               uint32_t *zetas);
extern void poly_basemul_acc_cache_init_end_rv64im(int16_t *r, const int16_t *a,
                                                   const int16_t *b,
                                                   int16_t *b_cache,
                                                   uint32_t *zetas,
                                                   int32_t *r_double);
extern void poly_basemul_acc_cached_rv64im(int32_t *r, const int16_t *a,
                                           const int16_t *b, int16_t *b_cache);
extern void poly_basemul_acc_cache_end_rv64im(int16_t *r, const int16_t *a,
                                              const int16_t *b,
                                              int16_t *b_cache,
                                              int32_t *r_double);

#endif