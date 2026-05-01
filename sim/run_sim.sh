#!/bin/bash
# ============================================================
#  run_sim.sh  —  Assemble, compile, and simulate (normal mode)
#  Usage: ./run_sim.sh [path/to/program.asm]
# ============================================================
set -e

ASM_FILE="${1:-../programs/demo.asm}"
PROG_TXT="../rtl/program.txt"
SIM_OUT="cpu_sim"

echo "========================================="
echo " 8-bit Pipelined CPU  —  Normal Sim Mode"
echo "========================================="

echo "[1/3] Assembling: $ASM_FILE"
python3 ../tools/assembler.py "$ASM_FILE" "$PROG_TXT"

echo "[2/3] Compiling Verilog..."
iverilog -o "$SIM_OUT" \
    ../rtl/top_piplined.v \
    ../rtl/control_unit.v \
    ../rtl/alu.v \
    ../rtl/pc.v \
    ../rtl/register_file.v \
    ../rtl/data_mem.v \
    ../rtl/instruction_mem.v \
    top_tb.v

echo "[3/3] Running simulation..."
vvp "$SIM_OUT"

echo ""
echo "Done! Open waveforms with:  gtkwave cpu_sim.vcd &"
