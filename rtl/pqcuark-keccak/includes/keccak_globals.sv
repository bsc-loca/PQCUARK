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