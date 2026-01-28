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

#ifndef NTT_H
#define NTT_H

#include <stdint.h>

#include "params.h"

void ntt(int16_t poly[256]);
void intt(int16_t poly[256]);
void basemul(int16_t r[2], const int16_t a[2], const int16_t b[2],
             int16_t zeta);

#if defined(VECTOR128)
#    include "ntt_rvv_vlen128.h"
#    include "ntt_rvv_vlen256.h"
void ntt2normal_order_rvv(int16_t *r);
void normal2ntt_order_rvv(int16_t *r);
#elif defined(RV64) || defined(KECCAK)
#    include "ntt_rv64im.h"
#else
extern const int16_t zetas[128];
#endif

#endif