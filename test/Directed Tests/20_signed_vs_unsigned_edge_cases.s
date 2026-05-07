.section .text
.globl _start

# Test 20: Signed versus unsigned edge cases
# Expected x3=1, x4=0, x5=99, x6=7 because BLTU x1,x2 is not taken for 0xffffffff < 1.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x1, x0, -1
    addi  x2, x0, 1
    slt   x3, x1, x2       # signed true
    sltu  x4, x1, x2       # unsigned false
    bltu  x1, x2, fail     # should not branch
    addi  x5, x0, 99
fail:
    addi  x6, x0, 7
    ecall
