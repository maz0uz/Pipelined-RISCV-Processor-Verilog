.section .text
.globl _start

# Test 08: Load-use stall
# Expected x1=0x55, x2=0xaa. The ADD must stall until the load value is available.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x10, x0, 0x300
    lw    x1, 0(x10)
    add   x2, x1, x1
    ecall
