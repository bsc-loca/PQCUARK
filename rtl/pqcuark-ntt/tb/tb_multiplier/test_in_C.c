#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

int main() {
	int32_t a_val = 0x41ca55;
	int32_t b_val = 0x22fa30;
	int sel_val = 0;

	int32_t d0, d1;
	int64_t m0, m1, m2;
	int64_t d;

	d0 = (sel_val) ? (b_val >> 12) : b_val;
	m0 = d0 * (a_val >> 12);
	m1 = (sel_val) ? (m0 << 24) : (m0 << 12);
	d1 = (sel_val) ? (b_val & 0x000FFF) : b_val;
	m2 = d1 * (a_val & 0x000FFF);
	d = m1 + m2;

	printf("d = %lx\n", d);
}