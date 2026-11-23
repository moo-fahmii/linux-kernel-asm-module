# Linux Kernel Module in x86-64 Assembly

A minimal Linux kernel module whose init and exit logic are written in x86-64 assembly. 
C is used only for the `module_init`/`module_exit` scaffolding; the functions that run in ring 0 are pure assembly.

## Files

- `mymod_main.c`  module metadata and hooks (`module_init`, `module_exit`)
- `myasm.S`  the `my_asm_init` and `my_asm_exit` functions in Intel-syntax x86-64
- `Makefile`  kbuild integration

## Build

    make

Requires `build-essential` and `linux-headers-$(uname -r)`.

## Test

Terminal 1: `sudo dmesg -w`

Terminal 2:

    sudo insmod mymod.ko
    lsmod | grep mymod
    sudo rmmod mymod

Expected dmesg:

    hello from assembly: init
    bye from assembly: exit

## What it demonstrates

- Calling kernel APIs (`_printk`) from assembly
- RIP-relative addressing (`lea rax, [rip + msg]`)
- x86-64 SysV calling convention in kernel context
- Kbuild integration for `.S` files (`AS [M]` in build output)
- Module load/unload lifecycle (`insmod` `dmesg` `rmmod`)

## Known limitations  RETHUNK mitigation

Modern kernels are built with `CONFIG_RETHUNK=y`  a Spectre v2 / ROP
mitigation that replaces every `ret` in compiled code with a jump to
`__x86_return_thunk`. The `objtool` static analyzer runs on every module
at build time and warns when it sees a bare `ret`:

    warning: objtool: my_asm_init+0x17: 'naked' return found
             in MITIGATION_RETHUNK build

This module **intentionally leaves the bare `ret` in place**, because:

1. The warning is a *hardening* concern, not a *correctness* concern.
   The module loads, runs, and unloads cleanly on a standard Ubuntu kernel.
2. It's a hello-world learning exercise, not production code. The goal is
   understanding the module lifecycle, not exhausting every hardening knob.

The proper fix would use the kernel's linkage macros:

    #include <linux/linkage.h>

    SYM_FUNC_START(my_asm_init)
        ...
        RET                  /* expands to jmp __x86_return_thunk */
    SYM_FUNC_END(my_asm_init)

`SYM_FUNC_START`/`SYM_FUNC_END` handle the prologue, alignment, and (on
IBT-enabled kernels) the `endbr64` instruction; `RET` expands to a jump
through the return thunk. This is how all hand-written kernel `.S` files
are written (`arch/x86/entry/entry_64.S`, `arch/x86/lib/memcpy_64.S`, etc.).

Verifying a fixed version would show no `c3` (ret) bytes in `objdump -d
myasm.o`; instead, `e9` (jmp) with a relocation to `__x86_return_thunk`.

## Notes

- Kernel taints on load  expected for an unsigned out-of-tree module,
  not an error. `/proc/sys/kernel/tainted` will be nonzero after `insmod`.
- Built with `.intel_syntax noprefix`  no libc, no syscalls; the module
  talks to the kernel through its exported symbols directly (`_printk`).
- The C file's `ret` instructions are already RETHUNK-safe because gcc
  compiles with `-mfunction-return=thunk-extern`; only the hand-written
  `.S` file needs explicit attention, and it's documented above.