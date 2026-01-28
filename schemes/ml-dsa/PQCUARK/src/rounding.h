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

#ifndef ROUNDING_H
#define ROUNDING_H

#include <stdint.h>

#include "params.h"

int32_t power2round(int32_t *a0, int32_t a);
int32_t decompose(int32_t *a0, int32_t a);
unsigned int make_hint(int32_t a0, int32_t a1);
int32_t use_hint(int32_t a, unsigned int hint);

#endif
