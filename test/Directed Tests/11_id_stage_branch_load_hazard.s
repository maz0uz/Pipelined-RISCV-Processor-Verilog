.section .text
.globl _start

# Test 11: ID-stage branch load hazard
# Expected x2=0, x3=2. Branch depends on loaded x1 and must stall before ID compare.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x10, x0, 0x300
    lw    x1, 0(x10)
    beq   x1, x0, taken
    addi  x2, x0, 1        # must be skipped
taken:
    addi  x3, x0, 2
    ecall
