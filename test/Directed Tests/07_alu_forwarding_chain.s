.section .text
.globl _start

# Test 07: ALU forwarding chain
# Expected x1=10, x2=20, x3=30 without inserting NOPs.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x1, x0, 10
    add   x2, x1, x1
    add   x3, x2, x1
    ecall
