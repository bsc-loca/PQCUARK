#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define Q 8380417
#define QINV 58728449  // q^(-1) mod 2^32
#define N 256

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
  #define CPU_PERF_START(i);
  #define CPU_PERF_END(i);
  #define PRINT_ALL();
  #define PRINT_ALL_AVG(); 
#else
  #define CPU_PERF_START(i) cpu_perf(&t_start[i], &i_start[i]);
  #define CPU_PERF_END(i) cpu_perf(&t_end[i], &i_end[i]);
  #define PRINT_ALL() print_median(&t_start, &t_end, &i_start, &i_end, NTESTS);
  #define PRINT_ALL_AVG() print_average(&t_start, &t_end, &i_start, &i_end, NTESTS);
#endif

uint64_t t_start[NTESTS];
uint64_t t_end[NTESTS];
uint64_t i_start[NTESTS];
uint64_t i_end[NTESTS];

static const int32_t zetas[N] = {
  0,        25847,    -2608894, -518909,  237124,   -777960,  -876248,
  466468,   1826347,  2353451,  -359251,  -2091905, 3119733,  -2884855,
  3111497,  2680103,  2725464,  1024112,  -1079900, 3585928,  -549488,
  -1119584, 2619752,  -2108549, -2118186, -3859737, -1399561, -3277672,
  1757237,  -19422,   4010497,  280005,   2706023,  95776,    3077325,
  3530437,  -1661693, -3592148, -2537516, 3915439,  -3861115, -3043716,
  3574422,  -2867647, 3539968,  -300467,  2348700,  -539299,  -1699267,
  -1643818, 3505694,  -3821735, 3507263,  -2140649, -1600420, 3699596,
  811944,   531354,   954230,   3881043,  3900724,  -2556880, 2071892,
  -2797779, -3930395, -1528703, -3677745, -3041255, -1452451, 3475950,
  2176455,  -1585221, -1257611, 1939314,  -4083598, -1000202, -3190144,
  -3157330, -3632928, 126922,   3412210,  -983419,  2147896,  2715295,
  -2967645, -3693493, -411027,  -2477047, -671102,  -1228525, -22981,
  -1308169, -381987,  1349076,  1852771,  -1430430, -3343383, 264944,
  508951,   3097992,  44288,    -1100098, 904516,   3958618,  -3724342,
  -8578,    1653064,  -3249728, 2389356,  -210977,  759969,   -1316856,
  189548,   -3553272, 3159746,  -1851402, -2409325, -177440,  1315589,
  1341330,  1285669,  -1584928, -812732,  -1439742, -3019102, -3881060,
  -3628969, 3839961,  2091667,  3407706,  2316500,  3817976,  -3342478,
  2244091,  -2446433, -3562462, 266997,   2434439,  -1235728, 3513181,
  -3520352, -3759364, -1197226, -3193378, 900702,   1859098,  909542,
  819034,   495491,   -1613174, -43260,   -522500,  -655327,  -3122442,
  2031748,  3207046,  -3556995, -525098,  -768622,  -3595838, 342297,
  286988,   -2437823, 4108315,  3437287,  -3342277, 1735879,  203044,
  2842341,  2691481,  -2590150, 1265009,  4055324,  1247620,  2486353,
  1595974,  -3767016, 1250494,  2635921,  -3548272, -2994039, 1869119,
  1903435,  -1050970, -1333058, 1237275,  -3318210, -1430225, -451100,
  1312455,  3306115,  -1962642, -1279661, 1917081,  -2546312, -1374803,
  1500165,  777191,   2235880,  3406031,  -542412,  -2831860, -1671176,
  -1846953, -2584293, -3724270, 594136,   -3776993, -2013608, 2432395,
  2454455,  -164721,  1957272,  3369112,  185531,   -1207385, -3183426,
  162844,   1616392,  3014001,  810149,   1652634,  -3694233, -1799107,
  -3038916, 3523897,  3866901,  269760,   2213111,  -975884,  1717735,
  472078,   -426683,  1723600,  -1803090, 1910376,  -1667432, -1104333,
  -260646,  -3833893, -2939036, -2235985, -420899,  -2286327, 183443,
  -976891,  1612842,  -3545687, -554416,  3919660,  -48306,   -1362209,
  3937738,  1400424,  -846154,  1976782};

/*************************************************
* Name:        montgomery_reduce
*
* Description: Montgomery reduction; given a 32-bit integer a, computes
*              16-bit integer congruent to a * R^-1 mod q, where R=2^16
*
* Arguments:   - int32_t a: input integer to be reduced;
*                           has to be in {-q2^15,...,q2^15-1}
*
* Returns:     integer in {-q+1,...,q-1} congruent to a * R^-1 modulo q.
**************************************************/
int32_t montgomery_reduce(int64_t a)
{
    int32_t t;

    t = (int64_t)(int32_t)a * QINV;
    t = (a - (int64_t)t * Q) >> 32;
    return t;
}

// Modular multiplication
int32_t fqmul(int32_t a, int32_t b) {
    return montgomery_reduce((int64_t)a * b);
}

// NTT butterfly operation
void ntt_butterfly(int32_t *x, int32_t *y, int32_t zeta) {
    int32_t t = fqmul(zeta, *y);
    *y = *x - t;
    *x = *x + t;
}

// Inverse NTT butterfly operation
void intt_butterfly(int32_t *x, int32_t *y, int32_t zeta) {
    int32_t t = *x;
    *x = t + *y;
    *y = *y - t;
    *y = fqmul(-zeta, *y);
}


void bfnttd_ins(
  uint64_t *rd,
  uint64_t *rs1,
  uint64_t *rs2)
{
register uint64_t rs1_r __asm__("t0");
rs1_r = *rs1;
register uint64_t rs2_r __asm__("t1");
rs2_r = *rs2;
register uint64_t rd_r __asm__("a0");
rd_r = *rd;

// Put in the .word directive the encoding
// for "BFNTTK a0, t0, t1"
__asm__ __volatile__(
    ".word 0x062A55B"
    : "=r"(rd_r)
    : "r"(rs1_r), "r"(rs2_r)
  );

*rd = rd_r;
}

void bfinttd_ins(
  uint64_t *rd,
  uint64_t *rs1,
  uint64_t *rs2)
{
register uint64_t rs1_r __asm__("t0");
rs1_r = *rs1;
register uint64_t rs2_r __asm__("t1");
rs2_r = *rs2;
register uint64_t rd_r __asm__("a0");
rd_r = *rd;

// Put in the .word directive the encoding
// for "BFNTTK a0, t0, t1"
__asm__ __volatile__(
    ".word 0x062B55B"
    : "=r"(rd_r)
    : "r"(rs1_r), "r"(rs2_r)
  );

*rd = rd_r;
}

int main() {

  int32_t x1 = 0x89ABCDEF;
  int32_t x2 = 0x01234567;
  int32_t zeta_x = zetas[1];

  // Expected outputs
  uint32_t init_x1 = x1, init_x2 = x2;

  for (int i = 0; i < NTESTS; i++) {
    CPU_PERF_START(i);
    ntt_butterfly(&init_x1, &init_x2, zeta_x);
    ntt_butterfly(&init_x1, &init_x2, zeta_x);
    ntt_butterfly(&init_x1, &init_x2, zeta_x);
    ntt_butterfly(&init_x1, &init_x2, zeta_x);
    CPU_PERF_END(i);
  }
  printf("ntt_butterfly Dilithium (Scalar): \n");
  PRINT_ALL();
  printf("NTTD scalar result: x1=%032lx x2=%032lx\n", init_x1, init_x2);

  for (int i = 0; i < NTESTS; i++) {
    CPU_PERF_START(i);
    intt_butterfly(&init_x1, &init_x2, zeta_x);
    intt_butterfly(&init_x1, &init_x2, zeta_x);
    intt_butterfly(&init_x1, &init_x2, zeta_x);
    intt_butterfly(&init_x1, &init_x2, zeta_x);
    CPU_PERF_END(i);
  }
  printf("intt_butterfly Dilithium (Scalar): \n");
  PRINT_ALL();
  printf("INTTD scalar result: x1=%032lx x2=%032lx\n", init_x1, init_x2);

  uint64_t rd;
  uint64_t rs1 = 0x0123456789ABCDEF;
  uint64_t rs2 = 1;

  for (int i = 0; i < NTESTS; i++) {
    CPU_PERF_START(i);
    bfnttd_ins(&rd, &rs1, &rs2);
    bfnttd_ins(&rd, &rs1, &rs2);
    bfnttd_ins(&rd, &rs1, &rs2);
    bfnttd_ins(&rd, &rs1, &rs2);
    CPU_PERF_END(i);
  }
  printf("ntt_butterfly Dilithium BFINTTD instruction: \n");
  PRINT_ALL();
  printf("BFNTTD instruction result: %016lx\n", rd);

  for (int i = 0; i < NTESTS; i++) {
    CPU_PERF_START(i);
    bfinttd_ins(&rd, &rs1, &rs2);
    bfinttd_ins(&rd, &rs1, &rs2);
    bfinttd_ins(&rd, &rs1, &rs2);
    bfinttd_ins(&rd, &rs1, &rs2);
    CPU_PERF_END(i);
  }
  printf("intt_butterfly Dilithium BFINTTD instruction: \n");
  PRINT_ALL();
  printf("BFINTTD instruction result: %016lx\n", rd);

  return 0;
}

