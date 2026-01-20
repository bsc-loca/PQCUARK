#include "poly.h"

#include <stdint.h>
#include <string.h>

#if defined(VECTOR128)
#    include <riscv_vector.h>
#endif

#include "fips202_pqcuark.h"
#include "ntt.h"
#include "params.h"
#include "reduce.h"
#include "rounding.h"
#include "vmacro.h"

#ifdef DBENCH
#    include "cpucycles.h"
extern const uint64_t timing_overhead;
extern uint64_t *tred, *tadd, *tmul, *tround, *tsample, *tpack;
#    define DBENCH_START() uint64_t time = cpucycles()
#    define DBENCH_STOP(t) t += cpucycles() - time - timing_overhead
#else
#    define DBENCH_START()
#    define DBENCH_STOP(t)
#endif

/*************************************************
 * Name:        poly_caddq
 *
 * Description: For all coefficients of in/out polynomial add Q if
 *              coefficient is negative.
 *
 * Arguments:   - poly *a: pointer to input/output polynomial
 **************************************************/
void poly_caddq(poly *a)
{
    unsigned int i;
    DBENCH_START();

    for (i = 0; i < N; ++i)
        a->coeffs[i] = caddq(a->coeffs[i]);

    DBENCH_STOP(*tred);
}

/*************************************************
 * Name:        poly_add
 *
 * Description: Add polynomials. No modular reduction is performed.
 *
 * Arguments:   - poly *c: pointer to output polynomial
 *              - const poly *a: pointer to first summand
 *              - const poly *b: pointer to second summand
 **************************************************/
void poly_add(poly *c, const poly *a, const poly *b)
{
    unsigned int i;
    DBENCH_START();

    for (i = 0; i < N; ++i)
        c->coeffs[i] = a->coeffs[i] + b->coeffs[i];

    DBENCH_STOP(*tadd);
}

/*************************************************
 * Name:        poly_sub
 *
 * Description: Subtract polynomials. No modular reduction is
 *              performed.
 *
 * Arguments:   - poly *c: pointer to output polynomial
 *              - const poly *a: pointer to first input polynomial
 *              - const poly *b: pointer to second input polynomial to be
 *                               subtraced from first input polynomial
 **************************************************/
void poly_sub(poly *c, const poly *a, const poly *b)
{
    unsigned int i;
    DBENCH_START();

    for (i = 0; i < N; ++i)
        c->coeffs[i] = a->coeffs[i] - b->coeffs[i];

    DBENCH_STOP(*tadd);
}

/*************************************************
 * Name:        poly_shiftl
 *
 * Description: Multiply polynomial by 2^D without modular reduction.
 *Assumes input coefficients to be less than 2^{31-D} in absolute value.
 *
 * Arguments:   - poly *a: pointer to input/output polynomial
 **************************************************/
void poly_shiftl(poly *a)
{
    unsigned int i;
    DBENCH_START();

    for (i = 0; i < N; ++i)
        a->coeffs[i] <<= D;

    DBENCH_STOP(*tmul);
}

/*************************************************
 * Name:        poly_power2round
 *
 * Description: For all coefficients c of the input polynomial,
 *              compute c0, c1 such that c mod Q = c1*2^D + c0
 *              with -2^{D-1} < c0 <= 2^{D-1}. Assumes coefficients to be
 *              standard representatives.
 *
 * Arguments:   - poly *a1: pointer to output polynomial with coefficients
 *c1
 *              - poly *a0: pointer to output polynomial with coefficients
 *c0
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void poly_power2round(poly *a1, poly *a0, const poly *a)
{
    unsigned int i;
    DBENCH_START();

    for (i = 0; i < N; ++i)
        a1->coeffs[i] = power2round(&a0->coeffs[i], a->coeffs[i]);

    DBENCH_STOP(*tround);
}

/*************************************************
 * Name:        poly_decompose
 *
 * Description: For all coefficients c of the input polynomial,
 *              compute high and low bits c0, c1 such c mod Q = c1*ALPHA +
 *c0 with -ALPHA/2 < c0 <= ALPHA/2 except c1 = (Q-1)/ALPHA where we set c1
 *= 0 and -ALPHA/2 <= c0 = c mod Q - Q < 0. Assumes coefficients to be
 *standard representatives.
 *
 * Arguments:   - poly *a1: pointer to output polynomial with coefficients
 *c1
 *              - poly *a0: pointer to output polynomial with coefficients
 *c0
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void poly_decompose(poly *a1, poly *a0, const poly *a)
{
    unsigned int i;
    DBENCH_START();

    for (i = 0; i < N; ++i)
        a1->coeffs[i] = decompose(&a0->coeffs[i], a->coeffs[i]);

    DBENCH_STOP(*tround);
}

/*************************************************
 * Name:        poly_make_hint
 *
 * Description: Compute hint polynomial. The coefficients of which indicate
 *              whether the low bits of the corresponding coefficient of
 *              the input polynomial overflow into the high bits.
 *
 * Arguments:   - poly *h: pointer to output hint polynomial
 *              - const poly *a0: pointer to low part of input polynomial
 *              - const poly *a1: pointer to high part of input polynomial
 *
 * Returns number of 1 bits.
 **************************************************/
unsigned int poly_make_hint(poly *h, const poly *a0, const poly *a1)
{
    unsigned int i, s = 0;
    DBENCH_START();

    for (i = 0; i < N; ++i) {
        h->coeffs[i] = make_hint(a0->coeffs[i], a1->coeffs[i]);
        s += h->coeffs[i];
    }

    DBENCH_STOP(*tround);
    return s;
}

/*************************************************
 * Name:        poly_use_hint
 *
 * Description: Use hint polynomial to correct the high bits of a
 *polynomial.
 *
 * Arguments:   - poly *b: pointer to output polynomial with corrected high
 *bits
 *              - const poly *a: pointer to input polynomial
 *              - const poly *h: pointer to input hint polynomial
 **************************************************/
void poly_use_hint(poly *b, const poly *a, const poly *h)
{
    unsigned int i;
    DBENCH_START();

    for (i = 0; i < N; ++i)
        b->coeffs[i] = use_hint(a->coeffs[i], h->coeffs[i]);

    DBENCH_STOP(*tround);
}

/*************************************************
 * Name:        poly_chknorm
 *
 * Description: Check infinity norm of polynomial against given bound.
 *              Assumes input coefficients were reduced by reduce32().
 *
 * Arguments:   - const poly *a: pointer to polynomial
 *              - int32_t B: norm bound
 *
 * Returns 0 if norm is strictly smaller than B <= (Q-1)/8 and 1 otherwise.
 **************************************************/
int poly_chknorm(const poly *a, int32_t B)
{
    unsigned int i;
    int32_t t;
    DBENCH_START();

    if (B > (Q - 1) / 8)
        return 1;

    /* It is ok to leak which coefficient violates the bound since
       the probability for each coefficient is independent of secret
       data but we must not leak the sign of the centralized
       representative. */
    for (i = 0; i < N; ++i) {
        /* Absolute value */
        t = a->coeffs[i] >> 31;
        t = a->coeffs[i] - (t & 2 * a->coeffs[i]);

        if (t >= B) {
            DBENCH_STOP(*tsample);
            return 1;
        }
    }

    DBENCH_STOP(*tsample);
    return 0;
}

/*************************************************
 * Name:        rej_uniform
 *
 * Description: Sample uniformly random coefficients in [0, Q-1] by
 *              performing rejection sampling on array of random bytes.
 *
 * Arguments:   - int32_t *a: pointer to output array (allocated)
 *              - unsigned int len: number of coefficients to be sampled
 *              - const uint8_t *buf: array of random bytes
 *              - unsigned int buflen: length of array of random bytes
 *
 * Returns number of sampled coefficients. Can be smaller than len if not
 *enough random bytes were given.
 **************************************************/
unsigned int rej_uniform(int32_t *a, unsigned int len, const uint8_t *buf,
                         unsigned int buflen)
{
    unsigned int ctr, pos;
    uint32_t t;
    DBENCH_START();

    ctr = pos = 0;
    while (ctr < len && pos + 3 <= buflen) {
        t = buf[pos++];
        t |= (uint32_t)buf[pos++] << 8;
        t |= (uint32_t)buf[pos++] << 16;
        t &= 0x7FFFFF;

        if (t < Q)
            a[ctr++] = t;
    }

    DBENCH_STOP(*tsample);
    return ctr;
}

#define GEN_MATRIX_NBLOCKS ((768 + SHAKE128_RATE - 1) / SHAKE128_RATE)
#define REJ_UNIFORM_VECTOR_BUFLEN (GEN_MATRIX_NBLOCKS * SHAKE128_RATE)

#if defined(VECTOR128)
unsigned int rej_uniform_vector(int32_t *a, const uint8_t *buf)
{
    unsigned int ctr, pos;
    unsigned long num0, num1;
    size_t vl;
    vuint8m1_t f0, f1, idx8;
    vuint32m1_t g0, g1;
    vbool32_t good0, good1;
    uint32_t t;

    const uint32_t mask_23bits = 0x7FFFFF;
    const uint32_t bound = Q;
    const uint8_t idx8_t[16] __attribute__((aligned(16))) = {
        0, 1, 2, 2, 3, 4, 5, 5, 6, 7, 8, 8, 9, 10, 11, 11};

    vl = __riscv_vsetvl_e8m1(128 / 8);
    idx8 = __riscv_vle8_v_u8m1(idx8_t, vl);

    ctr = pos = 0;
    while (ctr <= N - 8 && pos <= REJ_UNIFORM_VECTOR_BUFLEN - 24) {
        vl = __riscv_vsetvl_e8m1(128 / 8);
        f0 = __riscv_vle8_v_u8m1(&buf[pos], vl);
        f1 = __riscv_vle8_v_u8m1(&buf[pos + 12], vl);
        pos += 24;
        f0 = __riscv_vrgather_vv_u8m1(f0, idx8, vl);
        f1 = __riscv_vrgather_vv_u8m1(f1, idx8, vl);

        vl =__riscv_vsetvl_e32m1(128 / 32);
        g0 =__riscv_vreinterpret_v_u8m1_u32m1(f0);
        g1 =__riscv_vreinterpret_v_u8m1_u32m1(f1);
        g0 =__riscv_vand_vx_u32m1(g0, mask_23bits, vl);
        g1 =__riscv_vand_vx_u32m1(g1, mask_23bits, vl);
        good0 = __riscv_vmsltu_vx_u32m1_b32(g0, bound, vl);
        good1 = __riscv_vmsltu_vx_u32m1_b32(g1, bound, vl);
        num0 = __riscv_vcpop_m_b32(good0, vl);
        num1 = __riscv_vcpop_m_b32(good1, vl);
        g0 = __riscv_vcompress_vm_u32m1_tu(g0, g0, good0, vl);
        g1 = __riscv_vcompress_vm_u32m1_tu(g1, g1, good1, vl);
        __riscv_vse32_v_u32m1((uint32_t *)&a[ctr], g0, vl);
        ctr += num0;
        __riscv_vse32_v_u32m1((uint32_t *)&a[ctr], g1, vl);
        ctr += num1;
    }
    while (ctr < N && pos <= REJ_UNIFORM_VECTOR_BUFLEN - 3) {
        t = buf[pos++];
        t |= (uint32_t)buf[pos++] << 8;
        t |= (uint32_t)buf[pos++] << 16;
        t &= 0x7FFFFF;
        if (t < Q)
            a[ctr++] = t;
    }
    return ctr;
}
#endif

/*************************************************
 * Name:        poly_uniform
 *
 * Description: Sample polynomial with uniformly random coefficients
 *              in [0,Q-1] by performing rejection sampling on the
 *              output stream of SHAKE128(seed|nonce).
 *
 * Arguments:   - poly *a: pointer to output polynomial
 *              - const uint8_t seed[]: byte array with seed of length
 *SEEDBYTES
 *              - uint16_t nonce: 2-byte nonce
 **************************************************/
#define POLY_UNIFORM_NBLOCKS ((768 + SHAKE128_RATE - 1) / SHAKE128_RATE)
void poly_uniform(poly *a, const uint8_t seed[SEEDBYTES], uint16_t nonce)
{
    unsigned int i, ctr, off, pos;
    unsigned int buflen = POLY_UNIFORM_NBLOCKS * SHAKE128_RATE;
    uint8_t buf[POLY_UNIFORM_NBLOCKS * SHAKE128_RATE + 2];

    memcpy(buf, seed, SEEDBYTES);
    buf[SEEDBYTES] = nonce;
    buf[SEEDBYTES + 1] = nonce >> 8;

    asm volatile ("csrw 0x816, %0" :: "rK"(SEEDBYTES + 2)); // CSR_KECCAK_INLEN
    asm volatile ("csrw 0x817, %0" :: "rK"(0));

    shake128_init();
    pos = 0;
    shake128_absorb(&pos, buf, SEEDBYTES + 2);
    shake128_squeezeblocks(buf, POLY_UNIFORM_NBLOCKS);

#if defined(VECTOR128)
    ctr = rej_uniform_vector(a->coeffs, buf);
#else
    ctr = rej_uniform(a->coeffs, N, buf, buflen);
#endif

    while (ctr < N) {
        off = buflen % 3;
        for (i = 0; i < off; ++i)
            buf[i] = buf[buflen - off + i];

        shake128_squeezeblocks(buf + off, 1);
        buflen = SHAKE128_RATE + off;
        ctr += rej_uniform(a->coeffs + ctr, N - ctr, buf, buflen);
    }
}

/*************************************************
 * Name:        rej_eta
 *
 * Description: Sample uniformly random coefficients in [-ETA, ETA] by
 *              performing rejection sampling on array of random bytes.
 *
 * Arguments:   - int32_t *a: pointer to output array (allocated)
 *              - unsigned int len: number of coefficients to be sampled
 *              - const uint8_t *buf: array of random bytes
 *              - unsigned int buflen: length of array of random bytes
 *
 * Returns number of sampled coefficients. Can be smaller than len if not
 *enough random bytes were given.
 **************************************************/
unsigned int rej_eta(int32_t *a, unsigned int len, const uint8_t *buf,
                     unsigned int buflen)
{
    unsigned int ctr, pos;
    uint32_t t0, t1;
    DBENCH_START();

    ctr = pos = 0;
    while (ctr < len && pos < buflen) {
        t0 = buf[pos] & 0x0F;
        t1 = buf[pos++] >> 4;

#if ETA == 2
        if (t0 < 15) {
            t0 = t0 - (205 * t0 >> 10) * 5;
            a[ctr++] = 2 - t0;
        }
        if (t1 < 15 && ctr < len) {
            t1 = t1 - (205 * t1 >> 10) * 5;
            a[ctr++] = 2 - t1;
        }
#elif ETA == 4
        if (t0 < 9)
            a[ctr++] = 4 - t0;
        if (t1 < 9 && ctr < len)
            a[ctr++] = 4 - t1;
#endif
    }

    DBENCH_STOP(*tsample);
    return ctr;
}

/*************************************************
 * Name:        poly_uniform_eta
 *
 * Description: Sample polynomial with uniformly random coefficients
 *              in [-ETA,ETA] by performing rejection sampling on the
 *              output stream from SHAKE256(seed|nonce).
 *
 * Arguments:   - poly *a: pointer to output polynomial
 *              - const uint8_t seed[]: byte array with seed of length
 *CRHBYTES
 *              - uint16_t nonce: 2-byte nonce
 **************************************************/
#if ETA == 2
#    define POLY_UNIFORM_ETA_NBLOCKS \
        ((136 + SHAKE256_RATE - 1) / SHAKE256_RATE)
#elif ETA == 4
#    define POLY_UNIFORM_ETA_NBLOCKS \
        ((227 + SHAKE256_RATE - 1) / SHAKE256_RATE)
#endif
#define POLY_UNIFORM_ETA_BUFLEN (POLY_UNIFORM_ETA_NBLOCKS * SHAKE256_RATE)

#if defined(VECTOR128)
unsigned int rej_eta_vector(int32_t *a, const uint8_t *buf)
{
    unsigned int ctr, pos;
    unsigned long num0, num1;
    uint32_t t0, t1;
    size_t vl;
    vuint8m1_t f0, f1, ft0, idx8;
    uint8_t f0_m, f1_m;
    uint32_t g0[16];
    uint32_t g1[16];
    vbool8_t mask_10, mask_01;
    vbool32_t good0_v, good1_v;
    uint8_t good0[4];
    uint8_t good1[4];
#    if ETA == 2
    uint32_t gt0[16];
    uint32_t gt1[16];
#    endif

    const uint8_t idx8_t[16] __attribute__((aligned(16))) = {
        0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7};
    const uint8_t mask_10_t[16] = {1, 0, 1, 0, 1, 0, 1, 0,
                                   1, 0, 1, 0, 1, 0, 1, 0};

    vl = __riscv_vsetvl_e8m1(128 / 8);
    ft0 = __riscv_vle8_v_u8m1(mask_10_t, vl);
    mask_10 = __riscv_vmseq_vx_u8m1_b8(ft0, 1, vl);
    mask_01 = __riscv_vmsne_vx_u8m1_b8(ft0, 1, vl);
    idx8 = __riscv_vle8_v_u8m1(idx8_t, vl);

    ctr = pos = 0;
    while (ctr <= N - 32 && pos <= POLY_UNIFORM_ETA_BUFLEN - 16) {
        vl = __riscv_vsetvl_e8m1(128 / 8);
        f0 = __riscv_vle8_v_u8m1(&buf[pos], vl);
        f1 = __riscv_vle8_v_u8m1(&buf[pos + 8], vl);
        pos += vl;
        f0 = __riscv_vrgather_vv_u8m1(f0, idx8, vl);
        f1 = __riscv_vrgather_vv_u8m1(f1, idx8, vl);
        f0 = __riscv_vand_vx_u8m1_mu(mask_10, f0, f0, 0x0F, vl);
        f1 = __riscv_vand_vx_u8m1_mu(mask_10, f1, f1, 0x0F, vl);
        f0 = __riscv_vsrl_vx_u8m1_mu(mask_01, f0, f0, 4, vl);
        f1 = __riscv_vsrl_vx_u8m1_mu(mask_01, f1, f1, 4, vl);
        VZEXT_VF4_U32M4_NO_GROUPING(g0, f0, vl);
        VZEXT_VF4_U32M4_NO_GROUPING(g1, f1, vl);
#    if ETA == 2
        VMSLTU_VX_U32M4_B8_NO_GROUPING(good0, g0, 15, vl);
        VMSLTU_VX_U32M4_B8_NO_GROUPING(good1, g1, 15, vl);
        VMUL_VX_U32M4_NO_GROUPING(gt0, g0, 205, vl);
        VMUL_VX_U32M4_NO_GROUPING(gt1, g1, 205, vl);
        VSRL_VX_U32M4_NO_GROUPING(gt0, gt0, 10, vl);
        VSRL_VX_U32M4_NO_GROUPING(gt1, gt1, 10, vl);
        VMUL_VX_U32M4_NO_GROUPING(gt0, gt0, 5, vl);
        VMUL_VX_U32M4_NO_GROUPING(gt1, gt1, 5, vl);
        VSUB_VV_U32M4_NO_GROUPING(g0, g0, gt0, vl);
        VSUB_VV_U32M4_NO_GROUPING(g1, g1, gt1, vl);

        good0_v = __riscv_vlm_v_b32(&good0[0], vl/4);
        num0 = __riscv_vcpop_m_b32(good0_v, vl/4);
        good0_v = __riscv_vlm_v_b32(&good0[1], vl/4);
        num0 += __riscv_vcpop_m_b32(good0_v, vl/4);
        good0_v = __riscv_vlm_v_b32(&good0[2], vl/4);
        num0 += __riscv_vcpop_m_b32(good0_v, vl/4);
        good0_v = __riscv_vlm_v_b32(&good0[3], vl/4);
        num0 += __riscv_vcpop_m_b32(good0_v, vl/4);

        good1_v = __riscv_vlm_v_b32(&good1[0], vl/4);
        num1 = __riscv_vcpop_m_b32(good1_v, vl/4);
        good1_v = __riscv_vlm_v_b32(&good1[1], vl/4);
        num1 += __riscv_vcpop_m_b32(good1_v, vl/4);
        good1_v = __riscv_vlm_v_b32(&good1[2], vl/4);
        num1 += __riscv_vcpop_m_b32(good1_v, vl/4);
        good1_v = __riscv_vlm_v_b32(&good1[3], vl/4);
        num1 += __riscv_vcpop_m_b32(good1_v, vl/4);

        VRSUB_VX_U32M4_NO_GROUPING(g0, g0, 2, vl);
        VRSUB_VX_U32M4_NO_GROUPING(g1, g1, 2, vl);
        VCOMPRESS_VM_U32M4_NO_GROUPING(g0, g0, good0, vl);
        VCOMPRESS_VM_U32M4_NO_GROUPING(g1, g1, good1, vl);
        VSE32_V_U32M4_NO_GROUPING((uint32_t *)&a[ctr], g0, vl);
        ctr += num0;
        VSE32_V_U32M4_NO_GROUPING((uint32_t *)&a[ctr], g1, vl);
        ctr += num1;
#    elif ETA == 4
        VMSLTU_VX_U32M4_B8_NO_GROUPING(good0, g0, 9, vl);
        VMSLTU_VX_U32M4_B8_NO_GROUPING(good1, g1, 9, vl);
        VRSUB_VX_U32M4_NO_GROUPING(g0, g0, 4, vl);

        VRSUB_VX_U32M4_NO_GROUPING(g1, g1, 4, vl);
        good0_v = __riscv_vlm_v_b32(&good0[0], vl/4);
        num0 = __riscv_vcpop_m_b32(good0_v, vl/4);
        good0_v = __riscv_vlm_v_b32(&good0[1], vl/4);
        num0 += __riscv_vcpop_m_b32(good0_v, vl/4);
        good0_v = __riscv_vlm_v_b32(&good0[2], vl/4);
        num0 += __riscv_vcpop_m_b32(good0_v, vl/4);
        good0_v = __riscv_vlm_v_b32(&good0[3], vl/4);
        num0 += __riscv_vcpop_m_b32(good0_v, vl/4);

        good1_v = __riscv_vlm_v_b32(&good1[0], vl/4);
        num1 = __riscv_vcpop_m_b32(good1_v, vl/4);
        good1_v = __riscv_vlm_v_b32(&good1[1], vl/4);
        num1 += __riscv_vcpop_m_b32(good1_v, vl/4);
        good1_v = __riscv_vlm_v_b32(&good1[2], vl/4);
        num1 += __riscv_vcpop_m_b32(good1_v, vl/4);
        good1_v = __riscv_vlm_v_b32(&good1[3], vl/4);
        num1 += __riscv_vcpop_m_b32(good1_v, vl/4);

        VCOMPRESS_VM_U32M4_NO_GROUPING(g0, g0, good0, vl);
        VCOMPRESS_VM_U32M4_NO_GROUPING(g1, g1, good1, vl);
        VSE32_V_U32M4_NO_GROUPING((uint32_t *)&a[ctr], g0, vl);
        ctr += num0;
        VSE32_V_U32M4_NO_GROUPING((uint32_t *)&a[ctr], g1, vl);
        ctr += num1;
#    endif
    }

    while (ctr < N && pos < POLY_UNIFORM_ETA_BUFLEN) {
        t0 = buf[pos] & 0x0F;
        t1 = buf[pos++] >> 4;

#    if ETA == 2
        if (t0 < 15) {
            t0 = t0 - (205 * t0 >> 10) * 5;
            a[ctr++] = 2 - t0;
        }
        if (t1 < 15 && ctr < N) {
            t1 = t1 - (205 * t1 >> 10) * 5;
            a[ctr++] = 2 - t1;
        }
#    elif ETA == 4
        if (t0 < 9)
            a[ctr++] = 4 - t0;
        if (t1 < 9 && ctr < N)
            a[ctr++] = 4 - t1;
#    endif
    }

    return ctr;
}
#endif

void poly_uniform_eta(poly *a, const uint8_t seed[CRHBYTES],
                      uint16_t nonce)
{
    unsigned int ctr;
    uint8_t buf[POLY_UNIFORM_ETA_BUFLEN];

    memcpy(buf, seed, CRHBYTES);
    buf[CRHBYTES] = nonce;
    buf[CRHBYTES + 1] = nonce >> 8;

    asm volatile ("csrw 0x816, %0" :: "rK"(CRHBYTES + 2)); // CSR_KECCAK_INLEN
    asm volatile ("csrw 0x817, %0" :: "rK"(1));

    shake256_absorb_once(buf, CRHBYTES + 2);
    shake256_squeezeblocks(buf, POLY_UNIFORM_ETA_NBLOCKS);

#if defined(VECTOR128)
    ctr = rej_eta_vector(a->coeffs, buf);
#else
    ctr = rej_eta(a->coeffs, N, buf, POLY_UNIFORM_ETA_BUFLEN);
#endif

    while (ctr < N) {
        shake256_squeezeblocks(buf, 1);
        ctr += rej_eta(a->coeffs + ctr, N - ctr, buf, SHAKE256_RATE);
    }
}

/*************************************************
 * Name:        poly_uniform_gamma1m1
 *
 * Description: Sample polynomial with uniformly random coefficients
 *              in [-(GAMMA1 - 1), GAMMA1] by unpacking output stream
 *              of SHAKE256(seed|nonce).
 *
 * Arguments:   - poly *a: pointer to output polynomial
 *              - const uint8_t seed[]: byte array with seed of length
 *CRHBYTES
 *              - uint16_t nonce: 16-bit nonce
 **************************************************/
#define POLY_UNIFORM_GAMMA1_NBLOCKS \
    ((POLYZ_PACKEDBYTES + SHAKE256_RATE - 1) / SHAKE256_RATE)
void poly_uniform_gamma1(poly *a, const uint8_t seed[CRHBYTES],
                         uint16_t nonce)
{
    uint8_t buf[POLY_UNIFORM_GAMMA1_NBLOCKS * SHAKE256_RATE];

    memcpy(buf, seed, CRHBYTES);
    buf[CRHBYTES] = nonce;
    buf[CRHBYTES + 1] = nonce >> 8;

    asm volatile ("csrw 0x816, %0" :: "rK"(CRHBYTES + 2)); // CSR_KECCAK_INLEN
    asm volatile ("csrw 0x817, %0" :: "rK"(1));

    shake256_absorb_once(buf, CRHBYTES + 2);
    shake256_squeezeblocks(buf, POLY_UNIFORM_GAMMA1_NBLOCKS);
    polyz_unpack(a, buf);
}

/*************************************************
 * Name:        challenge
 *
 * Description: Implementation of H. Samples polynomial with TAU nonzero
 *              coefficients in {-1,1} using the output stream of
 *              SHAKE256(seed).
 *
 * Arguments:   - poly *c: pointer to output polynomial
 *              - const uint8_t mu[]: byte array containing seed of length
 *SEEDBYTES
 **************************************************/
void poly_challenge(poly *c, const uint8_t seed[SEEDBYTES])
{
    unsigned int i, b, pos;
    uint64_t signs;
    uint8_t buf[SHAKE256_RATE];

    asm volatile ("csrw 0x816, %0" :: "rK"(SEEDBYTES)); // CSR_KECCAK_INLEN
    asm volatile ("csrw 0x817, %0" :: "rK"(1));

    shake256_absorb_once(seed, SEEDBYTES);
    shake256_squeezeblocks(buf, 1);

    signs = 0;
    for (i = 0; i < 8; ++i)
        signs |= (uint64_t)buf[i] << 8 * i;
    pos = 8;

    for (i = 0; i < N; ++i)
        c->coeffs[i] = 0;
    for (i = N - TAU; i < N; ++i) {
        do {
            if (pos >= SHAKE256_RATE) {
                shake256_squeezeblocks(buf, 1);
                pos = 0;
            }

            b = buf[pos++];
        } while (b > i);

        c->coeffs[i] = c->coeffs[b];
        c->coeffs[b] = 1 - 2 * (signs & 1);
        signs >>= 1;
    }
}

/*************************************************
 * Name:        polyeta_pack
 *
 * Description: Bit-pack polynomial with coefficients in [-ETA,ETA].
 *
 * Arguments:   - uint8_t *r: pointer to output byte array with at least
 *                            POLYETA_PACKEDBYTES bytes
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void polyeta_pack(uint8_t *r, const poly *a)
{
    unsigned int i;
    uint8_t t[8];
    DBENCH_START();

#if ETA == 2
    for (i = 0; i < N / 8; ++i) {
        t[0] = ETA - a->coeffs[8 * i + 0];
        t[1] = ETA - a->coeffs[8 * i + 1];
        t[2] = ETA - a->coeffs[8 * i + 2];
        t[3] = ETA - a->coeffs[8 * i + 3];
        t[4] = ETA - a->coeffs[8 * i + 4];
        t[5] = ETA - a->coeffs[8 * i + 5];
        t[6] = ETA - a->coeffs[8 * i + 6];
        t[7] = ETA - a->coeffs[8 * i + 7];

        r[3 * i + 0] = (t[0] >> 0) | (t[1] << 3) | (t[2] << 6);
        r[3 * i + 1] =
            (t[2] >> 2) | (t[3] << 1) | (t[4] << 4) | (t[5] << 7);
        r[3 * i + 2] = (t[5] >> 1) | (t[6] << 2) | (t[7] << 5);
    }
#elif ETA == 4
    for (i = 0; i < N / 2; ++i) {
        t[0] = ETA - a->coeffs[2 * i + 0];
        t[1] = ETA - a->coeffs[2 * i + 1];
        r[i] = t[0] | (t[1] << 4);
    }
#endif

    DBENCH_STOP(*tpack);
}

/*************************************************
 * Name:        polyeta_unpack
 *
 * Description: Unpack polynomial with coefficients in [-ETA,ETA].
 *
 * Arguments:   - poly *r: pointer to output polynomial
 *              - const uint8_t *a: byte array with bit-packed polynomial
 **************************************************/
void polyeta_unpack(poly *r, const uint8_t *a)
{
    unsigned int i;
    DBENCH_START();

#if ETA == 2
    for (i = 0; i < N / 8; ++i) {
        r->coeffs[8 * i + 0] = (a[3 * i + 0] >> 0) & 7;
        r->coeffs[8 * i + 1] = (a[3 * i + 0] >> 3) & 7;
        r->coeffs[8 * i + 2] =
            ((a[3 * i + 0] >> 6) | (a[3 * i + 1] << 2)) & 7;
        r->coeffs[8 * i + 3] = (a[3 * i + 1] >> 1) & 7;
        r->coeffs[8 * i + 4] = (a[3 * i + 1] >> 4) & 7;
        r->coeffs[8 * i + 5] =
            ((a[3 * i + 1] >> 7) | (a[3 * i + 2] << 1)) & 7;
        r->coeffs[8 * i + 6] = (a[3 * i + 2] >> 2) & 7;
        r->coeffs[8 * i + 7] = (a[3 * i + 2] >> 5) & 7;

        r->coeffs[8 * i + 0] = ETA - r->coeffs[8 * i + 0];
        r->coeffs[8 * i + 1] = ETA - r->coeffs[8 * i + 1];
        r->coeffs[8 * i + 2] = ETA - r->coeffs[8 * i + 2];
        r->coeffs[8 * i + 3] = ETA - r->coeffs[8 * i + 3];
        r->coeffs[8 * i + 4] = ETA - r->coeffs[8 * i + 4];
        r->coeffs[8 * i + 5] = ETA - r->coeffs[8 * i + 5];
        r->coeffs[8 * i + 6] = ETA - r->coeffs[8 * i + 6];
        r->coeffs[8 * i + 7] = ETA - r->coeffs[8 * i + 7];
    }
#elif ETA == 4
    for (i = 0; i < N / 2; ++i) {
        r->coeffs[2 * i + 0] = a[i] & 0x0F;
        r->coeffs[2 * i + 1] = a[i] >> 4;
        r->coeffs[2 * i + 0] = ETA - r->coeffs[2 * i + 0];
        r->coeffs[2 * i + 1] = ETA - r->coeffs[2 * i + 1];
    }
#endif

    DBENCH_STOP(*tpack);
}

/*************************************************
 * Name:        polyt1_pack
 *
 * Description: Bit-pack polynomial t1 with coefficients fitting in 10
 *bits. Input coefficients are assumed to be standard representatives.
 *
 * Arguments:   - uint8_t *r: pointer to output byte array with at least
 *                            POLYT1_PACKEDBYTES bytes
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void polyt1_pack(uint8_t *r, const poly *a)
{
    unsigned int i;
    DBENCH_START();

    for (i = 0; i < N / 4; ++i) {
        r[5 * i + 0] = (a->coeffs[4 * i + 0] >> 0);
        r[5 * i + 1] =
            (a->coeffs[4 * i + 0] >> 8) | (a->coeffs[4 * i + 1] << 2);
        r[5 * i + 2] =
            (a->coeffs[4 * i + 1] >> 6) | (a->coeffs[4 * i + 2] << 4);
        r[5 * i + 3] =
            (a->coeffs[4 * i + 2] >> 4) | (a->coeffs[4 * i + 3] << 6);
        r[5 * i + 4] = (a->coeffs[4 * i + 3] >> 2);
    }

    DBENCH_STOP(*tpack);
}

/*************************************************
 * Name:        polyt1_unpack
 *
 * Description: Unpack polynomial t1 with 10-bit coefficients.
 *              Output coefficients are standard representatives.
 *
 * Arguments:   - poly *r: pointer to output polynomial
 *              - const uint8_t *a: byte array with bit-packed polynomial
 **************************************************/
void polyt1_unpack(poly *r, const uint8_t *a)
{
    unsigned int i;
    DBENCH_START();

    for (i = 0; i < N / 4; ++i) {
        r->coeffs[4 * i + 0] =
            ((a[5 * i + 0] >> 0) | ((uint32_t)a[5 * i + 1] << 8)) & 0x3FF;
        r->coeffs[4 * i + 1] =
            ((a[5 * i + 1] >> 2) | ((uint32_t)a[5 * i + 2] << 6)) & 0x3FF;
        r->coeffs[4 * i + 2] =
            ((a[5 * i + 2] >> 4) | ((uint32_t)a[5 * i + 3] << 4)) & 0x3FF;
        r->coeffs[4 * i + 3] =
            ((a[5 * i + 3] >> 6) | ((uint32_t)a[5 * i + 4] << 2)) & 0x3FF;
    }

    DBENCH_STOP(*tpack);
}

/*************************************************
 * Name:        polyt0_pack
 *
 * Description: Bit-pack polynomial t0 with coefficients in ]-2^{D-1},
 *2^{D-1}].
 *
 * Arguments:   - uint8_t *r: pointer to output byte array with at least
 *                            POLYT0_PACKEDBYTES bytes
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void polyt0_pack(uint8_t *r, const poly *a)
{
    unsigned int i;
    uint32_t t[8];
    DBENCH_START();

    for (i = 0; i < N / 8; ++i) {
        t[0] = (1 << (D - 1)) - a->coeffs[8 * i + 0];
        t[1] = (1 << (D - 1)) - a->coeffs[8 * i + 1];
        t[2] = (1 << (D - 1)) - a->coeffs[8 * i + 2];
        t[3] = (1 << (D - 1)) - a->coeffs[8 * i + 3];
        t[4] = (1 << (D - 1)) - a->coeffs[8 * i + 4];
        t[5] = (1 << (D - 1)) - a->coeffs[8 * i + 5];
        t[6] = (1 << (D - 1)) - a->coeffs[8 * i + 6];
        t[7] = (1 << (D - 1)) - a->coeffs[8 * i + 7];

        r[13 * i + 0] = t[0];
        r[13 * i + 1] = t[0] >> 8;
        r[13 * i + 1] |= t[1] << 5;
        r[13 * i + 2] = t[1] >> 3;
        r[13 * i + 3] = t[1] >> 11;
        r[13 * i + 3] |= t[2] << 2;
        r[13 * i + 4] = t[2] >> 6;
        r[13 * i + 4] |= t[3] << 7;
        r[13 * i + 5] = t[3] >> 1;
        r[13 * i + 6] = t[3] >> 9;
        r[13 * i + 6] |= t[4] << 4;
        r[13 * i + 7] = t[4] >> 4;
        r[13 * i + 8] = t[4] >> 12;
        r[13 * i + 8] |= t[5] << 1;
        r[13 * i + 9] = t[5] >> 7;
        r[13 * i + 9] |= t[6] << 6;
        r[13 * i + 10] = t[6] >> 2;
        r[13 * i + 11] = t[6] >> 10;
        r[13 * i + 11] |= t[7] << 3;
        r[13 * i + 12] = t[7] >> 5;
    }

    DBENCH_STOP(*tpack);
}

/*************************************************
 * Name:        polyt0_unpack
 *
 * Description: Unpack polynomial t0 with coefficients in ]-2^{D-1},
 *2^{D-1}].
 *
 * Arguments:   - poly *r: pointer to output polynomial
 *              - const uint8_t *a: byte array with bit-packed polynomial
 **************************************************/
void polyt0_unpack(poly *r, const uint8_t *a)
{
    unsigned int i;
    DBENCH_START();

    for (i = 0; i < N / 8; ++i) {
        r->coeffs[8 * i + 0] = a[13 * i + 0];
        r->coeffs[8 * i + 0] |= (uint32_t)a[13 * i + 1] << 8;
        r->coeffs[8 * i + 0] &= 0x1FFF;

        r->coeffs[8 * i + 1] = a[13 * i + 1] >> 5;
        r->coeffs[8 * i + 1] |= (uint32_t)a[13 * i + 2] << 3;
        r->coeffs[8 * i + 1] |= (uint32_t)a[13 * i + 3] << 11;
        r->coeffs[8 * i + 1] &= 0x1FFF;

        r->coeffs[8 * i + 2] = a[13 * i + 3] >> 2;
        r->coeffs[8 * i + 2] |= (uint32_t)a[13 * i + 4] << 6;
        r->coeffs[8 * i + 2] &= 0x1FFF;

        r->coeffs[8 * i + 3] = a[13 * i + 4] >> 7;
        r->coeffs[8 * i + 3] |= (uint32_t)a[13 * i + 5] << 1;
        r->coeffs[8 * i + 3] |= (uint32_t)a[13 * i + 6] << 9;
        r->coeffs[8 * i + 3] &= 0x1FFF;

        r->coeffs[8 * i + 4] = a[13 * i + 6] >> 4;
        r->coeffs[8 * i + 4] |= (uint32_t)a[13 * i + 7] << 4;
        r->coeffs[8 * i + 4] |= (uint32_t)a[13 * i + 8] << 12;
        r->coeffs[8 * i + 4] &= 0x1FFF;

        r->coeffs[8 * i + 5] = a[13 * i + 8] >> 1;
        r->coeffs[8 * i + 5] |= (uint32_t)a[13 * i + 9] << 7;
        r->coeffs[8 * i + 5] &= 0x1FFF;

        r->coeffs[8 * i + 6] = a[13 * i + 9] >> 6;
        r->coeffs[8 * i + 6] |= (uint32_t)a[13 * i + 10] << 2;
        r->coeffs[8 * i + 6] |= (uint32_t)a[13 * i + 11] << 10;
        r->coeffs[8 * i + 6] &= 0x1FFF;

        r->coeffs[8 * i + 7] = a[13 * i + 11] >> 3;
        r->coeffs[8 * i + 7] |= (uint32_t)a[13 * i + 12] << 5;
        r->coeffs[8 * i + 7] &= 0x1FFF;

        r->coeffs[8 * i + 0] = (1 << (D - 1)) - r->coeffs[8 * i + 0];
        r->coeffs[8 * i + 1] = (1 << (D - 1)) - r->coeffs[8 * i + 1];
        r->coeffs[8 * i + 2] = (1 << (D - 1)) - r->coeffs[8 * i + 2];
        r->coeffs[8 * i + 3] = (1 << (D - 1)) - r->coeffs[8 * i + 3];
        r->coeffs[8 * i + 4] = (1 << (D - 1)) - r->coeffs[8 * i + 4];
        r->coeffs[8 * i + 5] = (1 << (D - 1)) - r->coeffs[8 * i + 5];
        r->coeffs[8 * i + 6] = (1 << (D - 1)) - r->coeffs[8 * i + 6];
        r->coeffs[8 * i + 7] = (1 << (D - 1)) - r->coeffs[8 * i + 7];
    }

    DBENCH_STOP(*tpack);
}

/*************************************************
 * Name:        polyz_pack
 *
 * Description: Bit-pack polynomial with coefficients
 *              in [-(GAMMA1 - 1), GAMMA1].
 *
 * Arguments:   - uint8_t *r: pointer to output byte array with at least
 *                            POLYZ_PACKEDBYTES bytes
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void polyz_pack(uint8_t *r, const poly *a)
{
    unsigned int i;
    uint32_t t[4];
    DBENCH_START();

#if GAMMA1 == (1 << 17)
    for (i = 0; i < N / 4; ++i) {
        t[0] = GAMMA1 - a->coeffs[4 * i + 0];
        t[1] = GAMMA1 - a->coeffs[4 * i + 1];
        t[2] = GAMMA1 - a->coeffs[4 * i + 2];
        t[3] = GAMMA1 - a->coeffs[4 * i + 3];

        r[9 * i + 0] = t[0];
        r[9 * i + 1] = t[0] >> 8;
        r[9 * i + 2] = t[0] >> 16;
        r[9 * i + 2] |= t[1] << 2;
        r[9 * i + 3] = t[1] >> 6;
        r[9 * i + 4] = t[1] >> 14;
        r[9 * i + 4] |= t[2] << 4;
        r[9 * i + 5] = t[2] >> 4;
        r[9 * i + 6] = t[2] >> 12;
        r[9 * i + 6] |= t[3] << 6;
        r[9 * i + 7] = t[3] >> 2;
        r[9 * i + 8] = t[3] >> 10;
    }
#elif GAMMA1 == (1 << 19)
    for (i = 0; i < N / 2; ++i) {
        t[0] = GAMMA1 - a->coeffs[2 * i + 0];
        t[1] = GAMMA1 - a->coeffs[2 * i + 1];

        r[5 * i + 0] = t[0];
        r[5 * i + 1] = t[0] >> 8;
        r[5 * i + 2] = t[0] >> 16;
        r[5 * i + 2] |= t[1] << 4;
        r[5 * i + 3] = t[1] >> 4;
        r[5 * i + 4] = t[1] >> 12;
    }
#endif

    DBENCH_STOP(*tpack);
}

/*************************************************
 * Name:        polyz_unpack
 *
 * Description: Unpack polynomial z with coefficients
 *              in [-(GAMMA1 - 1), GAMMA1].
 *
 * Arguments:   - poly *r: pointer to output polynomial
 *              - const uint8_t *a: byte array with bit-packed polynomial
 **************************************************/
void polyz_unpack(poly *r, const uint8_t *a)
{
    unsigned int i;
    DBENCH_START();

#if GAMMA1 == (1 << 17)
    for (i = 0; i < N / 4; ++i) {
        r->coeffs[4 * i + 0] = a[9 * i + 0];
        r->coeffs[4 * i + 0] |= (uint32_t)a[9 * i + 1] << 8;
        r->coeffs[4 * i + 0] |= (uint32_t)a[9 * i + 2] << 16;
        r->coeffs[4 * i + 0] &= 0x3FFFF;

        r->coeffs[4 * i + 1] = a[9 * i + 2] >> 2;
        r->coeffs[4 * i + 1] |= (uint32_t)a[9 * i + 3] << 6;
        r->coeffs[4 * i + 1] |= (uint32_t)a[9 * i + 4] << 14;
        r->coeffs[4 * i + 1] &= 0x3FFFF;

        r->coeffs[4 * i + 2] = a[9 * i + 4] >> 4;
        r->coeffs[4 * i + 2] |= (uint32_t)a[9 * i + 5] << 4;
        r->coeffs[4 * i + 2] |= (uint32_t)a[9 * i + 6] << 12;
        r->coeffs[4 * i + 2] &= 0x3FFFF;

        r->coeffs[4 * i + 3] = a[9 * i + 6] >> 6;
        r->coeffs[4 * i + 3] |= (uint32_t)a[9 * i + 7] << 2;
        r->coeffs[4 * i + 3] |= (uint32_t)a[9 * i + 8] << 10;
        r->coeffs[4 * i + 3] &= 0x3FFFF;

        r->coeffs[4 * i + 0] = GAMMA1 - r->coeffs[4 * i + 0];
        r->coeffs[4 * i + 1] = GAMMA1 - r->coeffs[4 * i + 1];
        r->coeffs[4 * i + 2] = GAMMA1 - r->coeffs[4 * i + 2];
        r->coeffs[4 * i + 3] = GAMMA1 - r->coeffs[4 * i + 3];
    }
#elif GAMMA1 == (1 << 19)
    for (i = 0; i < N / 2; ++i) {
        r->coeffs[2 * i + 0] = a[5 * i + 0];
        r->coeffs[2 * i + 0] |= (uint32_t)a[5 * i + 1] << 8;
        r->coeffs[2 * i + 0] |= (uint32_t)a[5 * i + 2] << 16;
        r->coeffs[2 * i + 0] &= 0xFFFFF;

        r->coeffs[2 * i + 1] = a[5 * i + 2] >> 4;
        r->coeffs[2 * i + 1] |= (uint32_t)a[5 * i + 3] << 4;
        r->coeffs[2 * i + 1] |= (uint32_t)a[5 * i + 4] << 12;
        r->coeffs[2 * i + 0] &= 0xFFFFF;

        r->coeffs[2 * i + 0] = GAMMA1 - r->coeffs[2 * i + 0];
        r->coeffs[2 * i + 1] = GAMMA1 - r->coeffs[2 * i + 1];
    }
#endif

    DBENCH_STOP(*tpack);
}

/*************************************************
 * Name:        polyw1_pack
 *
 * Description: Bit-pack polynomial w1 with coefficients in [0,15] or
 *[0,43]. Input coefficients are assumed to be standard representatives.
 *
 * Arguments:   - uint8_t *r: pointer to output byte array with at least
 *                            POLYW1_PACKEDBYTES bytes
 *              - const poly *a: pointer to input polynomial
 **************************************************/
void polyw1_pack(uint8_t *r, const poly *a)
{
    unsigned int i;
    DBENCH_START();

#if GAMMA2 == (Q - 1) / 88
    for (i = 0; i < N / 4; ++i) {
        r[3 * i + 0] = a->coeffs[4 * i + 0];
        r[3 * i + 0] |= a->coeffs[4 * i + 1] << 6;
        r[3 * i + 1] = a->coeffs[4 * i + 1] >> 2;
        r[3 * i + 1] |= a->coeffs[4 * i + 2] << 4;
        r[3 * i + 2] = a->coeffs[4 * i + 2] >> 4;
        r[3 * i + 2] |= a->coeffs[4 * i + 3] << 2;
    }
#elif GAMMA2 == (Q - 1) / 32
    for (i = 0; i < N / 2; ++i)
        r[i] = a->coeffs[2 * i + 0] | (a->coeffs[2 * i + 1] << 4);
#endif

    DBENCH_STOP(*tpack);
}

/*************************************************
 * Name:        poly_ntt
 *
 * Description: Inplace forward NTT. Coefficients can grow by
 *              8*Q in absolute value.
 *
 * Arguments:   - poly *a: pointer to input/output polynomial
 **************************************************/
void poly_ntt(poly *a)
{
    DBENCH_START();

    ntt(a->coeffs);

    DBENCH_STOP(*tmul);
}

/*************************************************
 * Name:        poly_intt
 *
 * Description: Inplace inverse NTT and multiplication by 2^{32}.
 *              Input coefficients need to be less than Q in absolute
 *              value and output coefficients are again bounded by Q.
 *
 * Arguments:   - poly *a: pointer to input/output polynomial
 **************************************************/
void poly_intt(poly *a)
{
    DBENCH_START();

    intt(a->coeffs);

    DBENCH_STOP(*tmul);
}

#if defined(VECTOR128)

void poly_reduce(poly *a)
{
    DBENCH_START();
    poly_reduce_rvv(a->coeffs);
    DBENCH_STOP(*tred);
}

void poly_pointwise(poly *c, const poly *a, const poly *b)
{
    DBENCH_START();
    poly_basemul_8l_rvv(c->coeffs, a->coeffs, b->coeffs);
    DBENCH_STOP(*tmul);
}

void poly_pointwise_acc(poly *c, const poly *a, const poly *b)
{
    poly_basemul_acc_8l_rvv(c->coeffs, a->coeffs, b->coeffs);
}

#elif defined(RV64)

void poly_reduce(poly *a)
{
    DBENCH_START();
    poly_reduce_rv64im(a->coeffs);
    DBENCH_STOP(*tred);
}

void poly_basemul_init(poly_double *r, const poly *a, const poly *b)
{
    poly_basemul_8l_init_rv64im(r->coeffs, a->coeffs, b->coeffs);
}

void poly_basemul_acc(poly_double *r, const poly *a, const poly *b)
{
    poly_basemul_8l_acc_rv64im(r->coeffs, a->coeffs, b->coeffs);
}

void poly_basemul_acc_end(poly *r, const poly *a, const poly *b,
                          poly_double *r_double)
{
    poly_basemul_8l_acc_end_rv64im(r->coeffs, a->coeffs, b->coeffs,
                                   r_double->coeffs);
}

void poly_pointwise(poly *c, const poly *a, const poly *b)
{
    DBENCH_START();
    poly_basemul_8l_rv64im(c->coeffs, a->coeffs, b->coeffs);
    DBENCH_STOP(*tmul);
}

#else
    void poly_reduce(poly *a)
    {
        unsigned int i;
        DBENCH_START();

        for (i = 0; i < N; ++i)
            a->coeffs[i] = reduce32(a->coeffs[i]);

        DBENCH_STOP(*tred);
    }

#endif
