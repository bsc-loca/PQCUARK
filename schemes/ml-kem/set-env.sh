#!/bin/bash

# Absolute path to the project root directory
export ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

export GCC_PQCUARK=$ROOT_DIR/toolchain/gcc-pqcuark

echo "GCC_PQCUARK="$GCC_PQCUARK
