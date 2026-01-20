import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

def to_signed(value, bit_width):
    """
    Convierte un valor entero sin signo (unsigned) a su equivalente con signo (signed).
    
    Args:
        value (int): El valor a convertir.
        bit_width (int): El ancho de bits del número (e.g., 16 para un número de 16 bits).
    
    Returns:
        int: El valor convertido a signed.
    """
    # Verificar si el bit de signo está establecido
    if value & (1 << (bit_width - 1)):
        # Restar 2^bit_width para convertir a signed
        return value - (1 << bit_width)
    return value

def two_complement(number, bits):
    if number < 0:
        # Convertir a complemento a 2
        number = (1 << bits) + number
    return number

def print_twos_complement_as_hex(number, bits=8):
    # Imprimir en hexadecimal
    res = two_complement(number,bits)
    print(f"0x{res:0{bits // 4}X}")

def behavior_mul(a_val: int, b_val: int, sel_val: bool):
    # Calcular el resultado esperado directamente
    if (sel_val):
        A_HSB = to_signed((a_val >> 16) & 0xFFFF, 16)
        B_HSB = to_signed((b_val >> 16) & 0xFFFF, 16)
        A_LSB = to_signed(a_val & 0xFFFF, 16)
        B_LSB = to_signed(b_val & 0xFFFF, 16)
        expected_result = ((A_HSB * B_HSB) << 32) + (A_LSB * B_LSB)
    else:
        expected_result = a_val * b_val#to_signed(a_val & 0xFFFFFF, 32) * to_signed(b_val & 0xFFFFFF, 32)
    print(f"Expected Result (Direct Calculation):")
    print_twos_complement_as_hex(expected_result, 64)

    # Cálculo de d0
    b_32_16 = to_signed((b_val >> 16) & 0xFFFF, 16)
    d0 = b_32_16 if sel_val else to_signed(b_val & 0xFFFFFFFF, 32)
    print("d0:")
    print_twos_complement_as_hex(d0, 32)

    # Extraer y convertir a[32:16]
    a_32_16 = to_signed((a_val >> 16) & 0xFFFF, 16)
    print("a[32:16]:")
    print_twos_complement_as_hex(a_32_16, 32)

    # Calcular m0 y truncar a 35 bits
    m0 = d0 * a_32_16
    m0 = to_signed(m0 & ((1 << 32) - 1), 32) if sel_val else to_signed(m0 & ((1 << 48) - 1), 48)
    print("m0:")
    print_twos_complement_as_hex(m0, 48)

    # Calcular m1 con desplazamiento y truncar
    m1 = (m0 << 32) if sel_val else (m0 << 16)
    # m1 = to_signed(m1 & ((1 << 32) - 1), 32)
    print("m1:")
    print_twos_complement_as_hex(m1, 64)

    # Cálculo de d1
    b_16 = to_signed(b_val & 0xFFFF, 16)
    d1 = b_16 if sel_val else to_signed(b_val & 0xFFFFFFFF, 32)
    print("d1:")
    print_twos_complement_as_hex(d1, 32)

    # Extraer a[15:0]
    a_16 = to_signed(a_val & 0xFFFF, 16)
    print("a[11:0]:")
    print_twos_complement_as_hex(a_16, 32)

    # Calcular m2 y truncar a 47 bits
    m2 = (d1 * a_16) & 0xFFFFFFFF
    # m2 = to_signed(m2 & ((1 << 32) - 1), 32) if sel_val else to_signed(m2 & ((1 << 48) - 1), 48)
    print("m2:")
    print_twos_complement_as_hex(m2, 64)

    # Sumar m1 y m2, truncar a 64 bits
    d = m1 + m2
    d = to_signed(d & ((1 << 64) - 1), 64)  # Truncar a 64 bits
    print(f"d (Algorithm Result): {d:#x}")
    print_twos_complement_as_hex(d, 64)

    # Comparar con el resultado esperado
    if d != expected_result:
        print(f"Discrepancy detected! Algorithm result: {d:#x}, Expected: {expected_result:#x}")
    else:
        print("Results match!")

    return d


@cocotb.test()
async def test_bfu_multiplier(dut):
    """
    Test the 23x23-bit multiplier with a mode selector using random inputs, including negative values.
    """
    # Generate a clock on the `clk_i` signal
    cocotb.start_soon(Clock(dut.clk_i, 10, units="ns").start())  # 10ns clock period

    # Reset the DUT
    dut.rstn_i.value = 0  # Assert reset
    dut.srcA_i.value = 0      # Set input srcA_i to 0
    dut.srcB_i.value = 0      # Set input srcB_i to 0
    dut.selKD_i.value = 0    # Default selector
    dut.validSrc_i.value = 0       # Drive input validSrc_i 
    await Timer(20, units="ns")  # Wait for reset to propagate
    dut.rstn_i.value = 1  # Deassert reset
    await RisingEdge(dut.clk_i)    # Wait for one clock edge

    # Apply random test cases
    for _ in range(1):  # Run 100 random test cases
        a_val = random.randint(-(1<<31), (1<<31)-1)  # Random 32-bit number for srcA_i (including negative values)
        b_val = random.randint(-(1<<31), (1<<31)-1)    # Random 32-bit number for srcB_i (including negative values)
        sel_val = random.randint(0,1)      # Random selector value (0 or 1)
        behavior_mul(a_val, b_val, sel_val)
        if sel_val == 0:
            expected_result = to_signed(a_val & 0xFFFFFFFF,32) * to_signed(b_val & 0xFFFFFFFF,32)
        else:
            upper_result = to_signed((a_val >> 16) & 0xFFFF, 16) * to_signed((b_val >> 16) & 0xFFFF, 16)
            lower_result = to_signed(a_val & 0xFFFF, 16) * to_signed(b_val & 0xFFFF, 16)
            expected_result = to_signed((upper_result << 32),32) + (lower_result & 0xFFFFFFFF)

        dut.validSrc_i.value = 1       # Drive input validSrc_i 
        dut.srcA_i.value = a_val       # Drive input srcA_i
        dut.srcB_i.value = b_val       # Drive input srcB_i
        dut.selKD_i.value = sel_val   # Drive selector input
        await RisingEdge(dut.clk_i)  # Wait for clock edge
        dut.validSrc_i.value = 0       # Drive input validSrc_i 
        await RisingEdge(dut.validResult_o)

        await Timer(1, units='ns')
        # Calculate expected result based on selector value
        # Compare the output with the expected result
        assert dut.result_o.value.signed_integer == expected_result, \
            f"Mismatch: A={two_complement(a_val,32):#x}, B={two_complement(b_val,32):#x}, selKD_i={sel_val}, " \
            f"Expected={two_complement(expected_result,64):#x}, Got={(int(dut.result_o.value)):#x}"

        dut._log.info(f"PASS: A={a_val}, B={b_val}, selKD_i={sel_val}, Result={int(dut.result_o.value.signed_integer)}")

        while dut.validResult_o.value:
            await RisingEdge(dut.clk_i)

    # Final message
    dut._log.info("All random test cases passed!")
