#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#include "randombytes.h"
#include "sign.h"

#ifdef FPGA
  #include <uart.h>
  #define CLK_SYS_FREQ 25000000
  #define BAUDRATE 115200
  #define UART_INIT() uart_init(CLK_SYS_FREQ, BAUDRATE);
#else 
  #define UART_INIT() ;
#endif

#define MLEN 59
#define NTESTS 1

int main(void)
{
    size_t i, j;
    int ret;
    int pass = 1;
    size_t mlen, smlen;
    uint8_t b;
    uint8_t m[MLEN + CRYPTO_BYTES];
    uint8_t m2[MLEN + CRYPTO_BYTES];
    uint8_t sm[MLEN + CRYPTO_BYTES];
    uint8_t pk[CRYPTO_PUBLICKEYBYTES];
    uint8_t sk[CRYPTO_SECRETKEYBYTES]; 

    UART_INIT();

    printf("**************************************\n");
    printf("****** Dilithium PQCUARK Test *******\n");
    printf("**************************************\n");

    for (i = 0; i < NTESTS; ++i) {
        seed_randombytes(m, MLEN, i  + 1);
        printf("Test %d: \n", i + 1);

        crypto_sign_keypair(pk, sk); 
        
        // printf("pk: ");
        // for (j = 0; j < CRYPTO_PUBLICKEYBYTES; ++j) {
        //     printf("%02x", pk[j]);
        // }
        // printf("\n");
        // printf("sk: ");
        // for (j = 0; j < CRYPTO_SECRETKEYBYTES; ++j) {
        //     printf("%02x", sk[j]);
        // }
        // printf("\n");
        
        crypto_sign(sm, &smlen, m, MLEN, sk);
        ret = crypto_sign_open(m2, &mlen, sm, smlen, pk);

        if (ret) {
            printf("Verification failed\n");
            pass = 0;
        }
        printf("smlen: Expected %d, got %d\n", MLEN + CRYPTO_BYTES, smlen);
        if (smlen != MLEN + CRYPTO_BYTES) {
            printf("Signed message lengths wrong\n");
            pass = 0;
        }
        printf("mlen: Expected %d, got %d\n", MLEN, mlen);
        if (mlen != MLEN) {
            printf("Message lengths wrong\n");
            pass = 0;
        }
        for (j = 0; j < MLEN; ++j) {
            if (m2[j] != m[j]) {
                printf("Messages don't match\n");
                pass = 0;
            }
        }

        seed_randombytes((uint8_t *)&j, sizeof(j), i + 1);
        do {
            seed_randombytes(&b, 1, i + 1);
        } while (!b);
        sm[j % (MLEN + CRYPTO_BYTES)] += b;
        ret = crypto_sign_open(m2, &mlen, sm, smlen, pk);
        if (!ret) {
            printf("Trivial forgeries possible\n");
        }

        if (!pass) {
            printf("Test %d failed\n", i + 1);
            return -1;
        } else {
            printf("Test %d passed\n", i + 1);
        }
    }

    printf("CRYPTO_PUBLICKEYBYTES = %d\n", CRYPTO_PUBLICKEYBYTES);
    printf("CRYPTO_SECRETKEYBYTES = %d\n", CRYPTO_SECRETKEYBYTES);
    printf("CRYPTO_BYTES = %d\n", CRYPTO_BYTES);

    printf("TEST PASS\n");

    #ifdef FPGA
    exit(0);
    #endif

    return 0;
}
