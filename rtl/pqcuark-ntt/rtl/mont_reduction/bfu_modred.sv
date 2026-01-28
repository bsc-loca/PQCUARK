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

/*
 -----------------------------------------------
 Project Name   : PQCUARK 
 File           : bfu_modred.sv
 Organization   : Barcelona Supercomputing Center
 Author(s)      : Xavier Carril
 Email(s)       : xavier.carril@bsc.es
 -----------------------------------------------
 Revision History
  Revision   | Author    | Description
 --------------------------------------------------------------------------------
  1.0        | X. Carril | Initial implementation of Modular Reduction Functional Unit (BFU)
 --------------------------------------------------------------------------------
 -- Functional Overview:
 This module implements a Modular Reduction Functional Unit that applies 
 modular reduction using Montgomery reduction for both Kyber and Dilithium 
 post-quantum cryptographic schemes. It processes two 32-bit operands in 
 parallel for Kyber and a full 64-bit operand for Dilithium.

 -- Key Features:
 - Supports modular reduction using Montgomery reduction.
 - Selectable mode for Kyber (16+16 bits) and Dilithium (32+32 bits).
 - Parallel computation for Kyber with independent Montgomery reductions.
 - Fully pipelined architecture with clocked input registers.
 - Valid output signal synchronized with computation.
 --------------------------------------------------------------------------------
*/

module bfu_modred (
    input  logic        clk_i,
    input  logic        rstn_i,
    input  logic        flush_i,        // Flush signal to clear the pipeline 
    input  logic        validSrc_i,     // Valid Operands
    input  logic        selKD_i,        // Select Kyber(1) or Dilithium(0)
    input  logic [63:0] src_i,          // Source (32+32 bits)
    output logic        validResult_o,  // Valid result
    output logic [31:0] result_o        // Result (16+16 bits)
);

logic valid, selKD;
logic [31:0] srcA;
logic [31:0] srcB;
logic [31:0] result_kyber;
logic [31:0] result_dilithium;

always_ff @(posedge clk_i, negedge rstn_i) begin
  if (!rstn_i) begin
    valid <= 1'b0;
    selKD <= 1'b0;
    srcB <= '0;
    srcA <= '0;
  end else begin
    valid <= validSrc_i;
    selKD <= selKD_i;
    srcB <= src_i[63:32];
    srcA <= src_i[31:0];
  end
end

montgomery_kyber montgomery_kyber_B (
  .src_i(srcB),
  .result_o(result_kyber[31:16])
);

montgomery_kyber montgomery_kyber_A (
  .src_i(srcA),
  .result_o(result_kyber[15:0])
);

montgomery_dilithium montgomery_dilithium (
  .src_i({srcB,srcA}),
  .result_o(result_dilithium)
);

assign result_o = (selKD) ? result_kyber : result_dilithium;
assign validResult_o = valid & (~flush_i);


endmodule
