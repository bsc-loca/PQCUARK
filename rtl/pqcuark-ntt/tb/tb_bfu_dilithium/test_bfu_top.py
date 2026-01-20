import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import numpy as np
import random
import os

QINV =  58728449 # Replace with the actual QINV value (verify correctness for your application)
Q = 8380417  # Replace with the actual KYBER_Q value (verify correctness for your application)
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

async def init_zeta_sram(dut):
    """
    Initialize the SRAM with the values from the zetas array.
    """
    hex_file_path = os.path.join(os.path.dirname(__file__), 'zetas_dilithium.hex')
    zetas = read_hex_file(hex_file_path)
    for i, zeta in enumerate(zetas):
        addr = i
        dut.zeta_addr_i.value = int(addr) % 256
        dut.we_zeta_i.value = 1
        dut.selKD_i.value = 0
        dut.srcB_i.value = int(zeta)
        dut.validSrc_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.validSrc_i.value = 0
    dut.we_zeta_i.value = 0

zetas = np.array([
    0,        25847,    -2608894, -518909,  237124,   -777960,  -876248,
    466468,   1826347,  2353451,  -359251,  -2091905, 3119733,  -2884855,
    3111497,  2680103,  2725464,  1024112,  -1079900, 3585928,  -549488,
    -1119584, 2619752,  -2108549, -2118186, -3859737, -1399561, -3277672,
    1757237,  -19422,   4010497,  280005,   2706023,  95776,    3077325,
    3530437,  -1661693, -3592148, -2537516, 3915439,  -3861115, -3043716,
    3574422,  -2867647, 3539968,  -300467,  2348700,  -539299,  -1699267,
    -1643818, 3505694,  -3821735, 3507263,  -2140649, -1600420, 3699596,
    811944,   531354,   954230,   3881043,  3900724,  -2556880, 2071892,
    -2797779, -3930395, -1528703, -3677745, -3041255, -1452451, 3475950,
    2176455,  -1585221, -1257611, 1939314,  -4083598, -1000202, -3190144,
    -3157330, -3632928, 126922,   3412210,  -983419,  2147896,  2715295,
    -2967645, -3693493, -411027,  -2477047, -671102,  -1228525, -22981,
    -1308169, -381987,  1349076,  1852771,  -1430430, -3343383, 264944,
    508951,   3097992,  44288,    -1100098, 904516,   3958618,  -3724342,
    -8578,    1653064,  -3249728, 2389356,  -210977,  759969,   -1316856,
    189548,   -3553272, 3159746,  -1851402, -2409325, -177440,  1315589,
    1341330,  1285669,  -1584928, -812732,  -1439742, -3019102, -3881060,
    -3628969, 3839961,  2091667,  3407706,  2316500,  3817976,  -3342478,
    2244091,  -2446433, -3562462, 266997,   2434439,  -1235728, 3513181,
    -3520352, -3759364, -1197226, -3193378, 900702,   1859098,  909542,
    819034,   495491,   -1613174, -43260,   -522500,  -655327,  -3122442,
    2031748,  3207046,  -3556995, -525098,  -768622,  -3595838, 342297,
    286988,   -2437823, 4108315,  3437287,  -3342277, 1735879,  203044,
    2842341,  2691481,  -2590150, 1265009,  4055324,  1247620,  2486353,
    1595974,  -3767016, 1250494,  2635921,  -3548272, -2994039, 1869119,
    1903435,  -1050970, -1333058, 1237275,  -3318210, -1430225, -451100,
    1312455,  3306115,  -1962642, -1279661, 1917081,  -2546312, -1374803,
    1500165,  777191,   2235880,  3406031,  -542412,  -2831860, -1671176,
    -1846953, -2584293, -3724270, 594136,   -3776993, -2013608, 2432395,
    2454455,  -164721,  1957272,  3369112,  185531,   -1207385, -3183426,
    162844,   1616392,  3014001,  810149,   1652634,  -3694233, -1799107,
    -3038916, 3523897,  3866901,  269760,   2213111,  -975884,  1717735,
    472078,   -426683,  1723600,  -1803090, 1910376,  -1667432, -1104333,
    -260646,  -3833893, -2939036, -2235985, -420899,  -2286327, 183443,
    -976891,  1612842,  -3545687, -554416,  3919660,  -48306,   -1362209,
    3937738,  1400424,  -846154,  1976782
], dtype=np.int32)

# Helper functions
def montgomery_reduce(a: np.int64) -> int:
    mul_qinv = np.int64(np.int32(a * QINV))
    print(f"mul_qinv={two_c(mul_qinv,32):#x} => {mul_qinv}")
    mul_q = np.int64(mul_qinv)*Q
    diff = a - mul_q
    print(f"mul_q -> {int(mul_qinv):#x} * Q = {two_c(mul_q,128):#x}")
    print(f"diff -> {two_c(a,64):#x} - {two_c(mul_q,64):#x} = {two_c(diff,64):#x}")
    print(f"t -> diff >> 32 = {two_c((diff >> 32), 32):#x}")
    t = (a - mul_q) >> 32
    print(f"Montgomery reduce: t={two_c(t, 32):#x} => {t}")
    return np.int32(t)

def fqmul32(a: np.int32, b: np.int32) -> int:
    product = (sign(a & 0xFFFFFFFF, 32) * sign(b & 0xFFFFFFFF, 32))  # Usa np.int32 para evitar overflow inicial
    print(f"fqmul input product=> {two_c(sign(a & 0xFFFFFFFF, 32),32):#x} * {two_c(sign(b & 0xFFFFFFFF, 32),32):#x} = {two_c(product,64):#x}")
    reduced = montgomery_reduce(product)
    return np.int32(reduced)  # Fuerza el rango de salida a 16 bits


def ntt_butterfly(x: np.int32, y: np.int32, zeta: np.int32):
    t = fqmul32(zeta, y)
    y = np.int32(x - t)
    print(f"sub (y = x - t) y = {x:#x} - {t:#x} = {y}")
    print(f"add (x = x + t) x = {x:#x} + {t:#x}")
    x = np.int32(x + t)
    print(f"={x:#x}")
    return x, y


def intt_butterfly(x: np.int32, y: np.int32, zeta: int):
    t = x
    print(f"intt_butterfly enter: t => {two_c(t,32):#x} y => {two_c(y,32):#x}")
    x = np.int32(t + y)
    print(f"y - t = {two_c(y,32):#x} - {two_c(t,32):#x}")
    y = np.int32(y - t)
    print(f"intt_butterfly mid: zeta=>{two_c(zeta,32):#x} y => {two_c(y,32):#x}")
    y = np.int32(fqmul32(-zeta, y))
    print(f"intt_butterfly final: 1=>{two_c(x,32):#x} 2=> {two_c(y,32):#x}")
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

    mul = sign((y2 * w2) & 0xFFFFFF, 24)
    print(f"mul: {two_c(mul,24):#x} | {mul}")

    redh = montgomery_reduce(mulh)
    print(f"redh: {mulh} % {Q} -> {two_c(redh,16):#x} | {redh}")

    red = montgomery_reduce(mul)
    print(f"red: {mul} % {Q} -> {two_c(red,16):#x} | {red}")

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
    dut.fqmul_i.value = 0       # Set input fqmul_i to 0
    dut.zeta_addr_i.value = 0   # Set input wX_addr_i to 0
    dut.selKD_i.value = 0       # Set input selKD_i to 0
    dut.selNTT_i.value = 0      # Default selector
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
        zetax_addr = (test) % 256
        zetax = zetas[zetax_addr]

        print(f"zeta-x: {two_c(zetax,32):#x}")

        # Test vectors
        input_data_a = sign(random.randint(-(1<<23)+1, (1<<23)-1), 24) & 0xFFFFFF # 24-bit values
        input_data_b = sign(random.randint(-(1<<23)+1, (1<<23)-1), 24) & 0xFFFFFF # 24-bit values
        selNTT = random.randint(0,1)
        fqmul = random.randint(0,1)

        print(f"a: {two_c(input_data_a,32):#x}")
        print(f"b: {two_c(input_data_b,32):#x}")

        # Expected NTT outputs
        if (fqmul) :
            print(f"Test FQMul")
            expected_ntt_a = np.int32(sign(fqmul32(np.int32(sign(input_data_a, 32)), np.int32(sign(input_data_b, 32))),32))
            expected_ntt_b = 0
        else:
            if (selNTT) :
                print(f"Test NTT")
                expected_ntt_a, expected_ntt_b = ntt_butterfly(input_data_a, input_data_b, zetax)
            else :
                print(f"Test InvNTT")
                expected_ntt_a, expected_ntt_b = intt_butterfly(input_data_a, input_data_b, zetax)

        # Input data 32-bit words
        srcA_input = input_data_a & 0xFFFFFFFF
        srcB_input = input_data_b & 0xFFFFFFFF

        # behavior_top(srcA_input, srcB_input, w_input)

        #Set module inputs
        dut.validSrc_i.value = 1                # Drive input validSrc_i
        dut.srcA_i.value = srcA_input           # Drive input src_i
        dut.srcB_i.value = srcB_input           # Drive input src_i
        dut.selKD_i.value = 0                   # Drive selector input
        dut.selNTT_i.value = selNTT             # Drive selector input
        dut.fqmul_i.value = fqmul                # Drive input fqmul_i
        dut.zeta_addr_i.value = zetax_addr
        await RisingEdge(dut.clk_i)             # Wait for clock edge
        dut.validSrc_i.value = 0                # Drive input validSrc_i

        await RisingEdge(dut.validResult_o)

        await Timer(1, units='ns')
        # Check results
        dut_resA_output_a = (dut.resultA_o.value.signed_integer)
        dut_resB_output_b = (dut.resultB_o.value.signed_integer)
        assert dut_resA_output_a == expected_ntt_a, (
            f"Test {test} failed for a. \n"
            f"Expected output a={expected_ntt_a}, but got {dut_resA_output_a} \n"
            f"Expected output b={expected_ntt_b}, but got {dut_resB_output_b} \n"
        )
        assert dut_resB_output_b == expected_ntt_b, (
            f"Test {test} failed for b. \n"
            f"Expected output a={expected_ntt_a}, but got {dut_resA_output_a} \n"
            f"Expected output b={expected_ntt_b}, but got {dut_resB_output_b} \n"
        )

        dut._log.info(f"PASS Test {test}")

        while dut.validResult_o.value:
            await RisingEdge(dut.clk_i)


    # Final message
    dut._log.info("All test cases passed!")
