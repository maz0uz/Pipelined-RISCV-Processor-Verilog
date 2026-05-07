.section .text
.globl _start

# Test 06: Loads and stores edge cases
# Expected x2=0xffffff80, x3=0x80, x5=0xffffff80, x6=0xff80, x8=0x12345678; memory[0x308]=0x12345678.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x10, x0, 0x300
    addi  x1, x0, -128
    sb    x1, 0(x10)
    lb    x2, 0(x10)
    lbu   x3, 0(x10)
    addi  x4, x0, -128
    sh    x4, 4(x10)
    lh    x5, 4(x10)
    lhu   x6, 4(x10)
    li    x7, 0x12345678
    sw    x7, 8(x10)
    lw    x8, 8(x10)
    ecall
