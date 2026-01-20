// SDV
#ifdef SDV

#include "sdv_tracing.h"

// Generate tuples of Values (numbers) and names (strings)
const char * v_names[] = {"Other",
                          "gen_a", 
                          "poly_getnoise_eta1",
                          "poly_getnoise_eta2", 
                          "Poly NTT",
                          "Poly InvNTT",
                          "NTT",
                          "InvNTT",
                          "polyvec_basemul_acc_montgomery",
                          "poly_tomsg",
                          "poly_frommsg",
                          "poly_compress",
                          "poly_decompress",
                          "polyvec_compress",
                          "polyvec_decompress",
                          "indcpa_keypair",
                          "indcpa_enc",
                          "indcpa_dec",
                          "hash_h",
                          "hash_g",
                          "shake256_rkprf",
                          "kyber_keypair",
                          "kyber_encaps",
                          "kyber_decaps"
                          };

int values[] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24};


#define TRACE_NAME() trace_name_event_and_values(1000, "code_region", 23, values, v_names);
#define TRACE_INIT() trace_init();
#define TRACE_EVENT(i) trace_event_and_value(1000,i);
#define TRACE_ENABLE() trace_enable();
#define TRACE_DISABLE() trace_disable();
#else 
#define TRACE_NAME() ;
#define TRACE_INIT() ;
#define TRACE_EVENT(i) ;
#define TRACE_ENABLE() ;
#define TRACE_DISABLE() ;
#endif
