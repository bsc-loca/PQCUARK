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
 File           : montgomery_dilithium.sv
 Organization   : Barcelona Supercomputing Center
 Author(s)      : Xavier Carril
 Email(s)       : xavier.carril@bsc.es
 -----------------------------------------------
 Revision History
  Revision   | Author    | Description
 --------------------------------------------------------------------------------
  1.0        | X. Carril | Initial implementation of Montgomery reduction for Dilithium
 --------------------------------------------------------------------------------
 -- Functional Overview:
 This module implements the Montgomery reduction algorithm for the Dilithium 
 cryptographic scheme. It efficiently reduces a 64-bit integer modulo Q using 
 precomputed constants and shift-based arithmetic, avoiding costly division 
 operations. The reduction ensures that the result remains in the expected 
 modular range.

 -- Key Features:
 - Parameterized input/output sizes for flexibility.
 - Performs modular reduction using Montgomery multiplication.
 - Uses only shifts and additions for efficient computation.
 - Fully combinational implementation for low-latency execution.
 - Supports Dilithium cryptographic scheme.
 --------------------------------------------------------------------------------
*/

module montgomery_dilithium #(
  parameter INPUT_SIZE = 64,
  parameter OUTPUT_SIZE = INPUT_SIZE/2
)(
    input  logic [INPUT_SIZE-1:0] src_i,          // Source (32 bits)
    output logic [OUTPUT_SIZE-1:0] result_o       // Result (16bits)
);

localparam HALF = 32;

logic signed [INPUT_SIZE-1:0] src_ext;
assign src_ext = {{(INPUT_SIZE-HALF){src_i[HALF-1]}}, $signed(src_i[HALF-1:0])};

logic signed [INPUT_SIZE-1:0] mult_qinv; 
assign mult_qinv =  (src_ext << 25)
                  + (src_ext << 24)
                  + (src_ext << 23)
                  + (src_ext << 13)
                  + src_ext; //(int32_t)a*QINV

logic signed [INPUT_SIZE-1:0] t_ext;
assign t_ext = {{(INPUT_SIZE-HALF){mult_qinv[HALF-1]}}, $signed(mult_qinv[HALF-1:0])};

logic signed [INPUT_SIZE-1:0] mult_q;
assign mult_q =  (t_ext << 22) 
               + (t_ext << 21) 
               + (t_ext << 20)
               + (t_ext << 19)
               + (t_ext << 18)
               + (t_ext << 17)
               + (t_ext << 16)
               + (t_ext << 15)
               + (t_ext << 14)
               + (t_ext << 13)
               + (t_ext); //(int64_t)t * Q 

logic signed [INPUT_SIZE-1:0] diff;
assign diff = (src_i - mult_q);

assign result_o = diff[HALF+:OUTPUT_SIZE];

endmodule
