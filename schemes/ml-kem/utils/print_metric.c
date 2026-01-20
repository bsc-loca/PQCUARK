#include "print_metric.h"
#include "cpu_perf.h"
#include <stdint.h>
#include <stdio.h>

static int cmp_uint64(const void *a, const void *b) {
  if(*(uint64_t *)a < *(uint64_t *)b) return -1;
  if(*(uint64_t *)a > *(uint64_t *)b) return 1;
  return 0;
}

void print_double(double x) {
    int64_t integer_part = (int64_t)x;
    int64_t decimal_part = (int64_t)((x - integer_part) * 100);  // 2 decimales
    printf("%ld.%02ld", integer_part, decimal_part < 0 ? -decimal_part : decimal_part);
}

/* Custom square root function using Newton-Raphson method */
static double sqrt_newton(double x) {
    if (x == 0.0) return 0.0;

    double guess = x / 2.0;
    const double epsilon = 1e-9;  // Desired precision

    while (1) {
        double next = 0.5 * (guess + x / guess);
        if (guess - next < epsilon && guess - next > -epsilon) {
            break;
        }
        guess = next;
    }
    return guess;
}

static double standard_deviation(uint64_t *l, size_t llen) {
    // Calculate mean
    double sum = 0.0;
    for (size_t i = 0; i < llen; i++) {
        sum += (double)l[i];
    }
    double mean = sum / (double)llen;

    // Calculate variance sum
    double var_sum = 0.0;
    for (size_t i = 0; i < llen; i++) {
        double diff = (double)l[i] - mean;
        var_sum += diff * diff;
    }
    double variance = var_sum / (double)llen;  // For population std dev
    // Or use (llen - 1) for sample std dev:
    // double variance = var_sum / (double)(llen - 1);

    // Use custom sqrt function
    return sqrt_newton(variance);
}

static uint64_t median(uint64_t *l, size_t llen) {
  qsort(l,llen,sizeof(uint64_t),cmp_uint64);

  /*
  printf("---Standard Deviation: ");
  print_double(standard_deviation(l, llen));
  printf("\n");
  */

  if(llen%2) return l[llen/2];
  else return (l[llen/2-1]+l[llen/2])/2;
}

static uint64_t average(uint64_t *t, size_t tlen) {
  size_t i;
  uint64_t acc=0;

  for(i=0;i<tlen;i++)
    acc += t[i];

  return acc/tlen;
}

void print_one(const checkpoint_t *cp) {
  printf("/**************************************************************/\n");
  printf("Cycles: %llu\n", cp->mcycles.diff);
  printf("Instructions: %llu\n", cp->minstr.diff);
  printf("Missed Branches: %llu\n", cp->mbrmiss.diff);
  printf("Executed Branches: %llu\n", cp->mbr.diff);
  printf("Taken Branches: %llu\n", cp->mbrtaken.diff);
  printf("Executed Stores: %llu\n", cp->mstores.diff);
  printf("Executed Loads: %llu\n", cp->mloads.diff);
  printf("iCache Requests: %llu\n", cp->icache_req.diff);
  printf("iCache Kills: %llu\n", cp->icache_kills.diff);
  printf("Stalls of Fetch: %llu\n", cp->fetch_stalls.diff);
  printf("Stalls of Decode: %llu\n", cp->decode_stalls.diff);
  printf("Stalls of Read Register: %llu\n", cp->read_reg_stalls.diff);
  printf("Stalls of Execute: %llu\n", cp->exe_stalls.diff);
  printf("Stalls of Write Back: %llu\n", cp->wb_stalls.diff);
  printf("Buffer Miss: %llu\n", cp->buffermiss.diff);
  printf("iMiss Kill: %llu\n", cp->imiss_kill.diff);
  printf("iCache Busy: %llu\n", cp->icache_busy.diff);
  printf("iMiss Time: %llu\n", cp->imiss_time.diff);
  printf("Cycles of Load Blocked by Store: %llu\n", cp->cycles_load_blocked.diff);
  printf("Data Depend Stalls: %llu\n", cp->data_depend_stalls.diff);
  printf("Structural Stalls: %llu\n", cp->structural_stalls.diff);
  printf("Global Stalls: %llu\n", cp->gl_stalls.diff);
  printf("Free List Stalls: %llu\n", cp->free_list_stalls.diff);
  printf("iTLB Access: %llu\n", cp->itlb_access.diff);
  printf("iTLB Miss: %llu\n", cp->itlb_miss.diff);
  printf("dTLB Access: %llu\n", cp->dtlb_access.diff);
  printf("dTLB Miss: %llu\n", cp->dtlb_miss.diff);
  printf("PTW Cache Hit: %llu\n", cp->ptw_cache_hit.diff);
  printf("PTW Cache Miss: %llu\n", cp->ptw_cache_miss.diff);
  printf("Stalls by iTLB Miss: %llu\n", cp->stalls_itlb_miss.diff);
  printf("\n");
}
void print_all_average(const checkpoint_t *cp, size_t len) {
  size_t i;
  uint64_t t[len];

  if(len < 2) {
    printf("ERROR: Need at least two cycle counts!\n");
    return;
  }
  len--;
  for(i=0;i<len;++i) {
    if (cp[i].mcycles.diff == 0) {
      printf("ERROR: Uninitialized mcycles.diff at index %zu\n", i);
      return;
    }
    t[i] = cp[i].mcycles.diff;
  }
  printf("/**************************************************************/\n");
  printf("Cycles: %llu\n", (unsigned long long)average(t, len));
  for(i=0;i<len;++i) t[i] = cp[i].minstr.diff;
  printf("Instructions: %llu\n", (unsigned long long)average(t, len));
  for(i=0;i<len;++i) t[i] = cp[i].mbrmiss.diff;
  printf("Missed Branches: %llu\n", (unsigned long long)average(t, len));
  for(i=0;i<len;++i) t[i] = cp[i].mbr.diff;
  printf("Executed Branches: %llu\n", (unsigned long long)average(t, len));
  for(i=0;i<len;++i) t[i] = cp[i].mbrtaken.diff;
  printf("Taken Branches: %llu\n", (unsigned long long)average(t, len));
  for(i=0;i<len;++i) t[i] = cp[i].mstores.diff;
  printf("Executed Stores: %llu\n", (unsigned long long)average(t, len));
  for(i=0;i<len;++i) t[i] = cp[i].mloads.diff;
  printf("Executed Loads: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].icache_req.diff;
  printf("iCache Requests: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].icache_kills.diff;
  printf("iCache Kills: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].fetch_stalls.diff;
  printf("Stalls of Fetch: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].decode_stalls.diff;
  printf("Stalls of Decode: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].read_reg_stalls.diff;
  printf("Stalls of Read Register: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].exe_stalls.diff;
  printf("Stalls of Execute: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].wb_stalls.diff;
  printf("Stalls of Write Back: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].buffermiss.diff;
  printf("Buffer Miss: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].imiss_kill.diff;
  printf("iMiss Kill: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].icache_busy.diff;
  printf("iCache Busy: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].imiss_time.diff;
  printf("iMiss Time: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].cycles_load_blocked.diff;
  printf("Cycles of Load Blocked by Store: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].data_depend_stalls.diff;
  printf("Data Depend Stalls: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].structural_stalls.diff;
  printf("Structural Stalls: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].gl_stalls.diff;
  printf("Global Stalls: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].free_list_stalls.diff;
  printf("Free List Stalls: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].itlb_access.diff;
  printf("iTLB Access: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].itlb_miss.diff;
  printf("iTLB Miss: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].dtlb_access.diff;
  printf("dTLB Access: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].dtlb_miss.diff;
  printf("dTLB Miss: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].ptw_cache_hit.diff;
  printf("PTW Cache Hit: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].ptw_cache_miss.diff;
  printf("PTW Cache Miss: %llu\n", (unsigned long long)average(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].stalls_itlb_miss.diff;
  printf("Stalls by iTLB Miss: %llu\n", (unsigned long long)average(t, len));
  printf("/**************************************************************/\n");
}

void print_all_median(const checkpoint_t *cp, size_t len) {
  size_t i;
  uint64_t t[len];

  if(len < 2) {
    printf("ERROR: Need at least two cycle counts!\n");
    return;
  }
  len--;
  for(i=0;i<len;++i) {
    if (cp[i].mcycles.diff == 0) {
      printf("ERROR: Uninitialized mcycles.diff at index %zu\n", i);
      return;
    }
    t[i] = cp[i].mcycles.diff;
  }
  printf("/**************************************************************/\n");
  printf("Cycles: %llu\n", (unsigned long long)median(t, len));
  for(i=0;i<len;++i) t[i] = cp[i].minstr.diff;
  printf("Instructions: %llu\n", (unsigned long long)median(t, len));
  for(i=0;i<len;++i) t[i] = cp[i].mbrmiss.diff;
  printf("Missed Branches: %llu\n", (unsigned long long)median(t, len));
  for(i=0;i<len;++i) t[i] = cp[i].mbr.diff;
  printf("Executed Branches: %llu\n", (unsigned long long)median(t, len));
  for(i=0;i<len;++i) t[i] = cp[i].mbrtaken.diff;
  printf("Taken Branches: %llu\n", (unsigned long long)median(t, len));
  for(i=0;i<len;++i) t[i] = cp[i].mstores.diff;
  printf("Executed Stores: %llu\n", (unsigned long long)median(t, len));
  for(i=0;i<len;++i) t[i] = cp[i].mloads.diff;
  printf("Executed Loads: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].icache_req.diff;
  printf("iCache Requests: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].icache_kills.diff;
  printf("iCache Kills: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].fetch_stalls.diff;
  printf("Stalls of Fetch: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].decode_stalls.diff;
  printf("Stalls of Decode: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].read_reg_stalls.diff;
  printf("Stalls of Read Register: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].exe_stalls.diff;
  printf("Stalls of Execute: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].wb_stalls.diff;
  printf("Stalls of Write Back: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].buffermiss.diff;
  printf("Buffer Miss: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].imiss_kill.diff;
  printf("iMiss Kill: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].icache_busy.diff;
  printf("iCache Busy: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].imiss_time.diff;
  printf("iMiss Time: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].cycles_load_blocked.diff;
  printf("Cycles of Load Blocked by Store: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].data_depend_stalls.diff;
  printf("Data Depend Stalls: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].structural_stalls.diff;
  printf("Structural Stalls: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].gl_stalls.diff;
  printf("Global Stalls: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].free_list_stalls.diff;
  printf("Free List Stalls: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].itlb_access.diff;
  printf("iTLB Access: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].itlb_miss.diff;
  printf("iTLB Miss: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].dtlb_access.diff;
  printf("dTLB Access: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].dtlb_miss.diff;
  printf("dTLB Miss: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].ptw_cache_hit.diff;
  printf("PTW Cache Hit: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].ptw_cache_miss.diff;
  printf("PTW Cache Miss: %llu\n", (unsigned long long)median(t, len));
  for (i = 0; i < len; ++i) t[i] = cp[i].stalls_itlb_miss.diff;
  printf("Stalls by iTLB Miss: %llu\n", (unsigned long long)median(t, len));
  printf("/**************************************************************/\n");
}

void print_average(const checkpoint_t *cp, size_t len) {
  size_t i;
  uint64_t t[len];
  uint64_t instr[len];

  if(len < 1) {
    printf("ERROR: Need a least 1 experiment!\n");
    return;
  }
  for(i=0;i<len;++i)
    t[i] = cp[i].mcycles.diff;// - overhead;

  for(i=0;i<len;++i)
    instr[i] = cp[i].minstr.diff;// - overhead;

  printf("Cycles: %llu\n", (unsigned long long)average(t, len));
  printf("Instructions: %llu\n", (unsigned long long)average(instr, len));
  printf("\n");
}

void print_median(const checkpoint_t *cp, size_t len) {
  size_t i;
  uint64_t t[len];
  uint64_t instr[len];

  if(len < 1) {
    printf("ERROR: Need a least 1 experiment!\n");
    return;
  }
  for(i=0;i<len;++i)
    t[i] = cp[i].mcycles.diff;// - overhead;

  for(i=0;i<len;++i)
    instr[i] = cp[i].minstr.diff;// - overhead;

  printf("Cycles: %llu\n", (unsigned long long)median(t, len));
  printf("Instructions: %llu\n", (unsigned long long)median(instr, len));
  printf("\n");
}