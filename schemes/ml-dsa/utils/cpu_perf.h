#ifndef CPU_PERF_H
#define CPU_PERF_H

#include <stdint.h>
#include "encoding.h"

typedef struct {
  uint64_t start;
  uint64_t end;
  uint64_t diff;
} counter_t;

typedef struct {
  counter_t mcycles;
  counter_t minstr;
  counter_t mbrmiss;
  counter_t mbr;
  counter_t mbrtaken;
  counter_t mstores;
  counter_t mloads;
  counter_t icache_req;
  counter_t icache_kills;
  counter_t fetch_stalls;
  counter_t decode_stalls;
  counter_t read_reg_stalls;
  counter_t exe_stalls;
  counter_t wb_stalls;
  counter_t buffermiss;
  counter_t imiss_kill;
  counter_t icache_busy;
  counter_t imiss_time;
  counter_t cycles_load_blocked;
  counter_t data_depend_stalls;
  counter_t structural_stalls;
  counter_t gl_stalls;
  counter_t free_list_stalls;
  counter_t itlb_access;
  counter_t itlb_miss;
  counter_t dtlb_access;
  counter_t dtlb_miss;
  counter_t ptw_cache_hit;
  counter_t ptw_cache_miss;
  counter_t stalls_itlb_miss;
} checkpoint_t;

static inline uintptr_t cpucycles(void) {
  uintptr_t result;

  result = read_csr(mcycle);

  return result;
}


static inline uintptr_t cpuinstr(void) {
  uintptr_t result;

  result = read_csr(minstret);

  return result;
}

uint64_t cpucycles_overhead(void);

void cpu_perf(uint64_t* cycles, uint64_t* instr);

void set_checkpoint_start(checkpoint_t* checkpoint);
void set_checkpoint_end(checkpoint_t* checkpoint);

#endif