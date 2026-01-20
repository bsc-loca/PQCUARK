# PQCUARK-NTT

Pipelined Butterfly Functional Unit (BFU) for Number Theoretic Transform (NTT) and inverse NTT operations used in PQC schemes. The design targets Kyber and Dilithium arithmetic with selectable modes and a shared twiddle-factor ROM/SRAM interface.

## Overview

- Top-level module: `bfu_top`
- Modes: Kyber (16+16-bit packed) and Dilithium (32-bit)
- Operations: NTT/InvNTT butterflies, fqmul, modular reduction (Montgomery/Barrett)
- Twiddle factors: ROM or SRAM-backed (compile-time switch)

## Repository layout

- `src/rtl` RTL sources for arithmetic units, ROM/SRAM, and pipelines
- `tb` Cocotb-based testbenches (Kyber, Dilithium, multiplier, reduction)
- `scripts` Lint scripts (SpyGlass)
- `filelist.f` RTL file list for lint/synthesis

## Simulation (Cocotb)

Kyber BFU tests (Questa or Verilator):

```bash
cd rtl/src/pqcuark-ntt/tb/tb_bfu_kyber
make SIM=questa
# or
make SIM=verilator
```

Dilithium BFU tests:

```bash
cd rtl/src/pqcuark-ntt/tb/tb_bfu_dilithium
make SIM=questa
```

Notes:
- Requires `cocotb` and a supported simulator (Questa or Verilator).
- Verilator uses `zetas_rom.sv`; Questa flow uses SRAM macros via `+define+ZETAS_SRAM`.

## Lint (SpyGlass)

```bash
cd rtl/src/pqcuark-ntt
./scripts/lint_spyglass.sh
```

## Twiddle factor data

Twiddle hex files live in `src/rtl/twiddle_factor_rom`. To regenerate:

```bash
cd rtl/src/pqcuark-ntt/src/rtl/twiddle_factor_rom
python3 gen_hex.py
```

This updates:
- `zetas_kyber.hex`
- `zetas_dilithium.hex`
- `zetas.hex` (merged file)

## Top-level interface

`bfu_top` exposes:
- mode selects: `selKD_i` (Kyber/Dilithium), `selNTT_i` (NTT/InvNTT)
- operands: `srcA_i`, `srcB_i`
- twiddle addressing: `zeta_addr_i` (+ optional SRAM write)
- valid/flush control and pipelined outputs

Refer to `src/rtl/bfu_top.sv` for signal timing and pipeline behavior.
