/* myasm.S  the actual module logic in x86-64 assembly
* Called from mymod_main.c. Uses the Linux x86-64 SysV calling convention.
*/

.intel_syntax noprefix
.section .rodata
hello_msg:
 .asciz "hello from assembly: init\n "
exit_msg:
 .asciz "bye from assembly: exit\n"


.text
/* int my_asm_init(void) runs when insmod load the module */
.global my_asm_init

my_asm_init:
    push rbp
    mov rbp,rsp
    lea rdi, [rip + hello_msg]
    call _printk
    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret

.size my_asm_init, . - my_asm_init

/* void my_asm_exit(void) runs when the rmmod unload the module */
.global my_asm_exit
my_asm_exit:
    push rbp
    mov rbp, rsp
    lea rdi, [rip + exit_msg]
    call _printk
    mov rsp, rbp
    pop rbp
    ret
.size my_asm_exit, . - my_asm_exit
