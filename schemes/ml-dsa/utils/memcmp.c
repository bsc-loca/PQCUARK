/*
 * memcmp.c
 *
 * Implementation of the memory comparison (memcmp) function in C.
 * This implementation does not use the standard library stdlib.h.
 * The function follows the same declaration as the memcmp function from the standard library.
 *
 * Function prototype:
 * int memcmp(const void *s1, const void *s2, size_t n);
 *
 */

#include "memcmp.h"
#include <stdio.h>

// Implementation of the memcmp function
int memcmp(const void *s1, const void *s2, size_t n) {
    const unsigned char *p1 = (const unsigned char *)s1;
    const unsigned char *p2 = (const unsigned char *)s2;

    for (size_t i = 0; i < n; i++) {
        if (p1[i] != p2[i]) {
            return p1[i] - p2[i];
        }
    }
    return 0;
}

