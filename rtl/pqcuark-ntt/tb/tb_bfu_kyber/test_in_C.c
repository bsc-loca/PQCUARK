// Copyright 2026 Barcelona Supercomputing Center (BSC)
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License");
// you may not use this file except in compliance with the License, or,
// at your option, the Apache License version 2.0.
// You may obtain a copy of the License at
//
//     https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

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
  printf("a: %d\n", a);
  t = (int16_t)a*QINV;
  printf("t=> %d * %d = %d\n", (int16_t)a, QINV, t);
  t = (a - (int32_t)t*KYBER_Q) >> 16;
  printf("Montgomery reduce: t=%d\n", t);
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
  printf("v_mul_a: %x\n", (int32_t)v*a);
  printf("sum: %x\n", ((int32_t)v*a + (1<<25)));
  printf("shift: %x\n", (((int32_t)v*a + (1<<25)) >> 26));
  t  = ((int32_t)v*a + (1<<25)) >> 26;
  t *= KYBER_Q;
  printf("mult_q: %x\n", t);
  printf("Barret reduce: %x - %x -> reduced=%x\n", a, t, a-t);
  return a - t;
}

// Modular multiplication
int16_t fqmul(int16_t a, int16_t b) {
    printf("fqmul input product: a * b = %x * %x = %x\n", a, b, ((int32_t) a * b));
    return montgomery_reduce((int32_t)a * b);
    // int16_t mul;
    // mul = (int32_t)(a * b) % KYBER_Q;
    // return mul;
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
    printf("y - t = %x - %x\n", *y, t);
    *y = *y - t;
    printf("intt_butterfly mid: zeta=> %x y => %x\n", zeta, *y);
    *y = fqmul(zeta, *y);
}

int main() {

  int16_t x1 = 0x10d;
  int16_t x2 = 0xfa25;
  int16_t y1 = 0x5e7;
  int16_t y2 = 0xfd08;
  int16_t zeta_x = zetas[0];
  int16_t zeta_y = zetas[1];

  printf("Inputs: x1=%x, x2=%x, y1=%x, y2=%x, zeta_x=%x, zeta_y=%x\n", x1, x2, y1, y2, zeta_x, zeta_y);

  // Expected outputs
  int16_t expected_x1 = x1, expected_x2 = x2;
  int16_t expected_y1 = y1, expected_y2 = y2;

  intt_butterfly(&expected_x1, &expected_x2, zeta_x);
  intt_butterfly(&expected_y1, &expected_y2, zeta_y);

  printf("Expected outputs: x1=%x, x2=%x, y1=%x, y2=%x\n", expected_x1, expected_x2, expected_y1, expected_y2);

    return 0;
}
