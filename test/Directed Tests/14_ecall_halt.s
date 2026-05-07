.section .text
.globl _start

# Test 14: ECALL halt
# Expected PC stops at/after ECALL and x2 remains 0.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x1, x0, 1
    ecall
    addi  x2, x0, 99       # must not execute
