# 8-bit Pipelined CPU with Interactive Debugger

A fully functional **8-bit CPU** implemented in Verilog with a **3-stage pipeline** (IF → ID → EX/WB), a custom **10-instruction ISA**, Harvard memory architecture, a **Python assembler** with automatic hazard NOP insertion, and an **interactive hardware debugger** that lets you halt, step, and inspect registers while the simulation is live.

---

## What's New: The Debugger

The CPU exposes a **debug port** — four extra signals on `top_piplined.v` — that the testbench wires to a file-based IPC bridge. A Python console (`tools/debugger.py`) writes commands to `cmd.txt` and reads register values back from `status.txt`, all while the Verilog simulation runs in the background.

```
  Python Console                    Verilog Simulation
  ──────────────                    ──────────────────
  dbg>> halt          ──cmd.txt──▶  debug_halt  = 1  (pipeline frozen)
  dbg>> step          ──cmd.txt──▶  step_pulse  = 1  (one cycle advance)
  dbg>> show 3        ──cmd.txt──▶  debug_reg   = 3
  R3 = 0x0F          ◀─status.txt─  debug_data = 0x0F
```

See [`docs/debugger_architecture.md`](docs/debugger_architecture.md) for the full protocol, signal definitions, and limitations.

---

## Repository Layout

```
8bit_cpu/
├── rtl/
│   ├── top_piplined.v        # Top-level with debug port (halt/step/inspect)
│   ├── top_piplined_debug.v  # Alternate debug variant
│   ├── control_unit.v        # Instruction decoder
│   ├── alu.v                 # 8-bit ALU
│   ├── pc.v                  # Program counter (debug_halt + step_pulse aware)
│   ├── register_file.v       # 8x8-bit register file + debug_data output port
│   ├── data_mem.v            # 256x8-bit data RAM
│   └── instruction_mem.v     # 256x16-bit instruction ROM
│
├── sim/
│   ├── top_tb.v              # Normal simulation testbench
│   ├── top_debug_tb.v        # Debug testbench (file I/O bridge to Python)
│   ├── run_sim.sh            # One-shot: assemble + compile + simulate
│   └── run_debug.sh          # Launch interactive debug session
│
├── tools/
│   ├── assembler.py          # .asm → program.txt  (with auto NOP insertion)
│   └── debugger.py           # Interactive REPL debugger console
│
├── programs/
│   ├── demo.asm              # ALU + memory test (ADD, MUL, READ, WRITE)
│   └── counter_loop.asm      # JNZ countdown loop
│
├── docs/
│   ├── ISA_reference.md      # Full instruction set, encoding, flags
│   └── debugger_architecture.md  # IPC protocol, signals, limitations
│
└── .gitignore
```

---

## Architecture Overview

```
            +─────────────────────────────────────────────────────+
            │                  top_piplined.v                     │
            │                                                      │
  clk ─────▶│  +────────+  IF/ID  +──────────+  ID/EX            │
  rst ─────▶│  │   PC   │────────▶│ Control  │──────┐            │
            │  +────────+         │  Unit    │      ▼            │
 debug_halt▶│       │             +──────────+  +────────+        │
 step_pulse▶│       ▼                  │        │  ALU   │        │
  debug_reg▶│  +────────+         +──────────+  +────────+        │
            │  │  ROM   │         │ Reg File │      │             │
            │  +────────+         │ (8x8b)   │      ▼             │
            │                     +──────────+  +────────+        │
            │                          │        │  RAM   │        │
            │                          └───────▶│(256x8b)│        │
            │                                   +────────+        │
            │  debug_data ◀──────────────── reg_file.debug_port   │
            +─────────────────────────────────────────────────────+
```

### Pipeline Stages

| Stage | Name       | Modules                                   |
|-------|------------|-------------------------------------------|
| 1     | IF (Fetch) | `program_counter`, `instruction_mem`      |
| 2     | ID (Decode)| `control_unit`, `register_file`           |
| 3     | EX/WB      | `alu`, `data_mem`, register write-back    |

### Debug Control Logic

```verilog
// Edge-detect the step button (single-cycle pulse)
always @(posedge clk) step_prev <= external_step_btn;
wire step_pulse  = external_step_btn && !step_prev;

// Pipeline freezes on halt; one step_pulse advances it by one cycle
wire pipeline_en = !debug_halt || step_pulse;
```

---

## Getting Started

### Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [Icarus Verilog](https://steveicarus.github.io/iverilog/) | Simulation | `sudo apt install iverilog` |
| Python 3.x | Assembler + Debugger | `sudo apt install python3` |
| [GTKWave](http://gtkwave.sourceforge.net/) *(optional)* | Waveform viewer | `sudo apt install gtkwave` |

### Normal simulation (no debugger)

```bash
cd sim
chmod +x run_sim.sh
./run_sim.sh ../programs/demo.asm

# View waveforms
gtkwave cpu_sim.vcd &
```

### Interactive debug session

```bash
cd sim
chmod +x run_debug.sh
./run_debug.sh ../programs/counter_loop.asm
```

This launches the Verilog simulation in the background and opens the Python debugger console:

```
+==========================================+
|  8-bit Pipelined CPU  - Debugger        |
|  Type 'help' for available commands     |
+==========================================+

dbg>> step          # advance one pipeline stage
dbg>> show all      # dump all 8 registers
  +---------+------------+
  | Register|   Value    |
  +---------+------------+
  |   R0    |   0x00     |
  |   R1    |   0x03     |
  |   R2    |   0x00     |
  ...
dbg>> run           # resume free-running
dbg>> halt          # pause again
dbg>> show 2        # inspect a single register
  R2 = 0x06
dbg>> quit
```

### Assembler only

```bash
python3 tools/assembler.py programs/my_program.asm rtl/program.txt
```

---

## Debugger Commands

| Command      | Effect                                           |
|--------------|--------------------------------------------------|
| `halt`       | Freeze the pipeline (`debug_halt = 1`)           |
| `run`        | Resume free-running (`debug_halt = 0`)           |
| `step`       | Advance one pipeline cycle while halted          |
| `show <N>`   | Print register R*N* (0–7)                        |
| `show all`   | Dump all 8 registers                             |
| `help`       | Show command reference                           |
| `quit`       | Exit the debugger console                        |

---

## ISA Quick Reference

| Opcode | Mnemonic | Operation |
|:------:|----------|-----------|
| `0` | LOADI Rd, imm  | `Rd <- imm` |
| `1` | ADD Rd, Rs     | `Rd <- Rd + Rs` |
| `2` | SUB Rd, Rs     | `Rd <- Rd - Rs` |
| `3` | MOV Rd, Rs     | `Rd <- Rs` |
| `4` | READ Rd, addr  | `Rd <- RAM[addr]` |
| `5` | WRITE Rs, addr | `RAM[addr] <- Rs` |
| `6` | JUMP addr      | `PC <- addr` |
| `7` | JNZ addr       | `if (Z==0): PC <- addr` |
| `8` | MUL Rd, Rs     | `Rd <- Rd x Rs` |
| `E` | HALT           | Stop |

Full encoding, flags, and pipeline hazard rules: [`docs/ISA_reference.md`](docs/ISA_reference.md)

---

## Design Notes

- **Harvard architecture** — instruction ROM and data RAM are separate 256-entry address spaces.
- **Hazard handling** — done in software by the assembler (NOP insertion); no forwarding paths in hardware.
- **Debug port is read-only** — `debug_data` taps the register file directly; it cannot write registers. Program state is never corrupted by inspecting it.
- **Reset** — active-low asynchronous reset. All registers, PC, and pipeline registers clear to zero.
- **`cmd.txt` / `status.txt` are runtime files** — listed in `.gitignore`, not committed to the repo.

---

## License

MIT — free to use for learning, coursework, and personal projects.
