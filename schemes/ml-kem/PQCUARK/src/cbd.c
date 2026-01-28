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

#include "cbd.h"

#include <stdint.h>

#if defined(VECTOR128)
#    include <riscv_vector.h>
#endif

#include "params.h"

/*************************************************
 * Name:        cbd2
 *
 * Description: Given an array of uniformly random bytes, compute
 *              polynomial with coefficients distributed according to
 *              a centered binomial distribution with parameter eta=2
 *
 * Arguments:   - poly *r: pointer to output polynomial
 *              - const uint8_t *buf: pointer to input byte array
 **************************************************/
#if defined(VECTOR128)
static void cbd2(poly *r, const uint8_t buf[2 * KYBER_N / 4])
{
    unsigned int i, pos;
    size_t vl, vl_sext;
    const uint8_t idx8_0011_t[16] __attribute__((aligned(16))) = {
        0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7,
    };
    const uint8_t idx8_8899_t[16] = {
        8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15,
    };
    const uint8_t mask_0b0101_t[16] = {
        1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
    };

    vuint8m1_t f0, f1, f0t0, f0t1, f1t0, f1t1;
    vint8m1_t a0, a1;
    vint16m1_t g00, g01, g10, g11;
    vuint8m1_t idx8_0011, idx8_8899;
    vbool8_t mask_0b0101;

    vl = __riscv_vsetvl_e8m1(128 / 8);
    idx8_0011 = __riscv_vle8_v_u8m1(idx8_0011_t, vl);
    idx8_8899 = __riscv_vle8_v_u8m1(idx8_8899_t, vl);
    f0t0 = __riscv_vle8_v_u8m1(mask_0b0101_t, vl);
    mask_0b0101 = __riscv_vmseq_vx_u8m1_b8(f0t0, 1, vl);
    pos = 0;
    for (i = 0; i < KYBER_N / 32; i++) {
        f0 = __riscv_vle8_v_u8m1(&buf[pos], vl);
        pos += vl;
        f1 = __riscv_vsrl_vx_u8m1(f0, 1, vl);
        f0 = __riscv_vand_vx_u8m1(f0, 0x55, vl);
        f1 = __riscv_vand_vx_u8m1(f1, 0x55, vl);
        f0 = __riscv_vadd_vv_u8m1(f0, f1, vl);
        f1 = __riscv_vsrl_vx_u8m1(f0, 2, vl);
        f0 = __riscv_vand_vx_u8m1(f0, 0x33, vl);
        f1 = __riscv_vand_vx_u8m1(f1, 0x33, vl);
        f0 = __riscv_vadd_vx_u8m1(f0, 0x33, vl);
        f0 = __riscv_vsub_vv_u8m1(f0, f1, vl);
        f1 = __riscv_vsrl_vx_u8m1(f0, 4, vl);
        f0 = __riscv_vand_vx_u8m1(f0, 0x0f, vl);
        f0 = __riscv_vsub_vx_u8m1(f0, 3, vl);
        f1 = __riscv_vsub_vx_u8m1(f1, 3, vl);
        f0t0 = __riscv_vrgather_vv_u8m1(f0, idx8_0011, vl);
        f1t0 = __riscv_vrgather_vv_u8m1(f1, idx8_0011, vl);
        f0t1 = __riscv_vrgather_vv_u8m1(f0, idx8_8899, vl);
        f1t1 = __riscv_vrgather_vv_u8m1(f1, idx8_8899, vl);
        f0 = __riscv_vmerge_vvm_u8m1(f1t0, f0t0, mask_0b0101, vl);
        f1 = __riscv_vmerge_vvm_u8m1(f1t1, f0t1, mask_0b0101, vl);
        vl_sext = __riscv_vsetvl_e16m1(128/16);
        a0 = __riscv_vreinterpret_v_u8m1_i8m1(f0);
        g00 = __riscv_vsext_vf2_i16m1(__riscv_vlmul_trunc_v_i8m1_i8mf2(a0), vl);
        a0 = __riscv_vslidedown_vx_i8m1(a0, vl_sext, (vl_sext<<1));
        g01 = __riscv_vsext_vf2_i16m1(__riscv_vlmul_trunc_v_i8m1_i8mf2(a0), vl);
        __riscv_vse16_v_i16m1(&r->coeffs[i * 32 + 0], g00, vl);
        __riscv_vse16_v_i16m1(&r->coeffs[i * 32 + 8], g01, vl);
        a1 = __riscv_vreinterpret_v_u8m1_i8m1(f1);
        g10 = __riscv_vsext_vf2_i16m1(__riscv_vlmul_trunc_v_i8m1_i8mf2(a1), vl);
        a1 = __riscv_vslidedown_vx_i8m1(a1, vl_sext, (vl_sext<<1));
        g11 = __riscv_vsext_vf2_i16m1(__riscv_vlmul_trunc_v_i8m1_i8mf2(a1), vl);
        __riscv_vse16_v_i16m1(&r->coeffs[i * 32 + 16], g10, vl);
        __riscv_vse16_v_i16m1(&r->coeffs[i * 32 + 24], g11, vl);
    }
}
#else
/*************************************************
 * Name:        load32_littleendian
 *
 * Description: load 4 bytes into a 32-bit integer
 *              in little-endian order
 *
 * Arguments:   - const uint8_t *x: pointer to input byte array
 *
 * Returns 32-bit unsigned integer loaded from x
 **************************************************/
static uint32_t load32_littleendian(const uint8_t x[4])
{
    uint32_t r;
    r = (uint32_t)x[0];
    r |= (uint32_t)x[1] << 8;
    r |= (uint32_t)x[2] << 16;
    r |= (uint32_t)x[3] << 24;
    return r;
}

static void cbd2(poly *r, const uint8_t buf[2 * KYBER_N / 4])
{
    unsigned int i, j;
    uint32_t t, d;
    int16_t a, b;

    for (i = 0; i < KYBER_N / 8; i++) {
        t = load32_littleendian(buf + 4 * i);
        d = t & 0x55555555;
        d += (t >> 1) & 0x55555555;

        for (j = 0; j < 8; j++) {
            a = (d >> (4 * j + 0)) & 0x3;
            b = (d >> (4 * j + 2)) & 0x3;
            r->coeffs[8 * i + j] = a - b;
        }
    }
}
#endif

/*************************************************
 * Name:        cbd3
 *
 * Description: Given an array of uniformly random bytes, compute
 *              polynomial with coefficients distributed according to
 *              a centered binomial distribution with parameter eta=3.
 *              This function is only needed for Kyber-512
 *
 * Arguments:   - poly *r: pointer to output polynomial
 *              - const uint8_t *buf: pointer to input byte array
 **************************************************/
#if KYBER_ETA1 == 3
#    if defined(VECTOR128)
static void cbd3(poly *r, const uint8_t buf[3 * KYBER_N / 4])
{
    unsigned int i, pos;
    size_t vl_e8, vl_e32;
    const uint8_t idx8_0122_t[16] __attribute__((aligned(16))) = {
        0, 1, 2, 2, 3, 4, 5, 5, 6, 7, 8, 8, 9, 10, 11, 11,
    };
    const uint32_t idx32_0011_t[4] = {0, 0, 1, 1};
    const uint32_t idx32_2233_t[4] = {2, 2, 3, 3};
    const uint32_t mask_0b0101_t[4] = {1, 0, 1, 0};
    vuint8m1_t t0, idx8_0122;
    vuint32m1_t t1, idx32_0011, idx32_2233;
    vuint32m1_t f0, f1, f2, f3, f0t0, f0t1, f1t0, f1t1;
    vbool32_t mask_0b0101;

    vl_e32 = __riscv_vsetvl_e32m1(128 / 32);
    t1 = __riscv_vle32_v_u32m1(mask_0b0101_t, vl_e32);
    idx32_0011 = __riscv_vle32_v_u32m1(idx32_0011_t, vl_e32);
    idx32_2233 = __riscv_vle32_v_u32m1(idx32_2233_t, vl_e32);
    mask_0b0101 = __riscv_vmseq_vx_u32m1_b32(t1, 1, vl_e32);
    vl_e8 = __riscv_vsetvl_e8m1(128 / 8);
    idx8_0122 = __riscv_vle8_v_u8m1(idx8_0122_t, vl_e8);
    pos = 0;
    for (i = 0; i < KYBER_N / 16; i++) {
        t0 = __riscv_vle8_v_u8m1(&buf[pos], vl_e8);
        pos += 12;
        t0 = __riscv_vrgather_vv_u8m1(t0, idx8_0122, vl_e8);
        f0 = __riscv_vreinterpret_v_u8m1_u32m1(t0);
        f1 = __riscv_vsrl_vx_u32m1(f0, 1, vl_e32);
        f2 = __riscv_vsrl_vx_u32m1(f0, 2, vl_e32);
        f0 = __riscv_vand_vx_u32m1(f0, 0x249249, vl_e32);
        f1 = __riscv_vand_vx_u32m1(f1, 0x249249, vl_e32);
        f2 = __riscv_vand_vx_u32m1(f2, 0x249249, vl_e32);
        f0 = __riscv_vadd_vv_u32m1(f0, f1, vl_e32);
        f0 = __riscv_vadd_vv_u32m1(f0, f2, vl_e32);
        f1 = __riscv_vsrl_vx_u32m1(f0, 3, vl_e32);
        f0 = __riscv_vadd_vx_u32m1(f0, 0x6DB6DB, vl_e32);
        f0 = __riscv_vsub_vv_u32m1(f0, f1, vl_e32);
        f1 = __riscv_vsll_vx_u32m1(f0, 10, vl_e32);
        f2 = __riscv_vsrl_vx_u32m1(f0, 12, vl_e32);
        f3 = __riscv_vsrl_vx_u32m1(f0, 2, vl_e32);
        f0 = __riscv_vand_vx_u32m1(f0, 7, vl_e32);
        f1 = __riscv_vand_vx_u32m1(f1, 7 << 16, vl_e32);
        f2 = __riscv_vand_vx_u32m1(f2, 7, vl_e32);
        f3 = __riscv_vand_vx_u32m1(f3, 7 << 16, vl_e32);
        f0 = __riscv_vadd_vv_u32m1(f0, f1, vl_e32);
        f1 = __riscv_vadd_vv_u32m1(f2, f3, vl_e32);
        f0 = __riscv_vreinterpret_v_u16m1_u32m1(
            __riscv_vsub_vx_u16m1(__riscv_vreinterpret_v_u32m1_u16m1(f0), 3, vl_e32 * 2));
        f1 = __riscv_vreinterpret_v_u16m1_u32m1(
            __riscv_vsub_vx_u16m1(__riscv_vreinterpret_v_u32m1_u16m1(f1), 3, vl_e32 * 2));
        f0t0 = __riscv_vrgather_vv_u32m1(f0, idx32_0011, vl_e32);
        f1t0 = __riscv_vrgather_vv_u32m1(f1, idx32_0011, vl_e32);
        f0t1 = __riscv_vrgather_vv_u32m1(f0, idx32_2233, vl_e32);
        f1t1 = __riscv_vrgather_vv_u32m1(f1, idx32_2233, vl_e32);
        f0 = __riscv_vmerge_vvm_u32m1(f1t0, f0t0, mask_0b0101, vl_e32);
        f1 = __riscv_vmerge_vvm_u32m1(f1t1, f0t1, mask_0b0101, vl_e32);
        __riscv_vse32_v_u32m1((uint32_t *)&r->coeffs[i * 16 + 0], f0, vl_e32);
        __riscv_vse32_v_u32m1((uint32_t *)&r->coeffs[i * 16 + 8], f1, vl_e32);
    }
}
#    else
/*************************************************
 * Name:        load24_littleendian
 *
 * Description: load 3 bytes into a 32-bit integer
 *              in little-endian order.
 *              This function is only needed for Kyber-512
 *
 * Arguments:   - const uint8_t *x: pointer to input byte array
 *
 * Returns 32-bit unsigned integer loaded from x (most significant byte is
 *zero)
 **************************************************/
static uint32_t load24_littleendian(const uint8_t x[3])
{
    uint32_t r;
    r = (uint32_t)x[0];
    r |= (uint32_t)x[1] << 8;
    r |= (uint32_t)x[2] << 16;
    return r;
}

static void cbd3(poly *r, const uint8_t buf[3 * KYBER_N / 4])
{
    unsigned int i, j;
    uint32_t t, d;
    int16_t a, b;

    for (i = 0; i < KYBER_N / 4; i++) {
        t = load24_littleendian(buf + 3 * i);
        d = t & 0x00249249;
        d += (t >> 1) & 0x00249249;
        d += (t >> 2) & 0x00249249;

        for (j = 0; j < 4; j++) {
            a = (d >> (6 * j + 0)) & 0x7;
            b = (d >> (6 * j + 3)) & 0x7;
            r->coeffs[4 * i + j] = a - b;
        }
    }
}
#    endif
#endif

void poly_cbd_eta1(poly *r, const uint8_t buf[KYBER_ETA1 * KYBER_N / 4])
{
#if KYBER_ETA1 == 2
    cbd2(r, buf);
#elif KYBER_ETA1 == 3
    cbd3(r, buf);
#else
#    error "This implementation requires eta1 in {2,3}"
#endif
}

void poly_cbd_eta2(poly *r, const uint8_t buf[KYBER_ETA2 * KYBER_N / 4])
{
#if KYBER_ETA2 == 2
    cbd2(r, buf);
#else
#    error "This implementation requires eta2 = 2"
#endif
}
