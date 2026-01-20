################################################################################
## Company: BSC
##
## File: tb_keccak_round.py
## File history:
##      0.0     : 20/02/2025 : Creation
##      <Revision number>: <Date>: <Comments>
##      <Revision number>: <Date>: <Comments>
##
## Description: This file contains the testbench for the keccak_round module with
#               both VHDL and SV versions. To test the module, arbitrary 5x5x64
#               3D arrays and round values are created and assigned to the round_in 
#               and round_constant signals. The testbench waits until the round_out
#               is calculated and then writes the final state by printing the 3D array
#               of bits plane by plane and when desired, compares both states (SV and 
#               VHDL).  
## 
## Author: Alicia Manuel
##
################################################################################

import cocotb
from cocotb.triggers import Trigger, Timer
import os
from pathlib import Path
from cocotb.runner import get_runner
import numpy as np
from cocotb.types.array import Array
from cocotb.binary import BinaryValue
import random
import ast

language = "vhdl"  # Select the language to be tested
num_tests = 2000  # Number of tests to run
comp = 1

num_plane = 5
num_sheet = 5
N = 64 


# Function to convert the 2D array to a 1D bit vector and assign it to the round_in 
# signal for the SV simulation. Note: SystemVerilog signals in cocotb are represented 
# as BinaryValue objects, which are essentially bit vectors
def assign_k_state(dut, array_2d):
    bit_vector = ""
    for plane in array_2d:
        for lane in plane:
            bit_vector += f"{lane:064b}"  # Convert to 64-bit binary
    dut.round_in.value = BinaryValue(bit_vector, n_bits=1600, bigEndian=False)

# Function to compare the states of the VHDL and SV simulations
def compare_states(compare):
    if (compare == 1):
        with open("../test/test_vectors/sv_test.txt", "r") as file1, open("../test/test_vectors/vhdl_test.txt", "r") as file2:
                line_number = 1
                while True:
                    # Read one line from each file
                    line1 = file1.readline()
                    line2 = file2.readline()

                    # Check if both files have reached the end
                    if not line1 and not line2:
                        print("Test passed!")
                        break

                    # Compare the lines
                    if line1 != line2:
                        print(f"Difference at line {line_number}:")
                        print(f"SV: {line1.strip()}")
                        print(f"VHDL: {line2.strip()}")
                        return False

                    line_number += 1

# Testbench for the keccak_round module
@cocotb.test()
async def my_first_test(dut):
    sim = language # Choose the simulation language used for the module
    # Read the files
    with open("../test/test_vectors/arrays.txt", "r") as f1:
        array_rand_list_str = f1.read()  # Read the file content as a string

    with open("../test/test_vectors/round_constants.txt", "r") as f2:
        round_constant_list_str = f2.read()  # Read the file content as a string

    # Convert the string representations into Python lists
    try:
        array_rand_list = ast.literal_eval(array_rand_list_str)  # Convert to list
        round_constant_list = ast.literal_eval(round_constant_list_str)  # Convert to list
    except (SyntaxError, ValueError) as e:
        print(f"Error parsing file contents: {e}")
        exit(1)

    
    if (sim == "verilog"):
        with open("../test/test_vectors/sv_test.txt", "w") as f3:
            for i in range(num_tests):
                array_rand = array_rand_list[i]
                dut.round_constant_signal.value = round_constant_list[i]
                array_2d = Array(array_rand) 
                assign_k_state(dut, array_2d)
                await Timer(10, units="ns")  # Wait to ensure the signal is stable
                value = int(dut.round_out.value)  # Convert packed array to integer
                bit_matrix_sv = np.zeros((num_plane, num_sheet, N), dtype=int)  # Create a 3D NumPy 
                                                                            # array to store the bits
                f3.write(f"Test {i+1}\n")
                # Extract and print the 3D matrix of 0s and 1s
                for y in range(num_plane):
                    for x in range(num_sheet):
                        row = ""
                        for z in range(N):
                            bit_pos = (y * num_sheet * N) + (x * N) + z # Calculate the bit 
                                                                        # position in the integer
                            bit = (value >> bit_pos) & 1 # Extract the bit using bitwise operations
                            row += str(bit) + " "
                        f3.write(row)
                        f3.write("\n")
    else:
        with open("../test/test_vectors/vhdl_test.txt", "w") as f4:
            for i in range(num_tests):
                array_rand = array_rand_list[i]
                dut.round_constant_signal.value = round_constant_list[i]
                dut.round_in.value  = array_rand
                await Timer(10, units="ns")  # Wait to ensure the signal is stable
                bit_matrix_vhdl = np.zeros((num_plane, num_sheet, N), dtype=int)  # Create a 3D NumPy 
                                                                            # array to store the bits
                # Extract and print the 3D matrix of 0s and 1s
                f4.write(f"Test {i+1}\n")
                for y in range(num_plane):
                    for x in range(num_sheet):  # Each row (bit index)
                        row = ""
                        for z in range(N):  # Each column
                            bit = (dut.round_out[y][x][z].value)
                            row += str(bit) + " "  # Append bit with space
                        f4.write(row)
                        f4.write("\n")
    compare_states(comp)


# Function to run the testbench
def test():
    hdl_toplevel_lang = os.getenv("TOPLEVEL_LANG", language) # Select module language to be 
                                                              # tested

    if hdl_toplevel_lang == "vhdl":
        sim = os.getenv("SIM", "questa")
    else:
        sim = os.getenv("SIM", "verilator")
    

    proj_path = Path(__file__).resolve().parent.parent

    verilog_sources = []
    vhdl_sources = []

    if hdl_toplevel_lang == "vhdl":
        vhdl_sources = [proj_path / "vhd" / "work" / "keccak_globals.vhd",
                       proj_path / "vhd" / "work" / "keccak_round.vhd"]
        os.environ["GPI_EXTRA"] = "cocotb.gpi"
        os.environ["WORK"] = "work"  # Ensure work is the library used
        runner = get_runner(sim)
        runner.build(
            verilog_sources=verilog_sources,
            vhdl_sources=vhdl_sources,
            hdl_toplevel= "keccak_round",
            always = True
        )

    else:
        verilog_sources = [proj_path / "sv" / "keccak_round.sv"]
        runner = get_runner(sim)
        runner.build(
            verilog_sources=verilog_sources,
            vhdl_sources=vhdl_sources,
            hdl_toplevel= "keccak_round",
            build_args=[
                "--relative-includes",
                "--Wno-UNOPTFLAT",
                "--Wno-ALWCOMBORDER"], ## Revisar este warning
            always = True)

    

    runner.test(hdl_toplevel="keccak_round", test_module="tb_keccak_round")


if __name__ == "__main__":
    test()