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
#if defined(VECTOR128)
                          "poly_basemul_acc",
                          "poly_basemul_acc_cache_init",
                          "poly_basemul_acc_cached",
#elif !defined(REF_IMPL) && (defined(RV32) || defined(RV64))
                          "poly_basemul_acc_cache_init"
                          "poly_basemul_acc_cached",
                          "poly_basemul_acc_cache_end",
#else
                          "poly_basemul",
#endif
                          "polyvec_basemul_acc",
                          "matrix-vector-mul",
#if defined(VECTOR128) || defined(RV32)
                          "polyvec_basemul_acc_cached",
#endif
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
                          "kyber_keypair",
                          "kyber_encaps",
                          "kyber_decaps"
                          };

int values[] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25};

int trace_count = 1;

#define TRACE_NAME() trace_name_event_and_values(1000, "code_region", sizeof(values)/sizeof(values[0]) - 1, values, v_names);
#define TRACE_INIT() trace_init();
#define TRACE_EVENT() trace_event_and_value(1000,trace_count++);
#define TRACE_EVENT_ZERO() trace_event_and_value(1000, 0);
#define TRACE_ENABLE() trace_enable();
#define TRACE_DISABLE() trace_disable();
#else 
#define TRACE_NAME() ;
#define TRACE_INIT() ;
#define TRACE_EVENT() ;
#define TRACE_EVENT_ZERO() ;
#define TRACE_ENABLE() ;
#define TRACE_DISABLE() ;
#endif
