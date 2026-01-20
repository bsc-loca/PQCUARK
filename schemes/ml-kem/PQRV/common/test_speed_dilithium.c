#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "cpu_perf.h"
#include "params.h"
#include "poly.h"
#include "polyvec.h"
#include "sign.h"
#include "print_metric.h"

#define NTESTS 100 

#ifdef FPGA
  #include <uart.h>
  #define CLK_SYS_FREQ 25000000
  #define BAUDRATE 115200
  #define UART_INIT() uart_init(CLK_SYS_FREQ, BAUDRATE);
#else 
  #define UART_INIT() ;
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
uint8_t seed[SEEDBYTES] = {0};

int main(void)
{
    unsigned int i;
    size_t siglen;
    uint8_t pk[CRYPTO_PUBLICKEYBYTES];
    uint8_t sk[CRYPTO_SECRETKEYBYTES];
    uint8_t sig[CRYPTO_BYTES];
    uint8_t seed[CRHBYTES];
    polyvecl mat[K];
    polyveck veck;
    polyvecl vecl;
    poly *a = &mat[0].vec[0];
    poly *b = &mat[0].vec[1];
    poly *c = &mat[0].vec[2];
    UART_INIT();
    printf("Test speed of " CRYPTO_ALGNAME "\n");
    printf("**************************************\n");
    #if defined(VECTOR128)
    printf("****** Vector Speed Test *******\n");
    #elif defined(BITMAN)
    printf("****** Bit Manipulation Speed Test *******\n");
    #elif defined(RV32) || defined(RV64)
    printf("****** Scalar Optimized Speed Test *******\n");
    #else
    printf("****** Reference Speed Test *******\n");
    #endif
    printf("**************************************\n");

    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        polyvec_matrix_expand(mat, seed);
        CPU_PERF_END(i);
    }
    printf("polyvec_matrix_expand:\n");
    PRINT_MEDIAN();

#if defined(VECTOR128) && !defined(REF_IMPL)
    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        polyveclk_uniform_eta(&mat[0], &veck, seed, 0, L);
        CPU_PERF_END(i);
    }
    printf("polyveclk_uniform_eta:\n");
    PRINT_MEDIAN();
#else
    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        polyvecl_uniform_eta(&mat[0], seed, 0);
        CPU_PERF_END(i);
    }
    printf("polyvecl_uniform_eta:\n");
    PRINT_MEDIAN();

    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        polyveck_uniform_eta(&veck, seed, 0);
        CPU_PERF_END(i);
    }
    printf("polyveck_uniform_eta:\n");
    PRINT_MEDIAN();
#endif

    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        poly_ntt(a);
        CPU_PERF_END(i);
    }
    printf("poly_ntt:\n");
    PRINT_MEDIAN();

    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        poly_intt(a);
        CPU_PERF_END(i);
    }
    printf("poly_intt:\n");
    PRINT_MEDIAN();

    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        poly_pointwise(c, a, b);
        CPU_PERF_END(i);
    }
    printf("poly_pointwise:\n");
    PRINT_MEDIAN();

    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        polyveck_pointwise_poly(&veck, a, &veck);
        CPU_PERF_END(i);
    }
    printf("polyveck_pointwise_poly:\n");
    PRINT_MEDIAN();

    // for (i = 0; i < NTESTS; ++i) {
    //     CPU_PERF_START(i);
    //     polyvecl_pointwise_poly(&mat[0], a, &mat[0]);
    // }
    // printf("polyvecl_pointwise_poly:\n");

    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        polyvec_matrix_pointwise(&veck, mat, &vecl);
        CPU_PERF_END(i);
    }
    printf("polyvec_matrix_pointwise:\n");
    PRINT_MEDIAN();

    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        polyveck_reduce(&veck);
        CPU_PERF_END(i);
    }
    printf("polyveck_reduce:\n");
    PRINT_MEDIAN();

    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        poly_challenge(c, seed);
        CPU_PERF_END(i);
    }
    printf("poly_challenge:\n");
    PRINT_MEDIAN();

    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        crypto_sign_keypair(pk, sk);
        CPU_PERF_END(i);
    }
    printf("Keypair:\n");
    PRINT_MEDIAN();

    for (i = 0; i < NTESTS*10; ++i) {
        CPU_PERF_START(i);
        crypto_sign_signature(sig, &siglen, sig, CRHBYTES, sk);
        CPU_PERF_END(i);
    }
    printf("Sign with rand:\n");
    PRINT_MEDIAN();

    // uint8_t message[CRYPTO_BYTES];
    // memset(message, 0xff, CRHBYTES);
    // // Find a key pair such that the 'goto rej' statement within the Sign
    // // function does not execute
    // do {
    //     crypto_sign_keypair(pk, sk);
    //     i = crypto_sign_signature(sig, &siglen, message, CRHBYTES, sk);
    // } while (i != 0);
    // for (i = 0; i < NTESTS; ++i) {
    //     CPU_PERF_START(i);
    //     crypto_sign_signature(sig, &siglen, message, CRHBYTES, sk);
    //     CPU_PERF_END(i);
    // }
    // printf("Sign without rej:\n");

    // // Find a key pair such that the 'goto rej' statement within the Sign
    // // function executes exactly once
    // do {
    //     crypto_sign_keypair(pk, sk);
    //     i = crypto_sign_signature(sig, &siglen, message, CRHBYTES, sk);
    // } while (i != 1);
    // for (i = 0; i < NTESTS; ++i) {
    //     CPU_PERF_START(i);
    //     crypto_sign_signature(sig, &siglen, message, CRHBYTES, sk);
    //     CPU_PERF_END(i);
    // }
    // printf("Sign with 1 rej:\n");

    // // Find a key pair such that the 'goto rej' statement within the Sign
    // // function executes exactly twice
    // do {
    //     crypto_sign_keypair(pk, sk);
    //     i = crypto_sign_signature(sig, &siglen, message, CRHBYTES, sk);
    // } while (i != 2);
    // for (i = 0; i < NTESTS; ++i) {
    //     CPU_PERF_START(i);
    //     crypto_sign_signature(sig, &siglen, message, CRHBYTES, sk);
    //     CPU_PERF_END(i);
    // }
    // printf("Sign with 2 rej:\n");

    // do {
    //     crypto_sign_keypair(pk, sk);
    //     i = crypto_sign_signature(sig, &siglen, message, CRHBYTES, sk);
    // } while (i != 3);
    // for (i = 0; i < NTESTS; ++i) {
    //     CPU_PERF_START(i);
    //     crypto_sign_signature(sig, &siglen, message, CRHBYTES, sk);
    //     CPU_PERF_END(i);
    // }
    // printf("Sign with 3 rej:\n");

    // do {
    //     crypto_sign_keypair(pk, sk);
    //     i = crypto_sign_signature(sig, &siglen, message, CRHBYTES, sk);
    // } while (i != 4);
    // for (i = 0; i < NTESTS; ++i) {
    //     CPU_PERF_START(i);
    //     crypto_sign_signature(sig, &siglen, message, CRHBYTES, sk);
        // CPU_PERF_END(i);
    // }
    // printf("Sign with 4 rej:\n");

    for (i = 0; i < NTESTS; ++i) {
        CPU_PERF_START(i);
        crypto_sign_verify(sig, CRYPTO_BYTES, sig, CRHBYTES, pk);
        CPU_PERF_END(i);
    }
    printf("Verify:\n");
    PRINT_MEDIAN();

    printf("\nDONE\n");

    #ifdef FPGA
    exit(0);
    #endif

    return 0;
}
