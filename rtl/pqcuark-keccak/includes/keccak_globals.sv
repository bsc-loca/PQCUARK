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

////////////////////////////////////////////////////////////////////////////////
// Company: BSC
//
// File: keccak_globals.sv
// File history:
//      0.0     : 20/02/2025 : Creation
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: Package with all the constants and types used in Keccak
// 
// Targeted device: <Family::PolarFire> <Die::MPFS250T_ES> <Package::FCVG484>
// Author: Alicia Manuel
//
////////////////////////////////////////////////////////////////////////////////

`ifndef KECCAK_GLOBALS_SV
`define KECCAK_GLOBALS_SV

package keccak_globals;

    parameter int num_plane = 5;
    parameter int num_sheet = 5;
    parameter int N = 64;

    typedef logic [(N-1):0] k_lane;             // 64-bit element
    typedef k_lane [(num_sheet-1):0] k_plane;   // 5 × 64-bit (320 bits)
    typedef k_plane [(num_plane-1):0] k_state;  // 5 × 5 × 64-bit (1600 bits)


endpackage

`endif // KECCAK_GLOBALS_SV