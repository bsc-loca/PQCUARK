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

extern const int32_t zetas[256];

#ifdef PQCUARK
void ntt_pqcuark(int32_t poly[256]);

void intt_pqcuark(int32_t poly[256]);

void poly_pointwise_pqcuark(int32_t r[256], const int32_t a[256], const int32_t b[256]);

void poly_pointwise_acc_pqcuark(int32_t r[256], const int32_t a[256], const int32_t b[256]);

void poly_reduce_rv64im(int32_t r[256]);

#else 
void ntt(int32_t poly[256]);
void invntt(int32_t poly[256]);

#endif



#endif
