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
// Version: 2.2
//
// File: keccak_buffer.sv
// File history:
//      0.0     : 26/02/2025 : Creation
//      1.0     : 04/03/2025 : Module implemented with FSM 
//      1.1     : 11/03/2025 : Modifications for linting + RC simplified
//      2.0     : 19/03/2025 : Implementation of padding for the shake and sha3
//                             algorithms + absorbtion and squeeze can be computed
//                             at the same time.
//      2.1     : 19/03/2025 : Implementation of padding for the shake and sha3
//                             algorithms.
//      2.2     : 19/03/2025 : Implementation of absorbtion and squeeze can be
//
// Description: This module implements an I/O buffer for the Keccak-p[1600,24]
// to llows the simultaneous transfer of the input through the bus and the 
// computation of Keccak- f for the previous input block during the absorbtion. 
// Similarly, in the squeezing phase it allows the simultaneous transfer of the 
// output through the bus and the computation of Keccak- f for the next output 
// block. The width is fixed to the lane size w of the underlying Keccak- f 
// permutation. This limits the throughput of the sponge engine to w per cycle.
// 
// Author: Alicia Manuel
//
////////////////////////////////////////////////////////////////////////////////
`ifdef VERILATOR
    `include "keccak_globals.sv"
`endif

module keccak_buffer
    import keccak_globals::*;
    #(parameter LEN_WIDTH = 64,
      parameter BUFFER_WIDTH = 64, //512
      parameter RATE_WIDTH = 1344 // Largest rate size
    )
(
    input   logic                       clk_i,                  // Clock
    input   logic                       rst_ni,                 // Reset
    input   logic                       start,
    input   logic[(BUFFER_WIDTH-1):0]   din_buffer_in,          // Input data for the input 
                                                                // absorb_finish (absorb)
    input   logic                       din_buffer_in_valid,    // Asserts when input data is on 
                                                                // din_buffer_in
    input   logic[1:0]                  mode,                   // 00: Rest
                                                                // 01: Absorbtion
                                                                // 10: Squeeze
    input   logic[1:0]                  function_sel,           // Indicates the function to be computed
                                                                // 0: Shake128 (Keccak[256])
                                                                // 1: Shake256 (Keccak[512])
                                                                // 2: SHA3-256 (Keccak[512])
                                                                // 3: SHA3-512 (Keccak[1024])
    input   logic[(LEN_WIDTH-1):0]      inlen,                  // Indicates the size of the output message
    input   logic                       perm,                   // Indicates if the permutation is being computed
                                                                // 1: Permutation is being computed
                                                                // 0: Permutation is not being compute
    input   logic[(RATE_WIDTH-1):0]     dout_buffer_in,         // Maximum rate input data from the
                                                                // keccak_round module is 168 bit.
                                                                // However, it was decided to use 256
                                                                // bits to make it divisible to the 
                                                                // output buffer size.
    input   logic                       permutation_ready,      // Asserts to active the buffer     
    input   logic                       absorb_finish,
    output  logic                       din_buffer_ready,       // Asserts when shift register is full
    output  logic[(RATE_WIDTH-1):0]     din_buffer_out,         // Input data to absorb by the 
                                                                // keccak_round module
    output  logic[(BUFFER_WIDTH-1):0]   dout_buffer_out,        // Outupt data for the output absorb_finish
                                                                // (load_finish)
    output  logic                       dout_buffer_out_valid   // Asserts when there is a new output
);

/********************************************************************
 * Internal signals
********************************************************************/
localparam DATA_WIDTH = (BUFFER_WIDTH*4 < RATE_WIDTH) ? RATE_WIDTH : BUFFER_WIDTH*4;
localparam int PAD_WIDTH = (BUFFER_WIDTH*4 > RATE_WIDTH) ? (BUFFER_WIDTH*4 - RATE_WIDTH) : 0;

logic                       permutation_ready_edge, permutation_ready_reg;
logic                       buffer_ready;    // Asserts when all words have been send
logic                       waiting;
logic[(LEN_WIDTH-1):0]      rate_size;
logic[(LEN_WIDTH-1):0]      count_words, count_words_comb; 
logic[(LEN_WIDTH-1):0]      count_pos, count_pos_comb;
logic[(LEN_WIDTH-1):0]      subs_comb;
logic[(LEN_WIDTH-1):0]      rem_bits;  
logic[(BUFFER_WIDTH-1):0]   reg_temp;
logic[(DATA_WIDTH-1):0]     buffer_data;    // Shift register to store the input              

/********************************************************************
 * RTL Logic
********************************************************************/
always_ff @( posedge clk_i, negedge rst_ni) begin: blockName1
    if (!rst_ni) begin
        count_words         <= '0;
        buffer_data          <='0;
        buffer_data         <='0;
        dout_buffer_out_valid   <= 1'b0;
        count_words          <= '0;
        waiting                 <= 1'b0;
        reg_temp                <= '0;
        count_pos               <= '0;
        din_buffer_ready        <= '0;
    end
    else begin
        if (start) begin
            // Reset all registers
            count_words         <= '0;
            buffer_data          <='0;
            buffer_data         <='0;
            dout_buffer_out_valid   <= 1'b0;
            count_words          <= '0;
            waiting                 <= 1'b0;
            reg_temp                <= '0;
            count_pos               <= '0;
            din_buffer_ready        <= '0;
        end
        else begin
            /******************************************** LOAD ********************************************/
            if (mode == 2'b00) begin
                dout_buffer_out_valid   <= 1'b0;
                // ABSORB
                if (count_words_comb < inlen) begin
                    if (count_pos_comb >= rate_size) begin
                        if (!permutation_ready) begin
                            buffer_data  <= '0;
                            // Recover remainder bits that were not sent to keccak
                            for (longint i = 0; (i < subs_comb/64 & i < 4*BUFFER_WIDTH/64 & i < 4*BUFFER_WIDTH-subs_comb/64-64); i++) begin
                                automatic longint index   = (BUFFER_WIDTH-subs_comb)+i*64;
                                buffer_data[i[10:0]*64+:64]    <= reg_temp[index[8:0]+:64];
                            end
                            // We cannot load more data until the permutation ends  
                            din_buffer_ready    <= 1'b0;
                            count_pos           <= subs_comb;   // Starting position for the next load
                        end
                    end
                    else begin
                        // Load input data
                        if (din_buffer_in_valid && !buffer_ready) begin
                            buffer_data[count_pos_comb[10:0]+:BUFFER_WIDTH] <= din_buffer_in;
                            count_pos       <= count_pos_comb + (rem_bits < BUFFER_WIDTH ? rem_bits : BUFFER_WIDTH);
                            count_words  <= count_words_comb + (rem_bits < BUFFER_WIDTH ? rem_bits : BUFFER_WIDTH);
                            if (count_pos + BUFFER_WIDTH >= rate_size) begin
                                din_buffer_ready    <= 1'b1;
                                reg_temp            <= din_buffer_in;
                            end
                        end
                    end
                    // Wait until permutation finishes to load more data
                    // if (perm) begin           // We can continue loading data
                    //     din_buffer_ready <= 1'b0;    // We can load more data
                    // end
                end
                else begin
                    /****************************************** PADDING ******************************************/
                    if (count_words_comb >= inlen & count_words_comb != '0) begin
                        //din_buffer_ready <= 1'b1;
                        waiting          <= 1'b0;
                        // Message fills all the rate buffer
                        if (inlen == rate_size[63:0] || count_pos_comb == rate_size)begin
                            buffer_data    <= '0;
                            if (function_sel == 2'b00 || function_sel == 2'b01) begin // Shake padding
                                buffer_data[4:0] <= 5'b11111;
                            end
                            else begin //Sha3 padding
                                buffer_data[2:0] <= 3'b110;
                            end
                            buffer_data[(rate_size[31:0]-1)]   <= 1'b1;
                            // Wait until the previous permutation finishes
                            if (!permutation_ready) begin
                                count_words  <= '0;
                                din_buffer_ready <= 1'b0;
                            end
                            else begin
                                count_pos  <= count_pos_comb;
                                count_words <= count_words_comb;
                                din_buffer_ready <= 1'b1;
                            end
                        end 
                        // Message does not fill the rate buffer
                        else begin      
                            if (count_pos_comb < rate_size) begin   
                                if (function_sel == 2'b00 || function_sel == 2'b01) begin // Shake padding
                                        buffer_data[count_pos_comb[10:0]+:5] <= 5'b11111;
                                        buffer_data[(count_pos_comb[10:0]+5)+:59] <= '0;
                                end
                                else begin //Sha3 padding
                                    buffer_data[count_pos_comb[10:0]+:3] <= 3'b110;
                                    buffer_data[(count_pos_comb[10:0]+3)+:61] <= '0;
                                end
                                buffer_data[(rate_size[31:0]-1)]   <= 1'b1;
                                // Wait until the previous permutation finishes
                                if (!permutation_ready) begin
                                    count_words  <= '0;
                                    count_pos       <= '0;
                                    din_buffer_ready <= 1'b0;
                                end
                                else begin
                                    count_pos  <= count_pos_comb;
                                    count_words <= count_words_comb;
                                    din_buffer_ready <= 1'b1;
                                end
                            end
                            else begin // All the message was received and inlen > rate
                                // Recover remainder bits that were not sent to keccak
                                buffer_data  <= '0;
                                for (longint i = 0; (i < subs_comb/64 & i < 4*BUFFER_WIDTH/64 & i < 4*BUFFER_WIDTH-subs_comb/64-64); i++) begin
                                    automatic longint index   = (BUFFER_WIDTH-subs_comb)+i*64;
                                    buffer_data[i[10:0]*64+:64]    <= reg_temp[index[8:0]+:64];
                                end
                                if (function_sel == 2'b00 || function_sel == 2'b01) begin // Shake padding
                                        buffer_data[subs_comb[10:0]+:5] <= 5'b11111;
                                end
                                else begin //Sha3 padding
                                    buffer_data[subs_comb[10:0]+:3] <= 3'b110;
                                end
                                buffer_data[(rate_size[31:0]-1)]   <= 1'b1;
                                // Wait until the previous permutation finishes
                                if (!permutation_ready) begin
                                    count_words  <= '0;
                                    count_pos       <= '0;
                                    din_buffer_ready <= 1'b0;
                                end
                                else begin
                                    count_pos  <= count_pos_comb;
                                    count_words <= count_words_comb;
                                    din_buffer_ready <= 1'b1;
                                end
                            end
                        end
                    end
                end
            end
            /******************************************** STORE ********************************************/
            else if (mode == 2'b01) begin
                // Output mode
                dout_buffer_out_valid   <= 1'b0;
                din_buffer_ready         <= 1'b1;
                if (count_words_comb == 0) begin                // Start of squeeze
                    buffer_data <= ((DATA_WIDTH == RATE_WIDTH) ? dout_buffer_in : {{PAD_WIDTH{1'b0}}, dout_buffer_in});
                    dout_buffer_out_valid       <= 1'b1;            // Indicate new output data
                    count_words             <= BUFFER_WIDTH;
                    count_pos                   <= BUFFER_WIDTH;
                end
                else begin
                    if (count_pos_comb + BUFFER_WIDTH > rate_size) begin
                        dout_buffer_out_valid   <= 1'b0;
                        waiting                 <= 1'b1;
                        if (permutation_ready) begin//if (permutation_ready_edge) begin HE CAMBIADO ESTO PARA EL RISCV
                            waiting                 <= 1'b0;
                            //reg_temp                <= dout_buffer_in[rate_size[10:0]-:BUFFER_WIDTH];
                            for (int i = 0; i < BUFFER_WIDTH; i++) begin
                                reg_temp[i] <= dout_buffer_in[rate_size[10:0] - 1- i[10:0]];
                            end
                            count_pos               <= BUFFER_WIDTH-subs_comb;
                            dout_buffer_out_valid   <= 1'b1;
                            //$display("Data out = %0h", buffer_data);
                            // Linted:
                            for (longint i = 0; i < DATA_WIDTH-1; i++) begin
                                if (i < subs_comb & i + BUFFER_WIDTH <  4*BUFFER_WIDTH) begin
                                    buffer_data[i[10:0]]   <=  buffer_data[i[10:0]+BUFFER_WIDTH]; // Last shift, we keep the remainder bits
                                end
                                else if (i < (rate_size+subs_comb)) begin
                                    buffer_data[i[10:0]]   <= dout_buffer_in[i[10:0]-subs_comb[10:0]]; // Load the next permutation result
                                    //$display("Bits to loaded = %0h", dout_buffer_in[i[10:0]-subs_comb[10:0]]);
                                end
                                else begin
                                    buffer_data[i[10:0]]   <= '0;
                                end
                            end
                        end
                    end
                    else begin
                        if (count_pos_comb + BUFFER_WIDTH == rate_size) begin
                            count_words         <= '0;
                        end
                        if (!waiting) begin
                            dout_buffer_out_valid   <= 1'b1;
                            count_pos               <= count_pos_comb + BUFFER_WIDTH;
                            // Shift register to send next word
                            for (int i=0; i < (DATA_WIDTH/BUFFER_WIDTH); i++) begin // buffer_data[4*BUFFER_WIDTH:0]. Thus, 4 iterations to shift the buffer
                                if (i < (DATA_WIDTH/BUFFER_WIDTH - 1)) begin
                                    buffer_data[(BUFFER_WIDTH-1) + (i*BUFFER_WIDTH) -: BUFFER_WIDTH] <= 
                                    buffer_data[((BUFFER_WIDTH*2-1) + (i*BUFFER_WIDTH)) -: BUFFER_WIDTH];
                                end
                                else begin
                                    buffer_data[(BUFFER_WIDTH-1) + (i*BUFFER_WIDTH) -: BUFFER_WIDTH] <= '0;
                                end
                                // $display("i: %d", i);
                                // $display("Buffer data out: %h", buffer_data);
                            end
                        end
                    end
                end
            end
            // else if (mode == 2'b10) begin
            //     // PADDING
            //     din_buffer_ready <= 1'b1;
            //     //if (count_words_comb >= inlen & count_words_comb != '0 & (waiting == 1'b0 || permutation_ready_edge == 1'b1)) begin
            //     if (count_words_comb >= inlen & count_words_comb != '0 & (permutation_ready == 1'b1)) begin
            //         din_buffer_ready <= 1'b1;
            //         waiting          <= 1'b0;
            //         // Message fills all the rate buffer
            //         if (inlen == rate_size[63:0] || count_pos_comb == rate_size)begin
            //             buffer_data    <= '0;
            //             if (function_sel == 2'b00 || function_sel == 2'b01) begin // Shake padding
            //                 buffer_data[4:0] <= 5'b11111;
            //             end
            //             else begin //Sha3 padding
            //                 buffer_data[2:0] <= 3'b110;
            //             end
            //             buffer_data[(rate_size[31:0]-1)]   <= 1'b1;
            //             // Wait until the previous permutation finishes
            //             if (permutation_ready_edge) begin
            //                 count_words  <= '0;
            //                 load_finish     <= 1'b1;
            //                 //din_buffer_ready <= 1'b0;
            //             end
            //         end 
            //         // Message does not fill the rate buffer
            //         else begin      
            //             if (count_pos < rate_size) begin   
            //                 if (function_sel == 2'b00 || function_sel == 2'b01) begin // Shake padding
            //                         buffer_data[count_pos[10:0]+:5] <= 5'b11111;
            //                 end
            //                 else begin //Sha3 padding
            //                     buffer_data[count_pos[10:0]+:3] <= 3'b110;
            //                 end
            //                 buffer_data[(rate_size[31:0]-1)]   <= 1'b1;
            //                 // Wait until the previous permutation finishes
            //                 if (permutation_ready) begin
            //                     load_finish     <= 1'b1;
            //                     count_words  <= '0;
            //                     count_pos       <= '0;
            //                     //din_buffer_ready <= 1'b0;
            //                 end
            //             end
            //             else begin // All the message was received and inlen > rate
            //                 // Recover remainder bits that were not sent to keccak
            //                 buffer_data  <= '0;
            //                 for (longint i = 0; (i < subs_comb/64 & i < 4*BUFFER_WIDTH/64 & i < 4*BUFFER_WIDTH-subs_comb/64-64); i++) begin
            //                     automatic longint index   = (BUFFER_WIDTH-subs_comb)+i*64;
            //                     buffer_data[i[10:0]*64+:64]    <= reg_temp[index[8:0]+:64];
            //                 end
            //                 if (function_sel == 2'b00 || function_sel == 2'b01) begin // Shake padding
            //                         buffer_data[subs_comb[10:0]+:5] <= 5'b11111;
            //                 end
            //                 else begin //Sha3 padding
            //                     buffer_data[subs_comb[10:0]+:3] <= 3'b110;
            //                 end
            //                 buffer_data[(rate_size[31:0]-1)]   <= 1'b1;
            //                 // Wait until the previous permutation finishes
            //                 if (permutation_ready) begin
            //                     load_finish     <= 1'b1;
            //                     count_words  <= '0;
            //                     count_pos       <= '0;
            //                     //din_buffer_ready <= 1'b0;
            //                 end
            //             end
            //         end
            //     end
            // end
            // waiting
            else begin
                count_words        <= count_words_comb;
                count_words         <= count_words_comb;
                count_pos              <= count_pos_comb;
                dout_buffer_out_valid   <= 1'b0;
            end
        end
    end
end

/********************************************************************
 * Combinational Output Logic
********************************************************************/
always_comb begin
    permutation_ready_edge      = permutation_ready & !permutation_ready_reg;
    din_buffer_out              = buffer_data[(RATE_WIDTH-1):0];
    // buffer_data[(BUFFER_WIDTH*2-1):0] because we the shift is still being done and we need the data at the moment
    dout_buffer_out             = (count_words == 0) ? dout_buffer_in[(BUFFER_WIDTH-1):0] : buffer_data[(BUFFER_WIDTH*2-1):(BUFFER_WIDTH)];
    buffer_ready                = din_buffer_ready;
    count_words_comb            = count_words;
    count_pos_comb              = count_pos;
    subs_comb                   = (count_pos_comb > rate_size) ? (count_pos_comb - rate_size) : (rate_size - count_pos_comb);
    rem_bits                    = inlen - count_words; 
    case (function_sel)
        2'b00: rate_size = LEN_WIDTH'(1344);    // c = 256 bits, r = 1344 bits  (shake128)
        2'b01: rate_size = LEN_WIDTH'(1088);    // c = 512 bits, r = 1088 bits  (shake256)
        2'b10: rate_size = LEN_WIDTH'(1088);    // c = 512 bits, r = 1088 bits  (sha3-256)
        2'b11: rate_size = LEN_WIDTH'(576);     // c = 1024 bits, r = 576 bits  (sha3-512)
        default: rate_size = LEN_WIDTH'(0);
    endcase
end

endmodule
