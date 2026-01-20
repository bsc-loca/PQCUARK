.macro load_coeffs poly, len, wordLen
  ld s0,  \len*\wordLen*0(\poly)
  ld s1,  \len*\wordLen*1(\poly)
  ld s2,  \len*\wordLen*2(\poly)
  ld s3,  \len*\wordLen*3(\poly)
  ld s4,  \len*\wordLen*4(\poly)
  ld s5,  \len*\wordLen*5(\poly)
  ld s6,  \len*\wordLen*6(\poly)
  ld s7,  \len*\wordLen*7(\poly)
  ld s8,  \len*\wordLen*8(\poly)
  ld s9,  \len*\wordLen*9(\poly)
  ld s10, \len*\wordLen*10(\poly)
  ld s11, \len*\wordLen*11(\poly)
  ld a2,  \len*\wordLen*12(\poly)
  ld a3,  \len*\wordLen*13(\poly)
  ld a4,  \len*\wordLen*14(\poly)
  ld a5,  \len*\wordLen*15(\poly)
.endm

.macro store_coeffs poly, len, wordLen
  sd s0,  \len*\wordLen*0(\poly)
  sd s1,  \len*\wordLen*1(\poly)
  sd s2,  \len*\wordLen*2(\poly)
  sd s3,  \len*\wordLen*3(\poly)
  sd s4,  \len*\wordLen*4(\poly)
  sd s5,  \len*\wordLen*5(\poly)
  sd s6,  \len*\wordLen*6(\poly)
  sd s7,  \len*\wordLen*7(\poly)
  sd s8,  \len*\wordLen*8(\poly)
  sd s9,  \len*\wordLen*9(\poly)
  sd s10, \len*\wordLen*10(\poly)
  sd s11, \len*\wordLen*11(\poly)
  sd a2,  \len*\wordLen*12(\poly)
  sd a3,  \len*\wordLen*13(\poly)
  sd a4,  \len*\wordLen*14(\poly)
  sd a5,  \len*\wordLen*15(\poly)
.endm

.macro save_regs
  sd s0,  0*8(sp)
  sd s1,  1*8(sp)
  sd s2,  2*8(sp)
  sd s3,  3*8(sp)
  sd s4,  4*8(sp)
  sd s5,  5*8(sp)
  sd s6,  6*8(sp)
  sd s7,  7*8(sp)
  sd s8,  8*8(sp)
  sd s9,  9*8(sp)
  sd s10, 10*8(sp)
  sd s11, 11*8(sp)
  sd gp,  12*8(sp)
  sd tp,  13*8(sp)
  sd ra,  14*8(sp)
.endm

.macro restore_regs
  ld s0,  0*8(sp)
  ld s1,  1*8(sp)
  ld s2,  2*8(sp)
  ld s3,  3*8(sp)
  ld s4,  4*8(sp)
  ld s5,  5*8(sp)
  ld s6,  6*8(sp)
  ld s7,  7*8(sp)
  ld s8,  8*8(sp)
  ld s9,  9*8(sp)
  ld s10, 10*8(sp)
  ld s11, 11*8(sp)
  ld gp,  12*8(sp)
  ld tp,  13*8(sp)
  ld ra,  14*8(sp)
.endm

.macro build_k_pair k_pair k
  li \k_pair, \k                  // Load the immediate value of k into k_pair
.endm

.macro pack_lsb rd rs1 rs2 
  pack \rd, \rs1, \rs2    # rd = (rs1[31:0], rs2[31:0])
.endm

# .macro pack_msb rd, rs1, rs2
#   rori t0, \rs1, 32       # shift left to bits 63:32
#   rori t1, \rs2, 32       # shift right to bits 31:0
#   pack \rd, t0, t1        # rd = (rs1[63:32], rs2[63:32])
# .endm
.macro pack_msb rd, rs1, rs2
  packh \rd, \rs1, \rs2    # rd = (rs1[63:32], rs2[63:32])
.endm

.macro add32 rd, rs1, rs2
  slli s9, \rs1, 32       # Shift rs1 to upper 32 bits
  srli s9, s9, 32         # Shift back to lower 32 bits
  slli s10, \rs2, 32      # Shift rs2 to upper 32 bits
  srli s10, s10, 32       # Shift back to lower 32 bits
  add s9, s9, s10         # Add lower 32 bits

  srli s10, \rs1, 32      # Shift upper 32 bits of rs1 to lower
  srli s11, \rs2, 32      # Shift upper 32 bits of rs2 to lower
  add s10, s10, s11       # Add upper 32 bits

  pack \rd, s10, s9       # Combine upper and lower 32 bits
.endm

### LAYER 1+2+3+4
.macro ntt_pqcuark_loop1
    addi a0, a0, -8
    // 16*i, i \in [0-15]
    load_coeffs a0, 8, 8 
    // layer 1 LEN=128
    build_k_pair t4, 1      // Load twiddle factor
    pack_lsb t5, s8, s0 // (s8[32:0], s0[32:0])
    pack_msb t6, s8, s0 // (s8[64:32], s0[64:32])
    pack_lsb a6, s9, s1 // (s9[32:0], s1[32:0])
    pack_msb a7, s9, s1 // (s9[64:32], s1[64:32])
    pqcuark.bfnttd t5, t5, t4 
    pqcuark.bfnttd t6, t6, t4
    pqcuark.bfnttd a6, a6, t4 
    pqcuark.bfnttd a7, a7, t4
    pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s8, t6, t5 // (t6[64:32], t5[64:32]) 
    pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s9, a7, a6 // (a7[64:32], a6[64:32])

    pack_lsb t5, s10, s2 // (s10[32:0], s2[32:0])
    pack_msb t6, s10, s2 // (s10[64:32], s2[64:32])
    pack_lsb a6, s11, s3 // (s11[32:0], s3[32:0])
    pack_msb a7, s11, s3 // (s11[64:32], s3[64:32])
    pqcuark.bfnttd t5, t5, t4
    pqcuark.bfnttd t6, t6, t4
    pqcuark.bfnttd a6, a6, t4
    pqcuark.bfnttd a7, a7, t4
    pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s10, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s3, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])
    

    pack_lsb t5, a2, s4 // (a2[32:0], s4[32:0])
    pack_msb t6, a2, s4 // (a2[64:32], s4[64:32])
    pack_lsb a6, a3, s5 // (a3[32:0], s5[32:0])
    pack_msb a7, a3, s5 // (a3[64:32], s5[64:32])
    pqcuark.bfnttd t5, t5, t4
    pqcuark.bfnttd t6, t6, t4
    pqcuark.bfnttd a6, a6, t4
    pqcuark.bfnttd a7, a7, t4
    pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb a2, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s5, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb a3, a7, a6 // (a7[64:32], a6[64:32])
    

    pack_lsb t5, a4, s6 // (a4[32:0], s6[32:0])
    pack_msb t6, a4, s6 // (a4[64:32], s6[64:32])
    pack_lsb a6, a5, s7 // (a5[32:0], s7[32:0])
    pack_msb a7, a5, s7 // (a5[64:32], s7[64:32])
    pqcuark.bfnttd t5, t5, t4
    pqcuark.bfnttd t6, t6, t4
    pqcuark.bfnttd a6, a6, t4
    pqcuark.bfnttd a7, a7, t4
    pack_lsb s6, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s7, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

    // layer 2 LEN=64
    build_k_pair t4, 2      // Load twiddle factor
    pack_lsb t5, s4, s0 // (s4[32:0], s0[32:0])
    pack_msb t6, s4, s0 // (s4[64:32], s0[64:32])
    pack_lsb a6, s5, s1 // (s5[32:0], s1[32:0])
    pack_msb a7, s5, s1 // (s5[64:32], s1[64:32])
    pqcuark.bfnttd t5, t5, t4 
    pqcuark.bfnttd t6, t6, t4
    pqcuark.bfnttd a6, a6, t4 
    pqcuark.bfnttd a7, a7, t4
    pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s4, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s5, a7, a6 // (a7[64:32], a6[64:32])

    pack_lsb t5, s6, s2 // (s6[32:0], s2[32:0])
    pack_msb t6, s6, s2 // (s6[64:32], s2[64:32])
    pack_lsb a6, s7, s3 // (s7[32:0], s3[32:0])
    pack_msb a7, s7, s3 // (s7[64:32], s3[64:32])
    pqcuark.bfnttd t5, t5, t4
    pqcuark.bfnttd t6, t6, t4
    pqcuark.bfnttd a6, a6, t4 
    pqcuark.bfnttd a7, a7, t4
    pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s3, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

    build_k_pair t4, 3      // Load twiddle factor
    pack_lsb t5, a2, s8 // (a2[32:0], s8[32:0])
    pack_msb t6, a2, s8 // (a2[64:32], s8[64:32])
    pack_lsb a6, a3, s9 // (a3[32:0], s9[32:0])
    pack_msb a7, a3, s9 // (a3[64:32], s9[64:32])
    pqcuark.bfnttd t5, t5, t4 
    pqcuark.bfnttd t6, t6, t4
    pqcuark.bfnttd a6, a6, t4 
    pqcuark.bfnttd a7, a7, t4
    pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb a2, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb a3, a7, a6 // (a7[64:32], a6[64:32])

    pack_lsb t5, a4, s10 // (a4[32:0], s10[32:0])
    pack_msb t6, a4, s10 // (a4[64:32], s10[64:32])
    pack_lsb a6, a5, s11 // (a5[32:0], s11[32:0])
    pack_msb a7, a5, s11 // (a5[64:32], s11[64:32])
    pqcuark.bfnttd t5, t5, t4
    pqcuark.bfnttd t6, t6, t4
    pqcuark.bfnttd a6, a6, t4 
    pqcuark.bfnttd a7, a7, t4
    pack_lsb s10, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s11, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

    // layer 3 LEN=32
    build_k_pair t4, 4      // Load twiddle factor
    pack_lsb t5, s2, s0 // (s2[32:0], s0[32:0])
    pack_msb t6, s2, s0 // (s2[64:32], s0[64:32])
    pack_lsb a6, s3, s1 // (s3[32:0], s1[32:0])
    pack_msb a7, s3, s1 // (s3[64:32], s1[64:32])
    pqcuark.bfnttd t5, t5, t4 
    pqcuark.bfnttd t6, t6, t4
    pqcuark.bfnttd a6, a6, t4 
    pqcuark.bfnttd a7, a7, t4
    pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s2, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s3, a7, a6 // (a7[64:32], a6[64:32])

    build_k_pair t4, 5      // Load twiddle factor
    pack_lsb t5, s6, s4 // (s6[32:0], s4[32:0])
    pack_msb t6, s6, s4 // (s6[64:32], s4[64:32])
    pack_lsb a6, s7, s5 // (s7[32:0], s5[32:0])
    pack_msb a7, s7, s5 // (s7[64:32], s5[64:32])
    pqcuark.bfnttd t5, t5, t4 
    pqcuark.bfnttd t6, t6, t4
    pqcuark.bfnttd a6, a6, t4 
    pqcuark.bfnttd a7, a7, t4
    pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s5, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

    build_k_pair t4, 6      // Load twiddle factor
    pack_lsb t5, s10, s8 // (s10[32:0], s8[32:0])
    pack_msb t6, s10, s8 // (s10[64:32], s8[64:32])
    pack_lsb a6, s11, s9 // (s11[32:0], s9[32:0])
    pack_msb a7, s11, s9 // (s11[64:32], s9[64:32])
    pqcuark.bfnttd t5, t5, t4 
    pqcuark.bfnttd t6, t6, t4
    pqcuark.bfnttd a6, a6, t4 
    pqcuark.bfnttd a7, a7, t4
    pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s10, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

    build_k_pair t4, 7      // Load twiddle factor
    pack_lsb t5, a4, a2 // (a4[32:0], a2[32:0])
    pack_msb t6, a4, a2 // (a4[64:32], a2[64:32])
    pack_lsb a6, a5, a3 // (a5[32:0], a3[32:0])
    pack_msb a7, a5, a3 // (a5[64:32], a3[64:32])
    pqcuark.bfnttd t5, t5, t4 
    pqcuark.bfnttd t6, t6, t4
    pqcuark.bfnttd a6, a6, t4 
    pqcuark.bfnttd a7, a7, t4
    pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb a3, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

    // layer 4 LEN=16
    build_k_pair t4, 8      // Load twiddle factor
    pack_lsb t5, s1, s0 // (s1[32:0], s0[32:0])
    pack_msb t6, s1, s0 // (s1[64:32], s0[64:32])
    pqcuark.bfnttd t5, t5, t4 
    pqcuark.bfnttd t6, t6, t4
    pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s1, t6, t5 // (t6[64:32], t5[64:32])

    build_k_pair t4, 9      // Load twiddle factor
    pack_lsb t5, s3, s2 // (s3[32:0], s2[32:0])
    pack_msb t6, s3, s2 // (s3[64:32], s2[64:32])
    pqcuark.bfnttd t5, t5, t4
    pqcuark.bfnttd t6, t6, t4
    pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s3, t6, t5 // (t6[64:32], t5[64:32])

    build_k_pair t4, 10      // Load twiddle factor
    pack_lsb t5, s5, s4 // (s5[32:0], s4[32:0])
    pack_msb t6, s5, s4 // (s5[64:32], s4[64:32])
    pqcuark.bfnttd t5, t5, t4
    pqcuark.bfnttd t6, t6, t4
    pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s5, t6, t5 // (t6[64:32], t5[64:32])

    build_k_pair t4, 11     // Load twiddle factor
    pack_lsb t5, s7, s6 // (s7[32:0], s6[32:0])
    pack_msb t6, s7, s6 // (s7[64:32], s6[64:32])
    pqcuark.bfnttd t5, t5, t4
    pqcuark.bfnttd t6, t6, t4
    pack_lsb s6, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s7, t6, t5 // (t6[64:32], t5[64:32])

    build_k_pair t4, 12     // Load twiddle factor
    pack_lsb t5, s9, s8 // (s9[32:0], s8[32:0])
    pack_msb t6, s9, s8 // (s9[64:32], s8[64:32])
    pqcuark.bfnttd t5, t5, t4
    pqcuark.bfnttd t6, t6, t4
    pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s9, t6, t5 // (t6[64:32], t5[64:32])

    build_k_pair t4, 13     // Load twiddle factor
    pack_lsb t5, s11, s10 // (s11[32:0], s10[32:0])
    pack_msb t6, s11, s10 // (s11[64:32], s10[64:32])
    pqcuark.bfnttd t5, t5, t4
    pqcuark.bfnttd t6, t6, t4
    pack_lsb s10, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s11, t6, t5 // (t6[64:32], t5[64:32])


    build_k_pair t4, 14     // Load twiddle factor
    pack_lsb t5, a3, a2 // (a3[32:0], a2[32:0])
    pack_msb t6, a3, a2 // (a3[64:32], a2[64:32])
    pqcuark.bfnttd t5, t5, t4 
    pqcuark.bfnttd t6, t6, t4
    pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb a3, t6, t5 // (t6[64:32], t5[64:32])

    build_k_pair t4, 15     // Load twiddle factor
    pack_lsb t5, a5, a4 // (a5[32:0], a4[32:0])
    pack_msb t6, a5, a4 // (a5[64:32], a4[64:32])
    pqcuark.bfnttd t5, t5, t4
    pqcuark.bfnttd t6, t6, t4
    pack_lsb a4, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb a5, t6, t5 // (t6[64:32], t5[64:32])

    // store 16 coeffs
    store_coeffs a0, 8, 8
.endm

.macro ntt_pqcuark_loop2 base
  // load coefficients
  load_coeffs a0, 8, 1
  // layer 5 LEN=8
  build_k_pair t4, 16+2*\base     // Load twiddle factor
  pack_lsb t5, s4, s0 // (s4[32:0], s0[32:0])
  pack_msb t6, s4, s0 // (s4[64:32], s0[64:32])
  pack_lsb a6, s5, s1 // (s5[32:0], s1[32:0])
  pack_msb a7, s5, s1 // (s5[64:32], s1[64:32])
  pqcuark.bfnttd t5, t5, t4
  pqcuark.bfnttd t6, t6, t4
  pqcuark.bfnttd a6, a6, t4
  pqcuark.bfnttd a7, a7, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s4, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s5, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, s6, s2 // (s6[32:0], s2[32:0])
  pack_msb t6, s6, s2 // (s6[64:32], s2[64:32])
  pack_lsb a6, s7, s3 // (s7[32:0], s3[32:0])
  pack_msb a7, s7, s3 // (s7[64:32], s3[64:32])
  pqcuark.bfnttd t5, t5, t4
  pqcuark.bfnttd t6, t6, t4
  pqcuark.bfnttd a6, a6, t4
  pqcuark.bfnttd a7, a7, t4
  pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s3, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 17+2*\base     // Load twiddle factor
  pack_lsb t5, a2, s8 // (a2[32:0], s8[32:0])
  pack_msb t6, a2, s8 // (a2[64:32], s8[64:32])
  pack_lsb a6, a3, s9 // (a3[32:0], s9[32:0])
  pack_msb a7, a3, s9 // (a3[64:32], s9[64:32])
  pqcuark.bfnttd t5, t5, t4
  pqcuark.bfnttd t6, t6, t4
  pqcuark.bfnttd a6, a6, t4
  pqcuark.bfnttd a7, a7, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a2, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a3, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, a4, s10 // (a4[32:0], s10[32:0])
  pack_msb t6, a4, s10 // (a4[64:32], s10[64:32])
  pack_lsb a6, a5, s11 // (a5[32:0], s11[32:0])
  pack_msb a7, a5, s11 // (a5[64:32], s11[64:32])
  pqcuark.bfnttd t5, t5, t4
  pqcuark.bfnttd t6, t6, t4
  pqcuark.bfnttd a6, a6, t4
  pqcuark.bfnttd a7, a7, t4
  pack_lsb s10, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s11, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

  // layer 6 LEN=4
  build_k_pair t4, 32+4*\base     // Load twiddle factor
  pack_lsb t5, s2, s0 // (s2[32:0], s0[32:0])
  pack_msb t6, s2, s0 // (s2[64:32], s0[64:32])
  pqcuark.bfnttd t5, t5, t4
  pqcuark.bfnttd t6, t6, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s2, t6, t5 // (t6[64:32], t5[64:32])

  pack_lsb a6, s3, s1 // (s3[32:0], s1[32:0])
  pack_msb a7, s3, s1 // (s3[64:32], s1[64:32])
  pqcuark.bfnttd a6, a6, t4
  pqcuark.bfnttd a7, a7, t4
  pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s3, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 33+4*\base     // Load twiddle factor
  pack_lsb t5, s6, s4 // (s6[32:0], s4[32:0])
  pack_msb t6, s6, s4 // (s6[64:32], s4[64:32])
  pqcuark.bfnttd t5, t5, t4
  pqcuark.bfnttd t6, t6, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])

  pack_lsb a6, s7, s5 // (s7[32:0], s5[32:0])
  pack_msb a7, s7, s5 // (s7[64:32], s5[64:32])
  pqcuark.bfnttd a6, a6, t4
  pqcuark.bfnttd a7, a7, t4
  pack_lsb s5, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 34+4*\base     // Load twiddle factor
  pack_lsb t5, s10, s8 // (s10[32:0], s8[32:0])
  pack_msb t6, s10, s8 // (s10[64:32], s8[64:32])
  pqcuark.bfnttd t5, t5, t4
  pqcuark.bfnttd t6, t6, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s10, t6, t5 // (t6[64:32], t5[64:32])

  pack_lsb a6, s11, s9 // (s11[32:0], s9[32:0])
  pack_msb a7, s11, s9 // (s11[64:32], s9[64:32])
  pqcuark.bfnttd a6, a6, t4
  pqcuark.bfnttd a7, a7, t4
  pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 35+4*\base     // Load twiddle factor
  pack_lsb t5, a4, a2 // (a4[32:0], a2[32:0])
  pack_msb t6, a4, a2 // (a4[64:32], a2[64:32])
  pqcuark.bfnttd t5, t5, t4
  pqcuark.bfnttd t6, t6, t4
  pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])


  pack_lsb a6, a5, a3 // (a5[32:0], a3[32:0])
  pack_msb a7, a5, a3 // (a5[64:32], a3[64:32])
  pqcuark.bfnttd a6, a6, t4
  pqcuark.bfnttd a7, a7, t4
  pack_lsb a3, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

  // layer 7 LEN=2
  build_k_pair t4, 64+8*\base     // Load twiddle factor
  pack_lsb t5, s1, s0 // (s1[32:0], s0[32:0])
  pack_msb t6, s1, s0 // (s1[64:32], s0[64:32])
  pqcuark.bfnttd t5, t5, t4
  pqcuark.bfnttd t6, t6, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s1, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 65+8*\base     // Load twiddle factor
  pack_lsb a6, s3, s2 // (s3[32:0], s2[32:0])
  pack_msb a7, s3, s2 // (s3[64:32], s2[64:32])
  pqcuark.bfnttd a6, a6, t4
  pqcuark.bfnttd a7, a7, t4
  pack_lsb s2, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s3, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 66+8*\base     // Load twiddle factor
  pack_lsb t5, s5, s4 // (s5[32:0], s4[32:0])
  pack_msb t6, s5, s4 // (s5[64:32], s4[64:32])
  pqcuark.bfnttd t5, t5, t4
  pqcuark.bfnttd t6, t6, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s5, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 67+8*\base     // Load twiddle factor
  pack_lsb a6, s7, s6 // (s7[32:0], s6[32:0])
  pack_msb a7, s7, s6 // (s7[64:32], s6[64:32])
  pqcuark.bfnttd a6, a6, t4
  pqcuark.bfnttd a7, a7, t4
  pack_lsb s6, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 68+8*\base     // Load twiddle factor
  pack_lsb t5, s9, s8 // (s9[32:0], s8[32:0])
  pack_msb t6, s9, s8 // (s9[64:32], s8[64:32])
  pqcuark.bfnttd t5, t5, t4
  pqcuark.bfnttd t6, t6, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s9, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 69+8*\base     // Load twiddle factor
  pack_lsb a6, s11, s10 // (s11[32:0], s10[32:0])
  pack_msb a7, s11, s10 // (s11[64:32], s10[64:32])
  pqcuark.bfnttd a6, a6, t4
  pqcuark.bfnttd a7, a7, t4
  pack_lsb s10, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 70+8*\base     // Load twiddle factor
  pack_lsb t5, a3, a2 // (a3[32:0], a2[32:0])
  pack_msb t6, a3, a2 // (a3[64:32], a2[64:32])
  pqcuark.bfnttd t5, t5, t4
  pqcuark.bfnttd t6, t6, t4
  pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a3, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 71+8*\base     // Load twiddle factor
  pack_lsb a6, a5, a4 // (a5[32:0], a4[32:0])
  pack_msb a7, a5, a4 // (a5[64:32], a4[64:32])
  pqcuark.bfnttd a6, a6, t4
  pqcuark.bfnttd a7, a7, t4
  pack_lsb a4, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

  // layer 8 LEN=1
  build_k_pair t0, 128+16*\base     // Load twiddle factor
  build_k_pair t1, 129+16*\base     // Load twiddle factor
  build_k_pair t2, 130+16*\base     // Load twiddle factor
  build_k_pair t3, 131+16*\base     // Load twiddle factor
  build_k_pair t4, 132+16*\base     // Load twiddle factor
  build_k_pair t5, 133+16*\base     // Load twiddle factor
  build_k_pair t6, 134+16*\base     // Load twiddle factor
  pqcuark.bfnttd s0, s0, t0
  pqcuark.bfnttd s1, s1, t1
  pqcuark.bfnttd s2, s2, t2
  pqcuark.bfnttd s3, s3, t3
  pqcuark.bfnttd s4, s4, t4
  pqcuark.bfnttd s5, s5, t5
  pqcuark.bfnttd s6, s6, t6
  build_k_pair t0, 135+16*\base     // Load twiddle factor
  build_k_pair t1, 136+16*\base     // Load twiddle factor
  build_k_pair t2, 137+16*\base     // Load twiddle factor
  build_k_pair t3, 138+16*\base     // Load twiddle factor
  build_k_pair t4, 139+16*\base     // Load twiddle factor
  build_k_pair t5, 140+16*\base     // Load twiddle factor
  build_k_pair t6, 141+16*\base     // Load twiddle factor
  pqcuark.bfnttd s7, s7, t0
  pqcuark.bfnttd s8, s8, t1
  pqcuark.bfnttd s9, s9, t2
  pqcuark.bfnttd s10, s10, t3
  pqcuark.bfnttd s11, s11, t4
  pqcuark.bfnttd a2, a2, t5
  pqcuark.bfnttd a3, a3, t6
  build_k_pair t0, 142+16*\base     // Load twiddle factor
  build_k_pair t1, 143+16*\base     // Load twiddle factor
  pqcuark.bfnttd a4, a4, t0
  pqcuark.bfnttd a5, a5, t1

  store_coeffs a0, 8, 1 
  addi a0, a0, 128 // poly+=16
.endm

### LAYER 4+3+2+1 
.macro intt_pqcuark_loop1
  addi a0, a0, -8
  // load coefficients
  load_coeffs a0, 8, 8
  // layer 4 LEN=16
  build_k_pair t4, 15      // Load twiddle factor
  pack_lsb t5, s1, s0 // (s1[32:0], s0[32:0])
  pack_msb t6, s1, s0 // (s1[64:32], s0[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s1, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 14      // Load twiddle factor
  pack_lsb t5, s3, s2 // (s3[32:0], s2[32:0])
  pack_msb t6, s3, s2 // (s3[64:32], s2[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s3, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 13      // Load twiddle factor
  pack_lsb t5, s5, s4 // (s5[32:0], s4[32:0])
  pack_msb t6, s5, s4 // (s5[64:32], s4[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s5, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 12     // Load twiddle factor
  pack_lsb t5, s7, s6 // (s7[32:0], s6[32:0])
  pack_msb t6, s7, s6 // (s7[64:32], s6[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb s6, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s7, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 11     // Load twiddle factor
  pack_lsb t5, s9, s8 // (s9[32:0], s8[32:0])
  pack_msb t6, s9, s8 // (s9[64:32], s8[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s9, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 10     // Load twiddle factor
  pack_lsb t5, s11, s10 // (s11[32:0], s10[32:0])
  pack_msb t6, s11, s10 // (s11[64:32], s10[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb s10, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s11, t6, t5 // (t6[64:32], t5[64:32])


  build_k_pair t4, 9      // Load twiddle factor
  pack_lsb t5, a3, a2 // (a3[32:0], a2[32:0])
  pack_msb t6, a3, a2 // (a3[64:32], a2[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a3, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 8      // Load twiddle factor
  pack_lsb t5, a5, a4 // (a5[32:0], a4[32:0])
  pack_msb t6, a5, a4 // (a5[64:32], a4[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb a4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a5, t6, t5 // (t6[64:32], t5[64:32])

  // layer 3 LEN=32
  build_k_pair t4, 7      // Load twiddle factor
  pack_lsb t5, s2, s0 // (s2[32:0], s0[32:0])
  pack_msb t6, s2, s0 // (s2[64:32], s0[64:32])
  pack_lsb a6, s3, s1 // (s3[32:0], s1[32:0])
  pack_msb a7, s3, s1 // (s3[64:32], s1[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s2, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s3, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 6      // Load twiddle factor
  pack_lsb t5, s6, s4 // (s6[32:0], s4[32:0])
  pack_msb t6, s6, s4 // (s6[64:32], s4[64:32])
  pack_lsb a6, s7, s5 // (s7[32:0], s5[32:0])
  pack_msb a7, s7, s5 // (s7[64:32], s5[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s5, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 5      // Load twiddle factor
  pack_lsb t5, s10, s8 // (s10[32:0], s8[32:0])
  pack_msb t6, s10, s8 // (s10[64:32], s8[64:32])
  pack_lsb a6, s11, s9 // (s11[32:0], s9[32:0])
  pack_msb a7, s11, s9 // (s11[64:32], s9[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s10, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 4      // Load twiddle factor
  pack_lsb t5, a4, a2 // (a4[32:0], a2[32:0])
  pack_msb t6, a4, a2 // (a4[64:32], a2[64:32])
  pack_lsb a6, a5, a3 // (a5[32:0], a3[32:0])
  pack_msb a7, a5, a3 // (a5[64:32], a3[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb a3, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

  // layer 2 LEN=64
  build_k_pair t4, 3      // Load twiddle factor
  pack_lsb t5, s4, s0 // (s4[32:0], s0[32:0])
  pack_msb t6, s4, s0 // (s4[64:32], s0[64:32])
  pack_lsb a6, s5, s1 // (s5[32:0], s1[32:0])
  pack_msb a7, s5, s1 // (s5[64:32], s1[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s4, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s5, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, s6, s2 // (s6[32:0], s2[32:0])
  pack_msb t6, s6, s2 // (s6[64:32], s2[64:32])
  pack_lsb a6, s7, s3 // (s7[32:0], s3[32:0])
  pack_msb a7, s7, s3 // (s7[64:32], s3[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s3, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 2      // Load twiddle factor
  pack_lsb t5, a2, s8 // (a2[32:0], s8[32:0])
  pack_msb t6, a2, s8 // (a2[64:32], s8[64:32])
  pack_lsb a6, a3, s9 // (a3[32:0], s9[32:0])
  pack_msb a7, a3, s9 // (a3[64:32], s9[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a2, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a3, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, a4, s10 // (a4[32:0], s10[32:0])
  pack_msb t6, a4, s10 // (a4[64:32], s10[64:32])
  pack_lsb a6, a5, s11 // (a5[32:0], s11[32:0])
  pack_msb a7, a5, s11 // (a5[64:32], s11[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s10, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s11, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

  // layer 1 LEN=128
  build_k_pair t4, 1      // Load twiddle factor
  pack_lsb t5, s8, s0 // (s8[32:0], s0[32:0])
  pack_msb t6, s8, s0 // (s8[64:32], s0[64:32])
  pack_lsb a6, s9, s1 // (s9[32:0], s1[32:0])
  pack_msb a7, s9, s1 // (s9[64:32], s1[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s8, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s9, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, s10, s2 // (s10[32:0], s2[32:0])
  pack_msb t6, s10, s2 // (s10[64:32], s2[64:32])
  pack_lsb a6, s11, s3 // (s11[32:0], s3[32:0])
  pack_msb a7, s11, s3 // (s11[64:32], s3[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s10, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s3, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, a2, s4 // (a2[32:0], s4[32:0])
  pack_msb t6, a2, s4 // (a2[64:32], s4[64:32])
  pack_lsb a6, a3, s5 // (a3[32:0], s5[32:0])
  pack_msb a7, a3, s5 // (a3[64:32], s5[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a2, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s5, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a3, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, a4, s6 // (a4[32:0], s6[32:0])
  pack_msb t6, a4, s6 // (a4[64:32], s6[64:32])
  pack_lsb a6, a5, s7 // (a5[32:0], s7[32:0])
  pack_msb a7, a5, s7 // (a5[64:32], s7[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s6, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s7, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

  // store coefficients
  store_coeffs a0, 8, 8

.endm

### LAYER 7+6+5
.macro intt_pqcuark_loop2 base
  // load coefficients
  load_coeffs a0, 8, 1 
  // layer 8 LEN=1
  build_k_pair t0, 255-16*\base     // Load twiddle factor
  build_k_pair t1, 254-16*\base     // Load twiddle factor
  build_k_pair t2, 253-16*\base     // Load twiddle factor
  build_k_pair t3, 252-16*\base     // Load twiddle factor
  build_k_pair t4, 251-16*\base     // Load twiddle factor
  build_k_pair t5, 250-16*\base     // Load twiddle factor
  build_k_pair t6, 249-16*\base     // Load twiddle factor
  pqcuark.bfinttd s0, s0, t0
  pqcuark.bfinttd s1, s1, t1
  pqcuark.bfinttd s2, s2, t2
  pqcuark.bfinttd s3, s3, t3
  pqcuark.bfinttd s4, s4, t4
  pqcuark.bfinttd s5, s5, t5
  pqcuark.bfinttd s6, s6, t6
  build_k_pair t0, 248-16*\base     // Load twiddle factor
  build_k_pair t1, 247-16*\base     // Load twiddle factor
  build_k_pair t2, 246-16*\base     // Load twiddle factor
  build_k_pair t3, 245-16*\base     // Load twiddle factor
  build_k_pair t4, 244-16*\base     // Load twiddle factor
  build_k_pair t5, 243-16*\base     // Load twiddle factor
  build_k_pair t6, 242-16*\base     // Load twiddle factor
  pqcuark.bfinttd s7, s7, t0
  pqcuark.bfinttd s8, s8, t1
  pqcuark.bfinttd s9, s9, t2
  pqcuark.bfinttd s10, s10, t3
  pqcuark.bfinttd s11, s11, t4
  pqcuark.bfinttd a2, a2, t5
  pqcuark.bfinttd a3, a3, t6
  build_k_pair t0, 241-16*\base     // Load twiddle factor
  build_k_pair t1, 240-16*\base     // Load twiddle factor
  pqcuark.bfinttd a4, a4, t0
  pqcuark.bfinttd a5, a5, t1

  // layer 7 LEN=2
  build_k_pair t4, 127-8*\base     // Load twiddle factor
  pack_lsb t5, s1, s0 // (s1[32:0], s0[32:0])
  pack_msb t6, s1, s0 // (s1[64:32], s0[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb s0, t6 , t5 // (t6[32:0], t5[32:0])
  pack_msb s1, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 126-8*\base     // Load twiddle factor
  pack_lsb a6, s3, s2 // (s3[32:0], s2[32:0])
  pack_msb a7, s3, s2 // (s3[64:32], s2[64:32])
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s2, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s3, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 125-8*\base     // Load twiddle factor
  pack_lsb t5, s5, s4 // (s5[32:0], s4[32:0])
  pack_msb t6, s5, s4 // (s5[64:32], s4[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s5, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 124-8*\base     // Load twiddle factor
  pack_lsb a6, s7, s6 // (s7[32:0], s6[32:0])
  pack_msb a7, s7, s6 // (s7[64:32], s6[64:32])
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s6, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 123-8*\base     // Load twiddle factor
  pack_lsb t5, s9, s8 // (s9[32:0], s8[32:0])
  pack_msb t6, s9, s8 // (s9[64:32], s8[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s9, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 122-8*\base     // Load twiddle factor
  pack_lsb a6, s11, s10 // (s11[32:0], s10[32:0])
  pack_msb a7, s11, s10 // (s11[64:32], s10[64:32])
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s10, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 121-8*\base     // Load twiddle factor
  pack_lsb t5, a3, a2 // (a3[32:0], a2[32:0])
  pack_msb t6, a3, a2 // (a3[64:32], a2[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a3, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 120-8*\base     // Load twiddle factor
  pack_lsb t5, a5, a4 // (a5[32:0], a4[32:0])
  pack_msb t6, a5, a4 // (a5[64:32], a4[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb a4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a5, t6, t5 // (t6[64:32], t5[64:32])

  // layer 6 LEN=4
  build_k_pair t4, 63-4*\base     // Load twiddle factor
  pack_lsb t5, s2, s0 // (s2[32:0], s0[32:0])
  pack_msb t6, s2, s0 // (s2[64:32], s0[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s2, t6, t5 // (t6[64:32], t5[64:32])

  pack_lsb a6, s3, s1 // (s3[32:0], s1[32:0])
  pack_msb a7, s3, s1 // (s3[64:32], s1[64:32])
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s3, a7, a6 // (a7[64:32], a6[64:32])
  
  build_k_pair t4, 62-4*\base     // Load twiddle factor
  pack_lsb t5, s6, s4 // (s6[32:0], s4[32:0])
  pack_msb t6, s6, s4 // (s6[64:32], s4[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])

  pack_lsb a6, s7, s5 // (s7[32:0], s5[32:0])
  pack_msb a7, s7, s5 // (s7[64:32], s5[64:32])
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s5, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 61-4*\base     // Load twiddle factor
  pack_lsb t5, s10, s8 // (s10[32:0], s8[32:0])
  pack_msb t6, s10, s8 // (s10[64:32], s8[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s10, t6, t5 // (t6[64:32], t5[64:32])

  pack_lsb a6, s11, s9 // (s11[32:0], s9[32:0])
  pack_msb a7, s11, s9 // (s11[64:32], s9[64:32])
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 60-4*\base     // Load twiddle factor
  pack_lsb t5, a4, a2 // (a4[32:0], a2[32:0])
  pack_msb t6, a4, a2 // (a4[64:32], a2[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])

  pack_lsb a6, a5, a3 // (a5[32:0], a3[32:0])
  pack_msb a7, a5, a3 // (a5[64:32], a3[64:32])
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb a3, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

  // layer 5 LEN=8
  build_k_pair t4, 31-2*\base     // Load twiddle factor
  pack_lsb t5, s4, s0 // (s4[32:0], s0[32:0])
  pack_msb t6, s4, s0 // (s4[64:32], s0[64:32])
  pack_lsb a6, s5, s1 // (s5[32:0], s1[32:0])
  pack_msb a7, s5, s1 // (s5[64:32], s1[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s4, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s5, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, s6, s2 // (s6[32:0], s2[32:0])
  pack_msb t6, s6, s2 // (s6[64:32], s2[64:32])
  pack_lsb a6, s7, s3 // (s7[32:0], s3[32:0])
  pack_msb a7, s7, s3 // (s7[64:32], s3[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s3, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 30-2*\base     // Load twiddle factor
  pack_lsb t5, a2, s8 // (a2[32:0], s8[32:0])
  pack_msb t6, a2, s8 // (a2[64:32], s8[64:32])
  pack_lsb a6, a3, s9 // (a3[32:0], s9[32:0])
  pack_msb a7, a3, s9 // (a3[64:32], s9[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a2, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a3, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, a4, s10 // (a4[32:0], s10[32:0])
  pack_msb t6, a4, s10 // (a4[64:32], s10[64:32])
  pack_lsb a6, a5, s11 // (a5[32:0], s11[32:0])
  pack_msb a7, a5, s11 // (a5[64:32], s11[64:32])
  pqcuark.bfinttd t5, t5, t4
  pqcuark.bfinttd t6, t6, t4
  pqcuark.bfinttd a6, a6, t4
  pqcuark.bfinttd a7, a7, t4
  pack_lsb s10, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s11, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

  store_coeffs a0, 8, 1
  addi a0, a0, 128 // poly+=16
.endm

.macro fqmul_pqcuark_iteration
  load_coeffs a0, 8, 1

  pqcuark.bffqmul32.l t2, s0, t1 
  pqcuark.bffqmul32.l t3, s1, t1
  pqcuark.bffqmul32.l t4, s2, t1
  pqcuark.bffqmul32.l t5, s3, t1
  pqcuark.bffqmul32.h s0, t2, t1 
  pqcuark.bffqmul32.h s1, t3, t1
  pqcuark.bffqmul32.h s2, t4, t1
  pqcuark.bffqmul32.h s3, t5, t1

  pqcuark.bffqmul32.l t2, s4, t1
  pqcuark.bffqmul32.l t3, s5, t1
  pqcuark.bffqmul32.l t4, s6, t1
  pqcuark.bffqmul32.l t5, s7, t1
  pqcuark.bffqmul32.h s4, t2, t1 
  pqcuark.bffqmul32.h s5, t3, t1
  pqcuark.bffqmul32.h s6, t4, t1
  pqcuark.bffqmul32.h s7, t5, t1

  pqcuark.bffqmul32.l t2, s8, t1 
  pqcuark.bffqmul32.l t3, s9, t1 
  pqcuark.bffqmul32.l t4, s10, t1
  pqcuark.bffqmul32.l t5, s11, t1
  pqcuark.bffqmul32.h s8, t2, t1 
  pqcuark.bffqmul32.h s9, t3, t1
  pqcuark.bffqmul32.h s10, t4, t1
  pqcuark.bffqmul32.h s11, t5, t1
  
  pqcuark.bffqmul32.l t2, a2, t1
  pqcuark.bffqmul32.l t3, a3, t1
  pqcuark.bffqmul32.l t4, a4, t1
  pqcuark.bffqmul32.l t5, a5, t1
  pqcuark.bffqmul32.h a2, t2, t1 
  pqcuark.bffqmul32.h a3, t3, t1
  pqcuark.bffqmul32.h a4, t4, t1
  pqcuark.bffqmul32.h a5, t5, t1

  store_coeffs a0, 8, 1
  addi a0, a0, 128 // poly+=16
.endm


// |input| < 0.5q; |output| < 3.5q
// API: a0: poly, a1: 64-bit twiddle ptr; a6: q<<32; a7: tmp, variable twiddle factors; gp: loop;
// s0-s11, a2-a5: 16 coeffs; 
// Aux: t5,t6,a6,a7
// 16+2+1+1=20 regs; 
.global ntt_pqcuark_asm
.align 2
ntt_pqcuark_asm:
  addi sp, sp, -8*15
  save_regs
  addi a0, a0, 64   // poly[16]
    ### LAYER 1+2+3+4
  li gp, 8 
ntt_pqcuark_loop1_loop:
  ntt_pqcuark_loop1
  addi gp, gp, -1
  bnez gp, ntt_pqcuark_loop1_loop
  ### LAYER 5+6+7+8
  ntt_pqcuark_loop2 0
  ntt_pqcuark_loop2 1
  ntt_pqcuark_loop2 2
  ntt_pqcuark_loop2 3
  ntt_pqcuark_loop2 4 
  ntt_pqcuark_loop2 5
  ntt_pqcuark_loop2 6
  ntt_pqcuark_loop2 7

  restore_regs
  addi sp, sp, 8*15
  ret

// |input| < kq; |output| < 0.5q
// API: a0: poly, a1: 64-bit twiddle ptr; a6: q<<32; a7: tmp; gp: loop;
// s0-s11, a2-a5: 16 coeffs; 
// 16+2+1+1=20 regs; 
// 8 twiddle factors: can be preloaded; t0-t6, tp; ra: tmp zeta.
.global intt_pqcuark_asm
.align 2
intt_pqcuark_asm:
  addi sp, sp, -8*15
  save_regs
  ### LAYER 8+7+6+5
  intt_pqcuark_loop2 0
  intt_pqcuark_loop2 1
  intt_pqcuark_loop2 2
  intt_pqcuark_loop2 3
  intt_pqcuark_loop2 4
  intt_pqcuark_loop2 5
  intt_pqcuark_loop2 6
  intt_pqcuark_loop2 7
  ### LAYER 4+3+2+1
  addi a0, a0, -960 #-1024+64 = -960;
  li gp, 8
  intt_pqcuark_loop1_loop:
    intt_pqcuark_loop1
    addi gp, gp, -1
    bnez gp, intt_pqcuark_loop1_loop
  // store 16 coeffs
  restore_regs
  addi sp, sp, 8*15
  ret

.global fqmul_pqcuark_asm
.align 2
fqmul_pqcuark_asm:
  // fqmul(a0, a1, a2) = a0*a1 mod q
  // a0: poly, a1: poly, a2: q<<32
  // s0-s11, a2-a5: 16 coeffs; 
  // 16+2+1+1=20 regs; 
  addi sp, sp, -8*15
  save_regs
  li gp, 8
  li t1, 41978          // Load 41978 into t1
  slli t1, t1, 32       // Shift t1 to the upper 32 bits
  li t2, 41978          // Load 41978 into a temporary register t2
  or t1, t1, t2        // Combine the upper and lower 32 bits
  fqmul_pqcuark_loop:
    fqmul_pqcuark_iteration
    addi gp, gp, -1
    bnez gp, fqmul_pqcuark_loop
  restore_regs
  addi sp, sp, 8*15
  ret
  
.global poly_pointwise_pqcuark_asm
.align 2
poly_pointwise_pqcuark_asm:
  // pointwise(a0, a1, a2) = a0*a1 mod q
  // a0: poly, a1: poly, a2: q<<32
  // s0-s11, a2-a5: 16 coeffs; 
  // 16+2+1+1=20 regs; 
  addi sp, sp, -8*15
  save_regs
  li gp, 16*64           // 8 coefficients, 2 32-bit words each, 32 bits per word
  add gp, gp, a0          # Set the loop count based on the size of the input
pointwise_pqcuark_loop:
  ld  t0, 0*4(a1)         # Load the 64 bits (8B) of a1
  ld  t1, 2*4(a1)         # Load the 64 bits (8B) of a1
  ld  t2, 4*4(a1)         # Load the 64 bits (8B) of a1
  ld  t3, 6*4(a1)         # Load the 64 bits (8B) of a1
  ld  t4, 8*4(a1)         # Load the 64 bits (8B) of a1
  ld  t5, 10*4(a1)        # Load the 64 bits (8B) of a1
  ld  t6, 12*4(a1)        # Load the 64 bits (8B) of a1
  ld  s7, 14*4(a1)        # Load the 64 bits (8B) of a1

  ld  s0, 0*4(a2)         # Load the 64 bits (8B) of a2
  ld  s1, 2*4(a2)         # Load the 64 bits (8B) of a2
  ld  s2, 4*4(a2)         # Load the 64 bits (8B) of a2
  ld  s3, 6*4(a2)         # Load the 64 bits (8B) of a2
  ld  s4, 8*4(a2)         # Load the 64 bits (8B) of a2
  ld  s5, 10*4(a2)        # Load the 64 bits (8B) of a2
  ld  s6, 12*4(a2)        # Load the 64 bits (8B) of a2
  ld  s8, 14*4(a2)        # Load the 64 bits (8B) of a2
  
  pqcuark.bffqmul32.l t0, t0, s0 # b.l = a.l * b.l
  pqcuark.bffqmul32.l t1, t1, s1
  pqcuark.bffqmul32.l t2, t2, s2
  pqcuark.bffqmul32.l t3, t3, s3
  pqcuark.bffqmul32.l t4, t4, s4
  pqcuark.bffqmul32.l t5, t5, s5
  pqcuark.bffqmul32.l t6, t6, s6
  pqcuark.bffqmul32.l s7, s7, s8

  pqcuark.bffqmul32.h t0, t0, s0 # b.h = a.h * b.h
  pqcuark.bffqmul32.h t1, t1, s1
  pqcuark.bffqmul32.h t2, t2, s2
  pqcuark.bffqmul32.h t3, t3, s3
  pqcuark.bffqmul32.h t4, t4, s4
  pqcuark.bffqmul32.h t5, t5, s5
  pqcuark.bffqmul32.h t6, t6, s6
  pqcuark.bffqmul32.h s7, s7, s8


  // Store the results back to a0
  sd  t0, 0*4(a0)         # Store the first
  sd  t1, 2*4(a0)         # Store the second
  sd  t2, 4*4(a0)         # Store the third
  sd  t3, 6*4(a0)         # Store the fourth
  sd  t4, 8*4(a0)         # Store the fifth
  sd  t5, 10*4(a0)         # Store the sixth
  sd  t6, 12*4(a0)         # Store the seventh
  sd  s7, 14*4(a0)         # Store the eighth

  addi a0, a0, 64         # Move to the next 64 bytes of a0
  addi a1, a1, 64         # Move to the next 64 bytes of a1
  addi a2, a2, 64         # Move to the next 64 bytes of a2
  bne gp, a0, pointwise_pqcuark_loop
  
  # Restore registers and return
  restore_regs
  addi sp, sp, 8*15
  ret

.global poly_pointwise_acc_pqcuark_asm
.align 2
poly_pointwise_acc_pqcuark_asm:
  // pointwise(a0, a1, a2) = a1*a2 mod q
  // a0: poly, a1: poly, a2: q<<32
  // s0-s11, a2-a5: 16 coeffs; 
  // 16+2+1+1=20 regs; 
  addi sp, sp, -8*15
  save_regs
  li gp, 16*64           // 8 coefficients, 2 32-bit words each, 32 bits per word
  add gp, gp, a0          # Set the loop count based on the size of the input
pointwise_acc_pqcuark_loop:
  ld  t0, 0*4(a1)         # Load the 64 bits (8B) of a1
  ld  t1, 2*4(a1)         # Load the 64 bits (8B) of a1
  ld  t2, 4*4(a1)         # Load the 64 bits (8B) of a1
  ld  t3, 6*4(a1)         # Load the 64 bits (8B) of a1
  ld  t4, 8*4(a1)         # Load the 64 bits (8B) of a1
  ld  t5, 10*4(a1)        # Load the 64 bits (8B) of a1
  ld  t6, 12*4(a1)        # Load the 64 bits (8B) of a1
  ld  s7, 14*4(a1)        # Load the 64 bits (8B) of a1

  ld  s0, 0*4(a2)         # Load the 64 bits (8B) of a2
  ld  s1, 2*4(a2)         # Load the 64 bits (8B) of a2
  ld  s2, 4*4(a2)         # Load the 64 bits (8B) of a2
  ld  s3, 6*4(a2)         # Load the 64 bits (8B) of a2
  ld  s4, 8*4(a2)         # Load the 64 bits (8B) of a2
  ld  s5, 10*4(a2)        # Load the 64 bits (8B) of a2
  ld  s6, 12*4(a2)        # Load the 64 bits (8B) of a2
  ld  s8, 14*4(a2)        # Load the 64 bits (8B) of a2
  
  pqcuark.bffqmul32.l t0, t0, s0 # b.l = a.l * b.l
  pqcuark.bffqmul32.l t1, t1, s1
  pqcuark.bffqmul32.l t2, t2, s2
  pqcuark.bffqmul32.l t3, t3, s3
  pqcuark.bffqmul32.l t4, t4, s4
  pqcuark.bffqmul32.l t5, t5, s5
  pqcuark.bffqmul32.l t6, t6, s6
  pqcuark.bffqmul32.l s7, s7, s8

  pqcuark.bffqmul32.h t0, t0, s0 # b.h = a.h * b.h
  pqcuark.bffqmul32.h t1, t1, s1
  pqcuark.bffqmul32.h t2, t2, s2
  pqcuark.bffqmul32.h t3, t3, s3
  pqcuark.bffqmul32.h t4, t4, s4
  pqcuark.bffqmul32.h t5, t5, s5
  pqcuark.bffqmul32.h t6, t6, s6
  pqcuark.bffqmul32.h s7, s7, s8

  ld s0, 0*4(a0)         # Load the first 64 bits (8B) of a0
  ld s1, 2*4(a0)         # Load the second 64 bits (8B) of a0
  ld s2, 4*4(a0)         # Load the third 64 bits (8B) of a0
  ld s3, 6*4(a0)         # Load the fourth 64 bits (8B) of a0
  ld s4, 8*4(a0)         # Load the fifth 64 bits (8B) of a0
  ld s5, 10*4(a0)        # Load the sixth 64 bits (8B) of a0
  ld s6, 12*4(a0)        # Load the seventh 64 bits (8B) of a0
  ld s8, 14*4(a0)        # Load the eighth 64 bits (8B) of a0

  add32 t0, t0, s0         # Add the first result to the first coefficient
  add32 t1, t1, s1         # Add the second result to the second
  add32 t2, t2, s2         # Add the third result to the third
  add32 t3, t3, s3         # Add the fourth result to the fourth
  add32 t4, t4, s4         # Add the fifth result to the fifth
  add32 t5, t5, s5         # Add the sixth result to the sixth
  add32 t6, t6, s6         # Add the seventh result to the seventh
  add32 s7, s7, s8         # Add the eighth result to the eighth

  // Store the results back to a0
  sd  t0, 0*4(a0)         # Store the first
  sd  t1, 2*4(a0)         # Store the second
  sd  t2, 4*4(a0)         # Store the third
  sd  t3, 6*4(a0)         # Store the fourth
  sd  t4, 8*4(a0)         # Store the fifth
  sd  t5, 10*4(a0)         # Store the sixth
  sd  t6, 12*4(a0)         # Store the seventh
  sd  s7, 14*4(a0)         # Store the eighth

  addi a0, a0, 64         # Move to the next 64 bytes of a0
  addi a1, a1, 64         # Move to the next 64 bytes of a1
  addi a2, a2, 64         # Move to the next 64 bytes of a2
  bne gp, a0, pointwise_acc_pqcuark_loop
  
  # Restore registers and return
  restore_regs
  addi sp, sp, 8*15
  ret

.equ q, 8380417
.globl poly_reduce_rv64im_asm
.align 2
poly_reduce_rv64im_asm:
    li a1, 4194304  # 1<<22
    li a2, q
    addi a3, a0, 64*4*4
poly_reduce_rv64im_loop:
    lw a4, 0*4(a0)
    lw a5, 1*4(a0)
    lw a6, 2*4(a0)
    lw a7, 3*4(a0)
    add  t0, a4, a1
    add  t1, a5, a1
    add  t2, a6, a1
    add  t3, a7, a1
    srai t0, t0, 23
    srai t1, t1, 23
    srai t2, t2, 23
    srai t3, t3, 23
    mul  t0, t0, a2
    mul  t1, t1, a2
    mul  t2, t2, a2
    mul  t3, t3, a2
    sub  a4, a4, t0
    sub  a5, a5, t1
    sub  a6, a6, t2
    sub  a7, a7, t3
    sw a4, 0*4(a0)
    sw a5, 1*4(a0)
    sw a6, 2*4(a0)
    sw a7, 3*4(a0)
    addi a0, a0, 4*4
    bne a3, a0, poly_reduce_rv64im_loop
    ret