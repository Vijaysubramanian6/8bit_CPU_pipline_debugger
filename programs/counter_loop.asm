// counter_loop.asm
// ─────────────────────────────────────────────
// Counts down from 3 to 0, accumulating a sum.
//   R1 = counter  (starts at 3)
//   R2 = sum      (starts at 0)
//   R3 = 1        (constant decrement)
//
// Expected result: R2 = 3 + 2 + 1 = 6
// ─────────────────────────────────────────────

LOADI R1, 3       // R1 = 3  (loop counter)
LOADI R2, 0       // R2 = 0  (accumulator)

ADD   R2, R1      // R2 = R2 + R1      <-- loop top (assembled address 4)
LOADI R3, 1
SUB   R1, R3      // R1 = R1 - 1
JNZ   4           // Jump back if R1 != 0

HALT
