#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "cpu_perf.h"
#include "indcpa.h"
#include "kem.h"
#include "ntt.h"
#include "params.h"
#include "poly.h"
#include "polyvec.h"
#include "print_metric.h"
#include "sdv_env.h"
#include "symmetric.h"

#define NTESTS 1000

#ifdef FPGA
#    include <uart.h>
#    define CLK_SYS_FREQ 25000000
#    define BAUDRATE 115200
#    define UART_INIT() uart_init(CLK_SYS_FREQ, BAUDRATE);
#else
#    define UART_INIT() ;
#endif

#ifdef LINUX
    #define CPU_PERF_START(i) ;
    #define CPU_PERF_END(i) ;
    #define PRINT_ONE() ;
    #define PRINT_MEDIAN() ;
    #define PRINT_AVG() ;
#else
    #define CPU_PERF_START(i) set_checkpoint_start(&tests[i]);
    #define CPU_PERF_END(i) set_checkpoint_end(&tests[i]);
    #define PRINT_ONE() print_one(&tests[0]);
    #define PRINT_MEDIAN() print_median(tests, NTESTS);
    #define PRINT_AVG() print_average(tests, NTESTS);
    #define PRINT_ALL_MEDIAN() print_all_median(tests, NTESTS);
#endif

checkpoint_t tests[NTESTS];
uint8_t seed[KYBER_SYMBYTES] = {0};

int main()
{
    unsigned int i;
    uint8_t pk[CRYPTO_PUBLICKEYBYTES];
    uint8_t sk[CRYPTO_SECRETKEYBYTES];
    uint8_t ct[CRYPTO_CIPHERTEXTBYTES];
    uint8_t key[CRYPTO_BYTES];
    uint8_t buf[2 * KYBER_SYMBYTES];
    uint8_t kr[2 * KYBER_SYMBYTES];
    uint8_t ss[KYBER_SSBYTES];
    polyvec matrix[KYBER_K], pkpv, skpv;
    poly ap;
    polyvec *a = matrix;

    UART_INIT();

    printf("**************************************\n");
#if defined(VECTOR128)
    printf("****** Kyber Vector Speed Test *******\n");
#elif defined(BITMAN)
    printf("****** Kyber Bit Manipulation Speed Test *******\n");
#elif defined(RV32) || defined(RV64)
    printf("****** Kyber Scalar Optimized Speed Test *******\n");
#else
    printf("****** Kyber Reference Speed Test *******\n");
#endif
    printf("**************************************\n");

#if (KYBER_K == 2)
    printf("Test speed of Kyber512\n");
#elif (KYBER_K == 3)
    printf("Test speed of Kyber768\n");
#elif (KYBER_K == 4)
    printf("Test speed of Kyber1024\n");
#else
#    error "KYBER_K must be in {2,3,4}"
#endif

    TRACE_NAME();
    TRACE_INIT();
    TRACE_DISABLE();

    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        gen_matrix(matrix, seed, 0);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("gen_a:\n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_getnoise_eta1(&ap, seed, 0);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("poly_getnoise_eta1: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_getnoise_eta2(&ap, seed, 0);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("poly_getnoise_eta2: \n");
    PRINT_MEDIAN();
    // ap variable copies
    poly ap_poly_ntt, ap_poly_invntt, ap_ntt, ap_invntt;
    memcpy(&ap_poly_ntt, &ap, sizeof(ap));
    memcpy(&ap_poly_invntt, &ap, sizeof(ap));
    memcpy(&ap_ntt, &ap, sizeof(ap));
    memcpy(&ap_invntt, &ap, sizeof(ap));
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_ntt(&ap_poly_ntt);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("Poly NTT: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_intt(&ap_poly_invntt);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("Poly INVNTT: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        ntt(ap_ntt.coeffs);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("NTT: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        invntt(ap_invntt.coeffs);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("INVNTT: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/

#if defined(VECTOR128)
    poly_half b_cache;
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_basemul_acc(&ap, &matrix[0].vec[0], &matrix[1].vec[0]);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("poly_basemul_acc: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_basemul_acc_cache_init(&ap, &matrix[0].vec[0],
                                    &matrix[1].vec[0], &b_cache);
        CPU_PERF_END(i);
    }
    printf("poly_basemul_acc_cache_init: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_basemul_cached(&ap, &matrix[0].vec[0], &matrix[1].vec[0],
                            &b_cache);
        CPU_PERF_END(i);
    }
    printf("poly_basemul_cached: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_basemul_acc_cached(&ap, &matrix[0].vec[0], &matrix[1].vec[0],
                                &b_cache);
        CPU_PERF_END(i);
    }
    printf("poly_basemul_acc_cached: \n");
    PRINT_MEDIAN();
/******************************************************************************************/
#elif !defined(REF_IMPL) && (defined(RV32) || defined(RV64))
    TRACE_ENABLE();

    TRACE_EVENT();
    poly_double r_double;
    poly_half b_cache;
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_basemul_acc_cache_init(&r_double, &matrix[0].vec[0],
                                    &matrix[1].vec[0], &b_cache);
        CPU_PERF_END(i);
    }
    printf("poly_basemul_acc_cache_init: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_basemul_acc_cached(&r_double, &matrix[0].vec[0],
                                &matrix[1].vec[0], &b_cache);
        CPU_PERF_END(i);
    }
    printf("poly_basemul_acc_cached: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_basemul_acc_cache_end(&ap, &matrix[0].vec[0],
                                   &matrix[1].vec[0], &b_cache, &r_double);
        CPU_PERF_END(i);
    }
    printf("poly_basemul_acc_cache_end: \n");
    PRINT_MEDIAN();
/******************************************************************************************/
#else
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_basemul(&ap, &matrix[0].vec[0], &matrix[1].vec[0]);
        CPU_PERF_END(i);
    }
    printf("poly_basemul: \n");
    PRINT_MEDIAN();
/******************************************************************************************/
#endif

    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        polyvec_basemul_acc(&ap, &matrix[0], &matrix[1]);
        CPU_PERF_END(i);
    }
    printf("polyvec_basemul_acc: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/

#if defined(VECTOR128) || defined(RV32)
    polyvec_half skpv_cache;
#endif
    TRACE_ENABLE();

    TRACE_EVENT();
    // matrix-vector mul
    for (int j = 0; j < NTESTS; j++) {
        CPU_PERF_START(j);
#if defined(VECTOR128) || defined(RV32)
        polyvec_basemul_acc_cache_init(&pkpv.vec[0], &a[0], &skpv,
                                       &skpv_cache);
        for (i = 1; i < KYBER_K; i++) {
            polyvec_basemul_acc_cached(&pkpv.vec[i], &a[i], &skpv,
                                       &skpv_cache);
        }
        CPU_PERF_END(j);
#else
        for (i = 0; i < KYBER_K; i++) {
            polyvec_basemul_acc(&pkpv.vec[i], &a[i], &skpv);
        }
        CPU_PERF_END(j);
#endif
    }
    printf("matrix-vector mul: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/

#if defined(VECTOR128) || defined(RV32)
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        polyvec_basemul_acc_cached(&ap, &pkpv, &skpv, &skpv_cache);
        CPU_PERF_END(i);
    }
    printf("polyvec_basemul_acc_cached: \n");
    PRINT_MEDIAN();
#endif

    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_tomsg(ct, &ap);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("poly_tomsg: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_frommsg(&ap, ct);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("poly_frommsg: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_compress(ct, &ap);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("poly_compress: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_decompress(&ap, ct);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("poly_decompress: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        polyvec_compress(ct, &matrix[0]);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("polyvec_compress: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        polyvec_decompress(&matrix[0], ct);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("polyvec_decompress: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        indcpa_keypair(pk, sk);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("indcpa_keypair: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        indcpa_enc(ct, key, pk, seed);
        CPU_PERF_END(i);
    }
    printf("indcpa_enc: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        indcpa_dec(key, ct, sk);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("indcpa_dec: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        hash_h(buf + KYBER_SYMBYTES, pk,
               KYBER_PUBLICKEYBYTES);  // m||H(pk)
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("hash_h: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        hash_g(kr, buf, 2 * KYBER_SYMBYTES);  // (K,r)
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("hash_g: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    // TRACE_ENABLE();

    // TRACE_EVENT(20);
    // for(i=0;i<NTESTS;i++) {
    //     CPU_PERF_START(i);
    //     rkprf(ss,sk+KYBER_SECRETKEYBYTES-KYBER_SYMBYTES,ct);
    // CPU_PERF_END(i);
    // }
    // TRACE_EVENT_ZERO();

    // TRACE_DISABLE();
    // printf("shake256_rkprf: \n");
    // PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        crypto_kem_keypair(pk, sk);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("kyber_keypair: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        crypto_kem_enc(ct, key, pk);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("kyber_encaps: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        crypto_kem_dec(key, ct, sk);
        CPU_PERF_END(i);
    }
    TRACE_EVENT_ZERO();

    TRACE_DISABLE();
    printf("kyber_decaps: \n");
    PRINT_MEDIAN();
    /******************************************************************************************/

    // printf("Total Events: %d\n", trace_count);
    printf("\nDONE\n");

#ifdef FPGA
    exit(0);
#endif

    return 0;
}
