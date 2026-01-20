#include <stdint.h>
#include "reduce.h"
#include "params.h"
#include "ntt_pqcuark.h"

const int16_t zetas[128] = {
  -1044, -758,  -359,  -1517, 1493,  1422,  287,   202,  -171,  622,   1577,
  182,   962,   -1202, -1474, 1468,  573,   -1325, 264,  383,   -829,  1458,
  -1602, -130,  -681,  1017,  732,   608,   -1542, 411,  -205,  -1571, 1223,
  652,   -552,  1015,  -1293, 1491,  -282,  -1544, 516,  -8,    -320,  -666,
  -1618, -1162, 126,   1469,  -853,  -90,   -271,  830,  107,   -1421, -247,
  -951,  -398,  961,   -1508, -725,  448,   -1065, 677,  -1275, -1103, 430,
  555,   843,   -1251, 871,   1550,  105,   422,   587,  177,   -235,  -291,
  -460,  1574,  1653,  -246,  778,   1159,  -147,  -777, 1483,  -602,  1119,
  -1590, 644,   -872,  349,   418,   329,   -156,  -75,  817,   1097,  603,
  610,   1322,  -1285, -1465, 384,   -1215, -136,  1218, -1335, -874,  220,
  -1187, -1659, -1185, -1530, -1278, 794,   -1510, -854, -870,  478,   -108,
  -308,  996,   991,   958,   -1460, 1522,  1628};
  

static int16_t fqmul(int16_t a, int16_t b) {
  return montgomery_reduce((int32_t)a*b);
}

void ntt_pqcuark(int16_t r[256]) {
  ntt_pqcuark_asm(r);
}

void intt_pqcuark(int16_t r[256]) {
  intt_pqcuark_asm(r);
  fqmul_pqcuark_asm(r);
  //  for int j = 0; j < 256; j++)
  //    r[j] = fqmul(r[j], 1441);
}

void basemul_pqcuark(int16_t r[2], const int16_t a[2], const int16_t b[2],
                     int16_t zeta) {
  __asm__ __volatile__(
      /* 1–2: load a and b ---------------------------------------------- */
      "lw          t0, 0(%[A])              \n\t" /* t0 = {a1,a0}       */
      "lw          t1, 0(%[B])              \n\t" /* t1 = {b1,b0}       */

      /* 3: parallel products a1*b1 and a0*b0 ---------------------------- */
      "pqcuark.bffqmul16.l t2, t0, t1       \n\t"

      /* 4: cross-swap b0<->b1 (word-rotate right by 16) ---------------- */
      "roriw       t3, t1, 16               \n\t" /* t3 = {b0,b1}       */

      /* 5: cross products a1*b0 and a0*b1 -------------------------------- */
      "pqcuark.bffqmul16.l t3, t0, t3       \n\t"

      /* 6–9: r0 = zeta*(a1*b1) + a0*b0 ---------------------------------- */
      "srli        t4, t2, 16               \n\t" /* t4.low = a1*b1     */
      "pqcuark.bffqmul16.l t4, t4, %[Z]     \n\t"
      "zext.h      t2, t2                   \n\t" /* t2.low = a0*b0     */
      "add         t4, t4, t2               \n\t" /* t4.low = r0        */

      /* 10–12: r1 = a0*b1 + a1*b0 --------------------------------------- */
      "srli        t2, t3, 16               \n\t" /* t2.low = a1*b0     */
      "zext.h      t3, t3                   \n\t" /* t3.low = a0*b1     */
      "add         t3, t3, t2               \n\t" /* t3.low = r1        */

      /* 13–14: store ----------------------------------------------------- */
      "sh          t4, 0(%[R])              \n\t" /* r[0] = r0          */
      "sh          t3, 2(%[R])              \n\t" /* r[1] = r1          */
      :
      : [R] "r"(r), [A] "r"(a), [B] "r"(b), [Z] "r"((uint16_t)zeta)
      : "t0", "t1", "t2", "t3", "t4", "memory");
}

void basemul_acc_pqcuark(int16_t r[2], const int16_t a[2], const int16_t b[2],
                     int16_t zeta) {
  __asm__ __volatile__(
      /* 1–2: load a and b ---------------------------------------------- */
      "lw          t0, 0(%[A])              \n\t" /* t0 = {a1,a0}       */
      "lw          t1, 0(%[B])              \n\t" /* t1 = {b1,b0}       */
      "lh          t5, 0(%[R])              \n\t" /* t5 = {0,r0}       */
      "lh          t6, 2(%[R])              \n\t" /* t6 = {0,r1}       */

      /* 3: parallel products a1*b1 and a0*b0 ---------------------------- */
      "pqcuark.bffqmul16.l t2, t0, t1       \n\t"

      /* 4: cross-swap b0<->b1 (word-rotate right by 16) ---------------- */
      "roriw       t3, t1, 16               \n\t" /* t3 = {b0,b1}       */

      /* 5: cross products a1*b0 and a0*b1 -------------------------------- */
      "pqcuark.bffqmul16.l t3, t0, t3       \n\t"

      /* 6–9: r0 += zeta*(a1*b1) + a0*b0 ---------------------------------- */
      "srli        t4, t2, 16               \n\t" /* t4.low = a1*b1     */
      "pqcuark.bffqmul16.l t4, t4, %[Z]     \n\t"
      "zext.h      t2, t2                   \n\t" /* t2.low = a0*b0     */
      "add         t4, t4, t2               \n\t" /* t4.low = r0        */
      "add         t4, t4, t5               \n\t" /* t4.low = t5.low + t4.low */

      /* 10–12: r1 += a0*b1 + a1*b0 --------------------------------------- */
      "srli        t2, t3, 16               \n\t" /* t2.low = a1*b0     */
      "zext.h      t3, t3                   \n\t" /* t3.low = a0*b1     */
      "add         t3, t3, t2               \n\t" /* t3.low = r1        */
      "add         t3, t3, t6               \n\t" /* t3.low = t6.low + t3.low */

      /* 13–14: store ----------------------------------------------------- */
      "sh          t4, 0(%[R])              \n\t" /* r[0] = r0          */
      "sh          t3, 2(%[R])              \n\t" /* r[1] = r1          */
      :
      : [R] "rw"(r), [A] "r"(a), [B] "r"(b), [Z] "r"((uint16_t)zeta)
      : "t0", "t1", "t2", "t3", "t4", "t5", "t6", "memory");
}