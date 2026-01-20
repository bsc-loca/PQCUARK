
/*
 -----------------------------------------------
 Project Name   : PQCUARK 
 File           : bfu_multiplier.sv
 Organization   : Barcelona Supercomputing Center
 Author(s)      : Xavier Carril
 Email(s)       : xavier.carril@bsc.es
 -----------------------------------------------
 Revision History
  Revision   | Author    | Description
 --------------------------------------------------------------------------------
 -- Functional Overview:
 -- This module implements a pipelined integer multiplier for 12-bit and 23-bit operands.
 -- The design uses Booth Radix-4 encoding for efficient partial product generation.
 -- This multiplier is made for Kyber(12-bit)/Dilithium(23-bit) Butterfly Unit.
 --------------------------------------------------------------------------------
 -- Key Features:
 -- 1. Booth Radix-4 encoding to minimize partial products.
 -- 2. Multiplies a[31:0] * b[31:0] or {a[31:16] * b[31:16], a[15:0] * b[15:0]}
 -- 3. Fully pipelined design for high performance.
 --------------------------------------------------------------------------------
*/

module bfu_multiplier (
    input  logic        clk_i,
    input  logic        rstn_i,
    input  logic        flush_i,        // Flush signal to clear the pipeline
    input  logic        selKD_i,        // Select Kyber(1) or Dilithium(0) operation
    input  logic        validSrc_i,     // Valid Operands
    input  logic [31:0] srcA_i,         // Operand A (32 bits)
    input  logic [31:0] srcB_i,         // Operand B (32 bits)
    output logic        validResult_o,  // Valid result
    output logic [63:0] result_o        // Result (32+32 bits for Kyber, 64 bits for Dilithium)
);

  logic [31:0] d0, d1;
  logic validResult_m0, validResult_m2;
  logic selKD_d0;
  logic [47:0] m0, m2;
  logic [63:0] m1;
  logic [63:0] result;

  // Sign extension
  assign d0 = (selKD_i) ? {{16{srcB_i[31]}}, srcB_i[31:16]} : srcB_i[31:0]; 
  assign d1 = (selKD_i) ? {{16{srcB_i[15]}}, srcB_i[15:0]} : srcB_i[31:0];

  always_ff @(posedge clk_i, negedge rstn_i) begin
    if (!rstn_i) begin
        selKD_d0 <= 1'b0;
    end else begin
        selKD_d0 <= selKD_i;
    end
  end

  multiplier mul_m0_inst (
      .clk_i        (clk_i),
      .rstn_i       (rstn_i),
      .validSrc_i   (validSrc_i),
      .sign_i       (1'b1),
      .srcA_i       (srcA_i[31:16]),
      .srcB_i       (d0),
      .validResult_o(validResult_m0),
      .result_o     (m0)
  );

  assign m1 = (selKD_d0) ? ({m0[31:0], 32'b0}) : ({m0, 16'b0});

  multiplier mul_m2_inst (
      .clk_i        (clk_i),
      .rstn_i       (rstn_i),
      .sign_i       (selKD_i),
      .validSrc_i   (validSrc_i),
      .srcA_i       (srcA_i[15:0]),
      .srcB_i       (d1),
      .validResult_o(validResult_m2),
      .result_o     (m2)
  );

  logic [63:0] m2_ext;
  assign m2_ext = {{16{m2[47]}},m2}; 
  assign result   = (selKD_d0) ? (m1 + {32'b0, m2[31:0]}) : (m1 + m2_ext);
  assign validResult_o = validResult_m0 & validResult_m2 & (~flush_i);
  assign result_o = result[63:0];

endmodule
