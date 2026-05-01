#!/bin/bash
# ============================================================
#  run_debug.sh  —  Launch interactive debug session
#
#  This starts the Verilog simulation in the background, then
#  opens the Python debugger console in the foreground.
#
#  The two processes communicate via two text files:
#    cmd.txt    — Python  → Verilog  (commands)
#    status.txt — Verilog → Python   (register readback)
#
#  Usage: ./run_debug.sh [path/to/program.asm]
# ============================================================
set -e

ASM_FILE="${1:-../programs/demo.asm}"
PROG_TXT="../rtl/program.txt"
SIM_OUT="cpu_sim_debug"

echo "============================================="
echo " 8-bit Pipelined CPU  —  Interactive Debugger"
echo "============================================="

# 1. Assemble
echo "[1/3] Assembling: $ASM_FILE"
python3 ../tools/assembler.py "$ASM_FILE" "$PROG_TXT"

# 2. Compile debug build (uses top_piplined_debug.v + top_debug_tb.v)
echo "[2/3] Compiling Verilog (debug build)..."
iverilog -o "$SIM_OUT" \
    ../rtl/top_piplined.v \
    ../rtl/control_unit.v \
    ../rtl/alu.v \
    ../rtl/pc.v \
    ../rtl/register_file.v \
    ../rtl/data_mem.v \
    ../rtl/instruction_mem.v \
    top_debug_tb.v

# 3. Initialise IPC files
echo ""  > cmd.txt
echo ""  > status.txt

# 4. Launch simulation in the background
echo "[3/3] Launching simulation..."
vvp "$SIM_OUT" &
SIM_PID=$!
echo "      Simulation PID: $SIM_PID"
sleep 0.3   # Give vvp time to start and open the files

# 5. Open the Python debugger console (foreground)
echo ""
echo "--- Debugger console ready. Type 'help' for commands. ---"
echo ""
python3 ../tools/debugger.py

# 6. When the user exits the debugger, kill the simulation
echo ""
echo "Shutting down simulation (PID $SIM_PID)..."
kill "$SIM_PID" 2>/dev/null || true
echo "Done."
