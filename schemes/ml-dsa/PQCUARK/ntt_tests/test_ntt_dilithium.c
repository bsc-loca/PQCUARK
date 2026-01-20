#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <cpu_perf.h>
#include <print_metric.h>
#include <ntt.h>

#define NTESTS 1000 

#define DILITHIUM_N 256
#define DILITHIUM_Q 8380417
#define MONT -4186625  // 2^32 % Q
#define QINV 58728449  // q^(-1) mod 2^32
#define K 4
#define L 4

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

typedef struct {
    int32_t coeffs[N];
} poly;

typedef struct {
    poly vec[L];
} polyvecl;


void init_poly(poly *p, uint64_t seed, size_t n)
{
    // Initialize with pseudo-random values using a seed
    for (size_t i = 0; i < n; i++) {
        seed = seed * 1103515245 + 12345;
        p->coeffs[i] = (int32_t)((seed >> 32) % DILITHIUM_Q);
    }
}

int32_t montgomery_reduce_test(int64_t a)
{
    int32_t t;

    t = (int64_t)(int32_t)a * QINV;
    t = (a - (int64_t)t * DILITHIUM_Q) >> 32;
    return t;
}

void poly_add_test(poly *c, const poly *a, const poly *b)
{
    unsigned int i;

    for (i = 0; i < N; ++i)
        c->coeffs[i] = a->coeffs[i] + b->coeffs[i];
}

int32_t fqmul_test(int32_t a, int32_t b)
{
    return montgomery_reduce_test((int64_t)a * b);
}


void poly_pointwise_test(poly *c, const poly *a, const poly *b)
{
    unsigned int i;

    for (i = 0; i < N; ++i)
        c->coeffs[i] = montgomery_reduce((int64_t)a->coeffs[i] * b->coeffs[i]);

}

void polyvecl_pointwise_acc_test(poly *w, const polyvecl *u,
                                       const polyvecl *v)
{
    unsigned int i;
    poly t;

    poly_pointwise_test(w, &u->vec[0], &v->vec[0]);
    for (i = 1; i < L; ++i) {
        poly_pointwise_test(&t, &u->vec[i], &v->vec[i]);
        poly_add_test(w, w, &t);
    }
}

void polyvecl_pointwise_acc_pqcuark(poly *w, const polyvecl *u, const polyvecl *v)
{
    unsigned int i;

    poly_pointwise_pqcuark(w->coeffs, u->vec[0].coeffs, v->vec[0].coeffs);  // Pass coeffs arrays
    for (i = 1; i < L ; ++i) {
        poly_pointwise_acc_pqcuark(w->coeffs, u->vec[i].coeffs, v->vec[i].coeffs);  // Pass coeffs arrays
    }
}

void ntt_test(int32_t a[N])  // Change parameter from int32_t a to int32_t a[N]
{
    unsigned int len, start, j, k;
    int32_t zeta, t;

    k = 0;
    for (len = 128; len > 0; len >>= 1) {
        for (start = 0; start < N; start = j + len) {
            zeta = zetas[++k];
            for (j = start; j < start + len; ++j) {
                t = montgomery_reduce((int64_t)zeta * a[j + len]);
                a[j + len] = a[j] - t;
                a[j] = a[j] + t;
            }
        }
    }
}

void intt_test(int32_t a[N])
{
    unsigned int start, len, j, k;
    int32_t t, zeta;
    const int32_t f = 41978;  // mont^2/256

    k = 256;
    for (len = 1; len < N; len <<= 1) {
        for (start = 0; start < N; start = j + len) {
            zeta = -zetas[--k];
            for (j = start; j < start + len; ++j) {
                t = a[j];
                a[j] = t + a[j + len];
                a[j + len] = t - a[j + len];
                a[j + len] = montgomery_reduce_test((int64_t)zeta * a[j + len]);
            }
        }
    }

    for (j = 0; j < N; ++j) {
        a[j] = montgomery_reduce_test((int64_t)f * a[j]);
    }

}

void print_poly(int32_t *a, size_t n)
{
    int i;
    for (i = 0; i < n; i++) {
        if (i != 0 && i % 8 == 0)
            printf("\n");
        printf("%d, ", a[i]);
    }
    printf("\n\n");
}

void print_poly_mod(int32_t *a, size_t n)
{
    int i;
    for (i = 0; i < n; i++) {
        if (i != 0 && i % 8 == 0)
            printf("\n");
        printf("%d, ", (a[i] + 3329 * 10) % 3329);
    }
    printf("\n\n");
}

int poly_equal(int32_t *a, int32_t *b, size_t n)
{
    size_t i;
    int ok = 1;
    for (i = 0; i < n; i++) {
        if (a[i] != b[i]) {
            ok = 0;
            break;
        }
    }
    return ok;
}

void test_ntt()
{
    poly a, b;
    init_poly(&a, 1234, DILITHIUM_N);
    init_poly(&b, 1234, DILITHIUM_N);

    ntt_test(a.coeffs);
    ntt_pqcuark(b.coeffs);
    if (poly_equal(a.coeffs, b.coeffs, 256))
        printf("PQCUARK NTT all right\n");
    else {
        printf("NTT error\n");
        print_poly(a.coeffs, 16);
        print_poly(b.coeffs, 16);
    }
}

void test_intt()
{
    poly a0, a1;

    init_poly(&a0, 4321, DILITHIUM_N);
    init_poly(&a1, 4321, DILITHIUM_N);

    ntt_test(a0.coeffs);
    intt_test(a0.coeffs);

    ntt_test(a1.coeffs);
    intt_pqcuark(a1.coeffs);

    if (poly_equal(a0.coeffs, a1.coeffs, 256)) {
        printf("PQCUARK InvNTT all right\n");
    } else {
        printf("INTT error\n");
        print_poly_mod(a0.coeffs, 16);
        print_poly_mod(a1.coeffs, 16);
    }
}

void test_pointwise()
{
    polyvecl a, b;
    poly r_test, r;
    int test = 1;
    for (int i = 0; i < 20; i++) {
        init_poly(&a.vec[0], i + 1234, DILITHIUM_N);
        init_poly(&b.vec[0], i + 4321, DILITHIUM_N);

        poly_pointwise_test(&r_test, &a.vec[0], &b.vec[0]);
        poly_pointwise_pqcuark(r.coeffs, a.vec[0].coeffs, b.vec[0].coeffs);  // Pass coeffs arrays

        if (!poly_equal(r_test.coeffs, r.coeffs, DILITHIUM_N)) { 
            printf("Pointwise error\n");
            printf("r_test: ");
            print_poly(r_test.coeffs, 16); 
            printf("r: ");
            print_poly(r.coeffs, 16);
            printf("r_test [END]: ");
            print_poly(&r_test.coeffs[240], 16);
            printf("r [END]: ");
            print_poly(&r.coeffs[240], 16);
            test = 0;
            break;
        }
    }

    if (test) {
        printf("All PQCUARK pointwise tests passed\n");
    } else {
        printf("Some PQCUARK pointwise tests failed\n");
    }
}

void test_pointwise_acc()
{
    polyvecl a, b;
    poly r_test, r;
    int test = 1;
    for (int i = 0; i < 1; i++) {
        // Initialize all vectors in polyvecl
        for (int j = 0; j < L; j++) {
            init_poly(&a.vec[j], i + 1234 * j, DILITHIUM_N);
            init_poly(&b.vec[j], i + 4321 * j, DILITHIUM_N);
        }

        polyvecl_pointwise_acc_test(&r_test, &a, &b);  // Pass addresses
        polyvecl_pointwise_acc_pqcuark(&r, &a, &b);  // Pass addresses

        if (!poly_equal(r_test.coeffs, r.coeffs, DILITHIUM_N)) {
            printf("Pointwise Acc error TEST %d\n", i);
            printf("r: ");
            print_poly(r.coeffs, 16);
            printf("r_test: ");
            print_poly(r_test.coeffs, 16);
            printf("r [END]: ");
            print_poly(&r.coeffs[240], 16);
            printf("r_test [END]: ");
            print_poly(&r_test.coeffs[240], 16);
            test = 0;
            break;
        }
    }

    if (test) {
        printf("All PQCUARK pointwise acc tests passed\n");
    } else {
        printf("Some PQCUARK pointwise acc tests failed\n");
    }
}

int main()
{
    UART_INIT();
    int i, j;
    int32_t a[DILITHIUM_N], b[DILITHIUM_N];

    test_ntt();
    
    test_intt();
    
    test_pointwise();

    test_pointwise_acc();

    #ifdef PERF
        init_poly(a, 1234, DILITHIUM_N);

        for (i = 0; i < NTESTS; i++) {
            CPU_PERF_START(i);
            ntt_test(a);
            CPU_PERF_END(i);
        }
        printf("ntt: \n");
        printf("ntt result in @: %016lx\n", a);
        PRINT_MEDIAN();

        init_poly(a, 1234, DILITHIUM_N);

        for (i = 0; i < NTESTS; i++) {
            CPU_PERF_START(i);
            ntt_pqcuark(a);
            CPU_PERF_END(i);
        }
        printf("ntt_pqcuark: \n");
        printf("ntt pqcuark result in @: %016lx\n", b);
        PRINT_MEDIAN();

        init_poly(a, 1234, DILITHIUM_N);

        for (i = 0; i < NTESTS; i++) {
            CPU_PERF_START(i);
            intt_test(a);
            CPU_PERF_END(i);
        }
        printf("intt: \n");
        printf("intt result in @: %016lx\n", a);
        PRINT_MEDIAN();

        init_poly(a, 1234, DILITHIUM_N);

        for (i = 0; i < NTESTS; i++) {
            CPU_PERF_START(i);
            intt_pqcuark(a);
            CPU_PERF_END(i);
        }
        printf("intt_pqcuark: \n");
        printf("intt pqcuark result in @: %016lx\n", b);
        PRINT_MEDIAN();

        init_poly(a, 1234, DILITHIUM_N);

        for (i = 0; i < NTESTS; i++) {
            CPU_PERF_START(i);
            pointwise_test(b, a, a);
            CPU_PERF_END(i);
        }
        printf("pointwise: \n");
        printf("pointwise result in @: %016lx\n", &b);
        PRINT_MEDIAN();

        init_poly(a, 1234, DILITHIUM_N);

        for (i = 0; i < NTESTS; i++) {
            CPU_PERF_START(i);
            pointwise_pqcuark(b, a, a);
            CPU_PERF_END(i);
        }
        printf("pointwise_pqcuark: \n");
        printf("pointwise_pqcuark result in @: %016lx\n", b);
        PRINT_MEDIAN();
    #endif
    printf("TEST DONE\n");
    #ifdef FPGA
      exit(0);
    #endif
    return 0;
}
