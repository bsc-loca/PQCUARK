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
// File: keccak_round_constants_gen_simplified.sv
// File history:
//      0.0     : 07/03/2025 : Creation
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: This module produces a simplified version of the RC generator by
// only storing the position of "1s" in the RC 64 bits in order to reduce the 
// number of XOR operations during the keccak_round.
// 
// Author: Alicia Manuel
//
////////////////////////////////////////////////////////////////////////////////

`ifdef VERILATOR
    `include "keccak_globals.sv"
`endif


module keccak_round_constants_gen_simplified
	import keccak_globals::*;
(
    input   unsigned[4:0]   round_number,
    output  logic[6:0]     round_constant_signal_out
);

logic[6:0] round_constant_signal;

always @(round_number) begin
    case (round_number)
        5'b00000 : round_constant_signal = 7'b0000001; 
		5'b00001 : round_constant_signal = 7'b0011010; 
		5'b00010 : round_constant_signal = 7'b1011110; 
		5'b00011 : round_constant_signal = 7'b1110000; 
		5'b00100 : round_constant_signal = 7'b0011111; 
		5'b00101 : round_constant_signal = 7'b0100001; 
		5'b00110 : round_constant_signal = 7'b1111001; 
		5'b00111 : round_constant_signal = 7'b1010101; 
		5'b01000 : round_constant_signal = 7'b0001110; 
		5'b01001 : round_constant_signal = 7'b0001100; 
		5'b01010 : round_constant_signal = 7'b0110101; 
		5'b01011 : round_constant_signal = 7'b0100110; 
		5'b01100 : round_constant_signal = 7'b0111111; 
		5'b01101 : round_constant_signal = 7'b1001111; 
		5'b01110 : round_constant_signal = 7'b1011101; 
		5'b01111 : round_constant_signal = 7'b1010011; 
		5'b10000 : round_constant_signal = 7'b1010010; 
		5'b10001 : round_constant_signal = 7'b1001000; 
		5'b10010 : round_constant_signal = 7'b0010110; 
		5'b10011 : round_constant_signal = 7'b1100110; 
		5'b10100 : round_constant_signal = 7'b1111001; 
		5'b10101 : round_constant_signal = 7'b1011000; 
		5'b10110 : round_constant_signal = 7'b0100001; 
		5'b10111 : round_constant_signal = 7'b1110100; 
		default  : round_constant_signal = '0;
    endcase
end

always_comb begin : blockReady
	round_constant_signal_out = round_constant_signal;
end

endmodule
