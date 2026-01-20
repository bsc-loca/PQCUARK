/*
 -----------------------------------------------
 Project Name   : PQCUARK 
 File           : bfu_barrett.sv
 Organization   : Barcelona Supercomputing Center
 Author(s)      : Xavier Carril
 Email(s)       : xavier.carril@bsc.es
 -----------------------------------------------
 Revision History
  Revision   | Author    | Description
 --------------------------------------------------------------------------------
  1.0        | X. Carril | Initial implementation of Barrett reduction unit 
 --------------------------------------------------------------------------------
 -- Functional Overview:
 This module implements a Barrett Reduction Functional Unit for modular 
 reduction of 16-bit values within a 32-bit input. It processes two 16-bit 
 operands in parallel, applying the Barrett reduction algorithm to each operand.

 -- Key Features:
 - Fully pipelined design with clocked registers for input storage.
 - Parallel computation of Barrett reduction on two 16-bit values.
 - Generates valid output signal synchronized with computation.
 - Supports modular reduction for post-quantum cryptographic schemes like Kyber.
 --------------------------------------------------------------------------------
*/

module bfu_barrett (
    input  logic        clk_i,
    input  logic        rstn_i,
    input  logic        flush_i,        // Flush signal to clear the pipeline
    input  logic        validSrc_i,     // Valid Operands
    input  logic [31:0] src_i,          // Source (16+16 bits)
    output logic        validResult_o,  // Valid result
    output logic [31:0] result_o        // Result (16+16 bits)
);

logic valid;
logic [15:0] srcA;
logic [15:0] srcB;
logic [31:0] result;

always_ff @(posedge clk_i, negedge rstn_i) begin
  if (!rstn_i) begin
    valid <= 1'b0;
    srcB <= '0;
    srcA <= '0;
  end else begin
    valid <= validSrc_i;
    srcB <= src_i[31:16];
    srcA <= src_i[15:0];
  end
end

barrett_reduce barrett_B (
  .src_i(srcB),
  .result_o(result[31:16])
);

barrett_reduce barrett_A (
  .src_i(srcA),
  .result_o(result[15:0])
);

assign result_o = result;
assign validResult_o = valid & (~flush_i);


endmodule
