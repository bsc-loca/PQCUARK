#ifndef PRINT_METRIC_H
#define PRINT_METRIC_H

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include "qsort.h"
#include "cpu_perf.h"

void print_one(const checkpoint_t *cp);
void print_all_average(const checkpoint_t *cp, size_t len);
void print_all_median(const checkpoint_t *cp, size_t len);
void print_average(const checkpoint_t *cp, size_t len);
void print_median(const checkpoint_t *cp, size_t len);

#endif
