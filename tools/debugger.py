#!/usr/bin/env python3
"""
debugger.py  —  Interactive Console Debugger for the 8-bit Pipelined CPU

Communicates with the Verilog simulation via two shared files:
  cmd.txt    (Python writes)  → [halt_bit] [step_bit] [reg_address]
  status.txt (Verilog writes) → current value of the requested register (hex)

Commands
--------
  halt          Pause the CPU (assert debug_halt)
  run           Resume free-running mode (de-assert debug_halt)
  step          Advance exactly one pipeline step while halted
  show <N>      Read register R<N>  (N = 0-7)
  show all      Dump all 8 registers
  help          Print this help message
  quit / exit   Exit the debugger
"""

import sys
import time

CMD_FILE    = "cmd.txt"
STATUS_FILE = "status.txt"


def send_cmd(halt: int, step: int, reg: int) -> None:
    """Write a command to cmd.txt for the Verilog testbench to read."""
    with open(CMD_FILE, "w") as f:
        f.write(f"{halt} {step} {reg}")


def read_status() -> str:
    """Read the register value that Verilog wrote back to status.txt."""
    time.sleep(0.05)
    try:
        with open(STATUS_FILE, "r") as f:
            val = f.read().strip()
        return val if val else "??"
    except FileNotFoundError:
        return "??"


def cmd_halt() -> None:
    send_cmd(1, 0, 0)
    print("  CPU halted.")


def cmd_run() -> None:
    send_cmd(0, 0, 0)
    print("  CPU running.")


def cmd_step() -> None:
    send_cmd(1, 1, 0)
    time.sleep(0.1)
    send_cmd(1, 0, 0)
    print("  Stepped one cycle.")


def cmd_show(reg_str: str) -> None:
    if reg_str.lower() == "all":
        print("  +---------+------------+")
        print("  | Register|   Value    |")
        print("  +---------+------------+")
        for i in range(8):
            send_cmd(1, 0, i)
            val = read_status()
            print(f"  |   R{i}    |   0x{val.upper():<6}|")
        print("  +---------+------------+")
    else:
        try:
            reg_num = int(reg_str)
            if not (0 <= reg_num <= 7):
                raise ValueError
        except ValueError:
            print(f"  Error: register must be 0-7 or 'all', got '{reg_str}'")
            return
        send_cmd(1, 0, reg_num)
        val = read_status()
        print(f"  R{reg_num} = 0x{val.upper()}")


def main() -> None:
    print("+===========================================+")
    print("|   8-bit Pipelined CPU  - Debugger        |")
    print("|   Type 'help' for available commands     |")
    print("+===========================================+")
    print()

    # Start halted so the user can step through from the beginning
    send_cmd(1, 0, 0)

    while True:
        try:
            raw = input("dbg>> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n  Exiting debugger.")
            break

        if not raw:
            continue

        parts = raw.split()
        op    = parts[0].lower()

        if op == "halt":
            cmd_halt()
        elif op == "run":
            cmd_run()
        elif op == "step":
            cmd_step()
        elif op == "show":
            if len(parts) < 2:
                print("  Usage: show <reg_num | all>")
            else:
                cmd_show(parts[1])
        elif op in ("help", "?"):
            print(__doc__)
        elif op in ("quit", "exit", "q"):
            print("  Exiting debugger.")
            break
        else:
            print(f"  Unknown command '{op}'. Type 'help' for a list.")


if __name__ == "__main__":
    main()
