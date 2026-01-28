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

#define zetas KYBER_NAMESPACE(zetas)
extern const int16_t zetas[128];

#define ntt KYBER_NAMESPACE(ntt_pqcuark)
#define ntt_pqcuark KYBER_NAMESPACE(ntt_pqcuark)
void ntt_pqcuark(int16_t poly[256]);

#define invntt KYBER_NAMESPACE(intt_pqcuark)
#define intt KYBER_NAMESPACE(intt_pqcuark)
#define intt_pqcuark KYBER_NAMESPACE(intt_pqcuark)
void intt_pqcuark(int16_t poly[256]);

#define basemul KYBER_NAMESPACE(basemul_pqcuark)
#define basemul_pqcuark KYBER_NAMESPACE(basemul_pqcuark)
void basemul_pqcuark(int16_t r[2], const int16_t a[2], const int16_t b[2], int16_t zeta);


#ifdef BASEMUL_ACC
  #define basemul_acc KYBER_NAMESPACE(basemul_acc_pqcuark)
  #define basemul_acc_pqcuark KYBER_NAMESPACE(basemul_acc_pqcuark)
  void basemul_acc_pqcuark(int16_t r[2], const int16_t a[2], const int16_t b[2], int16_t zeta);
#endif



#endif
