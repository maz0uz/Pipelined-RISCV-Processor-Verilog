.section .text
.globl _start

# Test 10: ID-stage branch ALU forwarding
# Expected x3=0, x4=7. Branch compares x1/x2 through ID-stage forwarding.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x1, x0, 5
    addi  x2, x0, 5
    beq   x1, x2, taken
    addi  x3, x0, 99       # must be skipped
taken:
    addi  x4, x0, 7
    ecall
