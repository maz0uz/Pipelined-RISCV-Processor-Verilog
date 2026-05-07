.section .text
.globl _start

# Test 19: Mixed datapath stress
# Expected x3=7, memory[0x300]=7, x4=7, x5=0, x6=0, x7=0. Covers ALU, store, load, branch, shift, and flush together.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x10, x0, 0x300
    addi  x1, x0, 3
    addi  x2, x0, 4
    add   x3, x1, x2
    sw    x3, 0(x10)
    lw    x4, 0(x10)
    beq   x4, x3, taken
    addi  x5, x0, 99       # must be skipped
taken:
    xor   x6, x3, x4
    slli  x7, x6, 1
    ecall
