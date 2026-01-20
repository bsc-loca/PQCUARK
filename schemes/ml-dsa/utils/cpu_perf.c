#include <stdint.h>
#include "cpu_perf.h"

uint64_t cpucycles_overhead(void) {
  uint64_t t0, t1, overhead = -1LL;
  unsigned int i;

  for(i=0;i<100000;i++) {
    t0 = cpucycles();
    __asm__ volatile ("");
    t1 = cpucycles();
    if(t1 - t0 < overhead)
      overhead = t1 - t0;
  }

  return overhead;
}

void cpu_perf(uint64_t* cycles, uint64_t* instr) {
  *cycles = read_csr(mcycle);
  *instr = read_csr(minstret);
}

void set_checkpoint_start(checkpoint_t* checkpoint) {
  checkpoint->mbrmiss.start = read_csr(mhpmcounter3);
  checkpoint->mbr.start = read_csr(mhpmcounter4);
  checkpoint->mbrtaken.start = read_csr(mhpmcounter5);
  checkpoint->mstores.start = read_csr(mhpmcounter6);
  checkpoint->mloads.start = read_csr(mhpmcounter7);
  checkpoint->icache_req.start = read_csr(mhpmcounter8);
  checkpoint->icache_kills.start = read_csr(mhpmcounter9);
  checkpoint->fetch_stalls.start = read_csr(mhpmcounter10);
  checkpoint->decode_stalls.start = read_csr(mhpmcounter11);
  checkpoint->read_reg_stalls.start = read_csr(mhpmcounter12);
  checkpoint->exe_stalls.start = read_csr(mhpmcounter13);
  checkpoint->wb_stalls.start = read_csr(mhpmcounter14);
  checkpoint->buffermiss.start = read_csr(mhpmcounter15);
  checkpoint->imiss_kill.start = read_csr(mhpmcounter16);
  checkpoint->icache_busy.start = read_csr(mhpmcounter17);
  checkpoint->imiss_time.start = read_csr(mhpmcounter18);
  checkpoint->cycles_load_blocked.start = read_csr(mhpmcounter19);
  checkpoint->data_depend_stalls.start = read_csr(mhpmcounter20);
  checkpoint->structural_stalls.start = read_csr(mhpmcounter21);
  checkpoint->gl_stalls.start = read_csr(mhpmcounter22);
  checkpoint->free_list_stalls.start = read_csr(mhpmcounter23);
  checkpoint->itlb_access.start = read_csr(mhpmcounter24);
  checkpoint->itlb_miss.start = read_csr(mhpmcounter25);
  checkpoint->dtlb_access.start = read_csr(mhpmcounter26);
  checkpoint->dtlb_miss.start = read_csr(mhpmcounter27);
  checkpoint->ptw_cache_hit.start = read_csr(mhpmcounter28);
  checkpoint->ptw_cache_miss.start = read_csr(mhpmcounter29);
  checkpoint->mcycles.start = read_csr(mcycle);
  checkpoint->minstr.start = read_csr(minstret);
}

void set_checkpoint_end(checkpoint_t* checkpoint) {
  checkpoint->mcycles.end = read_csr(mcycle);
  checkpoint->minstr.end = read_csr(minstret);
  checkpoint->mbrmiss.end = read_csr(mhpmcounter3);
  checkpoint->mbr.end = read_csr(mhpmcounter4);
  checkpoint->mbrtaken.end = read_csr(mhpmcounter5);
  checkpoint->mstores.end = read_csr(mhpmcounter6);
  checkpoint->mloads.end = read_csr(mhpmcounter7);
  checkpoint->icache_req.end = read_csr(mhpmcounter8);
  checkpoint->icache_kills.end = read_csr(mhpmcounter9);
  checkpoint->fetch_stalls.end = read_csr(mhpmcounter10);
  checkpoint->decode_stalls.end = read_csr(mhpmcounter11);
  checkpoint->read_reg_stalls.end = read_csr(mhpmcounter12);
  checkpoint->exe_stalls.end = read_csr(mhpmcounter13);
  checkpoint->wb_stalls.end = read_csr(mhpmcounter14);
  checkpoint->buffermiss.end = read_csr(mhpmcounter15);
  checkpoint->imiss_kill.end = read_csr(mhpmcounter16);
  checkpoint->icache_busy.end = read_csr(mhpmcounter17);
  checkpoint->imiss_time.end = read_csr(mhpmcounter18);
  checkpoint->cycles_load_blocked.end = read_csr(mhpmcounter19);
  checkpoint->data_depend_stalls.end = read_csr(mhpmcounter20);
  checkpoint->structural_stalls.end = read_csr(mhpmcounter21);
  checkpoint->gl_stalls.end = read_csr(mhpmcounter22);
  checkpoint->free_list_stalls.end = read_csr(mhpmcounter23);
  checkpoint->itlb_access.end = read_csr(mhpmcounter24);
  checkpoint->itlb_miss.end = read_csr(mhpmcounter25);
  checkpoint->dtlb_access.end = read_csr(mhpmcounter26);
  checkpoint->dtlb_miss.end = read_csr(mhpmcounter27);
  checkpoint->ptw_cache_hit.end = read_csr(mhpmcounter28);
  checkpoint->ptw_cache_miss.end = read_csr(mhpmcounter29);

  checkpoint->mcycles.diff = checkpoint->mcycles.end - checkpoint->mcycles.start - 71; // Subtracting overhead
  checkpoint->minstr.diff = checkpoint->minstr.end - checkpoint->minstr.start - 21; // Subtracting overhead
  checkpoint->mbrmiss.diff = checkpoint->mbrmiss.end - checkpoint->mbrmiss.start;
  checkpoint->mbr.diff = checkpoint->mbr.end - checkpoint->mbr.start;
  checkpoint->mbrtaken.diff = checkpoint->mbrtaken.end - checkpoint->mbrtaken.start;
  checkpoint->mstores.diff = checkpoint->mstores.end - checkpoint->mstores.start;
  checkpoint->mloads.diff = checkpoint->mloads.end - checkpoint->mloads.start;
  checkpoint->icache_req.diff = checkpoint->icache_req.end - checkpoint->icache_req.start;
  checkpoint->icache_kills.diff = checkpoint->icache_kills.end - checkpoint->icache_kills.start;
  checkpoint->fetch_stalls.diff = checkpoint->fetch_stalls.end - checkpoint->fetch_stalls.start;
  checkpoint->decode_stalls.diff = checkpoint->decode_stalls.end - checkpoint->decode_stalls.start;
  checkpoint->read_reg_stalls.diff = checkpoint->read_reg_stalls.end - checkpoint->read_reg_stalls.start;
  checkpoint->exe_stalls.diff = checkpoint->exe_stalls.end - checkpoint->exe_stalls.start;
  checkpoint->wb_stalls.diff = checkpoint->wb_stalls.end - checkpoint->wb_stalls.start;
  checkpoint->buffermiss.diff = checkpoint->buffermiss.end - checkpoint->buffermiss.start;
  checkpoint->imiss_kill.diff = checkpoint->imiss_kill.end - checkpoint->imiss_kill.start;
  checkpoint->icache_busy.diff = checkpoint->icache_busy.end - checkpoint->icache_busy.start;
  checkpoint->imiss_time.diff = checkpoint->imiss_time.end - checkpoint->imiss_time.start;
  checkpoint->cycles_load_blocked.diff = checkpoint->cycles_load_blocked.end - checkpoint->cycles_load_blocked.start;
  checkpoint->data_depend_stalls.diff = checkpoint->data_depend_stalls.end - checkpoint->data_depend_stalls.start;
  checkpoint->structural_stalls.diff = checkpoint->structural_stalls.end - checkpoint->structural_stalls.start;
  checkpoint->gl_stalls.diff = checkpoint->gl_stalls.end - checkpoint->gl_stalls.start;
  checkpoint->free_list_stalls.diff = checkpoint->free_list_stalls.end - checkpoint->free_list_stalls.start;
  checkpoint->itlb_access.diff = checkpoint->itlb_access.end - checkpoint->itlb_access.start;
  checkpoint->itlb_miss.diff = checkpoint->itlb_miss.end - checkpoint->itlb_miss.start;
  checkpoint->dtlb_access.diff = checkpoint->dtlb_access.end - checkpoint->dtlb_access.start;
  checkpoint->dtlb_miss.diff = checkpoint->dtlb_miss.end - checkpoint->dtlb_miss.start;
  checkpoint->ptw_cache_hit.diff = checkpoint->ptw_cache_hit.end - checkpoint->ptw_cache_hit.start;
  checkpoint->ptw_cache_miss.diff = checkpoint->ptw_cache_miss.end - checkpoint->ptw_cache_miss.start;
}

