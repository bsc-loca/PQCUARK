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

#ifndef PARAMS_H
#define PARAMS_H

#include "config.h"

#define SEEDBYTES 32
#define CRHBYTES 64
#define N 256
#define Q 8380417
#define D 13
#define ROOT_OF_UNITY 1753

#if DILITHIUM_MODE == 2
#    define K 4
#    define L 4
#    define ETA 2
#    define TAU 39
#    define BETA 78
#    define GAMMA1 (1 << 17)
#    define GAMMA2 ((Q - 1) / 88)
#    define OMEGA 80

#elif DILITHIUM_MODE == 3
#    define K 6
#    define L 5
#    define ETA 4
#    define TAU 49
#    define BETA 196
#    define GAMMA1 (1 << 19)
#    define GAMMA2 ((Q - 1) / 32)
#    define OMEGA 55

#elif DILITHIUM_MODE == 5
#    define K 8
#    define L 7
#    define ETA 2
#    define TAU 60
#    define BETA 120
#    define GAMMA1 (1 << 19)
#    define GAMMA2 ((Q - 1) / 32)
#    define OMEGA 75

#endif

#define POLYT1_PACKEDBYTES 320
#define POLYT0_PACKEDBYTES 416
#define POLYVECH_PACKEDBYTES (OMEGA + K)

#if GAMMA1 == (1 << 17)
#    define POLYZ_PACKEDBYTES 576
#elif GAMMA1 == (1 << 19)
#    define POLYZ_PACKEDBYTES 640
#endif

#if GAMMA2 == (Q - 1) / 88
#    define POLYW1_PACKEDBYTES 192
#elif GAMMA2 == (Q - 1) / 32
#    define POLYW1_PACKEDBYTES 128
#endif

#if ETA == 2
#    define POLYETA_PACKEDBYTES 96
#elif ETA == 4
#    define POLYETA_PACKEDBYTES 128
#endif

#define CRYPTO_PUBLICKEYBYTES (SEEDBYTES + K * POLYT1_PACKEDBYTES)
#define CRYPTO_SECRETKEYBYTES                                            \
    (3 * SEEDBYTES + L * POLYETA_PACKEDBYTES + K * POLYETA_PACKEDBYTES + \
     K * POLYT0_PACKEDBYTES)
#define CRYPTO_BYTES (SEEDBYTES + L * POLYZ_PACKEDBYTES + POLYVECH_PACKEDBYTES)

#endif
