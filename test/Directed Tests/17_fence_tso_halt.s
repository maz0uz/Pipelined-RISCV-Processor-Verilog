.section .text
.globl _start

# Test 17: FENCE.TSO halt
# Expected PC stops at/after FENCE.TSO and x2 remains 0.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x1, x0, 1
    fence.tso
    addi  x2, x0, 99       # must not execute
