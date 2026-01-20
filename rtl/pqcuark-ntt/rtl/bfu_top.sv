/*
 -----------------------------------------------
 Project Name   : PQCUARK 
 File           : bfu_top.sv
 Organization   : Barcelona Supercomputing Center
 Author(s)      : Xavier Carril
 Email(s)       : xavier.carril@bsc.es
 -----------------------------------------------
 Revision History
  Revision   | Author    | Description
 --------------------------------------------------------------------------------
  1.0        | X. Carril | Initial implementation of the top-level BFU module
 --------------------------------------------------------------------------------
 -- Functional Overview:
 The `bfu_top` module implements a pipelined Butterfly Functional Unit (BFU) 
 that performs arithmetic operations required for Number Theoretic Transform 
 (NTT) and its inverse (InvNTT) for post-quantum cryptographic schemes, 
 specifically Kyber and Dilithium. It integrates multiple arithmetic 
 submodules, including modular reduction, Barrett reduction, Montgomery 
 multiplication, addition, and subtraction.

 -- Key Features:
 - Supports both Kyber and Dilithium operations.
 - Selectable NTT and InvNTT modes.
 - Fully pipelined architecture with multiple processing stages.
 - Performs modular reduction, Montgomery multiplication, and Barrett reduction.
 - Handles 16+16-bit processing for Kyber and 32-bit processing for Dilithium.
 - Efficient pipeline registers to optimize throughput.
 - High-performance arithmetic operations optimized for cryptographic computations.
 --------------------------------------------------------------------------------
*/

module bfu_top (
    input  logic        clk_i,
    input  logic        rstn_i,
    input  logic        flush_i,        // Flush signal to clear the pipeline
    input  logic        selKD_i,        // Select Kyber(1) or Dilithium(0) operation
    input  logic        selNTT_i,       // Select NTT(1) or InvNTT(0) operation
    input  logic        validSrc_i,     // Valid input operands
    input  logic        fqmul_i,        // Enable(1)/Disable(0) fqmul mode
    input  logic        hilo_i,         // Select high(1)/low(0) part of the result
    input  logic [31:0] srcA_i,         // Source (16+16 bits for Kyber, 32 bits for Dilithium)
    input  logic [31:0] srcB_i,         // Source (16+16 bits for Kyber, 32 bits for Dilithium)
    input  logic [15:0] zeta_addr_i,    // Twiddle Factor address input. For Kyber, SRAM returns {zeta_addr[15:8], zeta_addr[7:0]}
    input  logic        we_zeta_i,      // Write Enable to Twiddle Factor SRAM 
    output logic        validResult_o,  // Valid output result
    output logic [31:0] resultA_o,      // Result A (16+16 bits for Kyber, 32 bits for Dilithium)
    output logic [31:0] resultB_o       // Result B (16+16 bits for Kyber, 32 bits for Dilithium)
);

// Stage 1
logic [31:0] srcA_s1, srcB_s1;
logic [15:0] zeta_addr_s1;
logic valid_s1, fqmul_s1, hilo_s1, selKD_s1, selNTT_s1, we_zeta_s1;
logic [31:0] resSub_s1;

always_comb begin
  srcA_s1 = srcA_i;
  srcB_s1 = srcB_i;
  hilo_s1 = hilo_i;
  zeta_addr_s1 = zeta_addr_i;
  valid_s1 = validSrc_i & (~flush_i);
  fqmul_s1 = fqmul_i;
  selKD_s1 = selKD_i;
  selNTT_s1 = selNTT_i;
  we_zeta_s1 = we_zeta_i;
end

substraction_32bit substraction_32bit_m1_inst (
    .selKD_i     (selKD_s1),
    .srcA_i      (srcB_s1),
    .srcB_i      (srcA_s1),
    .result_o    (resSub_s1)
);

// Stage 2 
logic [31:0] srcA_s2, srcB_s2;
logic [31:0] w_s2, wMul_s2;
logic valid_s2, fqmul_s2, hilo_s2, selKD_s2, selNTT_s2, validMul_s3;
logic [31:0] resSub_s2;
logic [31:0] mulInput_s2;

logic [63:0] resMul_s3;

`ifndef ZETAS_SRAM
    zetas_rom u_zetas_rom (
    .clk_i           (clk_i),
    .rstn_i          (rstn_i),
    .valid_i         (valid_s1),
    .selKD_i         (selKD_s1),
    .selNTT_i        (selNTT_s1),
    .addrX_i         (zeta_addr_s1[15:8]),
    .addrY_i         (zeta_addr_s1[7:0]),
    .data_o          (w_s2)
    );
`else
    zetas_sram u_zetas_sram (
    .clk_i           (clk_i),
    .rstn_i          (rstn_i),
    .valid_i         (valid_s1),
    .selKD_i         (selKD_s1),
    .rdwen_i         (we_zeta_s1),
    .data_i          (srcB_s1),
    .addr_i          (zeta_addr_s1),
    .data_o          (w_s2)
    );
`endif


always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
        srcA_s2   <= '0;
        srcB_s2   <= '0;
        hilo_s2   <= 1'b0; 
        valid_s2  <= 1'b0;
        selKD_s2  <= 1'b0;
        selNTT_s2 <= 1'b0;
        resSub_s2 <= '0;
    end else begin
        srcA_s2     <= srcA_s1;
        srcB_s2     <= srcB_s1;
        hilo_s2     <= hilo_s1;
        valid_s2    <= valid_s1 && (~we_zeta_s1) && (~flush_i);
        fqmul_s2    <= fqmul_s1;
        selKD_s2    <= selKD_s1;
        selNTT_s2   <= selNTT_s1;
        resSub_s2   <= resSub_s1;
    end
end

always_comb begin
    if (fqmul_s2) begin 
        mulInput_s2 = srcA_s2; 
        wMul_s2 = srcB_s2; 
    end else begin 
        mulInput_s2 = (selNTT_s2) ? srcB_s2 : resSub_s2; 
        wMul_s2 = w_s2; //Dilithium InvNTT need to negate the twiddle factor
    end
end

bfu_multiplier bfu_multiplier_inst (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .flush_i(flush_i),
    .selKD_i(selKD_s2),
    .validSrc_i(valid_s2),
    .srcA_i(mulInput_s2),
    .srcB_i(wMul_s2),
    .validResult_o(validMul_s3),
    .result_o(resMul_s3)
);

logic selKD_s3;

always_ff @(posedge clk_i, negedge rstn_i) begin
  if(!rstn_i) begin
    selKD_s3 <= 1'b0;
  end else begin
    selKD_s3 <= selKD_s2;
  end
end

logic selNTT_s4, selKD_s4, fqmul_s4, hilo_s4;
logic [31:0] srcA_s4, srcB_s4;

pipe_queue #(
    .DATA_WIDTH    ($bits(srcA_s2)),
    .PIPE_DEPTH    (2)
) pipe_queue_srcA_s2_s4 (
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .flush_i       (flush_i),
    .data_i        (srcA_s2),
    .data_o        (srcA_s4)
);

pipe_queue #(
    .DATA_WIDTH    ($bits(srcB_s2)),
    .PIPE_DEPTH    (2)
) pipe_queue_srcB_s2_s4 (
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .flush_i       (flush_i),
    .data_i        (srcB_s2),
    .data_o        (srcB_s4)
);

pipe_queue #(
    .DATA_WIDTH    ($bits(selNTT_s2)),
    .PIPE_DEPTH    (2)
) pipe_queue_selNTT_s2_s4 (
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .flush_i       (flush_i),
    .data_i        (selNTT_s2),
    .data_o        (selNTT_s4)
);

pipe_queue #(
    .DATA_WIDTH    ($bits(selKD_s2)),
    .PIPE_DEPTH    (2)
) pipe_queue_selKD_s2_s4 (
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .flush_i       (flush_i),
    .data_i        (selKD_s2),
    .data_o        (selKD_s4)
);

pipe_queue #(
    .DATA_WIDTH    ($bits(fqmul_s2)),
    .PIPE_DEPTH    (2)
) pipe_queue_fqmul_s2_s4 (
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .flush_i       (flush_i),
    .data_i        (fqmul_s2),
    .data_o        (fqmul_s4)
);

pipe_queue #(
    .DATA_WIDTH    ($bits(hilo_s2)),
    .PIPE_DEPTH    (2)
) pipe_queue_hilo_s2_s4 (
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .flush_i       (flush_i),
    .data_i        (hilo_s2),
    .data_o        (hilo_s4)
);

// Stage 7
logic [31:0] resRed_s4, resSub_s4, resAdd_s4;
logic validRed_s4;

bfu_modred bfu_modred_inst (
    .clk_i            (clk_i),
    .rstn_i           (rstn_i),
    .flush_i          (flush_i),
    .validSrc_i       (validMul_s3),
    .selKD_i          (selKD_s3),
    .src_i            (resMul_s3),
    .validResult_o    (validRed_s4),
    .result_o         (resRed_s4)
);

substraction_32bit substraction_32bit_m2_inst (
    .selKD_i     (selKD_s4),
    .srcA_i      (srcA_s4),
    .srcB_i      (resRed_s4),
    .result_o    (resSub_s4)
);

logic [31:0] addInput_s4;
assign addInput_s4 = (selNTT_s4) ? resRed_s4 : srcB_s4;

adder_32bit adder_32bit_inst (
    .selKD_i     (selKD_s4),
    .srcA_i      (addInput_s4),
    .srcB_i      (srcA_s4),
    .result_o    (resAdd_s4)
);

logic valid_s5;
logic [31:0] resBarret_s5;
bfu_barrett u_bfu_barrett (
  .clk_i            (clk_i),
  .rstn_i           (rstn_i),
  .flush_i          (flush_i),
  .validSrc_i       (validRed_s4),
  .src_i            (resAdd_s4),
  .validResult_o    (valid_s5),
  .result_o         (resBarret_s5)
);

logic [31:0] resRed_s5, resAdd_s5, resSub_s5;
logic selNTT_s5, selKD_s5, fqmul_s5, hilo_s5;
always_ff @(posedge clk_i, negedge rstn_i) begin
    if (!rstn_i) begin
        selNTT_s5 <= 1'b0;
        selKD_s5 <= 1'b0;
        fqmul_s5 <= 1'b0;
        hilo_s5  <= 1'b0;
        resRed_s5 <= '0;
        resAdd_s5 <= '0;
        resSub_s5 <= '0;
    end else begin
        selNTT_s5 <= selNTT_s4;
        selKD_s5 <= selKD_s4;
        fqmul_s5 <= fqmul_s4;
        hilo_s5  <= hilo_s4;
        resRed_s5 <= resRed_s4;
        resAdd_s5 <= resAdd_s4;
        resSub_s5 <= resSub_s4;
    end
end

logic [15:0] resA_aH, resA_aL;
logic [15:0] resB_bH, resB_bL;

always_comb begin
    if (fqmul_s5) begin
      if (hilo_s5) begin
        resA_aH = '0;
        resA_aL = '0;
        resB_bH = resRed_s5[31:16];
        resB_bL = resRed_s5[15:0];
      end else begin
        resA_aH = resRed_s5[31:16];
        resA_aL = resRed_s5[15:0];
        resB_bH = '0;
        resB_bL = '0;
      end
    end else begin
        if (selKD_s5) begin
            resA_aH = (selNTT_s5) ? resAdd_s5[31:16] : resBarret_s5[31:16];
            resA_aL = (selNTT_s5) ? resAdd_s5[15:0] : resBarret_s5[15:0];
            resB_bH = (selNTT_s5) ? resSub_s5[31:16] : resRed_s5[31:16];
            resB_bL = (selNTT_s5) ? resSub_s5[15:0] : resRed_s5[15:0];
        end else begin
            resA_aH = resAdd_s5[31:16];
            resA_aL = resAdd_s5[15:0];
            resB_bH = (selNTT_s5) ? resSub_s5[31:16] : resRed_s5[31:16];
            resB_bL = (selNTT_s5) ? resSub_s5[15:0] : resRed_s5[15:0];
        end
    end
end

assign resultA_o = {resA_aH, resA_aL}; 
assign resultB_o = {resB_bH, resB_bL}; 

assign validResult_o = valid_s5 & (~flush_i);


endmodule
