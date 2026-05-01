# Debugger Architecture

## Overview

The interactive debugger lets you pause, step, and inspect the CPU state **while the Verilog simulation is running**, without stopping and recompiling.

It works by having Python and Verilog communicate through two plain text files acting as a shared-memory IPC channel.

---

## System Diagram

```
  ┌─────────────────────────┐          ┌──────────────────────────────┐
  │     debugger.py         │          │     top_debug_tb.v           │
  │   (Python Console)      │          │   (Verilog Testbench)        │
  │                         │          │                              │
  │  dbg>> halt             │          │  forever begin               │
  │  dbg>> step             │  writes  │    @(posedge clk);           │
  │  dbg>> show 3           │─────────▶│    $fscanf(cmd.txt, ...)     │
  │                         │  cmd.txt │    debug_halt ← halt_bit     │
  │                         │          │    step_btn   ← step_bit     │
  │                         │          │    debug_reg  ← reg_addr     │
  │                         │          │                              │
  │  R3 = 0x0F   ◀──────────│          │    $fdisplay(status.txt,     │
  │                         │ reads    │      debug_data)             │
  └─────────────────────────┘ status   └──────────────────────────────┘
                               .txt
```

---

## IPC Protocol

### `cmd.txt`  (Python → Verilog)

Written by `debugger.py`, read by `top_debug_tb.v` every clock cycle.

```
Format:  <halt_bit> <step_bit> <reg_address>
Example: 1 0 3
```

| Field        | Width | Meaning                                      |
|--------------|-------|----------------------------------------------|
| `halt_bit`   | 1     | `1` = pause the CPU; `0` = free-run          |
| `step_bit`   | 1     | `1` = advance one pipeline stage (edge)      |
| `reg_address`| 3     | Which register to expose on `debug_data` bus |

### `status.txt`  (Verilog → Python)

Written by `top_debug_tb.v` after every command read. Contains the current value of the register selected by `reg_address`, in lowercase hex.

```
Example: 0f
```

---

## Debug Signals in RTL

### `top_piplined.v` additions

| Port               | Direction | Purpose                                      |
|--------------------|-----------|----------------------------------------------|
| `debug_halt`       | input     | Freezes `pipeline_en`; stops IF/ID and ID/EX registers from advancing |
| `external_step_btn`| input     | Single-cycle pulse advances the pipeline by one stage |
| `debug_reg [2:0]`  | input     | Selects which register to read out           |
| `debug_data [7:0]` | output    | Value of the selected register               |

### Step-pulse edge detection

```verilog
reg step_prev;
always @(posedge clk) step_prev <= external_step_btn;
wire step_pulse = external_step_btn && !step_prev;
wire pipeline_en = !debug_halt || step_pulse;
```

`step_pulse` is a single-cycle strobe derived from the rising edge of `external_step_btn`. This means even if Python holds `step_bit = 1` for many simulation cycles (due to the `sleep(0.1)`), the pipeline only advances **once**.

### `register_file.v` additions

A dedicated read port driven by `debug_reg` outputs to `debug_data`, bypassing the normal read-port arbitration. This is read-only and does not affect program execution.

---

## Debugger Commands

| Command      | Action                                                  |
|--------------|---------------------------------------------------------|
| `halt`       | Assert `debug_halt`; CPU freezes after current stage   |
| `run`        | De-assert `debug_halt`; CPU resumes free-running       |
| `step`       | Pulse `step_bit` high then low; advances one stage     |
| `show <N>`   | Read and print register R*N* (0–7)                      |
| `show all`   | Print all 8 registers in a table                       |
| `help`       | Show command reference                                  |
| `quit`       | Exit the Python console                                 |

---

## Limitations & Known Behaviour

- **Polling latency** — the testbench reads `cmd.txt` once per clock cycle. At the simulated 100 MHz clock (`#0.005` half-period), this is essentially instantaneous relative to Python's I/O, but there is always at least one clock of lag.
- **`show` requires `halt`** — reading registers while the CPU is running gives a snapshot from one arbitrary clock edge. Always `halt` before inspecting state.
- **No breakpoint support** — the current architecture has no address-compare logic; breakpoints would require adding a `debug_pc` input and comparator in `top_piplined.v`.
- **`status.txt` race** — if Python reads `status.txt` before Verilog has written the new value, it sees the previous result. The `time.sleep(0.05)` in `debugger.py` is a soft guard; reduce simulation time precision if you see stale reads.
