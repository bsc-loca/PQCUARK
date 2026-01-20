/*
 * qsort.c
 *
 * Implementation of the Quick Sort (qsort) algorithm in C.
 * This implementation does not use the standard library stdlib.h.
 * The function follows the same declaration as the qsort function from the standard library.
 *
 * Function prototype:
 * void qsort(void *base, size_t nitems, size_t size, int (*compar)(const void *, const void *));
 */

#include "qsort.h"
#include <stdio.h>

// Helper function to swap two elements
void swap(void *a, void *b, size_t size) {
    char temp[size];
    for (size_t i = 0; i < size; i++) {
        temp[i] = ((char *)a)[i];
        ((char *)a)[i] = ((char *)b)[i];
        ((char *)b)[i] = temp[i];
    }
}

// Helper function to partition the array
size_t partition(void *base, size_t low, size_t high, size_t size, int (*compar)(const void *, const void *)) {
    char *pivot = (char *)base + high * size;
    size_t i = low;
    for (size_t j = low; j < high; j++) {
        if (compar((char *)base + j * size, pivot) < 0) {
            swap((char *)base + i * size, (char *)base + j * size, size);
            i++;
        }
    }
    swap((char *)base + i * size, (char *)base + high * size, size);
    return i;
}

// Recursive quicksort helper function
void quicksort(void *base, size_t low, size_t high, size_t size, int (*compar)(const void *, const void *)) {
    if (low < high) {
        size_t pi = partition(base, low, high, size, compar);
        if (pi > 0) {
            quicksort(base, low, pi - 1, size, compar);
        }
        quicksort(base, pi + 1, high, size, compar);
    }
}

// Implementation of the qsort function
void qsort(void *base, size_t nitems, size_t size, int (*compar)(const void *, const void *)) {
    if (nitems > 0) {
        quicksort(base, 0, nitems - 1, size, compar);
    }
}

// Comparison function for integers
int compar_int(const void *a, const void *b) {
    return (*(int *)a - *(int *)b);
}
