#ifndef NTT_H
#define NTT_H

#include <stdint.h>
#include "params.h"

#define zetas KYBER_NAMESPACE(zetas)
extern const int16_t zetas[128];

#define ntt KYBER_NAMESPACE(ntt_pqcuark)
#define ntt_pqcuark KYBER_NAMESPACE(ntt_pqcuark)
void ntt_pqcuark(int16_t poly[256]);

#define invntt KYBER_NAMESPACE(intt_pqcuark)
#define intt KYBER_NAMESPACE(intt_pqcuark)
#define intt_pqcuark KYBER_NAMESPACE(intt_pqcuark)
void intt_pqcuark(int16_t poly[256]);

#define basemul KYBER_NAMESPACE(basemul_pqcuark)
#define basemul_pqcuark KYBER_NAMESPACE(basemul_pqcuark)
void basemul_pqcuark(int16_t r[2], const int16_t a[2], const int16_t b[2], int16_t zeta);


#ifdef BASEMUL_ACC
  #define basemul_acc KYBER_NAMESPACE(basemul_acc_pqcuark)
  #define basemul_acc_pqcuark KYBER_NAMESPACE(basemul_acc_pqcuark)
  void basemul_acc_pqcuark(int16_t r[2], const int16_t a[2], const int16_t b[2], int16_t zeta);
#endif



#endif
