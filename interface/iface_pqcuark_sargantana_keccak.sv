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
// File: iface_sargantana_keccak.sv
// File history:
//      0.0     : 16/05/2025 : Creation
//
// Description:
// 
// Author: Alicia Manuel
//
////////////////////////////////////////////////////////////////////////////////

import drac_pkg::*;
import riscv_pkg::*;

module iface_pqcuark_sargantana_keccak (
  input  logic                    clk_i,
  input  logic                    rstn_i,         // Active low reset signal
  input  logic                    flush_i,        // Flush signal

  input  logic[63:0]              inlen_i,
  input  logic[2:0]               function_sel_i,
  input  logic[63:0]              input_data_i,
  input  logic                    input_valid_i,
  output logic[63:0]              output_data_o,
  output logic                    ready_keccak_f1600_o,
  output logic                    ready_keccak_buffer_o,

  input  rr_exe_arith_instr_t     instruction_i,  // Instruction valid signal
  output exe_wb_scalar_instr_t    instruction_o   // 512-bit result output
);

logic         keccak_active;
logic         validSrc, start, o_valid, permutation_ready, i_valid, o_validLD, perm;
logic         absorb_finish, load_finish, buffer_ready, i_valid_andxor, o_valid_andxor;
logic[1:0]    ld_st, ld_st_reg;
bus64_t       result_data;
logic[1:0]    f_sel;
rr_exe_arith_instr_t instr_pipe, instr_pipe_std, instr_pipe_keccakf1600, instr_pipe_muxed, instr_pipe_reg;

// Control logic
assign validSrc = instruction_i.instr.valid && (instruction_i.instr.unit == UNIT_PQC_KECCAK || instruction_i.instr.unit == UNIT_MEM);
assign perm = validSrc && (instruction_i.instr.instr_type == PQC_KECCAK_F1600);
//assign input_data = (instruction_i.instr.instr_type == PQC_KECCAK_LD) ? instruction_i.data_rs1 : '0;
//assign inlen = (instruction_i.instr.instr_type == PQC_KECCAK_INIT) ? instruction_i.data_rs2: '0;
assign i_valid = (instruction_i.instr.instr_type == PQC_KECCAK_LD & input_valid_i) ? 1'b1 : 1'b0;
assign start = (instruction_i.instr.instr_type == PQC_KECCAK_INIT) ? 1'b1 : 1'b0;
assign absorb_finish = 1'b1;

always_ff @ ( posedge clk_i, negedge rstn_i) begin: blockValid_reg
    if (!rstn_i) begin
        o_validLD <= '0;
        
    end
    else if ((instruction_i.instr.instr_type == PQC_KECCAK_LD) || (instruction_i.instr.instr_type == PQC_KECCAK_INIT)) begin
        o_validLD <= '1;
    end
    else begin
      o_validLD <= '0;
    end
end

always_comb begin
    if (instruction_i.instr.instr_type == PQC_KECCAK_LD  && validSrc) begin
        ld_st = 2'b00;
    end
    else if (instruction_i.instr.instr_type == PQC_KECCAK_ST && validSrc) begin
        ld_st = 2'b01;
    end
    else begin
        ld_st = (ld_st_reg == 2'b00) ? 2'b00 : 2'b11;
    end
end

always_ff @ ( posedge clk_i, negedge rstn_i) begin
    if (!rstn_i) begin
        ld_st_reg <= '0;
        
    end
    else if (instruction_i.instr.instr_type == PQC_KECCAK_LD) begin
        ld_st_reg <= 2'b00;
    end
    else if (instruction_i.instr.instr_type == PQC_KECCAK_ST) begin
        ld_st_reg <= 2'b01;
    end
end


// Pipeline for standard instructions
pipe_queue #(
    .DATA_WIDTH($size(instr_pipe)),
    .PIPE_DEPTH(1)
) u_pipe_std (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .flush_i(flush_i),
    .data_i(instruction_i),
    .data_o(instr_pipe_std)
);

// Pipeline for KECCAK instruction
pipe_queue #(
    .DATA_WIDTH($size(instr_pipe)),
    .PIPE_DEPTH(12)
) u_pipe_keccak (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .flush_i(flush_i),
    .data_i(instruction_i),
    .data_o(instr_pipe_keccakf1600)
);


always_ff @( posedge clk_i, negedge rstn_i) begin
    if (!rstn_i)
        keccak_active <= 0;
    else begin
        if (instruction_i.instr.instr_type == PQC_KECCAK_F1600)
            keccak_active <= 1;
        else if (instr_pipe_keccakf1600.instr.instr_type == PQC_KECCAK_F1600 && permutation_ready)
            keccak_active <= 0;
    end
end


always_comb begin
    if (keccak_active || (instruction_i.instr.instr_type == PQC_KECCAK_F1600))
        instr_pipe_muxed = instr_pipe_keccakf1600; // Maintain pipeline until the end of the instruction
    else
        instr_pipe_muxed = instr_pipe_std;
end


keccak keccak_inst(
  .clk_i                (clk_i),
  .rst_ni               (rstn_i),
  .start                (start),
  .din                  (input_data_i),
  .din_valid            (input_valid_i),
  .ld_st                (ld_st),
  .perm                 (perm),
  .function_sel         (function_sel_i),
  .inlen                (inlen_i*8),
  .buffer_ready         (buffer_ready),
  .permutation_ready    (permutation_ready),
  .dout                 (output_data_o),
  .dout_valid           (o_valid)
);

assign instr_pipe                    = instr_pipe_muxed;
assign instruction_o.valid = (
    (instr_pipe_muxed.instr.instr_type == PQC_KECCAK_LD    && o_validLD)     ||
    (instr_pipe_muxed.instr.instr_type == PQC_KECCAK_INIT  && o_validLD)     ||
    (instr_pipe_muxed.instr.instr_type == PQC_KECCAK_ST    && o_valid)       ||
    (instr_pipe_muxed.instr.instr_type == PQC_KECCAK_F1600 && permutation_ready));

assign instruction_o.pc              = instr_pipe.instr.pc;
assign instruction_o.bpred           = instr_pipe.instr.bpred;
assign instruction_o.rs1             = instr_pipe.instr.rs1;
assign instruction_o.rd              = instr_pipe.instr.rd;
assign instruction_o.regfile_we      = instr_pipe.instr.regfile_we;
assign instruction_o.instr_type      = instr_pipe.instr.instr_type;
assign instruction_o.stall_csr_fence = instr_pipe.instr.stall_csr_fence;
assign instruction_o.csr_addr        = instr_pipe.instr.imm[CSR_ADDR_SIZE-1:0];
assign instruction_o.prd             = instr_pipe.prd;
assign instruction_o.checkpoint_done = instr_pipe.checkpoint_done;
assign instruction_o.chkp            = instr_pipe.chkp;
assign instruction_o.gl_index        = instr_pipe.gl_index;
assign instruction_o.mem_type        = instr_pipe.instr.mem_type;
assign instruction_o.branch_taken    = 1'b0;
assign instruction_o.result_pc       = 0;
assign instruction_o.result          = '0;
assign instruction_o.vl              = '0;
assign instruction_o.sew             = SEW_8;
`ifdef SIM_KONATA_DUMP
assign instruction_o.id              = instr_pipe.instr.id;
`endif
assign instruction_o.fp_status     = 'h0;

assign ready_keccak_f1600_o = permutation_ready;
assign ready_keccak_buffer_o = buffer_ready;

always_comb begin
    instruction_o.ex.cause  = INSTR_ADDR_MISALIGNED;
    instruction_o.ex.origin = 0;
    instruction_o.ex.valid  = 0;
end


endmodule

