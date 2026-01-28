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

#define Q 8380417
#define QINV 58728449  // q^(-1) mod 2^32
#define N 256


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


void bffqmul32_ins(
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
    "pqcuark.bffqmul32.l t2, %[src1], %[src2]\n"
    "pqcuark.bffqmul32.h %[dst], t2, %[src2]"
    : [dst] "=r"(rd_r)
    : [src1] "r"(rs1_r), [src2] "r"(rs2_r)
  );

*rd = rd_r;

}

int main() {

  int32_t aL = 317;
  int32_t aH = 4117762;
  int32_t q_aL = 1110;
  int32_t q_aH = 5302315;


  // Expected outputs
  uint64_t expected_result;

  expected_result = (int64_t) fqmul(aH, q_aH) << 32 | (int64_t) fqmul(aL, q_aL) & 0xFFFFFFFF;

  printf("Expected outputs: a=0x%lx\n", expected_result);

  uint64_t rd;
  uint64_t rs1 = ((uint64_t)aH << 32) | (uint64_t)aL; // Concatenate the 32-bit values into a 64-bit value
  uint64_t rs2 = ((uint64_t)q_aH << 32) | (uint64_t)q_aL; // Concatenate the 32-bit values into a 64-bit value

  bffqmul32_ins(&rd, &rs1, &rs2);
  // Concatenate the 16-bit values into a 64-bit value

  printf("FQMUL instruction result: %016lx\n", rd);

  printf("rd[63:32]= %d\n", (rd >> 32) & 0xFFFFFFFF);
  printf("rd[31:0]= %d\n", rd & 0xFFFFFFFF);

  // Compare the concatenated value with the result from the BFNTTK instruction
  if (rd == expected_result) {
    printf("The values match.\n");
  } else {
    printf("The values do not match.\n");
  }
  return 0;
}

