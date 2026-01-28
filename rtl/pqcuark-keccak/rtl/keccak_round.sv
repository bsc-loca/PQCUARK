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
// File: keccak_round.sv
// File history:
//      0.0     : 20/02/2025 : Creation
//      0.1     : 11/03/2025 : RC simplified
//      <Revision number>: <Date>: <Comments>
//
// Description: This module produces one Keccak-p round 
// 
// Author: Alicia Manuel
//
////////////////////////////////////////////////////////////////////////////////

`ifdef VERILATOR
    `include "keccak_globals.sv"
`endif
//import keccak_globals::*;

module keccak_round 
	import keccak_globals::*;
    #(parameter rc_width = 7)
(
    input   k_state     round_in,
    input   logic[(rc_width-1):0] round_constant_signal,
    output  k_state     round_out
);

/********************************************************************
 * Internal signals
********************************************************************/
localparam int NON_ZERO_POS[7] = '{0, 1, 3, 7, 15, 31, 63};
k_state theta_in, theta_out, pi_in, pi_out,rho_in,rho_out,chi_in,chi_out,
        iota_in,iota_out;
k_plane sum_sheet;

/********************************************************************
 * Combinational logic
********************************************************************/

always_comb begin : blockName
    //order theta, pi, rho, chi, iota
    theta_in  =   round_in;

    // theta
    // Generate sum_sheet
    for (int x = 0; x <= 4; x++) begin
        for (int i = 0; i <= 63; i++) begin
            sum_sheet[x][i] = ((theta_in[0][x][i] ^ theta_in[1][x][i]) ^ 
                               (theta_in[2][x][i] ^ theta_in[3][x][i])) ^ 
                               theta_in[4][x][i];
        end
    end
    
    // Generate theta_out (middle columns)
    for (int y = 0; y <= 4; y++) begin
        for (int x = 1; x <= 3; x++) begin
            theta_out[y][x][0] = theta_in[y][x][0] ^ sum_sheet[x-1][0] ^ sum_sheet[x+1][63];
            for (int i = 1; i <= 63; i++) begin
                theta_out[y][x][i] = theta_in[y][x][i] ^ sum_sheet[x-1][i] ^ sum_sheet[x+1][i-1];
            end
        end
    end
    
    // Generate theta_out (first column)
    for (int y = 0; y <= 4; y++) begin
        theta_out[y][0][0] = theta_in[y][0][0] ^ sum_sheet[4][0] ^ sum_sheet[1][63];
        for (int i = 1; i <= 63; i++) begin
            theta_out[y][0][i] = theta_in[y][0][i] ^ sum_sheet[4][i] ^ sum_sheet[1][i-1];
        end
    end
    
    // Generate theta_out (last column)
    for (int y = 0; y <= 4; y++) begin
        theta_out[y][4][0] = theta_in[y][4][0] ^ sum_sheet[3][0] ^ sum_sheet[0][63];
        for (int i = 1; i <= 63; i++) begin
            theta_out[y][4][i] = theta_in[y][4][i] ^ sum_sheet[3][i] ^ sum_sheet[0][i-1];
        end
    end

    // rho
    rho_in    =   theta_out;
    // y=0
    for (int i=0; i<64; i++)
    begin: i4001
        rho_out[0][0][i]=rho_in[0][0][i];
    end
    for (int i=0; i<64; i++)
    begin: i4002
        rho_out[0][1][i]=rho_in[0][1][((i-1)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4003
        rho_out[0][2][i]=rho_in[0][2][((i-62)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4004
        rho_out[0][3][i]=rho_in[0][3][((i-28)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4005
        rho_out[0][4][i]=rho_in[0][4][((i-27)+64)% 64];
    end
    // y=1
    for (int i=0; i<64; i++)
    begin: i4011
        rho_out[1][0][i]=rho_in[1][0][((i-36)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4012
        rho_out[1][1][i]=rho_in[1][1][((i-44)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4013
        rho_out[1][2][i]=rho_in[1][2][((i-6)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4014
        rho_out[1][3][i]=rho_in[1][3][((i-55)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4015
        rho_out[1][4][i]=rho_in[1][4][((i-20)+64)% 64];
    end
    // y=2
    for (int i=0; i<64; i++)
    begin: i4021
        rho_out[2][0][i]=rho_in[2][0][((i-3)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4022
        rho_out[2][1][i]=rho_in[2][1][((i-10)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4023
        rho_out[2][2][i]=rho_in[2][2][((i-43)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4024
        rho_out[2][3][i]=rho_in[2][3][((i-25)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4025
        rho_out[2][4][i]=rho_in[2][4][((i-39)+64)% 64];
    end
    // y=3
    for (int i=0; i<64; i++)
    begin: i4031
        rho_out[3][0][i]=rho_in[3][0][((i-41)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4032
        rho_out[3][1][i]=rho_in[3][1][((i-45)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4033
        rho_out[3][2][i]=rho_in[3][2][((i-15)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4034
        rho_out[3][3][i]=rho_in[3][3][((i-21)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4035
        rho_out[3][4][i]=rho_in[3][4][((i-8)+64)% 64];
    end
    // y=4
    for (int i=0; i<64; i++)
    begin: i4041
        rho_out[4][0][i]=rho_in[4][0][((i-18)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4042
        rho_out[4][1][i]=rho_in[4][1][((i-2)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4043
        rho_out[4][2][i]=rho_in[4][2][((i-61)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4044
        rho_out[4][3][i]=rho_in[4][3][((i-56)+64)% 64];
    end
    for (int i=0; i<64; i++)
    begin: i4045
        rho_out[4][4][i]=rho_in[4][4][((i-14)+64)% 64];
    end
    
    // pi
    pi_in     =   rho_out;
    for (int y=0; y<5; y++)
    begin: i3001
        for (int x=0; x<5; x++)
        begin: i3002
            for (int i=0; i<64; i++)
            begin: i3003
                pi_out[(2*x+3*y) % 5][0*x+1*y][i]=pi_in[y][x][i];
            end
        end
    end

    // chi
    chi_in    =   pi_out;
    for (int y=0; y<5; y++)
    begin: i0000
        for (int x=0; x<5; x++) 
        begin: i0001
            for (int i=0; i<64; i++)
            begin: i0002
                if (x==3)
                    chi_out[y][x][i]=chi_in[y][x][i] ^ ( ~(chi_in[y][4][i]) & chi_in[y][0][i]);
                else if (x==4)
                    chi_out[y][x][i]=chi_in[y][x][i] ^ ( ~(chi_in[y][0][i]) & chi_in[y][1][i]);
                else
                    chi_out[y][x][i]=chi_in[y][x][i] ^ ( ~(chi_in[y][x+1][i])& chi_in[y][x+2][i]);
            end
        end
    end

    // iota
    iota_in     =   chi_out;
     for (int y = 1; y <= 4; y++) begin
        for (int x = 0; x <= 4; x++) begin
            for (int i = 0; i <= 63; i++) begin
                iota_out[y][x][i] = iota_in[y][x][i];
            end
        end
    end
    
    // Copy iota_in to iota_out for x = 1 to 4, y = 0
    for (int x = 1; x <= 4; x++) begin
        for (int i = 0; i <= 63; i++) begin
            iota_out[0][x][i] = iota_in[0][x][i];
        end
    end
    
    // Apply XOR with round_constant_signal for (0,0)
    // for (int i = 0; i <= 63; i++) begin
    //     iota_out[0][0][i] = iota_in[0][0][i] ^ round_constant_signal[i];
    // end

    /**************RC SIMPLIFIED******************/
    for (int i = 0; i < 64; i++) begin
        // Check if 'i' is in {0, 1, 3, 7, 15, 31, 63}
        if ( (i == 0  && round_constant_signal[0]) ||
             (i == 1  && round_constant_signal[1]) ||
             (i == 3  && round_constant_signal[2]) ||
             (i == 7  && round_constant_signal[3]) ||
             (i == 15 && round_constant_signal[4]) ||
             (i == 31 && round_constant_signal[5]) ||
             (i == 63 && round_constant_signal[6]) ) begin
            // Apply XOR only where required
            iota_out[0][0][i] = iota_in[0][0][i] ^ 1'b1;
        end
        else begin
            iota_out[0][0][i] = iota_in[0][0][i];
        end
    end
    round_out =   iota_out;
end

    
endmodule

