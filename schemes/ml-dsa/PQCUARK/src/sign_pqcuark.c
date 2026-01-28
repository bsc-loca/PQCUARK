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

#include "sign.h"

#include <stdint.h>

#include "fips202_pqcuark.h"
#include "packing.h"
#include "params.h"
#include "poly.h"
#include "polyvec.h"
#include "randombytes.h"

/*************************************************
 * Name:        crypto_sign_keypair
 *
 * Description: Generates public and private key.
 *
 * Arguments:   - uint8_t *pk: pointer to output public key (allocated
 *                             array of CRYPTO_PUBLICKEYBYTES bytes)
 *              - uint8_t *sk: pointer to output private key (allocated
 *                             array of CRYPTO_SECRETKEYBYTES bytes)
 *
 * Returns 0 (success)
 **************************************************/
int crypto_sign_keypair(uint8_t *pk, uint8_t *sk)
{
    uint8_t seedbuf[2 * SEEDBYTES + CRHBYTES];
    uint8_t tr[SEEDBYTES];
    const uint8_t *rho, *rhoprime, *key;
    polyvecl mat[K];
    polyvecl s1, s1hat;
    polyveck s2, t1, t0;

    /* Get randomness for rho, rhoprime and key */
    seed_randombytes(seedbuf, SEEDBYTES,123);
    // printf("seedbuf: ");
    // for (size_t i = 0; i < SEEDBYTES; ++i) {
    //     printf("%02x", seedbuf[i]);
    // }
    // printf("\n");
    shake256(seedbuf, 2 * SEEDBYTES + CRHBYTES, seedbuf, SEEDBYTES);
     
    rho = seedbuf;
    rhoprime = rho + SEEDBYTES;
    key = rhoprime + CRHBYTES;

    /* Expand matrix */
    polyvec_matrix_expand(mat, rho);

    /* Sample short vectors s1 and s2 */
    polyveclk_uniform_eta(&s1, &s2, rhoprime, 0, L);

    /* Matrix-vector multiplication */
    // s1hat = s1;
    memcpy(&s1hat, &s1, sizeof(polyvecl));
    polyvecl_ntt(&s1hat);
    polyvec_matrix_pointwise(&t1, mat, &s1hat);
    polyveck_intt(&t1);
    
    // printf("s2: ");
    // for (int i = 0; i < K; ++i) {
    //     printf("%d ", s2.vec[i].coeffs[0]);
    // }
    // printf("\n");
    // printf("s1: ");
    // for (int i = 0; i < L; ++i) {
    //     printf("%d ", s1.vec[i].coeffs[0]);
    // }
    // printf("\n");
    // printf("s1hat: ");
    // for (int i = 0; i < L; ++i) {
    //     printf("%d ", s1hat.vec[i].coeffs[0]);
    // }
    // printf("\n");

    /* Add error vector s2 */
    polyveck_add(&t1, &t1, &s2);

    

    /* Extract t1 and write public key */
    polyveck_caddq(&t1);
    polyveck_power2round(&t1, &t0, &t1);
    pack_pk(pk, rho, &t1);

    /* Compute H(rho, t1) and write secret key */
    // printf("pk: ");
    // for (size_t i = 0; i < CRYPTO_PUBLICKEYBYTES; ++i) {
    //     printf("%02x", pk[i]);
    // }   
    // printf("\n");
    // printf("SEEDBYTES: %d\n", SEEDBYTES);
    shake256(tr, SEEDBYTES, pk, CRYPTO_PUBLICKEYBYTES);
    // printf("tr: ");
    // for (size_t i = 0; i < SEEDBYTES; ++i) {
    //     printf("%02x", tr[i]);
    // }
    // printf("\n");
    pack_sk(sk, rho, tr, key, &t0, &s1, &s2);

    
    return 0;
}

/*************************************************
 * Name:        crypto_sign_signature
 *
 * Description: Computes signature.
 *
 * Arguments:   - uint8_t *sig:   pointer to output signature (of length
 *CRYPTO_BYTES)
 *              - size_t *siglen: pointer to output length of signature
 *              - uint8_t *m:     pointer to message to be signed
 *              - size_t mlen:    length of message
 *              - uint8_t *sk:    pointer to bit-packed secret key
 *
 * Returns 0 (success)
 **************************************************/
int crypto_sign_signature(uint8_t *sig, size_t *siglen, const uint8_t *m,
                          size_t mlen, const uint8_t *sk)
{
    unsigned int n, pos;
    uint8_t seedbuf[3 * SEEDBYTES + 2 * CRHBYTES];
    uint8_t *rho, *tr, *key, *mu, *rhoprime;
    uint16_t nonce = 0;
    polyvecl mat[K], s1, y, z;
    polyveck t0, s2, w1, w0, h;
    poly cp;

#if defined(DILITHIUM_COUNT_REJ_NUM)
    uint32_t rej_num = -1;
#endif

    // printf("message: ");
    // for (size_t i = 0; i < mlen; ++i) {
    //     printf("%02x", m[i]);
    // }
    // printf("\n");
    // printf("mlen: %d\n", mlen);
    // printf ("sk: ");
    // for (size_t i = 0; i < CRYPTO_SECRETKEYBYTES; ++i) {
    //     printf("%02x", sk[i]);
    // }
    // printf("\n");
    rho = seedbuf;
    tr = rho + SEEDBYTES;
    key = tr + SEEDBYTES;
    mu = key + SEEDBYTES;
    rhoprime = mu + CRHBYTES;
    unpack_sk(rho, tr, key, &t0, &s1, &s2, sk);

    asm volatile ("csrw 0x816, %0" :: "rK"(SEEDBYTES+mlen)); // CSR_KECCAK_INLEN
    asm volatile ("csrw 0x817, %0" :: "rK"(1));

    /* Compute CRH(tr, msg) */
    shake256_init();
    pos = 0;
    // printf("tr: ");
    // for (size_t i = 0; i < SEEDBYTES; ++i) {
    //     printf("%02x", tr[i]);
    // }
    // printf("\n");
    shake256_absorb(&pos, tr, SEEDBYTES);
    // printf("m: ");
    // for (size_t i = 0; i < mlen; ++i) {
    //     printf("%02x", m[i]);
    // }
    // printf("\n");
    uint8_t m_aligned[mlen] __attribute__((aligned(8)));
    memcpy(m_aligned, m, mlen);
    // printf("m_aligned = %p\n", m_aligned);
    // if (((uintptr_t)m_aligned) % 8 != 0) {
    //     printf("m_aligned NO está alineado\n");
    // } else {
    //     printf("m_aligned está alineado\n");
    // }

    shake256_absorb(&pos ,m_aligned, mlen);
    // shake256_absorb(m, mlen);
    shake256_squeeze(mu, CRHBYTES);

#ifdef DILITHIUM_RANDOMIZED_SIGNING
    randombytes(rhoprime, CRHBYTES);
#else
    shake256(rhoprime, CRHBYTES, key, SEEDBYTES + CRHBYTES);
#endif

    /* Expand matrix and transform vectors */
    polyvec_matrix_expand(mat, rho);
    polyvecl_ntt(&s1);
    polyveck_ntt(&s2);
    polyveck_ntt(&t0);

rej:
#if defined(DILITHIUM_COUNT_REJ_NUM)
    rej_num++;
#endif
    /* Sample intermediate vector y */
    polyvecl_uniform_gamma1(&y, rhoprime, nonce++);

    /* Matrix-vector multiplication */
    // z = y;
    memcpy(&z, &y, sizeof(polyvecl));
    polyvecl_ntt(&z);
    polyvec_matrix_pointwise(&w1, mat, &z);
    polyveck_intt(&w1);

    /* Decompose w and call the random oracle */
    polyveck_caddq(&w1);
    polyveck_decompose(&w1, &w0, &w1);
    polyveck_pack_w1(sig, &w1);

    asm volatile ("csrw 0x816, %0" :: "rK"(CRHBYTES+(K*POLYW1_PACKEDBYTES))); // CSR_KECCAK_INLEN
    asm volatile ("csrw 0x817, %0" :: "rK"(1));

    shake256_init();
    pos = 0;
    //printf("hola\n");
    shake256_absorb(&pos, mu, CRHBYTES);
    shake256_absorb(&pos, sig, K * POLYW1_PACKEDBYTES);
    //printf("adeu\n");
    shake256_squeeze(sig, SEEDBYTES);
    poly_challenge(&cp, sig);
    poly_ntt(&cp);

    /* Compute z, reject if it reveals secret */
    polyvecl_pointwise_poly(&z, &cp, &s1);
    polyvecl_intt(&z);
    polyvecl_add(&z, &z, &y);
    polyvecl_reduce(&z);
    if (polyvecl_chknorm(&z, GAMMA1 - BETA))
        goto rej;

    /* Check that subtracting cs2 does not change high bits of w and low
     * bits do not reveal secret information */
    polyveck_pointwise_poly(&h, &cp, &s2);
    polyveck_intt(&h);
    polyveck_sub(&w0, &w0, &h);
    polyveck_reduce(&w0);
    if (polyveck_chknorm(&w0, GAMMA2 - BETA))
        goto rej;

    //printf("hey\n");
    /* Compute hints for w1 */
    polyveck_pointwise_poly(&h, &cp, &t0);
    polyveck_intt(&h);
    polyveck_reduce(&h);
    if (polyveck_chknorm(&h, GAMMA2))
        goto rej;

    polyveck_add(&w0, &w0, &h);
    n = polyveck_make_hint(&h, &w0, &w1);
    if (n > OMEGA)
        goto rej;

    /* Write signature */
    pack_sig(sig, sig, &z, &h);
    *siglen = CRYPTO_BYTES;
    //printf("se acaba\n");
#if defined(DILITHIUM_COUNT_REJ_NUM)
    return rej_num;
#endif
    return 0;
}

/*************************************************
 * Name:        crypto_sign
 *
 * Description: Compute signed message.
 *
 * Arguments:   - uint8_t *sm: pointer to output signed message (allocated
 *                             array with CRYPTO_BYTES + mlen bytes),
 *                             can be equal to m
 *              - size_t *smlen: pointer to output length of signed
 *                               message
 *              - const uint8_t *m: pointer to message to be signed
 *              - size_t mlen: length of message
 *              - const uint8_t *sk: pointer to bit-packed secret key
 *
 * Returns 0 (success)
 **************************************************/
int crypto_sign(uint8_t *sm, size_t *smlen, const uint8_t *m, size_t mlen,
                const uint8_t *sk)
{
    size_t i;

    for (i = 0; i < mlen; ++i)
        sm[CRYPTO_BYTES + mlen - 1 - i] = m[mlen - 1 - i];

    crypto_sign_signature(sm, smlen, sm + CRYPTO_BYTES, mlen, sk);
    *smlen += mlen;
    return 0;
}

/*************************************************
 * Name:        crypto_sign_verify
 *
 * Description: Verifies signature.
 *
 * Arguments:   - uint8_t *m: pointer to input signature
 *              - size_t siglen: length of signature
 *              - const uint8_t *m: pointer to message
 *              - size_t mlen: length of message
 *              - const uint8_t *pk: pointer to bit-packed public key
 *
 * Returns 0 if signature could be verified correctly and -1 otherwise
 **************************************************/
int crypto_sign_verify(const uint8_t *sig, size_t siglen, const uint8_t *m,
                       size_t mlen, const uint8_t *pk)
{
    unsigned int i, pos;
    uint8_t buf[K * POLYW1_PACKEDBYTES];
    uint8_t rho[SEEDBYTES];
    uint8_t mu[CRHBYTES];
    uint8_t c[SEEDBYTES];
    uint8_t c2[SEEDBYTES];
    poly cp;
    polyvecl mat[K], z;
    polyveck t1, w1, h;

    if (siglen != CRYPTO_BYTES)
        return -1;

    unpack_pk(rho, &t1, pk);
    if (unpack_sig(c, &z, &h, sig))
        return -1;
    if (polyvecl_chknorm(&z, GAMMA1 - BETA))
        return -1;

    /* Compute CRH(H(rho, t1), msg) */
    // printf("pk: ");
    // for (size_t i = 0; i < CRYPTO_PUBLICKEYBYTES; ++i) {
    //     printf("%02x", pk[i]);
    // }
    // printf("\n");
    shake256(mu, SEEDBYTES, pk, CRYPTO_PUBLICKEYBYTES);

    asm volatile ("csrw 0x816, %0" :: "rK"(SEEDBYTES+mlen)); // CSR_KECCAK_INLEN
    asm volatile ("csrw 0x817, %0" :: "rK"(1));

    shake256_init();
    pos = 0;
    // printf("mu: ");
    // for (size_t i = 0; i < SEEDBYTES; ++i) {
    //     printf("%02x", mu[i]);
    // }
    // printf("\n");
    shake256_absorb(&pos, mu, SEEDBYTES);
    // printf("m: ");
    // for (size_t i = 0; i < mlen; ++i) {
    //     printf("%02x", m[i]);
    // }
    // printf("\n");
    uint8_t m_aligned[mlen] __attribute__((aligned(8)));
    memcpy(m_aligned, m, mlen);
    //printf("m_aligned = %p\n", m_aligned);
    // if (((uintptr_t)m_aligned) % 8 != 0) {
    //     printf("m_aligned NO está alineado\n");
    // } else {
    //     printf("m_aligned está alineado\n");
    // }

    shake256_absorb(&pos, m_aligned, mlen);
    //shake256_absorb(m, mlen);
    shake256_squeeze(mu, CRHBYTES);

    /* Matrix-vector multiplication; compute Az - c2^dt1 */
    
    poly_challenge(&cp, c);
    /////////////////////////// !!!!!!!!!!!!!!!!!!!1
    polyvec_matrix_expand(mat, rho);

    polyvecl_ntt(&z);
    polyvec_matrix_pointwise(&w1, mat, &z);

    poly_ntt(&cp);
    polyveck_shiftl(&t1);
    polyveck_ntt(&t1);
    polyveck_pointwise_poly(&t1, &cp, &t1);

    polyveck_sub(&w1, &w1, &t1);
    polyveck_reduce(&w1);
    polyveck_intt(&w1);

    /* Reconstruct w1 */
    polyveck_caddq(&w1);
    polyveck_use_hint(&w1, &w1, &h);
    polyveck_pack_w1(buf, &w1);

    //printf("Len: %d\n", CRHBYTES+(POLYW1_PACKEDBYTES*K));
    asm volatile ("csrw 0x816, %0" :: "rK"(CRHBYTES+(POLYW1_PACKEDBYTES*K))); // CSR_KECCAK_INLEN
    asm volatile ("csrw 0x817, %0" :: "rK"(1));

    /* Call random oracle and verify challenge */
    shake256_init();
    pos = 0;
    // printf("mu: ");
    // for (size_t i = 0; i < CRHBYTES; ++i) {
    //     printf("%02x", mu[i]);
    //     if (i % 7 == 0) {
    //         printf("\n");
    //     }
    // }
    // printf("\n");
    shake256_absorb(&pos, mu, CRHBYTES);
    // printf("buf: ");
    // for (size_t i = 0; i < K * POLYW1_PACKEDBYTES; ++i) {
    //     printf("%02x", buf[(K * POLYW1_PACKEDBYTES)-i-1]);
    // }
    shake256_absorb(&pos, buf, K * POLYW1_PACKEDBYTES);
    // printf("squeeze\n");
    shake256_squeeze(c2, SEEDBYTES);
    for (i = 0; i < SEEDBYTES; ++i)
        if (c[i] != c2[i])
            return -1;

    return 0;
}

/*************************************************
 * Name:        crypto_sign_open
 *
 * Description: Verify signed message.
 *
 * Arguments:   - uint8_t *m: pointer to output message (allocated
 *                            array with smlen bytes), can be equal to sm
 *              - size_t *mlen: pointer to output length of message
 *              - const uint8_t *sm: pointer to signed message
 *              - size_t smlen: length of signed message
 *              - const uint8_t *pk: pointer to bit-packed public key
 *
 * Returns 0 if signed message could be verified correctly and -1 otherwise
 **************************************************/
int crypto_sign_open(uint8_t *m, size_t *mlen, const uint8_t *sm,
                     size_t smlen, const uint8_t *pk)
{
    size_t i;

    //printf("crypto sign open\n");

    if (smlen < CRYPTO_BYTES)
        goto badsig;

    *mlen = smlen - CRYPTO_BYTES;
    if (crypto_sign_verify(sm, CRYPTO_BYTES, sm + CRYPTO_BYTES, *mlen, pk)) {
        printf("Signature verification failed\n");
        goto badsig;
    }
    else {  
        printf("Signature verification succeeded\n");
        /* All good, copy msg, return 0 */
        for (i = 0; i < *mlen; ++i)
            m[i] = sm[CRYPTO_BYTES + i];
        return 0;
    }

badsig:
    /* Signature verification failed */
    *mlen = -1;
    for (i = 0; i < smlen; ++i)
        m[i] = 0;

    return -1;
}
