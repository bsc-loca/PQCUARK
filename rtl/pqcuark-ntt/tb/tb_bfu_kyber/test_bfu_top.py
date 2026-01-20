import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import numpy as np
import random
import os

QINV = -3327  # Replace with the actual QINV value (verify correctness for your application)
KYBER_Q = 3329  # Replace with the actual KYBER_Q value (verify correctness for your application)
ZETAS_SRAM = bool(os.getenv('ZETAS_SRAM'))

def sign(value, bit_width):
    """
    Convierte un valor entero sin signo (unsigned) a su equivalente con signo (signed).
    
    Args:
        value (int): El valor a convertir.
        bit_width (int): El ancho de bits del número (e.g., 12 para un número de 12 bits).
    
    Returns:
        int: El valor convertido a signed.
    """
    # Verificar si el bit de signo está establecido
    if value & (1 << (bit_width - 1)):
        # Restar 2^bit_width para convertir a signed
        return value - (1 << bit_width)
    return value

def two_c(number, bits):
    if number < 0:
        # Convertir a complemento a 2
        number = (1 << bits) + number
    return number

def print_mul(srcA, srcB):
    mul = sign(srcA,12) * sign(srcB,12)
    complement = two_c(mul,24)
    print(f"{complement} : {hex(complement)}")

zetas = np.array([
    -1044,  -758,  -359, -1517,  1493,  1422,   287,   202,
    -171,   622,  1577,   182,   962, -1202, -1474,  1468,
    573, -1325,   264,   383,  -829,  1458, -1602,  -130,
    -681,  1017,   732,   608, -1542,   411,  -205, -1571,
    1223,   652,  -552,  1015, -1293,  1491,  -282, -1544,
    516,    -8,  -320,  -666, -1618, -1162,   126,  1469,
    -853,   -90,  -271,   830,   107, -1421,  -247,  -951,
    -398,   961, -1508,  -725,   448, -1065,   677, -1275,
    -1103,   430,   555,   843, -1251,   871,  1550,   105,
    422,   587,   177,  -235,  -291,  -460,  1574,  1653,
    -246,   778,  1159,  -147,  -777,  1483,  -602,  1119,
    -1590,   644,  -872,   349,   418,   329,  -156,   -75,
    817,  1097,   603,   610,  1322, -1285, -1465,   384,
    -1215,  -136,  1218, -1335,  -874,   220, -1187, -1659,
    -1185, -1530, -1278,   794, -1510,  -854,  -870,   478,
    -108,  -308,   996,   991,   958, -1460,  1522,  1628
], dtype=np.int16)

# Helper functions
def montgomery_reduce(a: np.int32) -> int:
    mul_qinv = np.int16(a * QINV)
    print(f"mul_qinv={two_c(mul_qinv,16):#x} => {mul_qinv}")
    mul_q = int(mul_qinv)*3329 
    diff = a - mul_q
    print(f"mul_q -> {int(mul_qinv):#x} * 3329 = {two_c(mul_q,64):#x}")
    print(f"diff -> {two_c(a,32):#x} - {two_c(mul_q,32):#x} = {two_c(diff,32):#x}")
    print(f"t -> diff >> 16 = {two_c((diff >> 16), 16):#x}")
    t = (a - int(mul_qinv) * KYBER_Q) >> 16
    print(f"Montgomery reduce: t={two_c(t, 16):#x} => {t}")
    return np.int16(t)

def barrett_reduce(a: np.int16) -> int:
    print(f"a:{two_c(a,16):#x}")
    v = np.int16(((1 << 26) + KYBER_Q // 2) // KYBER_Q)
    # t = ((v * a)) + (1 << 25)) >> 26)
    t = (np.int32(v) * np.int32(a) + (1 << 25)) >> 26
    t = np.int16(t)
    print(f"shift:{two_c(t,16):#x}")
    # t *= KYBER_Q
    t = np.int16(t * KYBER_Q)
    print(f"mult_q= {two_c(t,16):#x}")
    reduced = np.int16(a - t)
    print(f"Barret reduce: a - mul_q = {two_c(a,16):#x} - {two_c(t,16):#x} = {two_c(reduced,16):#x}")
    return reduced 

def fqmul16(a: np.int16, b: np.int16) -> int:
    product = (sign(a & 0xFFFF, 16) * sign(b & 0xFFFF, 16))  # Usa np.int32 para evitar overflow inicial
    print(f"fqmul16 input product=> {two_c(sign(a & 0xFFFF, 16),16):#x} * {two_c(sign(b & 0xFFFF, 16),16):#x} = {two_c(product,32):#x}")
    reduced = montgomery_reduce(product)
    return np.int16(reduced)  # Fuerza el rango de salida a 16 bits


def ntt_butterfly(x: np.int16, y: np.int16, zeta: int):
    t = fqmul16(zeta, y)
    y = np.int16(x - t)
    print(f"sub (y = x - t) y = {x:#x} - {t:#x} = {y}")
    print(f"add (x = x + t) x = {x:#x} + {t:#x}")
    x = np.int16(x + t)
    print(f"={x}")
    # x = barrett_reduce(x)
    # y = barrett_reduce(y)
    return x, y


def intt_butterfly(x: np.int16, y: np.int16, zeta: int):
    t = x 
    print(f"intt_butterfly enter: t => {two_c(t,16):#x} y => {two_c(y,16):#x}")
    x = np.int16(barrett_reduce(np.int16(t + y)))
    print(f"y - t = {two_c(y,16):#x} - {two_c(t,16):#x}")
    y = np.int16(y - t)
    print(f"intt_butterfly mid: zeta=>{two_c(zeta,32):#x} y => {two_c(y,16):#x}")
    y = np.int16(fqmul16(zeta, y))
    print(f"intt_butterfly final: 1=>{two_c(x,16):#x} 2=> {two_c(y,16):#x}")
    return x, y

def modulo_range(value, q):
    """
    Map a 24-bit signed integer value to the range (-q, q),
    ensuring the result is as close to 0 as possible.

    Parameters:
        value (int): The input value (24-bit signed integer).
        q (int): The base of the range (must be positive).

    Returns:
        int: The modulo result within (-q, q), closest to 0.
    """
    if q <= 0:
        raise ValueError("The base 'q' must be positive.")
    
    # Compute the modulo in the range [0, q)
    result = value % q
    
    # Adjust to the range (-q, q)
    if result > q // 2:
        result -= q

    return result

def behavior_ntt_top(srcA_i: np.int32, srcB_i: np.int32, w_i: np.int32):
    print("HW behavior:\n")

    x1 = sign((srcA_i >> 16) & 0xFFF,12)
    print(f"x1: {two_c(x1,12):#x}")

    x2 = sign((srcB_i >> 16) & 0xFFF,12)
    print(f"x2: {two_c(x2,12):#x}")

    y1 = sign((srcA_i) & 0xFFF,12)
    print(f"y1: {two_c(y1,12):#x}")

    y2 = sign((srcB_i) & 0xFFF,12)
    print(f"y2: {two_c(y2,12):#x}")

    w1 = sign((w_i >> 16) & 0xFFF,12)
    print(f"w1: {two_c(w1,12):#x}| {w1}")

    w2 = sign((w_i) & 0xFFF,12)
    print(f"w2: {two_c(w2,12):#x}| {w2}")

    mulh = sign((x2 * w1) & 0xFFFFFF,24) 
    print(f"mulh: {two_c(mulh,24):#x} | {mulh}")

    # mulh = (sign((mulh-2385) & 0xFFFFFF, 24)) if (mulh < 0) else sign(mulh & 0xFFFFFF, 24) 
    # print(f"mulh: {two_c(mulh,24):#x} | {mulh}")

    mul = sign((y2 * w2) & 0xFFFFFF, 24)
    print(f"mul: {two_c(mul,24):#x} | {mul}")

    # mul = (sign((mul-2385) & 0xFFFFFF, 24)) if (mul < 0) else sign(mul & 0xFFFFFF, 24) 
    # print(f"mul: {two_c(mul,24):#x} | {sign(mul,24)}")

    redh = montgomery_reduce(mulh)
    print(f"redh: {mulh} % {KYBER_Q} -> {two_c(redh,16):#x} | {redh}")

    red = montgomery_reduce(mul)
    print(f"red: {mul} % {KYBER_Q} -> {two_c(red,16):#x} | {red}")

    sumh = x1 + sign(redh,12)
    print(f"sumh: {x1} + {sign(redh,12)} = {two_c(sumh,12):#x} | {sumh}")

    sum = y1 + red
    print(f"sum: {y1} + {sign(red,12)} = {two_c(sum,12):#x} | {sum}")

    subh = x1 - sign(redh,12)
    print(f"subh: {x1} - {sign(redh,12)} = {two_c(subh,12):#x} | {subh}")

    sub = y1 - red
    print(f"sub: {y1} - {red} = {two_c(sub,12):#x} | {sub}")

    print(f"out_a:{sumh} | {sum}")
    print(f"out_b:{subh} | {sub}")

def read_hex_file(file_path):
    """
    Read values from a .hex file and return them as a list of integers.
    
    Args:
        file_path (str): The path to the .hex file.
    
    Returns:
        list: A list of integers read from the .hex file.
    """
    values = []
    with open(file_path, 'r') as file:
        for line in file:
            # Remove any whitespace and convert the hex string to an integer
            value = int(line.strip(), 16)
            values.append(value)
    return values

# Example usage

async def init_zeta_sram(dut):
    """
    Initialize the SRAM with the values from the zetas array.
    """
    hex_file_path = os.path.join(os.path.dirname(__file__), 'zetas_kyber.hex')
    print(hex_file_path)
    zetas = read_hex_file(hex_file_path)
    for i, zeta in enumerate(zetas):
        addr = i * 2
        dut.zeta_addr_i.value = int(addr) % 256
        dut.we_zeta_i.value = 1
        dut.selKD_i.value = 1 
        dut.srcB_i.value = int(zeta)
        dut.validSrc_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.validSrc_i.value = 0
    dut.we_zeta_i.value = 0

@cocotb.test()
async def test_bfu_top(dut):
    """
    Test the BFU top module with NTT and InvNTT operations.
    """
    # Apply test cases
    num_tests = 1000  # Number of random test cases

    # Generate a clock on the `clk_i` signal
    cocotb.start_soon(Clock(dut.clk_i, 10, units="ns").start())  # 10ns clock period

    # Reset the DUT
    dut.rstn_i.value = 0        # Assert reset
    dut.flush_i.value = 0       # Flush reset
    dut.srcA_i.value = 0        # Set input srcA_i to 0
    dut.srcB_i.value = 0        # Set input srcB_i to 0
    dut.zeta_addr_i.value = 0      # Set input wX_addr_i to 0
    dut.we_zeta_i.value = 0     # Set input we_zeta_i to 0
    dut.fqmul_i.value = 0      # Default fqmul_i value
    dut.selNTT_i.value = 0      # Default selector
    dut.selKD_i.value = 0       # Default selector
    dut.validSrc_i.value = 0    # Drive input validSrc_i 
    await Timer(20, units="ns") # Wait for reset to propagate
    dut.rstn_i.value = 1        # Deassert reset
    await RisingEdge(dut.clk_i) # Wait for one clock edge
    if ZETAS_SRAM:
        print("SRAM Enabled")
        await init_zeta_sram(dut)
    else:
        print("ROM Enabled")

    for test in range(num_tests):
        # Set Zeta
        selNTT = random.randint(0,1)
        fqmul = random.randint(0,1)
        if (selNTT) :
            zetaA_addr = (test) % 128
            zetaB_addr = (test) % 128
        else :
            zetaA_addr = (test) % 128
            zetaB_addr = (test) % 128
        
        zetaA = zetas[zetaA_addr]
        zetaB = zetas[zetaB_addr]
        print(f"zeta-a: {two_c(zetaA,16):#x}")
        print(f"zeta-b: {two_c(zetaB,16):#x}")

        # Test vectors
        input_data_aL = sign(random.randint(-(1<<15)+1, (1<<15)-1), 15) & 0xFFFF # 16-bit values
        input_data_bH = sign(random.randint(-(1<<15)+1, (1<<15)-1), 15) & 0xFFFF # 16-bit values
        input_data_aH = sign(random.randint(-(1<<15)+1, (1<<15)-1), 15) & 0xFFFF # 16-bit values
        input_data_bL = sign(random.randint(-(1<<15)+1, (1<<15)-1), 15) & 0xFFFF # 16-bit values

        print(f"aL: {two_c(input_data_aL,32):#x}")
        print(f"bH: {two_c(input_data_bH,32):#x}")
        print(f"aH: {two_c(input_data_aH,32):#x}")
        print(f"bL: {two_c(input_data_bL,32):#x}")

        # Expected NTT outputs
        if (fqmul) :
            print(f"Test FQMul")
            expected_ntt_aH = np.int16(sign(fqmul16(np.int16(sign(input_data_aH, 16)), np.int16(sign(input_data_bH, 16))),16))
            expected_ntt_bH = 0
            expected_ntt_aL = np.int16(sign(fqmul16(np.int16(sign(input_data_aL, 16)), np.int16(sign(input_data_bL, 16))),16))
            expected_ntt_bL = 0
        else:
            if (selNTT) : 
                print(f"Test NTT")
                expected_ntt_aH, expected_ntt_bH = ntt_butterfly(input_data_aH, input_data_bH, zetaB)
                expected_ntt_aL, expected_ntt_bL = ntt_butterfly(input_data_aL, input_data_bL, zetaA)
            else :
                print(f"Test InvNTT")
                expected_ntt_aH, expected_ntt_bH = intt_butterfly(input_data_aH, input_data_bH, zetaB)
                expected_ntt_aL, expected_ntt_bL = intt_butterfly(input_data_aL, input_data_bL, zetaA)


        # Combine input data into 24-bit words
        srcA_input = (input_data_aH << 16) | (input_data_aL & 0xFFFF)
        srcB_input = (input_data_bH << 16) | (input_data_bL & 0xFFFF)
        if ZETAS_SRAM:
            w_input    = ((zetaB_addr*2 & 0xFF) << 8 | zetaA_addr*2 & 0xFF)
        else:
            w_input    = ((zetaB_addr & 0xFF) << 8 | zetaA_addr & 0xFF)

        # behavior_top(srcA_input, srcB_input, w_input)

        #Set module inputs
        dut.validSrc_i.value = 1                # Drive input validSrc_i 
        dut.srcA_i.value = srcA_input           # Drive input src_i
        dut.srcB_i.value = srcB_input           # Drive input src_i
        dut.fqmul_i.value = fqmul             # Drive input fqmul_i
        dut.selNTT_i.value = selNTT             # Drive selector input
        dut.selKD_i.value = 1                   # Drive selector input
        dut.zeta_addr_i.value = w_input      # Drive zeta_addr_i 
        await RisingEdge(dut.clk_i)             # Wait for clock edge
        dut.validSrc_i.value = 0                # Drive input validSrc_i 

        await RisingEdge(dut.validResult_o)

        await Timer(1, units='ns')
        # Check results
        dut_resA_output_aH = (dut.resultA_o.value.signed_integer) >> 16
        dut_resA_output_aL = sign(dut.resultA_o.value.signed_integer & 0xFFFF, 16)
        dut_resA_output_bH = (dut.resultB_o.value.signed_integer) >> 16
        dut_resA_output_bL = sign(dut.resultB_o.value.signed_integer & 0xFFFF,16)
        assert dut_resA_output_aL == expected_ntt_aL, (
            f"Test {test} failed for aL. \n"
            f"dut_resA_output_aL={expected_ntt_aL}, but got {dut_resA_output_aL} \n"
            f"dut_resA_output_bH={expected_ntt_bH}, but got {dut_resA_output_bH} \n"
            f"dut_resA_output_aH={expected_ntt_aH}, but got {dut_resA_output_aH} \n"
            f"dut_resA_output_bL={expected_ntt_bL}, but got {dut_resA_output_bL} \n"
        )
        assert dut_resA_output_aH == expected_ntt_aH, (
            f"Test {test} failed for aH. \n"
            f"dut_resA_output_aL={expected_ntt_aL}, but got {dut_resA_output_aL} \n"
            f"dut_resA_output_bH={expected_ntt_bH}, but got {dut_resA_output_bH} \n"
            f"dut_resA_output_aH={expected_ntt_aH}, but got {dut_resA_output_aH} \n"
            f"dut_resA_output_bL={expected_ntt_bL}, but got {dut_resA_output_bL} \n"
        )
        assert dut_resA_output_bH == expected_ntt_bH, (
            f"Test {test} failed for bH. \n"
            f"dut_resA_output_aL={expected_ntt_aL}, but got {dut_resA_output_aL} \n"
            f"dut_resA_output_bH={expected_ntt_bH}, but got {dut_resA_output_bH} \n"
            f"dut_resA_output_aH={expected_ntt_aH}, but got {dut_resA_output_aH} \n"
            f"dut_resA_output_bL={expected_ntt_bL}, but got {dut_resA_output_bL} \n"
        )
        assert dut_resA_output_bL == expected_ntt_bL, (
            f"Test {test} failed for bL. \n"
            f"dut_resA_output_aL={expected_ntt_aL}, but got {dut_resA_output_aL} \n"
            f"dut_resA_output_bH={expected_ntt_bH}, but got {dut_resA_output_bH} \n"
            f"dut_resA_output_aH={expected_ntt_aH}, but got {dut_resA_output_aH} \n"
            f"dut_resA_output_bL={expected_ntt_bL}, but got {dut_resA_output_bL} \n"
        )
        print(f"dut_resA_output_aL={expected_ntt_aL}, but got {dut_resA_output_aL} \n")
        print(f"dut_resA_output_bH={expected_ntt_bH}, but got {dut_resA_output_bH} \n")
        print(f"dut_resA_output_aH={expected_ntt_aH}, but got {dut_resA_output_aH} \n")
        print(f"dut_resA_output_bL={expected_ntt_bL}, but got {dut_resA_output_bL} \n")

        dut._log.info(f"PASS Test {test}")

        while dut.validResult_o.value:
            await RisingEdge(dut.clk_i)
        

    # Final message
    dut._log.info("All test cases passed!")
