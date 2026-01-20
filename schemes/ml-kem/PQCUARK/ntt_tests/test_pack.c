/*-----------------------------------------------------------------------------
 *  test_pack_packu.c
 *  Description : Bare-metal test for RISC-V Zbkb instructions PACK and PACKU
 *                on RV64. Compares against reference models.
 *
 *  Requirements:
 *    - Target must support Zbkb extension (PACK and PACKU).
 *    - No use of rand(), assert(), or stdio.h (except for printf).
 *    - Exit code 0: all pass, non-zero: at least one mismatch.
 *---------------------------------------------------------------------------*/

 #include <stdint.h>
 #include <stdio.h>
 
 /* Reference model for PACK (lower halves) */
 static uint64_t pack_ref(uint64_t rs1, uint64_t rs2)
 {
	 uint64_t lo1 = rs1 & 0xFFFFFFFFULL;
	 uint64_t lo2 = rs2 & 0xFFFFFFFFULL;
	 return (lo1 << 32) | lo2;
 }
 
 /* Reference model for PACKU (upper halves) */
 static uint64_t packu_ref(uint64_t rs1, uint64_t rs2)
 {
	 uint64_t hi1 = (rs1 >> 32) & 0xFFFFFFFFULL;
	 uint64_t hi2 = (rs2 >> 32) & 0xFFFFFFFFULL;
	 return (hi1 << 32) | hi2;
 }
 
 /* Execute real PACK instruction */
 static inline uint64_t pack_exec(uint64_t rs1, uint64_t rs2)
 {
	 uint64_t rd;
	 asm volatile ("pack %0, %1, %2" : "=r"(rd) : "r"(rs1), "r"(rs2));
	 return rd;
 }
 
 /* Execute real PACKU instruction */
 static inline uint64_t packu_exec(uint64_t rs1, uint64_t rs2)
 {
	 uint64_t rd;
	 asm volatile ("packh %0, %1, %2" : "=r"(rd) : "r"(rs1), "r"(rs2));
	 return rd;
 }
 
 int main(void)
 {
	 const uint64_t vecs[][2] = {
		 {0x0123456789ABCDEFULL, 0xFFEEDDCCBBAA9988ULL},
		 {0x0000000000000000ULL, 0xFFFFFFFFFFFFFFFFULL},
		 {0x1234000056780000ULL, 0x0000ABCD0000DCBAULL},
		 {0xA5A5A5A5A5A5A5A5ULL, 0x5A5A5A5A5A5A5A5AULL}
	 };
 
	 int mismatches = 0;
 
	 for (size_t i = 0; i < sizeof(vecs) / sizeof(vecs[0]); ++i) {
		 uint64_t rs1 = vecs[i][0];
		 uint64_t rs2 = vecs[i][1];
 
		 uint64_t rd_pack_ref  = pack_ref(rs1, rs2);
		 uint64_t rd_pack_isa  = pack_exec(rs1, rs2);
		 uint64_t rd_packu_ref = packu_ref(rs1, rs2);
		 uint64_t rd_packu_isa = packu_exec(rs1, rs2);
 
		 if (rd_pack_ref != rd_pack_isa) {
			 printf("PACK Mismatch #%zu\n", i);
			 printf("  rs1=0x%016lx  rs2=0x%016lx\n", (unsigned long long)rs1, (unsigned long long)rs2);
			 printf("  REF=0x%016lx  ISA=0x%016lx\n\n", (unsigned long long)rd_pack_ref, (unsigned long long)rd_pack_isa);
			 ++mismatches;
		 }
 
		 if (rd_packu_ref != rd_packu_isa) {
			 printf("PACKU Mismatch #%zu\n", i);
			 printf("  rs1=0x%016lx  rs2=0x%016lx\n", (unsigned long long)rs1, (unsigned long long)rs2);
			 printf("  REF=0x%016lx  ISA=0x%016lx\n\n", (unsigned long long)rd_packu_ref, (unsigned long long)rd_packu_isa);
			 ++mismatches;
		 }
	 }
 
	 if (mismatches == 0) {
		 printf("[INFO] PACK/PACKU tests PASSED\n");
		 return 0;
	 } else {
		 printf("[INFO] FAIL: %d mismatches\n", mismatches);
		 return 1;
	 }
 }
 