.section .text
.globl _start

# Test 01: U-type LUI and AUIPC
# Expected: x1=0x12345000, x2=PC(4)+0x00010000=0x00010004.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    lui   x1, 0x12345
    auipc x2, 0x00010
    ecall
