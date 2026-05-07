.section .text
.globl _start

# Test 05: I-type ALU and shift instructions
# Expected x3=17, x4=1, x5=1, x6=5, x7=15, x8=10, x9=40, x10=5, x11=0xfffffffc.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x1, x0, 10
    addi  x2, x0, -8
    addi  x3, x1, 7
    slti  x4, x1, 11
    sltiu x5, x1, -1
    xori  x6, x1, 0x0f
    ori   x7, x1, 0x0f
    andi  x8, x1, 0x0f
    slli  x9, x1, 2
    srli  x10, x1, 1
    srai  x11, x2, 1
    ecall
