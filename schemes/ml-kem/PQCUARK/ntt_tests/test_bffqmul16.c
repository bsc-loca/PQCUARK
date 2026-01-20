#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define KYBER_Q 3329
#define QINV -3327  // -q^(-1) mod 2^16

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

/*************************************************
* Name:        barrett_reduce
*
* Description: Barrett reduction; given a 16-bit integer a, computes
*              centered representative congruent to a mod q in {-(q-1)/2,...,(q-1)/2}
*
* Arguments:   - int16_t a: input integer to be reduced
*
* Returns:     integer in {-(q-1)/2,...,(q-1)/2} congruent to a modulo q.
**************************************************/
int16_t barrett_reduce(int16_t a) {
  int16_t t;
  const int16_t v = ((1<<26) + KYBER_Q/2)/KYBER_Q;
  // printf("v_mul_a: %x\n", (int32_t)v*a);
  // printf("sum: %x\n", ((int32_t)v*a + (1<<25)));
  // printf("shift: %x\n", (((int32_t)v*a + (1<<25)) >> 26));
  t  = ((int32_t)v*a + (1<<25)) >> 26;
  t *= KYBER_Q;
  // printf("mult_q: %x\n", t);
  // printf("Barret reduce: %x - %x -> reduced=%x\n", a, t, a-t);
  return a - t;
}

// Modular multiplication
int16_t fqmul(int16_t a, int16_t b) {
    // printf("fqmul input product: a * b = %x * %x = %x\n", a, b, ((int32_t) a * b));
    return montgomery_reduce((int32_t)a * b);
}



void bffqmul_ins(
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
// ".word 0x062855B"
__asm__ __volatile__(
    "pqcuark.bffqmul16.l t2, %[src1], %[src2]\n"
    "pqcuark.bffqmul16.h %[dst], t2, %[src2]"
    : [dst] "=r"(rd_r)
    : [src1] "r"(rs1_r), [src2] "r"(rs2_r)
  );

*rd = rd_r;

}

int main() {

  int16_t aL = 0x89AB;
  int16_t aH = 0x0123;
  int16_t bL = 0xCDEF;
  int16_t bH = 0x4567;

  int16_t q_aL = 0xCDEF;
  int16_t q_aH = 0x89AB;
  int16_t q_bL = 0x4567;
  int16_t q_bH = 0x0123;


  printf("Inputs: bH=0x%04lx, bL=0x%x, aH=0x%x, aL=0x%x\n", bH, bL, aH, aL);

  // Expected outputs
  uint16_t expected_aL, expected_aH, expected_bL, expected_bH;

  expected_bL = fqmul(bL, q_bL);
  expected_bH = fqmul(bH, q_bH);
  expected_aL = fqmul(aL, q_aL);
  expected_aH = fqmul(aH, q_aH);
  printf("Expected outputs: aH=0x%04lx, aL=0x%04lx\n", expected_aH, expected_aL);
  printf("Expected outputs: bH=0x%04lx, bL=0x%04lx\n", expected_bH, expected_bL);

  printf("expected_aH: %016lx * %016lx = %016lx\n", aH, q_aH, (uint32_t) expected_aH << 16);
  printf("expected_aL: %016lx * %016lx = %016lx\n", aL, q_aL, (uint32_t) expected_aL);
  printf("expected_bH: %016lx * %016lx = %016lx\n", bH, q_bH, (uint32_t) expected_bH << 16);
  printf("expected_bL: %016lx * %016lx = %016lx\n", bL, q_bL, (uint32_t) expected_bL);
  // Concatenate the 16-bit values into a 32-bit value
  uint64_t concatenated = (((uint64_t) expected_bH << 48) | ((uint64_t) expected_bL << 32) | ((uint64_t) expected_aH << 16) | ((uint64_t) expected_aL));
  printf("Concatenated expected value: %016lx\n", concatenated);

  uint64_t rd;
  uint64_t rs1 = 0x4567cdef012389ab;
  uint64_t rs2 = 0x0123456789abcdef;

  bffqmul_ins(&rd, &rs1, &rs2);
  // Concatenate the 16-bit values into a 64-bit value

  printf("FQMUL instruction result: %016lx\n", rd);

  // Compare the concatenated value with the result from the BFNTTK instruction
  if (rd == concatenated) {
    printf("The values match.\n");
  } else {
    printf("The values do not match.\n");
  }
  return 0;
}

