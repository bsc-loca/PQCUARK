#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include "kem.h"
#include "params.h"
#include "indcpa.h"
#include "polyvec.h"
#include "poly.h"
#include "symmetric.h"
#include "randombytes.h"
#include "cpu_perf.h"
#include "print_metric.h"
#include "sdv_env.h"
#if defined(BFU) || defined(PQCUARK)
  #include "ntt_pqcuark.h"
#else
  #include "ntt.h"
#endif

#define NTESTS 1000

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
uint8_t seed[KYBER_SYMBYTES];

int main(void)
{
  unsigned int i;
  uint8_t pk[CRYPTO_PUBLICKEYBYTES];
  uint8_t sk[CRYPTO_SECRETKEYBYTES];
  uint8_t ct[CRYPTO_CIPHERTEXTBYTES];
  uint8_t key[CRYPTO_BYTES];
  uint8_t buf[2*KYBER_SYMBYTES];
  uint8_t kr[2*KYBER_SYMBYTES];
  uint8_t ss[KYBER_SSBYTES];
  polyvec matrix[KYBER_K], pkpv, skpv;
  polyvec *a = matrix;
  poly ap;

  // Generate tuples of Values (numbers) and names (strings)
  UART_INIT();

  printf("**************************************\n");
  printf("****** Kyber PQCUARK Speed Test *******\n");
  printf("**************************************\n");

  randombytes(seed, KYBER_SYMBYTES);

  TRACE_NAME();
  TRACE_INIT();
  TRACE_DISABLE();

/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(1);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    gen_matrix(matrix, seed, 1);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("gen_a:\n");
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(2);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    poly_getnoise_eta1(&ap, seed, 0);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("poly_getnoise_eta1: \n");
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(3);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    poly_getnoise_eta2(&ap, seed, 0);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

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

  TRACE_EVENT(4);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    poly_ntt(&ap_poly_ntt);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("Poly NTT: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(5);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    #ifdef NIST
      poly_invntt_tomont(&ap_poly_invntt);
    #else
      poly_intt(&ap_poly_invntt);
    #endif
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("Poly INVNTT: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(6);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    ntt(ap_ntt.coeffs);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("NTT: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(7);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    #if defined(RV64) || defined(KECCAK) || defined(BFU) || defined(PQCUARK)
    intt(ap_invntt.coeffs);
    #else
    invntt(ap_invntt.coeffs);
    #endif
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("INVNTT: \n"); 
  PRINT_MEDIAN();
  /******************************************************************************************/
  TRACE_ENABLE();
  #ifndef RV64
    TRACE_EVENT(8);
    for(i=0;i<NTESTS;i++) {
      CPU_PERF_START(i);
      #ifndef NIST
      poly_basemul(&ap, &matrix[0].vec[0], &matrix[1].vec[0]);
      #else
      poly_basemul_montgomery(&ap, &matrix[0].vec[0], &matrix[1].vec[0]);
      #endif
      CPU_PERF_END(i);
    }
    TRACE_EVENT(0);

    TRACE_DISABLE();
    printf("poly_basemul: \n"); 
    PRINT_MEDIAN();
/******************************************************************************************/  
  #else
    TRACE_ENABLE();

    TRACE_EVENT(8);
    for(i=0;i<NTESTS;i++) {
      CPU_PERF_START(i);
      polyvec_basemul_acc(&ap, &matrix[0], &matrix[1]);
      CPU_PERF_END(i);
    }
    TRACE_EVENT(0);

    TRACE_DISABLE();
    printf("polyvec_basemul_acc: \n"); 
    PRINT_MEDIAN();

/******************************************************************************************/
    TRACE_ENABLE();

    TRACE_EVENT();
    // matrix-vector mul
    for (int j = 0; j < NTESTS; j++) {
        CPU_PERF_START(j);
        for (i = 0; i < KYBER_K; i++) {
            polyvec_basemul_acc(&pkpv.vec[i], &a[i], &skpv);
        }
        CPU_PERF_END(j);
    }
    printf("matrix-vector mul: \n");
    PRINT_MEDIAN();
  #endif
    /******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(9);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    poly_tomsg(ct,&ap);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("poly_tomsg: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(10);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    poly_frommsg(&ap,ct);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("poly_frommsg: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(11);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    poly_compress(ct,&ap);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("poly_compress: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(12);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    poly_decompress(&ap,ct);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("poly_decompress: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(13);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    polyvec_compress(ct,&matrix[0]);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("polyvec_compress: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(14);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    polyvec_decompress(&matrix[0],ct);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("polyvec_decompress: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(15);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    indcpa_keypair(pk, sk);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("indcpa_keypair: \n"); 
/******************************************************************************************/
  PRINT_MEDIAN();
  TRACE_ENABLE();

  TRACE_EVENT(16);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    indcpa_enc(ct, key, pk, seed);
    CPU_PERF_END(i);
  }
  printf("indcpa_enc: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_EVENT(0);

  TRACE_DISABLE();

  TRACE_EVENT(17);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    indcpa_dec(key, ct, sk);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("indcpa_dec: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(18);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    hash_h(buf+KYBER_SYMBYTES, pk, KYBER_PUBLICKEYBYTES); // m||H(pk)
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("hash_h: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(19);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    hash_g(kr, buf, 2*KYBER_SYMBYTES); // (K,r)
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("hash_g: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  // TRACE_ENABLE();

  // TRACE_EVENT(20);
  // for(i=0;i<NTESTS;i++) {
  //   CPU_PERF_START(i);
  //   rkprf(ss,sk+KYBER_SECRETKEYBYTES-KYBER_SYMBYTES,ct);
  //   CPU_PERF_END(i);
  // }
  // TRACE_EVENT(0);

  // TRACE_DISABLE();
  // printf("shake256_rkprf: \n"); 
  // PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(21);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    crypto_kem_keypair(pk, sk);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("kyber_keypair: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(22);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    crypto_kem_enc(ct, key, pk);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("kyber_encaps: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/
  TRACE_ENABLE();

  TRACE_EVENT(23);
  for(i=0;i<NTESTS;i++) {
    CPU_PERF_START(i);
    crypto_kem_dec(key, ct, sk);
    CPU_PERF_END(i);
  }
  TRACE_EVENT(0);

  TRACE_DISABLE();
  printf("kyber_decaps: \n"); 
  PRINT_MEDIAN();
/******************************************************************************************/

  printf("DONE\n");
  #ifdef FPGA
  exit(0);
  #endif
  
  return 0;
}
