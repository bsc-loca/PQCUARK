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
--------------------------------------------------------------------------------
Project Name   : PQCUARK
File           : mul_12x23bit.sv
Organization   : Barcelona Supercomputing Center
Author(s)      : Xavier Carril
Email(s)       : xavier.carril@bsc.es
--------------------------------------------------------------------------------
Functional Overview:
 - This module implements a pipelined 12×23 multiplier.
 - B (23 bits) is always treated as a signed operand (two's complement).
 - A (12 bits) can be either signed or unsigned, controlled by SIGNED_MODE.
 - A Booth Radix-4 scheme (with 3-bit overlapping) is used, and partial products
   are accumulated. The design includes at least two stages:
   1) Partial product generation (pipelined)
   2) Summation of partial products
--------------------------------------------------------------------------------
Key Features:
 - Booth Radix-4 encoding (signed logic) for partial product generation.
 - Optional sign extension of A when SIGNED_MODE=1 (otherwise zero extension).
 - Pipeline register between partial product generation and final summation.
 - Produces a 35-bit signed result (two's complement).
--------------------------------------------------------------------------------
*/

module multiplier #(
  parameter A_WIDTH = 16,
  parameter B_WIDTH = 32,
  parameter PROD_WIDTH = A_WIDTH + B_WIDTH 
)(
  input  logic                          clk_i,        // Clock
  input  logic                          rstn_i,       // Active-low reset
  input  logic                          validSrc_i,   // Valid inputs
  input  logic                          sign_i,       // Signed(1) or Unsigned(0) 
  input  logic [A_WIDTH-1:0]            srcA_i,       // A operand (signed/unsigned)
  input  logic signed [B_WIDTH-1:0]     srcB_i,       // B Operand (always signed)
  output logic                          validResult_o,// Valid result indicator
  output logic signed [PROD_WIDTH-1:0]  result_o      // Signed product
);

  //--------------------------------------------------------------------------
  // Local parameters
  //--------------------------------------------------------------------------

  // Number of partial products using Booth Radix-4 (3-bit overlap on B)
  localparam int NUM_GROUPS = (B_WIDTH + 1) / 2; // ~12 for 23-bit B

  //--------------------------------------------------------------------------
  // Stage 1: Partial product generation (Booth Radix-4)
  //--------------------------------------------------------------------------
  // We'll store the partial products in a combinational array, then register them.
  logic signed [PROD_WIDTH-1:0] pp_array   [0:NUM_GROUPS-1];
  logic signed [PROD_WIDTH-1:0] pp_stageFF [0:NUM_GROUPS-1];
  logic                         validPP_stage;  // Valid after PP generation

  //--------------------------------------------------------------------------
  // Stage 2: Summation of partial products (simplified iterative sum)
  //--------------------------------------------------------------------------
  logic signed [PROD_WIDTH-1:0] result_stageFF;

  //--------------------------------------------------------------------------
  // 1) Extend srcA_i according to sign 
  //--------------------------------------------------------------------------
  // If SIGNED_MODE=1, we sign-extend A. Otherwise, we zero-extend.
  // The result is a 35-bit signal A_ext, to be used in Booth partial products.
  logic signed [PROD_WIDTH-1:0] A_ext;

  always_comb begin
    if (sign_i) begin
      // Sign-extend A's top bit (bit 11)
      A_ext = {{(PROD_WIDTH - A_WIDTH){srcA_i[A_WIDTH-1]}}, srcA_i};
    end else begin
      // Zero-extend A
      A_ext = {{(PROD_WIDTH - A_WIDTH){1'b0}}, srcA_i};
    end
  end

  //--------------------------------------------------------------------------
  // 2) Generate Booth partial products using srcB_i (signed)
  //--------------------------------------------------------------------------
  // We use a 3-bit overlapping scheme on B: (b2,b1,b0).
  // The highest group's b2 is B's sign bit (bit 22).
  // Then each group produces ±A or ±2A, or 0, depending on the Booth bits.
  genvar i;
  generate
    for (i = 0; i < NUM_GROUPS; i++) begin : booth_gen
      logic b2, b1, b0;

      // For the top group (i == NUM_GROUPS-1), b2 is B's sign bit (bit 22).
      // Otherwise, b2 = B[2*i+1].
      assign b2 = (i == (NUM_GROUPS-1))
                   ? srcB_i[B_WIDTH-1] // sign bit of B
                   : srcB_i[2*i+1];

      assign b1 = srcB_i[2*i];
      assign b0 = (i == 0) ? 1'b0 : srcB_i[2*i - 1];

      // Form the 3-bit Booth code
      logic [2:0] booth_bits;
      assign booth_bits = {b2, b1, b0};

      // Decide the partial product: 0, ±A_ext, ±2A_ext
      logic signed [PROD_WIDTH-1:0] partial_pp;
      always_comb begin
        unique case (booth_bits)
          3'b000, 3'b111: partial_pp = '0;            //  0
          3'b001, 3'b010: partial_pp = A_ext;         // +A
          3'b011:         partial_pp = A_ext <<< 1;   // +2A
          3'b100:         partial_pp = -(A_ext <<< 1);// -2A
          3'b101, 3'b110: partial_pp = -A_ext;        // -A
          default:        partial_pp = '0;
        endcase
      end

      // Shift the partial product according to the position of the bits (2*i)
      assign pp_array[i] = partial_pp <<< (2*i);
    end
  endgenerate

  //--------------------------------------------------------------------------
  // Pipeline stage for partial products
  //--------------------------------------------------------------------------
  // We register the partial products and mark them valid if validSrc_i=1.
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      integer j;
      for (j = 0; j < NUM_GROUPS; j++) begin
        pp_stageFF[j] <= '0;
      end
      validPP_stage <= 1'b0;
    end else begin
      if (validSrc_i) begin
        integer k;
        for (k = 0; k < NUM_GROUPS; k++) begin
          pp_stageFF[k] <= pp_array[k];
        end
        validPP_stage <= 1'b1;
      end else begin
        validPP_stage <= 1'b0;
      end
    end
  end

  //--------------------------------------------------------------------------
  // 3) Summation of partial products (simplified)
  //--------------------------------------------------------------------------
  // In a real design, you'd use a Wallace/Dadda tree with 3:2 or 4:2 compressors
  // and possibly more pipeline stages for higher performance. Here we do a
  // simple iterative sum for clarity.
  logic [PROD_WIDTH:0] acc_sum;
  always_comb begin
    // We'll accumulate in a 36-bit register for sign/carry
    acc_sum = '0; // 36 bits

    for (int m = 0; m < NUM_GROUPS; m++) begin
      // Signed addition, because partial products can be negative
      acc_sum = $signed(acc_sum) + $signed({1'b0, pp_stageFF[m]});
    end

    // The final 35-bit result is in acc_sum[34:0]
    result_stageFF = acc_sum[PROD_WIDTH-1:0];
  end


  //--------------------------------------------------------------------------
  // Outputs
  //--------------------------------------------------------------------------
  assign result_o      = result_stageFF;    // 35-bit signed product
  assign validResult_o = validPP_stage; // Goes high once product is ready

endmodule
