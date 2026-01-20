////////////////////////////////////////////////////////////////////////////////
// Company: BSC
//
// File: keccak_round_constants_gen.sv
// File history:
//      0.0     : 20/02/2025 : Creation
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: This module produces the round constants in Keccak
// 
// Author: Alicia Manuel
//
////////////////////////////////////////////////////////////////////////////////

`ifdef VERILATOR
    `include "keccak_globals.sv"
`endif


module keccak_round_constants_gen
	import keccak_globals::*;
(
    input   unsigned[4:0]   round_number,
    output  logic[63:0]     round_constant_signal_out
);

logic[63:0] round_constant_signal;

always @(round_number) begin
    case (round_number)
        5'b00000 : round_constant_signal = 64'h0000000000000001;
	    5'b00001 : round_constant_signal = 64'h0000000000008082;
	    5'b00010 : round_constant_signal = 64'h800000000000808A;
	    5'b00011 : round_constant_signal = 64'h8000000080008000;
	    5'b00100 : round_constant_signal = 64'h000000000000808B;
	    5'b00101 : round_constant_signal = 64'h0000000080000001;
	    5'b00110 : round_constant_signal = 64'h8000000080008081;
	    5'b00111 : round_constant_signal = 64'h8000000000008009;
	    5'b01000 : round_constant_signal = 64'h000000000000008A;
	    5'b01001 : round_constant_signal = 64'h0000000000000088;
	    5'b01010 : round_constant_signal = 64'h0000000080008009;
	    5'b01011 : round_constant_signal = 64'h000000008000000A;
	    5'b01100 : round_constant_signal = 64'h000000008000808B;
	    5'b01101 : round_constant_signal = 64'h800000000000008B;
	    5'b01110 : round_constant_signal = 64'h8000000000008089;
	    5'b01111 : round_constant_signal = 64'h8000000000008003;
	    5'b10000 : round_constant_signal = 64'h8000000000008002;
	    5'b10001 : round_constant_signal = 64'h8000000000000080;
	    5'b10010 : round_constant_signal = 64'h000000000000800A;
	    5'b10011 : round_constant_signal = 64'h800000008000000A;
	    5'b10100 : round_constant_signal = 64'h8000000080008081;
	    5'b10101 : round_constant_signal = 64'h8000000000008080;
	    5'b10110 : round_constant_signal = 64'h0000000080000001;
	    5'b10111 : round_constant_signal = 64'h8000000080008008;	    	    
	    default  : round_constant_signal = '0;
    endcase
end

always_comb begin : blockReady
	round_constant_signal_out = round_constant_signal;
end

endmodule
