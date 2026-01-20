import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def run_test_case(dut, srcA, srcB, expected):
    """Applies srcA, srcB, waits for valid result, and checks correctness."""
    dut.srcA_i.value = srcA
    dut.srcB_i.value = srcB
    dut.validSrc_i.value = 1
    await RisingEdge(dut.clk_i)
    dut.validSrc_i.value = 0

    # Wait for pipeline to produce a result
    while not dut.validResult_o.value:
        await RisingEdge(dut.clk_i)

    got = dut.result_o.value.signed_integer  # Because we expect a signed result
    assert got == expected, (
        f"[SIGNED_MODE=1] srcA={srcA}, srcB={srcB}, expected={expected}, got={got}"
    )

@cocotb.test()
async def test_mul_12x23bit_signed(dut):
    """Cocotb test for signed 12x23 multiplier (SIGNED_MODE=1)."""
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
    await RisingEdge(dut.clk_i)  # 1 more cycle for safe margin

    # Example signed test cases
    test_cases = [
        (  5,   7,   35),
        ( -5,   7,  -35),
        (  5,  -7,  -35),
        ( -5,  -7,   35),
        (  0,   0,    0),
        (  2,   2,    4),
        (2047,   1, 2047),     # near max positive for 12-bit signed
        (-2048,  1, -2048),    # min negative for 12-bit signed
    ]
    for a, b, expected in test_cases:
        await run_test_case(dut, a, b, expected)

    dut._log.info("All signed test cases passed.")
