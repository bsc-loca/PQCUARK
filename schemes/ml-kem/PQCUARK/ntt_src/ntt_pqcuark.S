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
  slli \k_pair, \k_pair, 32       // Shift k_pair to the MSB of 64 bits
  ori   \k_pair, \k_pair, \k      // Combine the MSB and LSB
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


.macro gs_butterfly result, r_concat, k_pair
  pqcuark.bfinttk \result, \r_concat, \k_pair
.endm

  ### LAYER 1+2+3+4
.macro ntt_pqcuark_loop1
    addi a0, a0, -8
    // 16*i, i \in [0-15]
    load_coeffs a0, 8, 4
    // layer 1 LEN=128
    build_k_pair t4, 1      // Load twiddle factor
    pack_lsb t5, s8, s0 // (s8[32:0], s0[32:0])
    pack_msb t6, s8, s0 // (s8[64:32], s0[64:32])
    pack_lsb a6, s9, s1 // (s9[32:0], s1[32:0])
    pack_msb a7, s9, s1 // (s9[64:32], s1[64:32])
    pqcuark.bfnttk t5, t5, t4 
    pqcuark.bfnttk t6, t6, t4
    pqcuark.bfnttk a6, a6, t4 
    pqcuark.bfnttk a7, a7, t4
    pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s8, t6, t5 // (t6[64:32], t5[64:32]) 
    pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s9, a7, a6 // (a7[64:32], a6[64:32])

    pack_lsb t5, s10, s2 // (s10[32:0], s2[32:0])
    pack_msb t6, s10, s2 // (s10[64:32], s2[64:32])
    pack_lsb a6, s11, s3 // (s11[32:0], s3[32:0])
    pack_msb a7, s11, s3 // (s11[64:32], s3[64:32])
    pqcuark.bfnttk t5, t5, t4
    pqcuark.bfnttk t6, t6, t4
    pqcuark.bfnttk a6, a6, t4
    pqcuark.bfnttk a7, a7, t4
    pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s10, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s3, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])
    

    pack_lsb t5, a2, s4 // (a2[32:0], s4[32:0])
    pack_msb t6, a2, s4 // (a2[64:32], s4[64:32])
    pack_lsb a6, a3, s5 // (a3[32:0], s5[32:0])
    pack_msb a7, a3, s5 // (a3[64:32], s5[64:32])
    pqcuark.bfnttk t5, t5, t4
    pqcuark.bfnttk t6, t6, t4
    pqcuark.bfnttk a6, a6, t4
    pqcuark.bfnttk a7, a7, t4
    pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb a2, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s5, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb a3, a7, a6 // (a7[64:32], a6[64:32])
    

    pack_lsb t5, a4, s6 // (a4[32:0], s6[32:0])
    pack_msb t6, a4, s6 // (a4[64:32], s6[64:32])
    pack_lsb a6, a5, s7 // (a5[32:0], s7[32:0])
    pack_msb a7, a5, s7 // (a5[64:32], s7[64:32])
    pqcuark.bfnttk t5, t5, t4
    pqcuark.bfnttk t6, t6, t4
    pqcuark.bfnttk a6, a6, t4
    pqcuark.bfnttk a7, a7, t4
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
    pqcuark.bfnttk t5, t5, t4 
    pqcuark.bfnttk t6, t6, t4
    pqcuark.bfnttk a6, a6, t4 
    pqcuark.bfnttk a7, a7, t4
    pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s4, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s5, a7, a6 // (a7[64:32], a6[64:32])

    pack_lsb t5, s6, s2 // (s6[32:0], s2[32:0])
    pack_msb t6, s6, s2 // (s6[64:32], s2[64:32])
    pack_lsb a6, s7, s3 // (s7[32:0], s3[32:0])
    pack_msb a7, s7, s3 // (s7[64:32], s3[64:32])
    pqcuark.bfnttk t5, t5, t4
    pqcuark.bfnttk t6, t6, t4
    pqcuark.bfnttk a6, a6, t4 
    pqcuark.bfnttk a7, a7, t4
    pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s3, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

    build_k_pair t4, 3      // Load twiddle factor
    pack_lsb t5, a2, s8 // (a2[32:0], s8[32:0])
    pack_msb t6, a2, s8 // (a2[64:32], s8[64:32])
    pack_lsb a6, a3, s9 // (a3[32:0], s9[32:0])
    pack_msb a7, a3, s9 // (a3[64:32], s9[64:32])
    pqcuark.bfnttk t5, t5, t4 
    pqcuark.bfnttk t6, t6, t4
    pqcuark.bfnttk a6, a6, t4 
    pqcuark.bfnttk a7, a7, t4
    pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb a2, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb a3, a7, a6 // (a7[64:32], a6[64:32])

    pack_lsb t5, a4, s10 // (a4[32:0], s10[32:0])
    pack_msb t6, a4, s10 // (a4[64:32], s10[64:32])
    pack_lsb a6, a5, s11 // (a5[32:0], s11[32:0])
    pack_msb a7, a5, s11 // (a5[64:32], s11[64:32])
    pqcuark.bfnttk t5, t5, t4
    pqcuark.bfnttk t6, t6, t4
    pqcuark.bfnttk a6, a6, t4 
    pqcuark.bfnttk a7, a7, t4
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
    pqcuark.bfnttk t5, t5, t4 
    pqcuark.bfnttk t6, t6, t4
    pqcuark.bfnttk a6, a6, t4 
    pqcuark.bfnttk a7, a7, t4
    pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s2, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s3, a7, a6 // (a7[64:32], a6[64:32])

    build_k_pair t4, 5      // Load twiddle factor
    pack_lsb t5, s6, s4 // (s6[32:0], s4[32:0])
    pack_msb t6, s6, s4 // (s6[64:32], s4[64:32])
    pack_lsb a6, s7, s5 // (s7[32:0], s5[32:0])
    pack_msb a7, s7, s5 // (s7[64:32], s5[64:32])
    pqcuark.bfnttk t5, t5, t4 
    pqcuark.bfnttk t6, t6, t4
    pqcuark.bfnttk a6, a6, t4 
    pqcuark.bfnttk a7, a7, t4
    pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s5, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

    build_k_pair t4, 6      // Load twiddle factor
    pack_lsb t5, s10, s8 // (s10[32:0], s8[32:0])
    pack_msb t6, s10, s8 // (s10[64:32], s8[64:32])
    pack_lsb a6, s11, s9 // (s11[32:0], s9[32:0])
    pack_msb a7, s11, s9 // (s11[64:32], s9[64:32])
    pqcuark.bfnttk t5, t5, t4 
    pqcuark.bfnttk t6, t6, t4
    pqcuark.bfnttk a6, a6, t4 
    pqcuark.bfnttk a7, a7, t4
    pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s10, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

    build_k_pair t4, 7      // Load twiddle factor
    pack_lsb t5, a4, a2 // (a4[32:0], a2[32:0])
    pack_msb t6, a4, a2 // (a4[64:32], a2[64:32])
    pack_lsb a6, a5, a3 // (a5[32:0], a3[32:0])
    pack_msb a7, a5, a3 // (a5[64:32], a3[64:32])
    pqcuark.bfnttk t5, t5, t4 
    pqcuark.bfnttk t6, t6, t4
    pqcuark.bfnttk a6, a6, t4 
    pqcuark.bfnttk a7, a7, t4
    pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])
    pack_lsb a3, a7, a6 // (a7[32:0], a6[32:0])
    pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

    // layer 4 LEN=16
    build_k_pair t4, 8      // Load twiddle factor
    pack_lsb t5, s1, s0 // (s1[32:0], s0[32:0])
    pack_msb t6, s1, s0 // (s1[64:32], s0[64:32])
    pqcuark.bfnttk t5, t5, t4 
    pqcuark.bfnttk t6, t6, t4
    pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s1, t6, t5 // (t6[64:32], t5[64:32])

    build_k_pair t4, 9      // Load twiddle factor
    pack_lsb t5, s3, s2 // (s3[32:0], s2[32:0])
    pack_msb t6, s3, s2 // (s3[64:32], s2[64:32])
    pqcuark.bfnttk t5, t5, t4
    pqcuark.bfnttk t6, t6, t4
    pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s3, t6, t5 // (t6[64:32], t5[64:32])

    build_k_pair t4, 10      // Load twiddle factor
    pack_lsb t5, s5, s4 // (s5[32:0], s4[32:0])
    pack_msb t6, s5, s4 // (s5[64:32], s4[64:32])
    pqcuark.bfnttk t5, t5, t4
    pqcuark.bfnttk t6, t6, t4
    pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s5, t6, t5 // (t6[64:32], t5[64:32])

    build_k_pair t4, 11     // Load twiddle factor
    pack_lsb t5, s7, s6 // (s7[32:0], s6[32:0])
    pack_msb t6, s7, s6 // (s7[64:32], s6[64:32])
    pqcuark.bfnttk t5, t5, t4
    pqcuark.bfnttk t6, t6, t4
    pack_lsb s6, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s7, t6, t5 // (t6[64:32], t5[64:32])

    build_k_pair t4, 12     // Load twiddle factor
    pack_lsb t5, s9, s8 // (s9[32:0], s8[32:0])
    pack_msb t6, s9, s8 // (s9[64:32], s8[64:32])
    pqcuark.bfnttk t5, t5, t4
    pqcuark.bfnttk t6, t6, t4
    pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s9, t6, t5 // (t6[64:32], t5[64:32])

    build_k_pair t4, 13     // Load twiddle factor
    pack_lsb t5, s11, s10 // (s11[32:0], s10[32:0])
    pack_msb t6, s11, s10 // (s11[64:32], s10[64:32])
    pqcuark.bfnttk t5, t5, t4
    pqcuark.bfnttk t6, t6, t4
    pack_lsb s10, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb s11, t6, t5 // (t6[64:32], t5[64:32])


    build_k_pair t4, 14     // Load twiddle factor
    pack_lsb t5, a3, a2 // (a3[32:0], a2[32:0])
    pack_msb t6, a3, a2 // (a3[64:32], a2[64:32])
    pqcuark.bfnttk t5, t5, t4 
    pqcuark.bfnttk t6, t6, t4
    pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb a3, t6, t5 // (t6[64:32], t5[64:32])

    build_k_pair t4, 15     // Load twiddle factor
    pack_lsb t5, a5, a4 // (a5[32:0], a4[32:0])
    pack_msb t6, a5, a4 // (a5[64:32], a4[64:32])
    pqcuark.bfnttk t5, t5, t4
    pqcuark.bfnttk t6, t6, t4
    pack_lsb a4, t6, t5 // (t6[32:0], t5[32:0])
    pack_msb a5, t6, t5 // (t6[64:32], t5[64:32])

    // store 16 coeffs
    store_coeffs a0, 16, 2
.endm

.macro ntt_pqcuark_loop2 base
  // load coefficients
  load_coeffs a0, 8, 1
  // layer 5 LEN=8
  build_k_pair t4, 16+4*\base     // Load twiddle factor
  pack_lsb t5, s2, s0 // (s2[32:0], s0[32:0])
  pack_msb t6, s2, s0 // (s2[64:32], s0[64:32])
  pack_lsb a6, s3, s1 // (s3[32:0], s1[32:0])
  pack_msb a7, s3, s1 // (s3[64:32], s1[64:32])
  pqcuark.bfnttk t5, t5, t4
  pqcuark.bfnttk t6, t6, t4
  pqcuark.bfnttk a6, a6, t4
  pqcuark.bfnttk a7, a7, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s2, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s3, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 17+4*\base     // Load twiddle factor
  pack_lsb t5, s6, s4 // (s6[32:0], s4[32:0])
  pack_msb t6, s6, s4 // (s6[64:32], s4[64:32])
  pack_lsb a6, s7, s5 // (s7[32:0], s5[32:0])
  pack_msb a7, s7, s5 // (s7[64:32], s5[64:32])
  pqcuark.bfnttk t5, t5, t4
  pqcuark.bfnttk t6, t6, t4
  pqcuark.bfnttk a6, a6, t4
  pqcuark.bfnttk a7, a7, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s5, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 18+4*\base     // Load twiddle factor
  pack_lsb t5, s10, s8 // (s10[32:0], s8[32:0])
  pack_msb t6, s10, s8 // (s10[64:32], s8[64:32])
  pack_lsb a6, s11, s9 // (s11[32:0], s9[32:0])
  pack_msb a7, s11, s9 // (s11[64:32], s9[64:32])
  pqcuark.bfnttk t5, t5, t4
  pqcuark.bfnttk t6, t6, t4
  pqcuark.bfnttk a6, a6, t4
  pqcuark.bfnttk a7, a7, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s10, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 19+4*\base     // Load twiddle factor
  pack_lsb t5, a4, a2 // (a4[32:0], a2[32:0])
  pack_msb t6, a4, a2 // (a4[64:32], a2[64:32])
  pack_lsb a6, a5, a3 // (a5[32:0], a3[32:0])
  pack_msb a7, a5, a3 // (a5[64:32], a3[64:32])
  pqcuark.bfnttk t5, t5, t4
  pqcuark.bfnttk t6, t6, t4
  pqcuark.bfnttk a6, a6, t4
  pqcuark.bfnttk a7, a7, t4
  pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb a3, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

  // layer 6 LEN=4
  build_k_pair t4, 32+8*\base     // Load twiddle factor
  pack_lsb t5, s1, s0 // (s1[32:0], s0[32:0])
  pack_msb t6, s1, s0 // (s1[64:32], s0[64:32])
  pqcuark.bfnttk t5, t5, t4
  pqcuark.bfnttk t6, t6, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s1, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 33+8*\base     // Load twiddle factor
  pack_lsb a6, s3, s2 // (s3[32:0], s2[32:0])
  pack_msb a7, s3, s2 // (s3[64:32], s2[64:32])
  pqcuark.bfnttk a6, a6, t4
  pqcuark.bfnttk a7, a7, t4
  pack_lsb s2, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s3, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 34+8*\base     // Load twiddle factor
  pack_lsb t5, s5, s4 // (s5[32:0], s4[32:0])
  pack_msb t6, s5, s4 // (s5[64:32], s4[64:32])
  pqcuark.bfnttk t5, t5, t4
  pqcuark.bfnttk t6, t6, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s5, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 35+8*\base     // Load twiddle factor
  pack_lsb a6, s7, s6 // (s7[32:0], s6[32:0])
  pack_msb a7, s7, s6 // (s7[64:32], s6[64:32])
  pqcuark.bfnttk a6, a6, t4
  pqcuark.bfnttk a7, a7, t4
  pack_lsb s6, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 36+8*\base     // Load twiddle factor
  pack_lsb t5, s9, s8 // (s9[32:0], s8[32:0])
  pack_msb t6, s9, s8 // (s9[64:32], s8[64:32])
  pqcuark.bfnttk t5, t5, t4
  pqcuark.bfnttk t6, t6, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s9, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 37+8*\base     // Load twiddle factor
  pack_lsb a6, s11, s10 // (s11[32:0], s10[32:0])
  pack_msb a7, s11, s10 // (s11[64:32], s10[64:32])
  pqcuark.bfnttk a6, a6, t4
  pqcuark.bfnttk a7, a7, t4
  pack_lsb s10, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 38+8*\base     // Load twiddle factor
  pack_lsb t5, a3, a2 // (a3[32:0], a2[32:0])
  pack_msb t6, a3, a2 // (a3[64:32], a2[64:32])
  pqcuark.bfnttk t5, t5, t4
  pqcuark.bfnttk t6, t6, t4
  pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a3, t6, t5 // (t6[64:32], t5[64:32])


  build_k_pair t4, 39+8*\base     // Load twiddle factor
  pack_lsb a6, a5, a4 // (a5[32:0], a4[32:0])
  pack_msb a7, a5, a4 // (a5[64:32], a4[64:32])
  pqcuark.bfnttk a6, a6, t4
  pqcuark.bfnttk a7, a7, t4
  pack_lsb a4, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

  // layer 7 LEN=2
  build_k_pair t0, 64+16*\base     // Load twiddle factor
  build_k_pair t1, 65+16*\base     // Load twiddle factor
  build_k_pair t2, 66+16*\base     // Load twiddle factor
  build_k_pair t3, 67+16*\base     // Load twiddle factor
  build_k_pair t4, 68+16*\base     // Load twiddle factor
  build_k_pair t5, 69+16*\base     // Load twiddle factor
  build_k_pair t6, 70+16*\base     // Load twiddle factor
  pqcuark.bfnttk s0, s0, t0
  pqcuark.bfnttk s1, s1, t1
  pqcuark.bfnttk s2, s2, t2
  pqcuark.bfnttk s3, s3, t3
  pqcuark.bfnttk s4, s4, t4
  pqcuark.bfnttk s5, s5, t5
  pqcuark.bfnttk s6, s6, t6
  build_k_pair t0, 71+16*\base     // Load twiddle factor
  build_k_pair t1, 72+16*\base     // Load twiddle factor
  build_k_pair t2, 73+16*\base     // Load twiddle factor
  build_k_pair t3, 74+16*\base     // Load twiddle factor
  build_k_pair t4, 75+16*\base     // Load twiddle factor
  build_k_pair t5, 76+16*\base     // Load twiddle factor
  build_k_pair t6, 77+16*\base     // Load twiddle factor
  pqcuark.bfnttk s7, s7, t0
  pqcuark.bfnttk s8, s8, t1
  pqcuark.bfnttk s9, s9, t2
  pqcuark.bfnttk s10, s10, t3
  pqcuark.bfnttk s11, s11, t4
  pqcuark.bfnttk a2, a2, t5
  pqcuark.bfnttk a3, a3, t6
  build_k_pair t0, 78+16*\base     // Load twiddle factor
  build_k_pair t1, 79+16*\base     // Load twiddle factor
  pqcuark.bfnttk a4, a4, t0
  pqcuark.bfnttk a5, a5, t1

  store_coeffs a0, 8, 1
  addi a0, a0, 128 // poly+=16
.endm

### LAYER 4+3+2+1 
.macro intt_pqcuark_loop1
  addi a0, a0, -8
  // load coefficients
  load_coeffs a0, 8, 4
  // layer 4 LEN=16
  build_k_pair t4, 15      // Load twiddle factor
  pack_lsb t5, s1, s0 // (s1[32:0], s0[32:0])
  pack_msb t6, s1, s0 // (s1[64:32], s0[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s1, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 14      // Load twiddle factor
  pack_lsb t5, s3, s2 // (s3[32:0], s2[32:0])
  pack_msb t6, s3, s2 // (s3[64:32], s2[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s3, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 13      // Load twiddle factor
  pack_lsb t5, s5, s4 // (s5[32:0], s4[32:0])
  pack_msb t6, s5, s4 // (s5[64:32], s4[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s5, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 12     // Load twiddle factor
  pack_lsb t5, s7, s6 // (s7[32:0], s6[32:0])
  pack_msb t6, s7, s6 // (s7[64:32], s6[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pack_lsb s6, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s7, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 11     // Load twiddle factor
  pack_lsb t5, s9, s8 // (s9[32:0], s8[32:0])
  pack_msb t6, s9, s8 // (s9[64:32], s8[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s9, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 10     // Load twiddle factor
  pack_lsb t5, s11, s10 // (s11[32:0], s10[32:0])
  pack_msb t6, s11, s10 // (s11[64:32], s10[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pack_lsb s10, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s11, t6, t5 // (t6[64:32], t5[64:32])


  build_k_pair t4, 9      // Load twiddle factor
  pack_lsb t5, a3, a2 // (a3[32:0], a2[32:0])
  pack_msb t6, a3, a2 // (a3[64:32], a2[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a3, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 8      // Load twiddle factor
  pack_lsb t5, a5, a4 // (a5[32:0], a4[32:0])
  pack_msb t6, a5, a4 // (a5[64:32], a4[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pack_lsb a4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a5, t6, t5 // (t6[64:32], t5[64:32])

  // layer 3 LEN=32
  build_k_pair t4, 7      // Load twiddle factor
  pack_lsb t5, s2, s0 // (s2[32:0], s0[32:0])
  pack_msb t6, s2, s0 // (s2[64:32], s0[64:32])
  pack_lsb a6, s3, s1 // (s3[32:0], s1[32:0])
  pack_msb a7, s3, s1 // (s3[64:32], s1[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s2, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s3, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 6      // Load twiddle factor
  pack_lsb t5, s6, s4 // (s6[32:0], s4[32:0])
  pack_msb t6, s6, s4 // (s6[64:32], s4[64:32])
  pack_lsb a6, s7, s5 // (s7[32:0], s5[32:0])
  pack_msb a7, s7, s5 // (s7[64:32], s5[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s5, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 5      // Load twiddle factor
  pack_lsb t5, s10, s8 // (s10[32:0], s8[32:0])
  pack_msb t6, s10, s8 // (s10[64:32], s8[64:32])
  pack_lsb a6, s11, s9 // (s11[32:0], s9[32:0])
  pack_msb a7, s11, s9 // (s11[64:32], s9[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s10, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 4      // Load twiddle factor
  pack_lsb t5, a4, a2 // (a4[32:0], a2[32:0])
  pack_msb t6, a4, a2 // (a4[64:32], a2[64:32])
  pack_lsb a6, a5, a3 // (a5[32:0], a3[32:0])
  pack_msb a7, a5, a3 // (a5[64:32], a3[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
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
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s4, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s5, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, s6, s2 // (s6[32:0], s2[32:0])
  pack_msb t6, s6, s2 // (s6[64:32], s2[64:32])
  pack_lsb a6, s7, s3 // (s7[32:0], s3[32:0])
  pack_msb a7, s7, s3 // (s7[64:32], s3[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s3, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 2      // Load twiddle factor
  pack_lsb t5, a2, s8 // (a2[32:0], s8[32:0])
  pack_msb t6, a2, s8 // (a2[64:32], s8[64:32])
  pack_lsb a6, a3, s9 // (a3[32:0], s9[32:0])
  pack_msb a7, a3, s9 // (a3[64:32], s9[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a2, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a3, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, a4, s10 // (a4[32:0], s10[32:0])
  pack_msb t6, a4, s10 // (a4[64:32], s10[64:32])
  pack_lsb a6, a5, s11 // (a5[32:0], s11[32:0])
  pack_msb a7, a5, s11 // (a5[64:32], s11[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
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
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s8, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s9, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, s10, s2 // (s10[32:0], s2[32:0])
  pack_msb t6, s10, s2 // (s10[64:32], s2[64:32])
  pack_lsb a6, s11, s3 // (s11[32:0], s3[32:0])
  pack_msb a7, s11, s3 // (s11[64:32], s3[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s10, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s3, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, a2, s4 // (a2[32:0], s4[32:0])
  pack_msb t6, a2, s4 // (a2[64:32], s4[64:32])
  pack_lsb a6, a3, s5 // (a3[32:0], s5[32:0])
  pack_msb a7, a3, s5 // (a3[64:32], s5[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a2, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s5, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a3, a7, a6 // (a7[64:32], a6[64:32])

  pack_lsb t5, a4, s6 // (a4[32:0], s6[32:0])
  pack_msb t6, a4, s6 // (a4[64:32], s6[64:32])
  pack_lsb a6, a5, s7 // (a5[32:0], s7[32:0])
  pack_msb a7, a5, s7 // (a5[64:32], s7[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s6, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s7, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

  // store coefficients
  store_coeffs a0, 16, 2

.endm

### LAYER 7+6+5
.macro intt_pqcuark_loop2 base
  // load coefficients
  load_coeffs a0, 8, 1
  // layer 7 LEN=2
  build_k_pair t0, 127-16*\base     // Load twiddle factor
  build_k_pair t1, 126-16*\base     // Load twiddle factor
  build_k_pair t2, 125-16*\base     // Load twiddle factor
  build_k_pair t3, 124-16*\base     // Load twiddle factor
  build_k_pair t4, 123-16*\base     // Load twiddle factor
  build_k_pair t5, 122-16*\base     // Load twiddle factor
  build_k_pair t6, 121-16*\base     // Load twiddle factor
  pqcuark.bfinttk s0, s0, t0
  pqcuark.bfinttk s1, s1, t1
  pqcuark.bfinttk s2, s2, t2
  pqcuark.bfinttk s3, s3, t3
  pqcuark.bfinttk s4, s4, t4
  pqcuark.bfinttk s5, s5, t5
  pqcuark.bfinttk s6, s6, t6
  build_k_pair t0, 120-16*\base     // Load twiddle factor
  build_k_pair t1, 119-16*\base     // Load twiddle factor
  build_k_pair t2, 118-16*\base     // Load twiddle factor
  build_k_pair t3, 117-16*\base     // Load twiddle factor
  build_k_pair t4, 116-16*\base     // Load twiddle factor
  build_k_pair t5, 115-16*\base     // Load twiddle factor
  build_k_pair t6, 114-16*\base     // Load twiddle factor
  pqcuark.bfinttk s7, s7, t0
  pqcuark.bfinttk s8, s8, t1
  pqcuark.bfinttk s9, s9, t2
  pqcuark.bfinttk s10, s10, t3
  pqcuark.bfinttk s11, s11, t4
  pqcuark.bfinttk a2, a2, t5
  pqcuark.bfinttk a3, a3, t6
  build_k_pair t0, 113-16*\base     // Load twiddle factor
  build_k_pair t1, 112-16*\base     // Load twiddle factor
  pqcuark.bfinttk a4, a4, t0
  pqcuark.bfinttk a5, a5, t1

  // layer 6 LEN=4
  build_k_pair t4, 63-8*\base     // Load twiddle factor
  pack_lsb t5, s1, s0 // (s1[32:0], s0[32:0])
  pack_msb t6, s1, s0 // (s1[64:32], s0[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s1, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 62-8*\base     // Load twiddle factor
  pack_lsb a6, s3, s2 // (s3[32:0], s2[32:0])
  pack_msb a7, s3, s2 // (s3[64:32], s2[64:32])
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s2, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s3, a7, a6 // (a7[64:32], a6[64:32])
  
  build_k_pair t4, 61-8*\base     // Load twiddle factor
  pack_lsb t5, s5, s4 // (s5[32:0], s4[32:0])
  pack_msb t6, s5, s4 // (s5[64:32], s4[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s5, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 60-8*\base     // Load twiddle factor
  pack_lsb a6, s7, s6 // (s7[32:0], s6[32:0])
  pack_msb a7, s7, s6 // (s7[64:32], s6[64:32])
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s6, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 59-8*\base     // Load twiddle factor
  pack_lsb t5, s9, s8 // (s9[32:0], s8[32:0])
  pack_msb t6, s9, s8 // (s9[64:32], s8[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s9, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 58-8*\base     // Load twiddle factor
  pack_lsb a6, s11, s10 // (s11[32:0], s10[32:0])
  pack_msb a7, s11, s10 // (s11[64:32], s10[64:32])
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s10, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])


  build_k_pair t4, 57-8*\base     // Load twiddle factor
  pack_lsb t5, a3, a2 // (a3[32:0], a2[32:0])
  pack_msb t6, a3, a2 // (a3[64:32], a2[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a3, t6, t5 // (t6[64:32], t5[64:32])

  build_k_pair t4, 56-8*\base     // Load twiddle factor
  pack_lsb a6, a5, a4 // (a5[32:0], a4[32:0])
  pack_msb a7, a5, a4 // (a5[64:32], a4[64:32])
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb a4, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])


  // layer 5 LEN=8
  build_k_pair t4, 31-4*\base     // Load twiddle factor
  pack_lsb t5, s2, s0 // (s2[32:0], s0[32:0])
  pack_msb t6, s2, s0 // (s2[64:32], s0[64:32])
  pack_lsb a6, s3, s1 // (s3[32:0], s1[32:0])
  pack_msb a7, s3, s1 // (s3[64:32], s1[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s0, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s2, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s1, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s3, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 30-4*\base     // Load twiddle factor
  pack_lsb t5, s6, s4 // (s6[32:0], s4[32:0])
  pack_msb t6, s6, s4 // (s6[64:32], s4[64:32])
  pack_lsb a6, s7, s5 // (s7[32:0], s5[32:0])
  pack_msb a7, s7, s5 // (s7[64:32], s5[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s4, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s6, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s5, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s7, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 29-4*\base     // Load twiddle factor
  pack_lsb t5, s10, s8 // (s10[32:0], s8[32:0])
  pack_msb t6, s10, s8 // (s10[64:32], s8[64:32])
  pack_lsb a6, s11, s9 // (s11[32:0], s9[32:0])
  pack_msb a7, s11, s9 // (s11[64:32], s9[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb s8, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb s10, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb s9, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb s11, a7, a6 // (a7[64:32], a6[64:32])

  build_k_pair t4, 28-4*\base     // Load twiddle factor
  pack_lsb t5, a4, a2 // (a4[32:0], a2[32:0])
  pack_msb t6, a4, a2 // (a4[64:32], a2[64:32])
  pack_lsb a6, a5, a3 // (a5[32:0], a3[32:0])
  pack_msb a7, a5, a3 // (a5[64:32], a3[64:32])
  pqcuark.bfinttk t5, t5, t4
  pqcuark.bfinttk t6, t6, t4
  pqcuark.bfinttk a6, a6, t4
  pqcuark.bfinttk a7, a7, t4
  pack_lsb a2, t6, t5 // (t6[32:0], t5[32:0])
  pack_msb a4, t6, t5 // (t6[64:32], t5[64:32])
  pack_lsb a3, a7, a6 // (a7[32:0], a6[32:0])
  pack_msb a5, a7, a6 // (a7[64:32], a6[64:32])

  store_coeffs a0, 8, 1
  addi a0, a0, 128 // poly+=16
.endm

.macro fqmul_pqcuark_iteration
  load_coeffs a0, 8, 1

  pqcuark.bffqmul16.l t2, s0, t1 
  pqcuark.bffqmul16.l t3, s1, t1
  pqcuark.bffqmul16.l t4, s2, t1
  pqcuark.bffqmul16.l t5, s3, t1
  pqcuark.bffqmul16.h s0, t2, t1 
  pqcuark.bffqmul16.h s1, t3, t1
  pqcuark.bffqmul16.h s2, t4, t1
  pqcuark.bffqmul16.h s3, t5, t1

  pqcuark.bffqmul16.l t2, s4, t1
  pqcuark.bffqmul16.l t3, s5, t1
  pqcuark.bffqmul16.l t4, s6, t1
  pqcuark.bffqmul16.l t5, s7, t1
  pqcuark.bffqmul16.h s4, t2, t1 
  pqcuark.bffqmul16.h s5, t3, t1
  pqcuark.bffqmul16.h s6, t4, t1
  pqcuark.bffqmul16.h s7, t5, t1

  pqcuark.bffqmul16.l t2, s8, t1 
  pqcuark.bffqmul16.l t3, s9, t1 
  pqcuark.bffqmul16.l t4, s10, t1
  pqcuark.bffqmul16.l t5, s11, t1
  pqcuark.bffqmul16.h s8, t2, t1 
  pqcuark.bffqmul16.h s9, t3, t1
  pqcuark.bffqmul16.h s10, t4, t1
  pqcuark.bffqmul16.h s11, t5, t1
  
  pqcuark.bffqmul16.l t2, a2, t1
  pqcuark.bffqmul16.l t3, a3, t1
  pqcuark.bffqmul16.l t4, a4, t1
  pqcuark.bffqmul16.l t5, a5, t1
  pqcuark.bffqmul16.h a2, t2, t1 
  pqcuark.bffqmul16.h a3, t3, t1
  pqcuark.bffqmul16.h a4, t4, t1
  pqcuark.bffqmul16.h a5, t5, t1

  store_coeffs a0, 8, 1
  addi a0, a0, 128 // poly+=16
.endm


.equ q,    3329
.equ qinv, 0x3c0f12886ba8f301           // q^-1 mod 2^64

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
  addi a0, a0, 32   // poly[16]
    ### LAYER 1+2+3+4
  li gp, 4
ntt_pqcuark_loop1_loop:
  ntt_pqcuark_loop1
  addi gp, gp, -1
  bnez gp, ntt_pqcuark_loop1_loop
  ### LAYER 5+6+7
  ntt_pqcuark_loop2 0
  ntt_pqcuark_loop2 1
  ntt_pqcuark_loop2 2
  ntt_pqcuark_loop2 3

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
  ### LAYER 7+6+5
  intt_pqcuark_loop2 0
  intt_pqcuark_loop2 1
  intt_pqcuark_loop2 2
  intt_pqcuark_loop2 3
  ### LAYER 4+3+2+1
  addi a0, a0, -480 # -512+32
  li gp, 4
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
  li gp, 4
  li t1, 1441          // Load 1441 into t1
  slli t1, t1, 16      // Shift 1441 to the upper 16 bits
  ori t1, t1, 1441     // Combine with 1441 in the lower 16 bits
  slli t1, t1, 16      // Shift 1441 to the upper 32 bits
  ori t1, t1, 1441     // Combine with 1441 in the lower 16 bits
  slli t1, t1, 16      // Shift 1441 to the upper 32 bits
  ori t1, t1, 1441     // Combine with 1441 in the lower 16 bits
  fqmul_pqcuark_loop:
    fqmul_pqcuark_iteration
    addi gp, gp, -1
    bnez gp, fqmul_pqcuark_loop
  restore_regs
  addi sp, sp, 8*15
  ret
  
  
