#include "util.h"
#include "metrics.h"
#include <stdio.h>

uint64_t _cycles ;
uint64_t _instructions ; 

uint32_t roi_start (void){
    _cycles = read_csr(mcycle);
    _instructions = read_csr(minstret);
    return 0; 
}

uint32_t roi_end (void){
    _cycles = read_csr(mcycle) - _cycles;
    _instructions = read_csr(minstret) - _instructions;
    return 0; 
}

uint32_t print_metrics (char *test_name ){
    printf("\n");
    printf("--  %s  -- \r\n",test_name);
    printf("Cycles:  %d \r\n", _cycles);
    printf("Instructions:  %d \r\n\n",_instructions);
    return 0; 
}

