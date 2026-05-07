.section .text
.globl _start

# Test 04: R-type ALU instructions
# Expected x4=17, x5=7, x6=384, x7=1, x8=0, x9=9, x10=0, x11=0xffffffff, x12=13, x13=4.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x1, x0, 12
    addi  x2, x0, 5
    addi  x3, x0, -8
    add   x4, x1, x2
    sub   x5, x1, x2
    sll   x6, x1, x2
    slt   x7, x3, x2
    sltu  x8, x3, x2
    xor   x9, x1, x2
    srl   x10, x1, x2
    sra   x11, x3, x2
    or    x12, x1, x2
    and   x13, x1, x2
    ecall
