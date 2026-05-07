.section .text
.globl _start

# Test 13: JALR target bit zero masking
# Expected x2=8, x3=0, x4=7. Target (23+1)&~1 = 24.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x1, x0, 23
    jalr  x2, 1(x1)        # target becomes 24
    addi  x3, x0, 99       # must be skipped
    nop
    nop
    nop
    addi  x4, x0, 7
    ecall
