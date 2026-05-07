.section .text
.globl _start

# Test 02: JAL and JALR control flow
# Expected: x1=4, x2=24, x3=16, x4=44, x5=0, x6=0.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    jal   x1, target_jal
    addi  x5, x0, 1        # must be flushed/skipped
target_jal:
    addi  x2, x0, target_jalr
    jalr  x3, 0(x2)
    addi  x6, x0, 6        # must be flushed/skipped
    nop
target_jalr:
    addi  x4, x0, 44
    ecall
