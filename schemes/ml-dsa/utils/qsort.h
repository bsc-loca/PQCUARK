/*
 * qsort.h
 *
 * Header for the Quick Sort (qsort) algorithm implementation in C.
 * This implementation does not use the standard library stdlib.h.
 * The function follows the same declaration as the qsort function from the standard library.
 */

#ifndef QSORT_H
#define QSORT_H

#include <stddef.h>

// Prototype of the qsort function
void qsort(void *base, size_t nitems, size_t size, int (*compar)(const void *, const void *));

#endif // QSORT_H
