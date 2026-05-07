.section .text
.globl _start

# Test 12: x0 hardwired zero
# Expected x0 remains 0 and x2=5.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x0, x0, 123      # must not change x0
    addi  x1, x0, 5
    add   x2, x0, x1
    ecall
