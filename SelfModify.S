#include "config.h"
    .text
    .section    .rodata
    .data
    .align  64
BUF: .zero 128                                                          // for cache line
    
    .text
    .global selfModify
    .extern cBuf


    .type selfModify, %function
selfModify:

    push %rbp
    mov %rsp, %rbp
    sub $64, %rsp

/*
    flush cache line
*/
    lea BUF(%rip), %rbx
    mfence
    clflush (%rbx)

/*
    get getting uncached data time
*/
    rdtsc
    mov %eax, %ecx
    mov (%rbx), %eax
    rdtsc
    sub %ecx, %eax
    cmp $THRESHOLD, %eax
    jng EAX0
    mov %eax, -64(%rbp)

    clflush (%rbx)

MODIFY:
#if SELFMODIFY > 0
    mov SELF+3(%rip), %ecx
    add $64, %ecx
    mov %ecx, SELF+3(%rip)                                              // modify code
SELF:
    mov BUF(%rip), %rax                                                 // be modified code
#else
SELF:
#endif
/*
	if no self-modify code , BUF is not cached.
	if have self-modify code , BUF probably has been cached, will significantly widen the gap between the first reading cycles and the second reading cycles.
*/
NEXT:
    rdtsc
    mov %eax, %ecx
    mov (%rbx), %eax
    rdtsc
    sub %ecx, %eax
    cmp $THRESHOLD, %eax
    jg  FAIL
    cmp $0, %eax
    jng FAIL
    sub %eax, -64(%rbp)
    mov -64(%rbp), %eax
    sub $80, %eax                                                       // cache hit and miss differ by about 80
    cmp $0, %eax
    jng FAIL
SUCCESS:
#if SELFMODIFY > 0
    mov SELF+3(%rip), %ecx                                              // recover
    sub $64, %ecx
    mov %ecx, SELF+3(%rip)
    mfence
#endif
    mov $1, %eax                                                        // success return 1
    jmp QUIT
FAIL:
#if SELFMODIFY > 0
    mov SELF+3(%rip), %ecx
    sub $64, %ecx
    mov %ecx, SELF+3(%rip)
    mfence
#endif
EAX0:
    mov $0, %eax                                                        // fail return 0

QUIT:
    mov %rbp, %rsp
    pop %rbp
    ret

    .end
