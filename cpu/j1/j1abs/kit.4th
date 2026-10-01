\ cpu/j1/j1abs/kit.4th — bit-serial J1a. Same cell and depths as j1a.
\ The wrap file is j1a's. This directory has the core and the stack RAM.

s" j1abs" kit-new
s" j1.v" kit-core
s" stacks.v" kit-stack
s" j1_wrap.v" kit-wrap
16 kit-width
16 kit-insn
15 kit-dsp
17 kit-rsp
4096 kit-ram
