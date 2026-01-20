/*
 -----------------------------------------------
 Project Name   : PQCUARK 
 File           : add_sub_32bit.sv
 Organization   : Barcelona Supercomputing Center
 Author(s)      : Xavier Carril
 Email(s)       : xavier.carril@bsc.es
 -----------------------------------------------
 Revision History
  Revision   | Author    | Description
 --------------------------------------------------------------------------------
  1.0        | X. Carril | Initial implementation of 32-bit addition and subtraction
 --------------------------------------------------------------------------------
 -- Functional Overview:
 This module provides both addition and subtraction operations for 32-bit inputs.
 It supports modular arithmetic operations for Kyber and Dilithium cryptographic 
 schemes. The Kyber mode processes two 16-bit values separately, while the 
 Dilithium mode operates on full 32-bit values.

 -- Key Features:
 - Supports both addition and subtraction.
 - Selectable mode for Kyber (16+16 bits) and Dilithium (32 bits).
 - Handles carry propagation in both operations.
 - Fully combinational design for low-latency execution.
 --------------------------------------------------------------------------------
*/

module adder_32bit (
    input  logic        selKD_i,        // Select Kyber(1) or Dilithium(0) operation
    input  logic [31:0] srcA_i,         // Source (16+16 bits for Kyber, 32 bits for Dilithium)
    input  logic [31:0] srcB_i,         // Source (16+16 bits for Kyber, 32 bits for Dilithium)
    output logic [31:0] result_o        // Result (16+16 bits for Kyber, 32 bits for Dilithium)
);

  logic [15:0] C1;
  logic [16:0] C2;
  logic carry, cin;

  assign {carry, C1} = srcA_i[15:0] + srcB_i[15:0]; 
  assign cin = (selKD_i) ? 1'b0 : carry;
  assign C2 = srcA_i[31:16] + srcB_i[31:16] + {15'b0, cin}; 

  assign result_o = {C2[15:0], C1[15:0]};

endmodule

module substraction_32bit (
    input  logic        selKD_i,        // Select Kyber(1) or Dilithium(0) operation
    input  logic [31:0] srcA_i,         // Source (16+16 bits for Kyber, 32 bits for Dilithium)
    input  logic [31:0] srcB_i,         // Source (16+16 bits for Kyber, 32 bits for Dilithium)
    output logic [31:0] result_o        // Result (16+16 bits for Kyber, 32 bits for Dilithium)
);
  logic [16:0] C1;
  logic [16:0] C2;
  logic carry, cin;

  assign C1 = {1'b1, srcA_i[15:0]} - {1'b0, srcB_i[15:0]}; 
  assign carry = C1[16];
  assign cin = (selKD_i) ? 1'b0 : !carry;
  assign C2 = srcA_i[31:16] - srcB_i[31:16] - {15'b0, cin}; 

  assign result_o = {C2[15:0], C1[15:0]};

endmodule
