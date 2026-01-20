#ifndef NTT_H
#define NTT_H

#include <stdint.h>
#include "params.h"

extern const int32_t zetas[256];

#ifdef PQCUARK
void ntt_pqcuark(int32_t poly[256]);

void intt_pqcuark(int32_t poly[256]);

void poly_pointwise_pqcuark(int32_t r[256], const int32_t a[256], const int32_t b[256]);

void poly_pointwise_acc_pqcuark(int32_t r[256], const int32_t a[256], const int32_t b[256]);

void poly_reduce_rv64im(int32_t r[256]);

#else 
void ntt(int32_t poly[256]);
void invntt(int32_t poly[256]);

#endif



#endif
