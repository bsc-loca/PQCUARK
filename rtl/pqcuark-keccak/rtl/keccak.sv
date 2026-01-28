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
// Version: 0.1
//
// File: keccak.sv
// File history:
//      0.0     : 25/02/2025 : Creation
//      0.1     : 11/03/2025 : Modifications for linting + RC simplified
//      1.0     : 19/03/2025 : Implementation to absorb and load_finish at the same
//                             time.
//      2.0     : 24/03/2025 : Added the possibility to calculate more than one round
//                             in the same clock cycle.
//
// Description: This module produces the Keccak-p[1600,24]  with the absorbtion and 
// squeezing phases integrated in order to achive higher throughput.
// 
// Author: Alicia Manuel
//
////////////////////////////////////////////////////////////////////////////////

 
//import keccak_globals::*;

module keccak
	import keccak_globals::*;
    #(parameter BUFFER_WIDTH = 64,
      parameter RATE_WIDTH = 1344,
      parameter RC_WIDTH = 7,
      parameter LEN_WIDTH = 64,
      parameter ROUNDS = 2)
(
    input   logic                       clk_i,
    input   logic                       rst_ni,
    input   logic                       start,
    input   logic[(BUFFER_WIDTH-1):0]   din,            // Input buffer data
    input   logic                       din_valid,      // Asserts when input data is on 
                                                        // the I/O buffer
    input   logic[1:0]                  ld_st,           // Indicates:
                                                        // 0: Load, 1: Store, else 
    input   logic                       perm,          // 0: Absorb, 1: Squeeze
    input   logic[1:0]                  function_sel,   // Indicates the function to be computed
                                                        // 0: Shake128 (Keccak[256])
                                                        // 1: Shake256 (Keccak[512])
                                                        // 2: SHA3-256 (Keccak[512])
                                                        // 3: SHA3-512 (Keccak[1024])
    input   logic[(LEN_WIDTH-1):0]      inlen,          // Indicates the size of the input message       
    //input   logic[(LEN_WIDTH-1):0]      outlen,         // Indicates the size of the output message
    output  logic                       buffer_ready,    // Indicates that the buffer has 
                                                        // received
                                                        // the maximum number of words (15)
    output  logic                       permutation_ready, // Indicates that the permutation has been
                                                            // computed
    output  logic[(BUFFER_WIDTH-1):0]   dout,           // Output buffer data
    output  logic                       dout_valid      // Asserts when output data is out
);

/********************************************************************
 * Internal signals
********************************************************************/
k_state                   reg_data, round_in, reg_data_ff;
k_state [ROUNDS-1:0]      round_out ;
longint                   rate_size;
logic[(RATE_WIDTH-1):0]   reg_data_vector;
logic[4:0]                counter_nr_rounds, counter_nr_rounds_comb, stop_value;
logic                     din_buffer_ready, permutation_computed_ab, permutation_computed_sq, absorb_finish, dout_valid_neg, dout_valid_reg;
logic[ROUNDS-1:0][(RC_WIDTH-1):0]     round_constant_signal;
logic[(RATE_WIDTH-1):0]   din_buffer_out;
logic[(LEN_WIDTH-1):0]  rate, rate_comb;
logic[(LEN_WIDTH-1):0]    inlen_reg, outlen_reg;
logic                    working;

/********************************************************************
 * Components
********************************************************************/


 genvar i;
    generate
        for (i = 0; i < ROUNDS; i++) begin : gen_block
            keccak_round_constants_gen_simplified keccak_round_constant_inst (
                .round_number((i == 0) ? counter_nr_rounds : counter_nr_rounds + i),
                .round_constant_signal_out(round_constant_signal[i])
            );

            keccak_round keccak_round_inst (
                .round_in((i==0) ? round_in : round_out[i-1]),
                .round_constant_signal(round_constant_signal[i]),
                .round_out(round_out[i])
            );
        end
    endgenerate

keccak_buffer keccak_buffer_inst (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .start(start),
    .din_buffer_in(din),
    .din_buffer_in_valid(din_valid),
    .mode(ld_st),
    .function_sel(function_sel),
    .inlen(inlen),
    .din_buffer_ready(din_buffer_ready),
    .din_buffer_out(din_buffer_out),
    .dout_buffer_in(reg_data_vector),
    .dout_buffer_out(dout),
    .dout_buffer_out_valid(dout_valid),
    .absorb_finish(absorb_finish),
    .permutation_ready(permutation_computed_ab & permutation_computed_sq)
);



/********************************************************************
 * RTL
********************************************************************/
// Register to about glitches
// always_ff @( posedge clk_i, negedge rst_ni) begin: blockRegInlen
//     if (!rst_ni) begin
//         inlen_reg <= '0;
//     end
//     else begin
//         if (start) begin
//             inlen_reg   <= inlen;
//         end
//     end
// end
// Map part of the state to a vector lane by lane.
always_comb begin : blockMapping
    reg_data_vector = '0;
    case(function_sel)
    2'b00: begin // c = 256 bits, r = 1344 bits
        for (int row=0; row<4; row++) begin 
            for (int col=0; col<5; col++) begin 
                for (int i=0; i<64; i++) begin 
                    reg_data_vector[(row*64*5)+(col*64)+i] = reg_data[row][col][i];
                end
            end
        end
        for (int i=0; i<64; i++) begin
            reg_data_vector[(4*64*5)+(0*64)+i] = reg_data[4][0][i];
        end 
    end
    2'b01: begin
        for (int row=0; row<3; row++) begin 
            for (int col=0; col<5; col++) begin 
                for (int i=0; i<64; i++) begin 
                    reg_data_vector[(row*64*5)+(col*64)+i] = reg_data[row][col][i];
                end
            end
        end
        for (int col=0; col<2; col++) begin 
            for (int i=0; i<64; i++) begin 
                reg_data_vector[(3*64*5)+(col*64)+i] = reg_data[3][col][i];
            end
        end
    end
    2'b10: begin
        for (int col=0; col<5; col++) begin
            for (int i=0; i<64; i++) begin
                reg_data_vector[(0*64*5)+(col*64)+i] = reg_data[0][col][i];
            end
        end
        for (int col=0; col<4; col++) begin
            for (int i=0; i<64; i++) begin
                reg_data_vector[(1*64*5)+(col*64)+i] = reg_data[1][col][i];
            end
        end
    end
    2'b11: begin
        for (int col=0; col<5; col++) begin
            for (int i=0; i<64; i++) begin
                reg_data_vector[(0*64*5)+(col*64)+i] = reg_data[0][col][i];
            end
        end
        for (int col=0; col<4; col++) begin
            for (int i=0; i<64; i++) begin
                reg_data_vector[(1*64*5)+(col*64)+i] = reg_data[1][col][i];
            end
        end
    end
    default: reg_data_vector = '0;
    endcase
end

// Assign correct rate and capacity inputs with corresponding XORs 
// for absorbtion.
always_comb begin : blockCapRate
    if (rst_ni) begin
        round_in    = '0;
    end
    // Default assignments
    for (int row = 0; row < 5; row++) begin
        for (int col = 0; col < 5; col++) begin
            for (int i = 0; i < 64; i++) begin
                round_in[row][col][i] = reg_data[row][col][i];
            end
        end
    end
    case (function_sel)
    2'b00: begin 
        // c = 256 bits, r = 1344 bits
        // Rate part: The rate part is xored with the input data
        for (int row=0; row<4; row++) begin: i0010
            for (int col=0; col<5; col++) begin: i0011
                for (int i=0; i<64; i++) begin: i0012
                    round_in[row][col][i] = reg_data[row][col][i] ^ 
                        (din_buffer_out[(row*64*5)+(col*64)+i] & 
                        (din_buffer_ready & permutation_computed_ab) & !ld_st[0]);
                end
            end
        end
        for (int i=0; i<64; i++) begin: i0016
            round_in[4][0][i] = reg_data[4][0][i] ^ 
                    (din_buffer_out[((4*64*5)+(0*64)+i)] & 
                    (din_buffer_ready & permutation_computed_ab) & !ld_st[0]);
        end 
        // Capacity:
        for (int col=1; col<5; col++) begin: i0011
            for (int i=0; i<64; i++) begin: i0012
                round_in[4][col][i] = reg_data[4][col][i];
            end
        end
    end
    2'b01: begin
        // c = 512 bits, r = 1088 bits
        // Rate part: The rate part is xored with the input data
        for (int row=0; row<3; row++) begin: i0010
            for (int col=0; col<5; col++) begin: i0011
                for (int i=0; i<64; i++) begin: i0012
                    round_in[row][col][i] = reg_data[row][col][i] ^ 
                        (din_buffer_out[(row*64*5)+(col*64)+i] & 
                        (din_buffer_ready & permutation_computed_ab) & !ld_st[0]);
                end
            end
        end
        for (int col=0; col<2; col++) begin: i0013
            for (int i=0; i<64; i++) begin: i0014
                round_in[3][col][i] = reg_data[3][col][i] ^ 
                    (din_buffer_out[((3*64*5)+(col*64)+i)] & 
                    (din_buffer_ready && permutation_computed_ab) & !ld_st[0] );
            end
        end
        // Capacity part: corresponds to the 4th and 5th rows of the state
        for (int col=2; col<5; col++) begin: i0015
            for (int i=1; i<64; i++) begin: i0016
                round_in[3][col][i] = reg_data[3][col][i];
            end
        end
        for (int col=0; col<5; col++) begin: i0017
            for (int i=0; i<64; i++) begin: i0018
                round_in[4][col][i] = reg_data[4][col][i];
            end
        end
    end
    2'b10: begin
        // c = 512 bits, r = 1088 bits
        // Rate part: The rate part is xored with the input data
        for (int row=0; row<3; row++) begin: i0010
            for (int col=0; col<5; col++) begin: i0011
                for (int i=0; i<64; i++) begin: i0012
                    round_in[row][col][i] = reg_data[row][col][i] ^ 
                        (din_buffer_out[(row*64*5)+(col*64)+i] & 
                        (din_buffer_ready & permutation_computed_ab) & !ld_st[0]);
                end
            end
        end
        for (int col=0; col<2; col++) begin: i0013
            for (int i=0; i<64; i++) begin: i0014
                round_in[3][col][i] = reg_data[3][col][i] ^ 
                    (din_buffer_out[((3*64*5)+(col*64)+i)] & 
                    (din_buffer_ready && permutation_computed_ab) & !ld_st[0] );
            end
        end
        // Capacity part: corresponds to the 4th and 5th rows of the state
        for (int col=2; col<5; col++) begin: i0015
            for (int i=1; i<64; i++) begin: i0016
                round_in[3][col][i] = reg_data[3][col][i];
            end
        end
        for (int col=0; col<5; col++) begin: i0017
            for (int i=0; i<64; i++) begin: i0018
                round_in[4][col][i] = reg_data[4][col][i];
            end
        end
    end
    2'b11: begin // c = 1024 bits, r = 576 bits
        // Rate part: The rate part is xored with the input data
        for (int col=0; col<5; col++) begin: i0020
            for (int i=0; i<64; i++) begin: i0021
                round_in[0][col][i] = reg_data[0][col][i] ^ 
                    (din_buffer_out[((0*64*5)+(col*64)+i)] & 
                    (din_buffer_ready && permutation_computed_ab) & !ld_st[0]);
            end
        end
        for (int col=0; col<4; col++) begin: i0020
            for (int i=0; i<64; i++) begin: i0021
                round_in[1][col][i] = reg_data[1][col][i] ^ 
                    (din_buffer_out[((1*64*5)+(col*64)+i)] & 
                    (din_buffer_ready && permutation_computed_ab) & !ld_st[0]);
            end
        end
        // Capacity part: corresponds to the 4th and 5th rows of the state
        for (int i=0; i<64; i++) begin: i0022
            round_in[1][4][i] = reg_data[1][4][i];
        end
        for (int row=2; row<5; row++) begin: i0023
            for (int col=0; col<5; col++) begin: i0024
                for (int i=0; i<64; i++) begin: i0025
                    round_in[row][col][i] = reg_data[row][col][i];
                end
            end
        end
    end
    default: begin
        for (int row=0; row<5; row++) begin: i0033
            for (int col=0; col<5; col++) begin: i0034
                for (int i=0; i<64; i++) begin: i0035
                    round_in[row][col][i] = reg_data[row][col][i];
                end
            end
        end
    end
    endcase
end

// This process implements the 24 ROUNDS of the Keccak-p[1600,24] permutation
always_ff @( posedge clk_i, negedge rst_ni) begin: blockKeccak_p
    if (!rst_ni) begin
        for (int row = 0; row < 5; row++) 
        begin: i0100
            for (int col = 0; col < 5; col++) 
            begin: i0102
                for (int i = 0; i < 64; i++) 
                begin: i0103
                    reg_data[row][col][i] <= '0; // Initialize the state to 0
                end
            end
        end
        absorb_finish                    <= 1'b0;
        counter_nr_rounds       <= '0;
        permutation_computed_ab    <= 1'b1;
        permutation_computed_sq    <= 1'b1;
        rate                    <= rate_size;
        working                <= 1'b0;
    end
    else if (start == 1'b1) begin
        for (int row=0; row<5; row++) begin: i0201
            for (int col=0; col<5; col++) begin: i0202
                for (int i=0; i<64; i++) begin: i0203
                    reg_data[row][col][i] <= '0; // Initialize the state to 0
                end
            end
        end
        rate                    <= rate_size;
        absorb_finish                    <= 1'b0;
        counter_nr_rounds       <= '0;
        permutation_computed_ab    <= 1'b1;
        permutation_computed_sq    <= 1'b1;
    end
    else begin
        /************************************ PERMUTE ************************************/
        if (perm || working) begin 
            absorb_finish        <= 1'b0;
            rate        <= rate_comb;
            working        <= 1'b1;
            // First round
            if (permutation_computed_ab == 1'b1) begin
                counter_nr_rounds       <= ROUNDS;
                permutation_computed_ab    <= 0;
                reg_data                <= round_out[ROUNDS-1];
                // for (int row = 0; row < 5; row++) begin
                //     for (int col = 0; col < 5; col++) begin
                //         $display("Round in [%0d][%0d]: %0H", row, col, round_in[row][col]);
                //     end
                // end
            end
            // 24 ROUNDS calculation
            else begin
                // 22 or 23 depending on ROUNDS.
                if (counter_nr_rounds_comb <(24-ROUNDS) & permutation_computed_ab == 1'b0) begin
                    counter_nr_rounds   <= counter_nr_rounds_comb + ROUNDS;
                    reg_data            <= round_out[ROUNDS-1];
                end
                // counter_nr_rounds == 23: last round has been computed
                else if(counter_nr_rounds_comb == (24-ROUNDS)) begin 
                    permutation_computed_ab    <= 1'b1;
                    counter_nr_rounds       <= '0;
                    reg_data                <= round_out[ROUNDS-1];
                    working               <= 1'b0;
                    absorb_finish                <= 1'b1;
                    // for (int i = 0; i < ROUNDS; i++) begin
                    //     $display("Round out [%0d]: %0h", i, round_out[i]);
                    // end
                end
            end
        end
        else begin
            rate                    <= rate_size;
            absorb_finish                    <= 1'b0;
            counter_nr_rounds       <= '0;
            permutation_computed_ab    <= 1'b1;
            permutation_computed_sq    <= 1'b1;
            working                <= 1'b0;
        end
    end
end

always_ff @ ( posedge clk_i, negedge rst_ni) begin: blockReg
    if (!rst_ni) begin
        dout_valid_reg <= 1'b0;
    end
    else begin
        dout_valid_reg <= dout_valid;
    end
end



always_comb begin : blockReady
    case (function_sel)
        2'b00: rate_size = 1344;    // c = 256 bits, r = 1344 bits  (shake128)
        2'b01: rate_size = 1088;    // c = 512 bits, r = 1088 bits  (shake256)
        2'b10: rate_size = 1088;    // c = 512 bits, r = 1088 bits   (sha3-256)
        2'b11: rate_size = 576;     // c = 1024 bits, r = 576 bits (sha3-512)
        default: rate_size = 0;     // Default case
    endcase
    counter_nr_rounds_comb = counter_nr_rounds;
    rate_comb       = rate;
    dout_valid_neg  = !dout_valid & dout_valid_reg;
    buffer_ready     = din_buffer_ready; 
    permutation_ready =  permutation_computed_ab;
end

endmodule