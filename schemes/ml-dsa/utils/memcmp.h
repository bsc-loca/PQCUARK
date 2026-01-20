/*
 * memcmp.h
 *
 * Header for the memory comparison (memcmp) function implementation in C.
 * This implementation does not use the standard library stdlib.h.
 * The function follows the same declaration as the memcmp function from the standard library.
 *
 */

#ifndef MEMCMP_H
#define MEMCMP_H

#include <stddef.h>

// Prototype of the memcmp function
int memcmp(const void *s1, const void *s2, size_t n);

#endif // MEMCMP_H
