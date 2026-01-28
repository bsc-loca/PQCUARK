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
 File           : iface_sargantana_bfu.sv
 Organization   : Barcelona Supercomputing Center
 Author(s)      : Xavier Carril
 Email(s)       : xavier.carril@bsc.es
 -----------------------------------------------
 Revision History
  Revision   | Author    | Description
 --------------------------------------------------------------------------------
  1.0        | X. Carril | Initial implementation of the top-level PQCUARK-NTT module
 --------------------------------------------------------------------------------
 -- Functional Overview:

 -- Key Features:
 --------------------------------------------------------------------------------
*/

import drac_pkg::*;
import riscv_pkg::*;

module iface_pqcuark_sargantana_bfu (
  input  logic                    clk_i,
  input  logic                    rstn_i,         // Active low reset signal
  input  logic                    flush_i,        // Flush signal
  input  rr_exe_arith_instr_t     instruction_i,  // Instruction valid signal
  output exe_wb_scalar_instr_t    instruction_o   // 64-bit result output
);

logic selKD, selNTT, validSrc, validResult, fqmul, hilo;
logic [31:0] srcA, srcB, srcMul, resultA, resultB;
logic [15:0] zeta_addr;
logic [63:0] result;
rr_exe_arith_instr_t instr_pipe;

assign validSrc = instruction_i.instr.valid && (instruction_i.instr.unit == UNIT_PQC_NTT);
assign selKD =  (instruction_i.instr.instr_type inside {PQC_BF_NTT_KEM, PQC_BF_INTT_KEM, PQC_BF_FQMUL16_L, PQC_BF_FQMUL16_H})  ? 1'b1 : 1'b0;
assign selNTT = (instruction_i.instr.instr_type inside {PQC_BF_NTT_KEM, PQC_BF_NTT_DSA})  ? 1'b1 : 1'b0;
assign fqmul = (instruction_i.instr.instr_type inside {PQC_BF_FQMUL16_L, PQC_BF_FQMUL16_H, PQC_BF_FQMUL32_L, PQC_BF_FQMUL32_H}) ? 1'b1 : 1'b0; 
assign hilo = (instruction_i.instr.instr_type inside {PQC_BF_FQMUL16_H, PQC_BF_FQMUL32_H}) ? 1'b1 : 1'b0;
assign srcA = (hilo) ? instruction_i.data_rs1[63:32] : instruction_i.data_rs1[31:0];
assign zeta_addr = {instruction_i.data_rs2[39:32],instruction_i.data_rs2[7:0]};

always_comb begin
  if (fqmul) begin
    if (hilo) begin
      srcB = instruction_i.data_rs2[63:32];
    end else begin
      srcB = instruction_i.data_rs2[31:0];
    end
  end else begin
    srcB = instruction_i.data_rs1[63:32];
  end
end

pipe_queue #(
    .DATA_WIDTH    ($size(instr_pipe)),
    .PIPE_DEPTH    (4)
) u_pipe_bfu_queue (
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .flush_i       (flush_i),
    .data_i        (instruction_i),
    .data_o        (instr_pipe)
);

bfu_top u_bfu_top (
  .clk_i            (clk_i),
  .rstn_i           (rstn_i),
  .flush_i          (flush_i),
  .selKD_i          (selKD),
  .selNTT_i         (selNTT),
  .validSrc_i       (validSrc),
  .fqmul_i          (fqmul),
  .hilo_i           (hilo), 
  .srcA_i           (srcA),
  .srcB_i           (srcB),
  .zeta_addr_i      (zeta_addr),
  .we_zeta_i        (1'b0),
  .validResult_o    (validResult),
  .resultA_o        (resultA),
  .resultB_o        (resultB)
);

always_comb begin
  if ((instr_pipe.instr.instr_type inside {PQC_BF_FQMUL16_H, PQC_BF_FQMUL32_H})) begin
    result = {resultB, instr_pipe.data_rs1[31:0]};
  end else if (instr_pipe.instr.instr_type inside {PQC_BF_FQMUL16_L, PQC_BF_FQMUL32_L}) begin
    result = {instr_pipe.data_rs1[63:32], resultA};
  end else begin
    result = {resultB, resultA};
  end
end


assign instruction_o.valid           = validResult;
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
assign instruction_o.result          = result;
assign instruction_o.vl              = instr_pipe.instr.vl;
assign instruction_o.sew             = instr_pipe.instr.sew;
`ifdef SIM_KONATA_DUMP
assign instruction_o.id              = instr_pipe.instr.id;
`endif
assign instruction_o.fp_status     = 'h0;

always_comb begin
  if (instr_pipe.data_rs2[63:8] != 0) begin
    instruction_o.ex.cause  = LD_ACCESS_FAULT;
    instruction_o.ex.origin = instr_pipe.instr.pc;
    instruction_o.ex.valid  = 1'b1;
  end else begin
    instruction_o.ex.cause  = INSTR_ADDR_MISALIGNED;
    instruction_o.ex.origin = 0;
    instruction_o.ex.valid  = 0;
  end
end


endmodule
