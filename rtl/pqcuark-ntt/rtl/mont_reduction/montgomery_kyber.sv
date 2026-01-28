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
 File           : montgomery_kyber.sv
 Organization   : Barcelona Supercomputing Center
 Author(s)      : Xavier Carril
 Email(s)       : xavier.carril@bsc.es
 -----------------------------------------------
 Revision History
  Revision   | Author    | Description
 --------------------------------------------------------------------------------
  1.0        | X. Carril | Initial implementation of Montgomery reduction for Kyber
 --------------------------------------------------------------------------------
 -- Functional Overview:
 This module implements the Montgomery reduction algorithm for the Kyber 
 cryptographic scheme. It efficiently reduces a 32-bit integer modulo KYBER_Q 
 using precomputed constants and shift-based arithmetic, eliminating the need 
 for costly division operations. The reduction ensures that the result remains 
 in the expected modular range.

 -- Key Features:
 - Parameterized input/output sizes for flexibility.
 - Performs modular reduction using Montgomery multiplication.
 - Uses only shifts and additions for efficient computation.
 - Fully combinational implementation for low-latency execution.
 - Supports Kyber cryptographic scheme.
 --------------------------------------------------------------------------------
*/

module montgomery_kyber #(
  parameter INPUT_SIZE = 32,
  parameter OUTPUT_SIZE = INPUT_SIZE/2
)(
    input  logic [INPUT_SIZE-1:0] src_i,          // Source (32 bits)
    output logic [OUTPUT_SIZE-1:0] result_o       // Result (16bits)
);

localparam HALF = 16;

logic signed [INPUT_SIZE-1:0] src_ext;
assign src_ext = {{(INPUT_SIZE-HALF){src_i[HALF-1]}}, $signed(src_i[HALF-1:0])};

logic signed [INPUT_SIZE-1:0] mult_qinv; 
assign mult_qinv = src_ext - (src_ext <<< 11) - (src_ext <<< 10) - (src_ext <<< 8); //(int16_t)a*QINV;

logic signed [INPUT_SIZE-1:0] t_ext;
assign t_ext = {{(INPUT_SIZE-HALF){mult_qinv[HALF-1]}}, $signed(mult_qinv[HALF-1:0])};

logic signed [INPUT_SIZE-1:0] mult_q;
assign mult_q = (t_ext <<< 11) + (t_ext <<< 10) + (t_ext <<< 8) + t_ext; //(int32_t)t*KYBER_Q

logic signed [INPUT_SIZE-1:0] diff;
assign diff = (src_i - mult_q);

assign result_o = diff[HALF+:OUTPUT_SIZE];

endmodule
