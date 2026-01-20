#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <cpu_perf.h>
#include <print_metric.h>
#include <ntt.h>

#define NTESTS 1000 

#define KYBER_N 256
#define KYBER_Q 3329
#define MONT -1044  // 2^16 mod q
#define QINV -3327  // q^-1 mod 2^16

#ifdef FPGA
  #include <uart.h>
  #define CLK_SYS_FREQ 25000000
  #define BAUDRATE 115200
  #define UART_INIT() uart_init(CLK_SYS_FREQ, BAUDRATE);
#else 
  #define UART_INIT() ;
#endif

#ifdef LINUX
  #define CPU_PERF_START(i);
  #define CPU_PERF_END(i);
  #define PRINT_ONE();
  #define PRINT_MEDIAN();
  #define PRINT_AVG(); 
#else
  #define CPU_PERF_START(i) set_checkpoint_start(&tests[i]);
  #define CPU_PERF_END(i) set_checkpoint_end(&tests[i]);
  #define PRINT_ONE() print_one(&tests[0]);
  #define PRINT_MEDIAN() print_median(tests, NTESTS);
  #define PRINT_AVG() print_all_average(tests, NTESTS);
  #define PRINT_ALL_MEDIAN() print_all_median(tests, NTESTS);
#endif

checkpoint_t tests[NTESTS];


void init_poly(int16_t *a, uint64_t seed, size_t n)
{
    // Initialize with pseudo-random values using a seed
    for (size_t i = 0; i < n; i++) {
        seed = seed * 1103515245 + 12345;
        a[i] = (int16_t)((seed >> 16) % KYBER_Q);
    }
}

int16_t montgomery_reduce_test(int32_t a)
{
    int16_t t;

    t = (int16_t)a * QINV;
    t = (a - (int32_t)t * KYBER_Q) >> 16;
    return t;
}

int16_t barrett_reduce_test(int16_t a)
{
    int16_t t;
    const int16_t v = ((1 << 26) + KYBER_Q / 2) / KYBER_Q;

    t = ((int32_t)v * a + (1 << 25)) >> 26;
    t *= KYBER_Q;
    return a - t;
}

int16_t fqmul_test(int16_t a, int16_t b)
{
    return montgomery_reduce_test((int32_t)a * b);
}

__attribute__((noinline)) void basemul_test(int16_t r[2], const int16_t a[2], const int16_t b[2], int16_t zeta)
{
  r[0]  = fqmul_test(a[1], b[1]);
  r[0]  = fqmul_test(r[0], zeta);
  r[0] += fqmul_test(a[0], b[0]);
  r[1]  = fqmul_test(a[0], b[1]);
  r[1] += fqmul_test(a[1], b[0]);
}

__attribute__((noinline)) void poly_basemul_test(int16_t r[2], const int16_t a[2], const int16_t b[2])
{
    unsigned int j;
    for(j=0;j<KYBER_N/4;j++) {
        basemul_test(&r[4*j], &a[4*j], &b[4*j], zetas[64+j]);
        basemul_test(&r[4*j+2], &a[4*j+2], &b[4*j+2], -zetas[64+j]);
    }
}

void poly_basemul_pqcuark(int16_t r[2], const int16_t a[2], const int16_t b[2])
{
    unsigned int j;
    for(j=0;j<KYBER_N/4;j++) {
        basemul_pqcuark(&r[4*j], &a[4*j], &b[4*j], zetas[64+j]);
        basemul_pqcuark(&r[4*j+2], &a[4*j+2], &b[4*j+2], -zetas[64+j]);
    }
}

void ntt_test(int16_t r[256])
{
    unsigned int len, start, j, k;
    int16_t t, zeta;

    k = 1;
    for (len = 128; len >= 2; len >>= 1) {
        // printf("**len: %u**\n", len);
        for (start = 0; start < 256; start = j + len) {
            // printf("  start: %u\n", start);
            zeta = zetas[k++];
            for (j = start; j < start + len; j++) {
                // printf("    j: %u, k: %u\n", j, k - 1);
                t = fqmul_test(zeta, r[j + len]);
                // printf("      PRE:  r[%d]: %d, r[%d]: %d, zeta: %d\n", j, r[j], j + len, r[j + len], zeta);
                r[j + len] = r[j] - t;
                r[j] = r[j] + t;
                // printf("      POST: r[%d]: %d, r[%d]: %d, zeta: %d\n", j, r[j], j + len, r[j + len], zeta);
            }
        }
    }
}

void intt_test(int16_t r[256])
{
    unsigned int start, len, j, k;
    int16_t t, zeta;
    const int16_t f = 1441;  // mont^2/128

    k = 127;
    for (len = 2; len <= 128; len <<= 1) {
        for (start = 0; start < 256; start = j + len) {
            zeta = zetas[k--];
            for (j = start; j < start + len; j++) {
                t = r[j];
                r[j] = barrett_reduce_test(t + r[j + len]);
                r[j + len] = r[j + len] - t;
                r[j + len] = fqmul_test(zeta, r[j + len]);
            }
        }
    }

    for (j = 0; j < 256; j++)
        r[j] = fqmul_test(r[j], f);
}


void print_poly(int16_t *a, size_t n)
{
    int i;
    for (i = 0; i < n; i++) {
        if (i != 0 && i % 8 == 0)
            printf("\n");
        printf("%d, ", a[i]);
    }
    printf("\n\n");
}

void print_poly_mod(int16_t *a, size_t n)
{
    int i;
    for (i = 0; i < n; i++) {
        if (i != 0 && i % 8 == 0)
            printf("\n");
        printf("%d, ", (a[i] + 3329 * 10) % 3329);
    }
    printf("\n\n");
}

int poly_equal(int16_t *a, int16_t *b, size_t n)
{
    size_t i;
    int ok = 1;
    for (i = 0; i < n; i++) {
        // printf("a[%d]: %d, b[%d]: %d\n", i, (a[i] + 3329*10) % 3329, i, (b[i] + 3329*10) % 3329);
        //if (((a[i] + 3329 * 10) % 3329) != ((b[i] + 3329 * 10) % 3329)) {
        if (a[i] != b[i]) {
            ok = 0;
            // printf("a[%d]: %d, b[%d]: %d\n", i, (a[i] + 3329*10) % 3329, i, (b[i] + 3329*10) % 3329);
            // printf("a[%d]: %d, b[%d]: %d\n", i, a[i], i, b[i]);
            break;
        }
    }
    return ok;
}

void test_ntt()
{
    int i;
    int16_t a[KYBER_N], b[KYBER_N];
    init_poly(a, 1234, KYBER_N);
    init_poly(b, 1234, KYBER_N);

    ntt_test(a);
    ntt_pqcuark(b);
    if (poly_equal(a, b, 256))
        printf("PQCUARK NTT all right\n");
    else {
        printf("NTT error\n");
        print_poly(a, 16);
        print_poly(b, 16);
    }
}

void test_intt()
{
    int i;
    int16_t a0[KYBER_N];
    int16_t a1[KYBER_N];

    init_poly(a0, 1234, KYBER_N);
    init_poly(a1, 1234, KYBER_N);

    ntt_test(a0);
    intt_test(a0);

    ntt_test(a1);
    intt_pqcuark(a1);

    if (poly_equal(a0, a1, 256)) {
        printf("PQCUARK InvNTT all right\n");
    } else {
        printf("INTT error\n");
        print_poly_mod(a0, 16);
        print_poly_mod(a1, 16);
    }
}

void test_basemul()
{
    int16_t a[2], b[2], r_test[2], r[2];
    int test = 1;
    for (int i = 0; i < 128; i++) {
        init_poly(a, i + 4321, 2);
        init_poly(b, i + 9874, 2);

        basemul_test(r_test, a, b, -zetas[i]);
        basemul_pqcuark(r, a, b, -zetas[i]);

        if (!poly_equal(r_test, r, 2)) {
            printf("basemul error\n");
            print_poly_mod(r_test, 2);
            printf("r: ");
            print_poly_mod(r, 2);
            test = 0;
            break;
        }
    }
    if (test) {
        printf("All PQCUARK basemul tests passed\n");
    } else {
        printf("Some PQCUARK basemul tests failed\n");
    }
}

int main()
{
    UART_INIT();
    int i, j;
    int16_t a[KYBER_N], b[KYBER_N];

    test_ntt();
    
    test_intt();
    
    test_basemul();

    init_poly(a, 1234, KYBER_N);

    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        ntt_test(a);
        CPU_PERF_END(i);
    }
    printf("ntt: \n");
    printf("ntt result in @: %032lx\n", a);
    PRINT_MEDIAN();

    init_poly(a, 1234, KYBER_N);

    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        ntt_pqcuark(a);
        CPU_PERF_END(i);
    }
    printf("ntt_pqcuark: \n");
    printf("ntt pqcuark result in @: %032lx\n", b);
    PRINT_MEDIAN();

    init_poly(a, 1234, KYBER_N);

    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        intt_test(a);
        CPU_PERF_END(i);
    }
    printf("intt: \n");
    printf("intt result in @: %032lx\n", a);
    PRINT_MEDIAN();

    init_poly(a, 1234, KYBER_N);

    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        intt_pqcuark(a);
        CPU_PERF_END(i);
    }
    printf("intt_pqcuark: \n");
    printf("intt pqcuark result in @: %032lx\n", b);
    PRINT_MEDIAN();

    init_poly(a, 1234, KYBER_N);

    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_basemul_test(b, a, a);
        CPU_PERF_END(i);
    }
    printf("poly basemul: \n");
    printf("poly basemul result in @: %032lx\n", &b);
    PRINT_MEDIAN();

    init_poly(a, 1234, KYBER_N);

    for (i = 0; i < NTESTS; i++) {
        CPU_PERF_START(i);
        poly_basemul_pqcuark(b, a, a);
        CPU_PERF_END(i);
    }
    printf("poly basemul_pqcuark: \n");
    printf("poly basemul_pqcuark result in @: %032lx\n", b);
    PRINT_MEDIAN();
    printf("TEST DONE\n");
    // #ifdef FPGA
    //   exit(0);
    // #endif
    return 0;
}
