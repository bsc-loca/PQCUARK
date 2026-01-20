################################################################################
## Company: BSC
##
## File: tb_keccak_round.py
## File history:
##      0.0     : 20/02/2025 : Creation
##      <Revision number>: <Date>: <Comments>
##      <Revision number>: <Date>: <Comments>
##
## Description: This file contains the testbench for the keccak module with
#               both VHDL and SV versions. To test the module, 
## 
## Author: Alicia Manuel
##
################################################################################

import cocotb
from cocotb.triggers import Trigger, Timer, ClockCycles, RisingEdge, FallingEdge    
from cocotb import start_soon
import os
from cocotb.clock import Clock
from pathlib import Path
from cocotb.runner import get_runner
import numpy as np
from cocotb.types.array import Array
from cocotb.binary import BinaryValue
import random
import ast
from cocotb.result import TestSuccess, TestFailure

############Configuration Settings############
# Do all tests at one
ALL = 1

# Number of tests to run
NUM_TESTS = 1200

# Function Selection
# 0: Shake128 (Keccak[256])
# 1: Shake256 (Keccak[512])
# 2: SHA3-256 (Keccak[512])
# 3: SHA3-512 (Keccak[1024])
SELECTED_FUNCTION = 0

# Output length for Shake algorithms
OUTPUT_LENGTH = 3072

BUFFER_WIDTH = 512

SIMULATOR = "questa"

################################################

def read_hex_blocks(file_path):
    with open(file_path, "r") as f:
        # Read all lines and remove whitespace
        lines = [line.strip() for line in f.readlines()]
        
        # Remove empty lines
        lines = [line for line in lines if line]
        
        num_blocks = int(lines[0])
        blocks = []
        current_block = []
        counter = 0
        
        # Process remaining lines (skip first line which is block count)
        for line in lines[1:-1]:  # Skip first and last lines
            if line == "-":
                # End of current block
                if current_block:
                    blocks.append(current_block)
                    current_block = []
                    counter += 1
            else:
                # Add hex value to current block
                current_block.append(line)
                # if (counter == 0):
                #     print(f"Current block: {current_block}")
        
        # Check if we have the correct number of blocks
        if len(blocks) != num_blocks:
            raise ValueError(f"Expected {num_blocks} blocks, found {len(blocks)}")
        
        return blocks          

async def count_rising_edges(signal, counter, stop_flag):
    """
    Counts the number of rising edges on the given signal.
    Terminates when stop_flag is set to True.
    """
    while not stop_flag["stop"]:
        await RisingEdge(signal)
        counter["count"] += 1  # Increment the counter in the shared dictionary
        print(f"Rising edge detected. Current count: {counter['count']}")
        await Timer(10, units="ns")  # Optional: Add a small delay

## EL PADDING SE HACE MAS TARDE DEL QUE TOCA
async def absorb_phase(dut, block, rate):
    """
    Handles the absorb phase: sends data, performs permutations, and ensures padding.
    """
    num_absorbs = (len(block) * 512) // rate + 1 # Calculate the number of absorbs required
    absorb_count = {"count": 0}  # Use a dictionary to store the counter
    counter = 0  # Track the current word in the block
    stop_flag = {"stop": False}

    # Start the rising edge counter coroutine
    start_soon(count_rising_edges(dut.permutation_ready, absorb_count, stop_flag))
    print(f"Absorb phase started. Expected absorbs: {num_absorbs}")
    while absorb_count["count"] < num_absorbs or counter < len(block):
        print(f"Absorb count: {absorb_count['count']}, Words sent: {counter}/{len(block)}")
        print(f"Buffer ready: {dut.buffer_ready.value}, Permutation: {dut.perm.value}")
        if dut.buffer_ready.value == 1:
            # Start permutation
            #dut.perm.value = 1
            #await FallingEdge(dut.buffer_ready)
            if (absorb_count["count"] == num_absorbs - 1):
                dut.din_valid.value = 0
                dut.ld_st.value = 2  # PADDING
                await RisingEdge(dut.clk_i)
                dut.perm.value = 1
            if dut.perm == 1 and (counter >= len(block)):
                # Reset the permutation signal
                print("hola")
                dut.perm.value = 0
                await RisingEdge(dut.permutation_ready)
                await RisingEdge(dut.clk_i)
            else:
                dut.perm.value = 1
            await RisingEdge(dut.clk_i)
        else:
            # Send the next word
            if counter < len(block):
                hex_value = int(block[counter], 16)
                dut.din.value = BinaryValue(hex_value, n_bits=512, bigEndian=False)
                dut.din_valid.value = 1
                dut.ld_st.value = 0  # LOAD
                print(f"Sending word {counter}: {block[counter]}")
                counter += 1
            else:
                if (absorb_count["count"] == 0): 
                    dut.perm.value = 1
                # Handle padding phase
                dut.din_valid.value = 0
                dut.ld_st.value = 2  # PADDING
                while absorb_count["count"] < num_absorbs - 1:
                    dut.perm.value = 1
                    await RisingEdge(dut.permutation_ready)
                print("Starting padding phase.")
                dut.ld_st.value = 2  # PADDING
                dut.perm.value = 0
            await RisingEdge(dut.clk_i)

    dut.perm.value = 0
    dut.din_valid.value = 0
    print(f"Last absorb count: {absorb_count['count']}, Words sent: {counter}/{len(block)}")
    # Ensure all permutations are completed
    while absorb_count["count"] < num_absorbs:
        print(f"Absorb count: {absorb_count['count']}, Words sent: {counter}/{len(block)}")
        await RisingEdge(dut.permutation_ready)
        await RisingEdge(dut.clk_i)
    stop_flag["stop"] = True  # Stop the rising edge counter
    print("Absorb phase completed.")


async def squeeze_phase(dut, outlen):
    """
    Handles the squeeze phase: retrieves output data.
    """
    output = ""
    counter = 0
    flag = 0

    # Activate squeeze mode
    dut.ld_st.value = 1  # SQUEEZE
    print("Squeeze phase started.")

    while counter < outlen:
        if dut.dout_valid.value == 1:
            # Read output data
            hex_value = f"{dut.dout.value.integer:0{BUFFER_WIDTH // 4}X}"  # Ensure leading zeros
            #output += hex_value
            output = hex_value + output  # Prepend the hex_value to reverse the order
            print(f"Output word {counter // BUFFER_WIDTH}: {hex_value}")
            counter += BUFFER_WIDTH
            dut.perm.value = 0  # PERMUTE
            flag = 0
        else:
            if (counter > 0 and flag == 0):
                dut.perm.value = 1  # PERMUTE
                flag = 1
            if (dut.perm == 1):
                dut.perm.value = 0
        await RisingEdge(dut.clk_i)

    if (counter > outlen):
        # Adjust the output length
        hex_cars = outlen // 4
        output = output[-hex_cars:]
        print(f"Output length adjusted to {outlen} bits: {output}")
    dut.perm.value = 0  # PERMUTE
    print("Squeeze phase completed.")
    dut.ld_st.value = 3 # RESTART
    return output


@cocotb.test()
async def my_first_test(dut):
    # Initialize clock
    start_soon(Clock(dut.clk_i, 10, units="ns").start())
    reset_n = dut.rst_ni
    reset_n.value = 0

    # Reset the DUT
    await Timer(19, units="ns")
    reset_n.value = 1
    await RisingEdge(dut.clk_i)

    # Get the directory where the script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_file_path = os.path.join(script_dir, "test_vectors", "keccak_in_512.txt")
    read_file_path = os.path.join(script_dir, "test_vectors", "c_keccak_out.txt")

    blocks = read_hex_blocks(input_file_path)

    with open(read_file_path, "r") as f1:
        for i in range(4):
            # Configure function and rate
            if i == 0:
                dut.function_sel.value = 0
                rate = 1344
                outlen = 3072
            elif i == 1:
                dut.function_sel.value = 1
                rate = 1088
                outlen = 2048
            elif i == 2:
                dut.function_sel.value = 2
                rate = 1088
                outlen = 256
            elif i == 3:
                dut.function_sel.value = 3
                rate = 576
                outlen = 512
            else:
                raise TestFailure("Invalid function selection.")

            print(f"Testing function {i} with rate {rate} and output length {outlen}.")
            for block_idx, block in enumerate(blocks):
                print(f"Processing block {block_idx + 1}/{len(blocks)}.")
                dut.start.value = 1
                dut.inlen.value = int(len(block)) * 512
                await RisingEdge(dut.clk_i)
                print(f"Block length: {dut.inlen.value}")
                dut.start.value = 0
                # Absorb phase
                await absorb_phase(dut, block, rate)

                # Squeeze phase
                output = await squeeze_phase(dut, outlen)

                # Compare results
                expected_output = f1.readline().strip()
                if output != expected_output:
                    print(f"Test failed for block {block_idx + 1}.")
                    print(f"Expected: {expected_output}")
                    print(f"Got: {output}")
                    raise TestFailure("Output mismatch.")
                else:
                    print(f"Test passed for block {block_idx + 1}.")


# Function to run the testbench
def test():
    hdl_toplevel_lang = os.getenv("TOPLEVEL_LANG", "verilog") 
    
    sim = os.getenv("SIM", SIMULATOR)
    

    proj_path = Path(__file__).resolve().parent.parent / "sv"
    print("Project root path:", proj_path)

    if (SIMULATOR == "questa"):
        verilog_sources = [proj_path / "keccak_globals.sv",
                       proj_path / "keccak_round.sv",
                       proj_path / "keccak_round_constants_gen_simplified.sv",
                       proj_path / "keccak_buffer.sv",
                       proj_path / "keccak.sv",]
        os.environ["GPI_EXTRA"] = "cocotb.gpi"
        os.environ["WORK"] = "work"  # Ensure work is the library used
        runner = get_runner(sim)
        runner.build(
            verilog_sources=verilog_sources,
            hdl_toplevel= "keccak",
            waves = True,
            always = True
        )

    else:
        verilog_sources = [proj_path / "keccak.sv"]
        runner = get_runner(sim)
        runner.build(
            verilog_sources=verilog_sources,
            hdl_toplevel= "keccak",
            waves = True,
            build_dir="sim_build", 
            build_args=[
                "--relative-includes",
                "--Wno-UNOPTFLAT",
                "--Wno-ALWCOMBORDER"] ## Revisar este warning
            )
    

    runner.test(hdl_toplevel="keccak", test_module="tb_keccak", build_dir="sim_build", waves = True)


if __name__ == "__main__":
    test()

