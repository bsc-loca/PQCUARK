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
 File           : barret_reduce.sv
 Organization   : Barcelona Supercomputing Center
 Author(s)      : Xavier Carril
 Email(s)       : xavier.carril@bsc.es
 -----------------------------------------------
 Revision History
  Revision   | Author    | Description
 --------------------------------------------------------------------------------
  1.0        | X. Carril | Initial implementation of Barrett reduction
 --------------------------------------------------------------------------------
 -- Functional Overview:
 The module implements the Barrett reduction algorithm to efficiently reduce
 16-bit integers modulo KYBER_Q. It approximates the division using bit-shifts
 and precomputed constants to avoid expensive division operations.

 -- Key Features:
 - Computes Barrett reduction with minimal resource usage.
 - Uses only shifts and additions to approximate division.
 - Supports 16-bit input and output.
 - Fully combinational implementation.
 --------------------------------------------------------------------------------
*/
module barrett_reduce
(
  input logic  [15:0] src_i,     // 16-bit input value
  output logic [15:0] result_o    // 16-bit reduced and centered result
);

  // Registers for intermediate calculations
  logic [31:0] v_mul_a; // Product of v * a
  logic [31:0] sum;
  logic [31:0] shift;
  logic [15:0] t;       // Approximation of the quotient
  logic signed [15:0] mult_q; // Multiple of Q (intermediate result)
  logic signed [15:0] diff; // Intermediate result before centering

  always_comb begin
    // Calculate v * a
      v_mul_a = ({{2{src_i[15]}}, src_i, 14'b0}) + 
                ({{5{src_i[15]}}, src_i, 11'b0}) +
                ({{6{src_i[15]}}, src_i, 10'b0}) +
                ({{7{src_i[15]}}, src_i, 9'b0}) +
                ({{9{src_i[15]}}, src_i, 7'b0}) +
                ({{11{src_i[15]}}, src_i,5'b0}) +
                ({{12{src_i[15]}}, src_i,4'b0}) +
                ({{13{src_i[15]}}, src_i,3'b0}) +
                ({{14{src_i[15]}}, src_i,2'b0}) +
                ({{15{src_i[15]}}, src_i,1'b0}) +
                ({{16{src_i[15]}}, src_i});

      // Compute t = floor((v * a + 2^25) / 2^26)
      sum = (v_mul_a + (1 << 25));
      shift = {{26{sum[31]}}, sum[31:26]};
      t = shift[15:0];

      // Compute mult_q = t * Q
      mult_q = (t <<< 11) + (t <<< 10) + (t <<< 8) + t; //(int32_t)t*KYBER_Q

      // Compute the result
      diff = src_i - mult_q;
  end

  assign result_o = diff;

endmodule

