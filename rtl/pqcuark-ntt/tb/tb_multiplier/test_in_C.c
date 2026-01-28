// Copyright 2026 Barcelona Supercomputing Center (BSC)
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License");
// you may not use this file except in compliance with the License, or,
// at your option, the Apache License version 2.0.
// You may obtain a copy of the License at
//
//     https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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