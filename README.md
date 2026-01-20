# PQCUARK

PQCUARK is a set of hardware accelerators and toolchain support for post-quantum cryptography (PQC) on RISC-V. This repo aggregates RTL, scheme submodules, the binutils patch workflow, and a Sargantana simulation environment.

Related paper: https://eprint.iacr.org/2025/2178

## Index

- [Overview](#overview)
- [Repository structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Initialize submodules](#initialize-submodules)
- [Generate the PQCUARK toolchain](#generate-the-pqcuark-toolchain)
- [Build scheme binaries](#build-scheme-binaries)
- [Run binaries on Sargantana (Verilator)](#run-binaries-on-sargantana-verilator)
- [Cleanup](#cleanup)
- [Notes](#notes)

## Overview

Main flow:

1. Generate and build the RISC-V toolchain with PQCUARK opcodes.
2. Build ML-KEM or ML-DSA binaries.
3. Run them on the Sargantana simulator (Verilator).

## Repository structure

- `interface/` RISC-V interfaces for BFU/Keccak.
- `rtl/` RTL for PQCUARK-NTT and PQCUARK-Keccak.
- `includes/` shared RTL utilities (submodule `pqcuark-common`).
- `schemes/` scheme submodules (ML-KEM and ML-DSA).
- `toolchain/` local clones of `riscv-gnu-toolchain` and PQCUARK binutils.
- `patches/` generated patches (binutils and Sargantana).
- `scripts/` toolchain/Sargantana/run helpers.
- `filelist.f` RTL file list for simulation/lint.

## Prerequisites

- Git access to the remote repositories.
- Usual `riscv-gnu-toolchain` build dependencies.
- Verilator and dependencies for `core_tile` (Sargantana).

## Generate the PQCUARK toolchain

The `toolchain` target clones `riscv-gnu-toolchain`, generates the opcode patch from the PQCUARK binutils fork, and builds the toolchain with a local prefix.

```bash
make toolchain
```

The toolchain is installed at:

```bash
toolchain/gcc-pqcuark
```

Set `GCC_PQCUARK` to build the schemes (use the helper script):

```bash
source schemes/ml-kem/set-env.sh
# or
source schemes/ml-dsa/set-env.sh
```

## Build scheme binaries

Default binaries (PQCUARK):

```bash
make ml-kem-bin
make ml-dsa-bin
```

Output binaries:

- `schemes/ml-kem/out/test_kyber512_pqcuark`
- `schemes/ml-dsa/out/test_dilithium2_pqcuark`

Override test and configuration via variables:

```bash
make ml-kem-bin ML_KEM_TEST=test_kyber768 ML_KEM_CONF=pqcuark
make ml-dsa-bin ML_DSA_TEST=test_dilithium3 ML_DSA_CONF=pqcuark
```

All supported variations:

```bash
# ML-KEM tests (ML_KEM_TEST)
test_kyber512 | test_kyber768 | test_kyber1024
test_speed512 | test_speed768 | test_speed1024

# ML-KEM configurations (ML_KEM_CONF)
nist | pqrv_rv64im | pqrv_rv64imb | pqcuark

# ML-DSA tests (ML_DSA_TEST)
test_dilithium2 | test_dilithium3 | test_dilithium5
test_speed2 | test_speed3 | test_speed5

# ML-DSA configurations (ML_DSA_CONF)
nist | pqrv_rv64im | pqrv_rv64imb | pqcuark
```

## Run binaries on Sargantana (Verilator)

Full flow initializes Sargantana, builds the simulator, and runs a default binary (kyber512_pqcuark, dilithium2_pqcuark):

```bash
make verilator-ml-kem
make verilator-ml-dsa
```

To run a specific binary, pass the same variables to the Verilator targets (they build and then execute the matching output binary name `out/<test>_<conf>`):

```bash
make verilator-ml-kem ML_KEM_TEST=test_kyber768 ML_KEM_CONF=pqcuark
make verilator-ml-dsa ML_DSA_TEST=test_dilithium3 ML_DSA_CONF=pqcuark
```

Useful `RUN_VERILATOR_OPTS` flags (forwarded to `scripts/run_verilator.sh`):

```bash
RUN_VERILATOR_OPTS="-w -d" make verilator-ml-kem
```

Flags:

- `-w` generate a VCD waveform under `output/waves/`.
- `-d` dump a signature file under `output/signature/`.
- `-k` generate a Konata trace under `output/konata/`.
- `-s` run Spike reference execution (requires `SPIKE_PATH`).
- `-c` run cosimulation (`DefaultConfig-sim-cosim` binary).
- `-a "<args>"` append extra arguments to the Verilator invocation.

If you only need to prepare Sargantana or the simulator:

```bash
make sargantana-init
make core-sim
```

## Cleanup

```bash
make clean
```

Individual targets:

```bash
make clean-toolchain
make clean-sargantana
make schemes-clean
```

## Notes

- PQCUARK paper (important): https://eprint.iacr.org/2025/2178
- PQRV code is sourced from: https://github.com/Ji-Peng/PQRV
- NIST reference code is sourced from: https://github.com/pq-crystals/kyber and https://github.com/pq-crystals/dilithium
- `sargantana-init` clones `external/core_tile`, applies PQCUARK/CSR patches, and clones this repo into the Sargantana tree.
- `scripts/run_verilator.sh` supports extra options (`-w`, `-d`, `-k`, `-c`, `-a`).
- The toolchain and Sargantana flows require network access to clone remote repositories.
