.section .text
.globl _start

# Test 03: All branch conditions
# Expected: x10-x15 remain 0, x16=99.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x1, x0, 5
    addi  x2, x0, 5
    addi  x3, x0, -1
    addi  x4, x0, 1
    beq   x1, x2, 1f
    addi  x10, x0, 127     # fail if executed
1:
    bne   x1, x4, 2f
    addi  x11, x0, 127     # fail if executed
2:
    blt   x3, x4, 3f       # signed -1 < 1
    addi  x12, x0, 127
3:
    bge   x4, x3, 4f       # signed 1 >= -1
    addi  x13, x0, 127
4:
    bltu  x4, x3, 5f       # unsigned 1 < 0xffffffff
    addi  x14, x0, 127
5:
    bgeu  x3, x4, 6f       # unsigned 0xffffffff >= 1
    addi  x15, x0, 127
6:
    addi  x16, x0, 99
    ecall
