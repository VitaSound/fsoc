\ fsys/fasm/mcpu/fasm.4th — experimental micro-core. 64 instruction bytes.
\ https://github.com/cpldcpu/MCPU
\ Not a Forth image and not used by the soc task.

include ../session.4th
0 fasm-pack? !
0 fasm-print? !
64 fasm-max !
include words.4th
