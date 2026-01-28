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

/* Based on the public domain implementation in crypto_hash/keccakc512/simple/ from
 * http://bench.cr.yp.to/supercop.html by Ronny Van Keer and the public domain "TweetFips202"
 * implementation from https://twitter.com/tweetfips202 by Gilles Van Assche, Daniel J. Bernstein,
 * and Peter Schwabe */

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include "fips202_pqcuark.h"
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <ctype.h>

#define DEBUG 0
#define DEBUG_IO 0

#if DEBUG
  #define PRINTF(...) printf(__VA_ARGS__)
#else
  #define PRINTF(...) // no hace nada
#endif

#if DEBUG_IO
  #define PRINTF_IO(...) printf(__VA_ARGS__)
  #define FOR_IO(...) for(__VA_ARGS__)
#else
  #define PRINTF_IO(...) // no hace nada
  #define FOR_IO(...)
#endif


/*************************************************
* Name:        keccak_ld
*
* Description: Load 8 bytes into uint64_t
*
* Arguments:   - const uint64_t *x: pointer to input 64bit array
*
**************************************************/
inline void keccak_ld(uint64_t *rs1) // Probar: aixi inserta directament la funcio i no fa el jump (pero no sap que fara amb els registres)
{
    register uint64_t* rs1_r __asm__("a0");
    rs1_r = rs1;

    // Encoding for your custom instruction:
    // funct7 = 0000001, rs2 = 00000, rs1 = 01010, funct3 = 001, rd = 00000, opcode =1011011 
    // __asm__ __volatile__(
    //     ".word 0x0205105B"   // Your custom encoding
    //     :: "r"(rs1_r) // Inputs: rs1_rs
    //     : "memory"         // Clobber → warns compiler about side effects
    // );

    __asm__ __volatile__(
      "keccak.ld %[src1]"
      : 
      : [src1] "r"(rs1_r)
      : "memory"  // Añade si modifica memoria
    );

}

/*************************************************
* Name:        keccak_st
*
* Description: Store a 64-bit integer to array of 8 bytes in little-endian order
*
* Arguments:   - uint64_t *u: pointer to input 64bit array
**************************************************/
inline void keccak_st(uint64_t *rs1)
{
    register uint64_t* rs1_r __asm__("a0");
    rs1_r = rs1;
 
    // Encoding for your custom instruction:
    // funct7 = 0000001, rs2 = 00000, rs1 = 01010, funct3 = 011, rd = 00000, opcode =1011011 
    // __asm__ __volatile__(
    //     ".word 0x0205305B"   // Your custom encoding
    //     :: "r"(rs1_r) // Inputs: rs1_rs
    //     : "memory"         // Clobber → warns compiler about side effects
    // );

    __asm__ __volatile__(
      "keccak.st %[src1]"
      : 
      : [src1] "r"(rs1_r)
      : "memory"  // Añade si modifica memoria
    );
}

/*************************************************
* Name:        KeccakF1600_StatePermute
*
* Description: The Keccak F1600 Permutation
*
* Arguments:   - uint64_t *state: pointer to input/output Keccak state
**************************************************/
inline void KeccakF1600_StatePermute()
{
    // Encoding for your custom andxor instruction:
    // funct7 = 0000001, rs2 = 00000, rs1 = 00000, funct3 = 001, rd = 00000, opcode =1011011 
    // __asm__ __volatile__(
    //     ".word 0x0200205B"   // Your custom andxor encoding
    //     ::: "memory"         // ::: No inputs or outputs
    // );
    __asm__ __volatile__("keccak.f1600");

}

/*************************************************
* Name:        keccak_init
*
* Description: Initializes the Keccak state.
*
* Arguments:   - uint64_t *s: pointer to Keccak state
**************************************************/
inline void keccak_init()
{

    // Encoding for your custom instruction:
    // funct7 = 0000001, rs2 = 00000, rs1 = 00000, funct3 = 000, rd = 00000, opcode =1011011 
    // __asm__ __volatile__(
    //     ".word 0x0200005B"   // Your custom encoding
    //     ::: "memory"         // Clobber → warns compiler about side effects
    // );
  __asm__ __volatile__("keccak.init");
}

/*************************************************
* Name:        keccak_squeeze
*
* Description: Squeeze step of Keccak. Squeezes arbitratrily many bytes.
*              Modifies the state. Can be called multiple times to keep
*              squeezing, i.e., is incremental.
*
* Arguments:   - uint8_t *out: pointer to output
*              - size_t outlen: number of bytes to be squeezed (written to out)
*              - uint64_t *s: pointer to input/output Keccak state
*              - unsigned int pos: number of bytes in current block already squeezed
*              - unsigned int r: rate in bytes (e.g., 168 for SHAKE128)
*
* Returns new position pos in current block
**************************************************/
void keccak_squeeze(uint8_t *out, size_t outlen, unsigned int r)
{
  unsigned int i;
  unsigned int pos = r;
  uint64_t output_word;
  //uint64_t* addr;
  uint8_t* original_out = out; // Guardamos para imprimir después
  uint8_t *out_start = out;  // Guardamos el puntero original
  size_t outlen_orig = outlen;  // Guardamos el tamaño original

  PRINTF("Outlen: %ld\n", outlen);
  // PRINTF("Rate: %d\n", r);

  while(outlen) 
  {
    if(pos == r) 
    {
      PRINTF("Permuting...\n");
      KeccakF1600_StatePermute();
      PRINTF("finish permuting\n");
      pos = 0;
    }

    //addr = &output_words[pos/8];
    keccak_st((uint64_t *) out);
    PRINTF("Store %d: %016llx\n", pos, *(uint64_t *)out);
    // for(i=0;i < 8; i++)
    // {
    //   //PRINTF("Byte %d: %02x\n", i, ((output_word >> (8*(i%8))) & 0xFF));
    //   *out++ = (output_word >> (8*(i%8))) & 0xFF;
      
    // }
    outlen -= 8;
    pos += 8;
    out += 8;
    //PRINTF("Outlen: %ld\n", outlen);
  }
  PRINTF_IO("Output block: ");
  FOR_IO (i = 0; i < outlen_orig; i++) {
      PRINTF_IO("%02x", out_start[outlen_orig - 1 - i]);
  }
  PRINTF_IO("\n");
}

/*************************************************
* Name:        keccak_absorb_once
*
* Description: Absorb step of Keccak;
*              non-incremental, starts by zeroeing the state.
*
* Arguments:   - uint64_t *s: pointer to (uninitialized) output Keccak state
*              - unsigned int r: rate in bytes (e.g., 168 for SHAKE128)
*              - const uint8_t *in: pointer to input to be absorbed into s
*              - size_t inlen: length of input in bytes
*              - uint8_t p: domain-separation byte for different Keccak-derived functions
**************************************************/
static unsigned int keccak_absorb(unsigned int pos, unsigned int r, const uint8_t *in, size_t inlen)
{
  unsigned int i;
  const uint64_t* input_data = (const uint64_t*)in;
  uint64_t* addr;
  uint64_t in2 = 0;

  PRINTF_IO("Input: ");
  FOR_IO (size_t j = 0; j < inlen; j++) {
      PRINTF_IO("%02x", in[inlen - 1 - j]);  // Print each byte in hexadecimal
  }
  PRINTF_IO("\n");

  PRINTF("Inlen: %ld\n", inlen);
  //printf("pos = %d\n", pos);

  while(pos + inlen > r) {
    for(i=(in2/8);i<(r+in2-pos)/8;i++){
      PRINTF("Loading %d: %016lx\n", i, input_data[i]);
      keccak_ld(&input_data[i]);
    }
    in2 += r - pos;
    inlen -= r - pos;
    PRINTF("Permuting...\n");
    KeccakF1600_StatePermute();
    PRINTF("r = %d\n", r);
    PRINTF("in2 = %d ", in2);
    PRINTF("inlen = %d\n", inlen);
    pos = 0;
  }
  

  for(i=in2/8;i<(inlen+in2+7)/8;i++){
    PRINTF("Loading %d: %016lx\n", i, input_data[i]);
    keccak_ld(&input_data[i]);
    pos += 8;
  }

  //printf("pos = %d\n", pos);

  return pos;
 
}




/*************************************************
* Name:        keccak_absorb_once
*
* Description: Absorb step of Keccak;
*              non-incremental, starts by zeroeing the state.
*
* Arguments:   - uint64_t *s: pointer to (uninitialized) output Keccak state
*              - unsigned int r: rate in bytes (e.g., 168 for SHAKE128)
*              - const uint8_t *in: pointer to input to be absorbed into s
*              - size_t inlen: length of input in bytes
*              - uint8_t p: domain-separation byte for different Keccak-derived functions
**************************************************/
static void keccak_absorb_once(unsigned int r,
                               const uint8_t *in,
                               size_t inlen)
{
  unsigned int i;
  const uint64_t* input_data = (const uint64_t*)in;
  uint64_t* addr;
  uint64_t in2 = 0;

  PRINTF("Inlen: %ld\n", inlen);
  PRINTF("Initializing keccak...\n");
  keccak_init();

  PRINTF_IO("Input to absorb: ");
  FOR_IO (size_t j = 0; j < inlen; j++) {
      PRINTF_IO("%02x", in[inlen-1-j]);  // Print each byte in hexadecimal
  }
  PRINTF_IO("\n");


  while(inlen > r) {
    for(i=(in2/8);i<(r+in2)/8;i++){
      PRINTF("Loading %d: %016lx\n", i, input_data[i]);
      keccak_ld(&input_data[i]);
    }
    in2 += r;
    inlen -= r;
    PRINTF("Permuting...\n");
    KeccakF1600_StatePermute();
    PRINTF("r = %d\n", r);
    PRINTF("in2 = %d ", in2);
    PRINTF("inlen = %d\n", inlen);
  }
  

  for(i=in2/8;i<(inlen+in2+7)/8;i++){
    PRINTF("Loading %d: %016lx\n", i, input_data[i]);
    keccak_ld(&input_data[i]);
  }
 
}

/*************************************************
* Name:        keccak_squeezeblocks
*
* Description: Squeeze step of Keccak. Squeezes full blocks of r bytes each.
*              Modifies the state. Can be called multiple times to keep
*              squeezing, i.e., is incremental. Assumes zero bytes of current
*              block have already been squeezed.
*
* Arguments:   - uint8_t *out: pointer to output blocks
*              - size_t nblocks: number of blocks to be squeezed (written to out)
*              - uint64_t *s: pointer to input/output Keccak state
*              - unsigned int r: rate in bytes (e.g., 168 for SHAKE128)
**************************************************/
static void keccak_squeezeblocks(uint8_t *out,
                                 size_t nblocks,
                                 unsigned int r)
{
  unsigned int i = 0;
  unsigned int j = 0;
  uint64_t output_word;
  uint8_t *block_start = out;

  //PRINTF("keccak_squeezeblocks\n");
  //PRINTF("r/8 = %d\n", r/8);

  PRINTF_IO("Output block: ");
  while(nblocks) {
    //PRINTF("Perm\n");
    KeccakF1600_StatePermute();
    for(i=0;i<r/8;i++){
      keccak_st((uint64_t*) out);
      PRINTF("Store %d: %016llx\n", i, *(uint64_t *)out);
      out += 8;
    }
    FOR_IO(i = 0; i < r; i++) {
        PRINTF_IO("%02x", block_start[r-1-i]);  // Print each byte in hexadecimal
    }
    nblocks -= 1;
  }
  PRINTF_IO("\n");
}

/*************************************************
* Name:        shake128_init
*
* Description: Initilizes Keccak state for use as SHAKE128 XOF
*
* Arguments:   - keccak_state *state: pointer to (uninitialized) Keccak state
**************************************************/
void shake128_init()
{
  keccak_init();
}

/*************************************************
* Name:        shake128_squeeze
*
* Description: Squeeze step of SHAKE128 XOF. Squeezes arbitraily many
*              bytes. Can be called multiple times to keep squeezing.
*
* Arguments:   - uint8_t *out: pointer to output blocks
*              - size_t outlen : number of bytes to be squeezed (written to output)
*              - keccak_state *s: pointer to input/output Keccak state
**************************************************/
void shake128_squeeze(uint8_t *out, size_t outlen)
{
  keccak_squeeze(out, outlen, SHAKE128_RATE);
}

/*************************************************
* Name:        shake128_absorb
*
* Description: Initialize, absorb into and finalize SHAKE128 XOF; non-incremental.
*
* Arguments:   - keccak_state *state: pointer to (uninitialized) output Keccak state
*              - const uint8_t *in: pointer to input to be absorbed into s
*              - size_t inlen: length of input in bytes
**************************************************/
void shake128_absorb(unsigned int *pos, const uint8_t *in, size_t inlen)
{
  *pos = keccak_absorb(*pos, SHAKE128_RATE, in, inlen);
}

/*************************************************
* Name:        shake128_absorb_once
*
* Description: Initialize, absorb into and finalize SHAKE128 XOF; non-incremental.
*
* Arguments:   - keccak_state *state: pointer to (uninitialized) output Keccak state
*              - const uint8_t *in: pointer to input to be absorbed into s
*              - size_t inlen: length of input in bytes
**************************************************/
void shake128_absorb_once(const uint8_t *in, size_t inlen)
{
  keccak_absorb_once(SHAKE128_RATE, in, inlen);
}

/*************************************************
* Name:        shake128_squeezeblocks
*
* Description: Squeeze step of SHAKE128 XOF. Squeezes full blocks of
*              SHAKE128_RATE bytes each. Can be called multiple times
*              to keep squeezing. Assumes new block has not yet been
*              started (state->pos = SHAKE128_RATE).
*
* Arguments:   - uint8_t *out: pointer to output blocks
*              - size_t nblocks: number of blocks to be squeezed (written to output)
*              - keccak_state *s: pointer to input/output Keccak state
**************************************************/
void shake128_squeezeblocks(uint8_t *out, size_t nblocks)
{
  keccak_squeezeblocks(out, nblocks, SHAKE128_RATE);
}

/*************************************************
* Name:        shake256_init
*
* Description: Initilizes Keccak state for use as SHAKE256 XOF
*
* Arguments:   - keccak_state *state: pointer to (uninitialized) Keccak state
**************************************************/
void shake256_init()
{
  keccak_init();
}

/*************************************************
* Name:        shake256_squeeze
*
* Description: Squeeze step of SHAKE256 XOF. Squeezes arbitraily many
*              bytes. Can be called multiple times to keep squeezing.
*
* Arguments:   - uint8_t *out: pointer to output blocks
*              - size_t outlen : number of bytes to be squeezed (written to output)
*              - keccak_state *s: pointer to input/output Keccak state
**************************************************/
void shake256_squeeze(uint8_t *out, size_t outlen)
{
  keccak_squeeze(out, outlen, SHAKE256_RATE);
}

/*************************************************
* Name:        shake256_absorb
*
* Description: Initialize, absorb into and finalize SHAKE256 XOF; non-incremental.
*
* Arguments:   - keccak_state *state: pointer to (uninitialized) output Keccak state
*              - const uint8_t *in: pointer to input to be absorbed into s
*              - size_t inlen: length of input in bytes
**************************************************/
void shake256_absorb(unsigned int *pos, const uint8_t *in, size_t inlen)
{
  *pos = keccak_absorb(*pos, SHAKE256_RATE, in, inlen);
}


/*************************************************
* Name:        shake256_absorb_once
*
* Description: Initialize, absorb into and finalize SHAKE256 XOF; non-incremental.
*
* Arguments:   - keccak_state *state: pointer to (uninitialized) output Keccak state
*              - const uint8_t *in: pointer to input to be absorbed into s
*              - size_t inlen: length of input in bytes
**************************************************/
void shake256_absorb_once(const uint8_t *in, size_t inlen)
{
  keccak_absorb_once(SHAKE256_RATE, in, inlen);
}

/*************************************************
* Name:        shake256_squeezeblocks
*
* Description: Squeeze step of SHAKE256 XOF. Squeezes full blocks of
*              SHAKE256_RATE bytes each. Can be called multiple times
*              to keep squeezing. Assumes next block has not yet been
*              started (state->pos = SHAKE256_RATE).
*
* Arguments:   - uint8_t *out: pointer to output blocks
*              - size_t nblocks: number of blocks to be squeezed (written to output)
*              - keccak_state *s: pointer to input/output Keccak state
**************************************************/
void shake256_squeezeblocks(uint8_t *out, size_t nblocks)
{
  keccak_squeezeblocks(out, nblocks, SHAKE256_RATE);
}

/*************************************************
* Name:        shake128
*
* Description: SHAKE128 XOF with non-incremental API
*
* Arguments:   - uint8_t *out: pointer to output
*              - size_t outlen: requested output length in bytes
*              - const uint8_t *in: pointer to input
*              - size_t inlen: length of input in bytes
**************************************************/
void shake128(uint8_t *out, size_t outlen, const uint8_t *in, size_t inlen)
{
  size_t nblocks;
  uint32_t inlen_csr;

  // printf("Received size: %ld\n", inlen);
  asm volatile ("csrw 0x816, %0" :: "rK"(inlen)); // CSR_KECCAK_INLEN
  asm volatile ("csrw 0x817, %0" :: "rK"(0));

  shake128_absorb_once(in, inlen);
  nblocks = outlen/SHAKE128_RATE;
  //PRINTF("Nblocks: %d/%d = %ld\n", outlen, SHAKE128_RATE, nblocks);
  shake128_squeezeblocks(out, nblocks);
  outlen -= nblocks*SHAKE128_RATE;
  shake128_squeeze(out + nblocks*SHAKE128_RATE, outlen);
}

/*************************************************
* Name:        shake256
*
* Description: SHAKE256 XOF with non-incremental API
*
* Arguments:   - uint8_t *out: pointer to output
*              - size_t outlen: requested output length in bytes
*              - const uint8_t *in: pointer to input
*              - size_t inlen: length of input in bytes
**************************************************/
void shake256(uint8_t *out, size_t outlen, const uint8_t *in, size_t inlen)
{
  size_t nblocks;

  asm volatile ("csrw 0x816, %0" :: "rK"(inlen)); // CSR_KECCAK_INLEN
  asm volatile ("csrw 0x817, %0" :: "rK"(1));


  shake256_absorb_once(in, inlen);
  nblocks = outlen/SHAKE256_RATE;
  shake256_squeezeblocks(out, nblocks);
  outlen -= nblocks*SHAKE256_RATE;
  shake256_squeeze(out + nblocks*SHAKE256_RATE, outlen);

}

/*************************************************
* Name:        sha3_256
*
* Description: SHA3-256 with non-incremental API
*
* Arguments:   - uint8_t *h: pointer to output (32 bytes)
*              - const uint8_t *in: pointer to input
*              - size_t inlen: length of input in bytes
**************************************************/
void sha3_256(uint8_t *out, const uint8_t *in, size_t inlen)
{
  unsigned int i;
  uint64_t *addr;
  uint64_t output_word;
  unsigned int pos = 0;

  PRINTF("inlen\n: %d", inlen);

  // printf("Input: \n");
  // for (size_t j = 0; j < inlen; j++) {
  //     printf("%02x", in[inlen - 1 - j]);  // Print each byte in hexadecimal
  // }
  // printf("\n");

  asm volatile ("csrw 0x816, %0" :: "rK"(inlen)); // CSR_KECCAK_INLEN
  asm volatile ("csrw 0x817, %0" :: "rK"(2));

  keccak_absorb_once(SHA3_256_RATE, in, inlen);
  //KeccakF1600_StatePermute();
  // //asm volatile("fence" ::: "memory");
  keccak_squeeze(out, 32, SHA3_256_RATE);
  
}

/*************************************************
* Name:        sha3_512
*
* Description: SHA3-512 with non-incremental API
*
* Arguments:   - uint8_t *h: pointer to output (64 bytes)
*              - const uint8_t *in: pointer to input
*              - size_t inlen: length of input in bytes
**************************************************/
void sha3_512(uint8_t *out, const uint8_t *in, size_t inlen)
{
  unsigned int i;
  uint64_t *addr;
  uint64_t output_word;
  unsigned int pos = 0;

  PRINTF("SHA3-512\n");

  asm volatile ("csrw 0x816, %0" :: "rK"(inlen)); // CSR_KECCAK_INLEN
  asm volatile ("csrw 0x817, %0" :: "rK"(3));

  // printf("Input: \n");
  // for (size_t j = 0; j < inlen; j++) {
  //     printf("%02x", in[inlen - 1 - j]);  // Print each byte in hexadecimal
  // }
  // printf("\n");

  keccak_absorb_once(SHA3_512_RATE, in, inlen);
  //KeccakF1600_StatePermute();
  // //asm volatile("fence" ::: "memory");
  keccak_squeeze(out, 64, SHA3_512_RATE);

}