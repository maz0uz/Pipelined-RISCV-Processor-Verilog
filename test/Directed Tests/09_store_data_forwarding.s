.section .text
.globl _start

# Test 09: Store-data forwarding
# Expected memory[0x300]=0x55 and x2=0x55; store uses freshly produced x1.
# Pass/fail is checked by simulation or FPGA debug registers.
# The program ends with ECALL unless the halt instruction itself is under test.

_start:
    addi  x10, x0, 0x300
    addi  x1, x0, 0x55
    sw    x1, 0(x10)
    lw    x2, 0(x10)
    ecall
