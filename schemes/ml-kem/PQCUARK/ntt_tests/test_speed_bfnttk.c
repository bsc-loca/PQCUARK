#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define KYBER_Q 3329
#define QINV -3327  // -q^(-1) mod 2^16

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

int16_t zetas[128] = {
  -1044, -758, -359, -1517, 1493, 1422, 287, 202,
  -171, 622, 1577, 182, 962, -1202, -1474, 1468,
  573, -1325, 264, 383, -829, 1458, -1602, -130,
  -681, 1017, 732, 608, -1542, 411, -205, -1571,
  1223, 652, -552, 1015, -1293, 1491, -282, -1544,
  516, -8, -320, -666, -1618, -1162, 126, 1469,
  -853, -90, -271, 830, 107, -1421, -247, -951,
  -398, 961, -1508, -725, 448, -1065, 677, -1275,
  -1103, 430, 555, 843, -1251, 871, 1550, 105,
  422, 587, 177, -235, -291, -460, 1574, 1653,
  -246, 778, 1159, -147, -777, 1483, -602, 1119,
  -1590, 644, -872, 349, 418, 329, -156, -75,
  817, 1097, 603, 610, 1322, -1285, -1465, 384,
  -1215, -136, 1218, -1335, -874, 220, -1187, -1659,
  -1185, -1530, -1278, 794, -1510, -854, -870, 478,
  -108, -308, 996, 991, 958, -1460, 1522, 1628
};

int16_t montgomery_reduce(int32_t a)
{
  int16_t t;
  //printf("a: %d\n", a);
  t = (int16_t)a*QINV;
  //printf("t=> %d * %d = %d\n", (int16_t)a, QINV, t);
  t = (a - (int32_t)t*KYBER_Q) >> 16;
  //printf("Montgomery reduce: t=%d\n", t);
  return t;
}

int16_t barrett_reduce(int16_t a) {
  int16_t t;
  const int16_t v = ((1<<26) + KYBER_Q/2)/KYBER_Q;
  t  = ((int32_t)v*a + (1<<25)) >> 26;
  t *= KYBER_Q;
  return a - t;
}

// Modular multiplication
int16_t fqmul(int16_t a, int16_t b) {
    return montgomery_reduce((int32_t)a * b);
}

// NTT butterfly operation
void ntt_butterfly(int16_t *x, int16_t *y, int16_t zeta) {
    int16_t t = fqmul(zeta, *y);
    *y = *x - t;
    *x = *x + t;
}

// Inverse NTT butterfly operation
void intt_butterfly(int16_t *x, int16_t *y, int16_t zeta) {
    int16_t t = *x;
    *x = barrett_reduce(t + *y);
    *y = *y - t;
    *y = fqmul(zeta, *y);
}

void bfnttk_ins(
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
    ".word 0x062855B"
    : "=r"(rd_r)
    : "r"(rs1_r), "r"(rs2_r)
  );

*rd = rd_r;

}

void bfinttk_ins(
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
    ".word 0x062955B"
    : "=r"(rd_r)
    : "r"(rs1_r), "r"(rs2_r)
  );

*rd = rd_r;

}

int main() {

  int16_t x1 = 0x89AB;
  int16_t x2 = 0x0123;
  int16_t y1 = 0xCDEF;
  int16_t y2 = 0x4567;
  int16_t zeta_x = zetas[0];
  int16_t zeta_y = zetas[1];

  // Expected outputs
  uint16_t init_x1 = x1, init_x2 = x2;
  uint16_t init_y1 = y1, init_y2 = y2;

  for (int i = 0; i < NTESTS; i++) {
    CPU_PERF_START(i);
    ntt_butterfly(&init_x1, &init_x2, zeta_x);
    ntt_butterfly(&init_y1, &init_y2, zeta_y);
    ntt_butterfly(&init_x1, &init_x2, zeta_x);
    ntt_butterfly(&init_y1, &init_y2, zeta_y);
    ntt_butterfly(&init_x1, &init_x2, zeta_x);
    ntt_butterfly(&init_y1, &init_y2, zeta_y);
    ntt_butterfly(&init_x1, &init_x2, zeta_x);
    ntt_butterfly(&init_y1, &init_y2, zeta_y);
    CPU_PERF_END(i);
  }
  printf("ntt_butterfly Kyber (Scalar): \n");
  PRINT_ALL();
  printf("NTTD scalar result: x1=%032lx x2=%032lx\n", init_x1, init_x2);

  for (int i = 0; i < NTESTS; i++) {
    CPU_PERF_START(i);
    intt_butterfly(&init_x1, &init_x2, zeta_x);
    intt_butterfly(&init_y1, &init_y2, zeta_y);
    intt_butterfly(&init_x1, &init_x2, zeta_x);
    intt_butterfly(&init_y1, &init_y2, zeta_y);
    intt_butterfly(&init_x1, &init_x2, zeta_x);
    intt_butterfly(&init_y1, &init_y2, zeta_y);
    intt_butterfly(&init_x1, &init_x2, zeta_x);
    intt_butterfly(&init_y1, &init_y2, zeta_y);
    CPU_PERF_END(i);
  }
  printf("intt_butterfly Kyber (Scalar): \n");
  PRINT_ALL();
  printf("INTTD scalar result: x1=%032lx x2=%032lx\n", init_x1, init_x2);

  uint64_t rd;
  uint64_t rs1 = 0x0123456789ABCDEF;
  uint64_t rs2 = ((uint64_t) zetas[1] << 32 | (uint64_t) zetas[0]);

  for (int i = 0; i < NTESTS; i++) {
    CPU_PERF_START(i);
    bfnttk_ins(&rd, &rs1, &rs2);
    bfnttk_ins(&rd, &rs1, &rs2);
    bfnttk_ins(&rd, &rs1, &rs2);
    bfnttk_ins(&rd, &rs1, &rs2);
    CPU_PERF_END(i);
  }
  printf("ntt_butterfly Kyber BFINTTK instruction: \n");
  PRINT_ALL();
  printf("BFNTTK instruction result: %016lx\n", rd);

  for (int i = 0; i < NTESTS; i++) {
    CPU_PERF_START(i);
    bfinttk_ins(&rd, &rs1, &rs2);
    bfinttk_ins(&rd, &rs1, &rs2);
    bfinttk_ins(&rd, &rs1, &rs2);
    bfinttk_ins(&rd, &rs1, &rs2);
    CPU_PERF_END(i);
  }
  printf("intt_butterfly Kyber BFINTTK instruction: \n");
  PRINT_ALL();
  printf("BFINTTK instruction result: %016lx\n", rd);

  return 0;
}

