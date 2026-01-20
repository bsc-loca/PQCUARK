import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

async def run_test_case(dut, srcA, srcB, expected):
    """Applies srcA, srcB, waits for valid result, checks correctness (unsigned)."""
    dut.srcA_i.value = srcA
    dut.srcB_i.value = srcB
    dut.validSrc_i.value = 1
    await RisingEdge(dut.clk_i)
    dut.validSrc_i.value = 0

    while not dut.validResult_o.value:
        await RisingEdge(dut.clk_i)

    # Because in unsigned mode, we read .integer instead of .signed_integer
    got = dut.result_o.value.signed_integer  # Because we expect a signed result
    assert got == expected, (
        f"[SIGNED_MODE=0] srcA={srcA}, srcB={srcB}, expected={expected}, got={got}"
    )

@cocotb.test()
async def test_mul_12x23bit_unsigned(dut):
    """Cocotb test for unsigned 12x23 multiplier (SIGNED_MODE=0)."""
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rstn_i.value = 0
    dut.validSrc_i.value = 0
    dut.srcA_i.value = 0
    dut.srcB_i.value = 0

    # Wait ~2 cycles
    for _ in range(2):
        await RisingEdge(dut.clk_i)
    dut.rstn_i.value = 1
    await RisingEdge(dut.clk_i)

    # Example unsigned test cases
    test_cases = [
        (   0,    0, 0),
        (   5,    7, 35),
        (   10,  10, 100),
        (   10,  -10, -100),
        ( 4095,   1, 4095),   # max 12-bit unsigned
        ( 4095,  100, 4095*100),
        ( 4095,  -100, 4095*(-100)),
    ]
    for a, b, expected in test_cases:
        await run_test_case(dut, a, b, expected)

    dut._log.info("All unsigned test cases passed.")
