test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    # Note that one/two/eight are data labels
    lw  x1, threshold # X1 <- 0x40
    lui  x2, 2       # X2 <= 0x2000
    srli x2, x2, 12  # X2 <= 2
    addi x2, x2, 10   # X2 <= 12, 0xc
    add x2, x2, x2   # X2 <= 24 , 0x18
    add x2, x2, x2   # X2 <= 48, 0x30

    addi x3, x2, 1 # X3 <= 0x31
    lw  x4, threshold # X4 <- 0x40
    lbu x5, bad
    la x7, result
    sw  x5, 0(x7)
    lw  x6, result
    bltu x0, x6, _start


halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

.section .rodata

bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x600d600d
