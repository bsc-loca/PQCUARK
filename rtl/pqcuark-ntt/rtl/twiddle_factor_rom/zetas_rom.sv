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
 File           : zetas_rom.sv
 Organization   : Barcelona Supercomputing Center
 Author(s)      : Xavier Carril
 Email(s)       : xavier.carril@bsc.es
 -----------------------------------------------
 Revision History
    Revision   | Author    | Description
 --------------------------------------------------------------------------------
    1.0        | X. Carril | Initial implementation of the Zetas ROM module
 --------------------------------------------------------------------------------
 -- Functional Overview:
 The `zetas_rom` module implements a read-only memory (ROM) that stores the 
 Zetas values required for Number Theoretic Transform (NTT) operations in 
 post-quantum cryptographic schemes, specifically Kyber and Dilithium. It 
 provides a signed 32-bit data output based on the input address and selection 
 signal for Kyber or Dilithium.

 -- Key Features:
 - Supports both Kyber and Dilithium Zetas values.
 - Selectable Kyber and Dilithium modes.
 - 256 addressable locations for Kyber and 320 for Dilithium.
 - Signed 32-bit data output.
 - Efficient ROM initialization using external file.
 --------------------------------------------------------------------------------
*/
module zetas_rom #(
    parameter int DATA_WIDTH = 32,   // Data width (32-bit values)
    parameter int ADDR_WIDTH = 8     // Address width (memory of 2^ADDR_WIDTH, here 256 locations)
)(
    input  logic                            clk_i,      // Clock signal
    input  logic                            rstn_i,     // Reset signal
    input  logic                            valid_i,    // Valid data input signal
    input  logic                            selKD_i,    // Select Kyber(1) or Dilithium(0)
    input  logic                            selNTT_i,   // Select NTT(1) or InvNTT(0)
    input  logic [ADDR_WIDTH-1:0]           addrX_i,    // Address input (Only Kyber)
    input  logic [ADDR_WIDTH-1:0]           addrY_i,    // Address input
    output logic signed [DATA_WIDTH-1:0]    data_o      // Signed 16-bit data output
);

    logic validOut;
    // logic [ADDR_WIDTH-1:0] addrXIn, addrYIn; // Adding 1 bit more because we have Kyber + Dilithium (384bits)
    logic signed [DATA_WIDTH-1:0] dataOut;

    // Define address input based on selection signal
    // always_comb begin
    //     case ({selKD_i, selNTT_i})
    //         2'b00: addrXIn = addrX_i + ADDR_WIDTH'('d128);                        // Dilithium InvNTT
    //         2'b01: addrXIn = addrX_i + ADDR_WIDTH'('d128);                        // Dilithium NTT
    //         2'b10: addrXIn = {1'b0, addrX_i[ADDR_WIDTH-1:1] + ADDR_WIDTH'('d64)}; // Kyber InvNTT
    //         2'b11: addrXIn = {2'b0, addrX_i[ADDR_WIDTH-1:1]};                     // Kyber NTT
    //         default: addrXIn = '0;                                               // Default case
    //     endcase
    // end
    // // Define address input based on selection signal
    // always_comb begin
    //     case ({selKD_i, selNTT_i})
    //         2'b10: addrYIn = {1'b0, addrY_i[ADDR_WIDTH-1:1] + ADDR_WIDTH'('d64)}; // Kyber InvNTT
    //         2'b11: addrYIn = {2'b0, addrY_i[ADDR_WIDTH-1:1]};                     // Kyber NTT
    //         default: addrXIn = '0;                                               // Default case
    //     endcase
    // end

    // Define rom with Dilithium Zetas array (NOT SYNTHESIZABLE)
    logic selKD, selNTT;
    logic signed [15:0] kyber_rom_array [0:127];
    logic signed [31:0] dilithium_rom_array [0:255];
    logic [ADDR_WIDTH-1:0] addrX, addrY;
    initial begin
        $readmemh("/users/xcarril/sargantana-tile-pqcuark/rtl/core/sargantana/rtl/datapath/rtl/exe_stage/rtl/pqcuark_ntt/src/rtl/twiddle_factor_rom/zetas_kyber.hex", kyber_rom_array);
        $readmemh("/users/xcarril/sargantana-tile-pqcuark/rtl/core/sargantana/rtl/datapath/rtl/exe_stage/rtl/pqcuark_ntt/src/rtl/twiddle_factor_rom/zetas_dilithium.hex", dilithium_rom_array);
    end
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            validOut <= 1'b0;
            selKD <= 1'b0;
            selNTT <= 1'b0;
            addrX <= '0;
            addrY <= '0;
        end else begin
            validOut <= valid_i;
            selKD <= selKD_i;
            selNTT <= selNTT_i;
            addrX <= addrX_i;
            addrY <= addrY_i;
        end
    end

    assign dataOut = (selKD) ? {kyber_rom_array[addrX[6:0]], kyber_rom_array[addrY[6:0]]} : dilithium_rom_array[addrY];

    assign data_o = (validOut) ? dataOut : '0;

endmodule
