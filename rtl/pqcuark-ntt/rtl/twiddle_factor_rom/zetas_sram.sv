/*
 -----------------------------------------------
 Project Name   : PQCUARK 
 File           : zetas_sram.sv
 Organization   : Barcelona Supercomputing Center
 Author(s)      : Xavier Carril
 Email(s)       : xavier.carril@bsc.es
 -----------------------------------------------
 Revision History
    Revision   | Author    | Description
 --------------------------------------------------------------------------------
    1.0        | X. Carril | Initial implementation of the zetas_sram module
 --------------------------------------------------------------------------------
 -- Functional Overview:
 The `zetas_sram` module implements a memory block that stores the zeta values 
 required for Number Theoretic Transform (NTT) and its inverse (InvNTT) for 
 post-quantum cryptographic schemes, specifically Kyber and Dilithium. It 
 supports both read and write operations and can be synthesized for different 
 technologies.

 -- Key Features:
 - Supports both Kyber and Dilithium operations.
 - Selectable memory addressing for Kyber and Dilithium.
 - Synthesizable for different technologies.
 - Handles 32-bit data width and 256 address locations.
 - Efficient memory operations optimized for cryptographic computations.
 --------------------------------------------------------------------------------
*/
module zetas_sram #(
    parameter int DATA_WIDTH = 32,   // Data width (32-bit values)
    parameter int ADDR_WIDTH = 8     // Address width (memory of 2^ADDR_WIDTH, here 256 locations)
)(
    input  logic                            clk_i,      // Clock signal
    input  logic                            rstn_i,     // Reset signal
    input  logic                            valid_i,
    input  logic                            selKD_i,    // Select Kyber(1) or Dilithium(0)
    input  logic                            rdwen_i,    // Write Enable
    input  logic [DATA_WIDTH-1:0]           data_i,     // Data input
    input  logic [ADDR_WIDTH-1:0]           addr_i,     // Address input
    output logic signed [DATA_WIDTH-1:0]    data_o      // Signed 16-bit data output
);

    logic validOut;
    logic [ADDR_WIDTH:0] addrIn; // Adding 1 bit more because we have Kyber + Dilithium (320bits)
    logic signed [DATA_WIDTH-1:0] dataOut;

    assign addrIn = (selKD_i) ? ({2'b0, addr_i[ADDR_WIDTH-1:1]}) : addr_i + ADDR_WIDTH'('d64);

    // Define SRAM with Dilithium Zetas array (SYNTHESIZABLE)
    `ifdef SYNTHESIS_22NM 
        MBH_ZSBL_IN22FDX_S1P_BFRG_W00320B032M08C128 u_sram (
            .clk(clk_i),
            .cen(~valid_i),
            .rdwen(~rdwen_i),
            .deepsleep(1'b0),
            .powergate(1'b0),
            .a(addrIn),
            .d(data_i),
            .bw(32'hFFFFFFFF),
            .q(dataOut)
        );
    `else
        logic signed [DATA_WIDTH-1:0] sram_array_d [0:319];
        logic signed [DATA_WIDTH-1:0] sram_array_q [0:319];
        logic selKD_q;
        logic [ADDR_WIDTH:0] addr;

        always_comb begin
            sram_array_d = sram_array_q;
            if (rdwen_i && valid_i) begin
                sram_array_d[addrIn] = data_i;
            end
        end

        always_ff @(posedge clk_i or negedge rstn_i) begin
            if (!rstn_i) begin
                validOut <= 1'b0;
                addr <= '0;
                selKD_q <= 1'b0;
                for (int i = 0; i < 320; i++) begin
                    sram_array_q[i] <= '0;
                end
            end else begin
                validOut <= valid_i && ~rdwen_i;
                selKD_q <= selKD_i;
                addr <= addrIn;
                sram_array_q <= sram_array_d;
            end
        end

        assign dataOut = (selKD_q) ? {sram_array_q[addr][15:0], sram_array_q[addr][15:0]} : sram_array_q[addr];
        // initial begin
        //     $readmemh("/users/xcarril/pqcuark_ntt/src/rtl/twiddle_factor_rom/zetas.hex", rom_array);
        // end
    `endif

    assign data_o = (validOut) ? dataOut : '0;

endmodule
