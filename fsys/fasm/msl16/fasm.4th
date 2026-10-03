\ fsys/fasm/msl16/fasm.4th — MSL16 host assembler. 2048 instruction words.
\ https://web.archive.org/web/20070205070645/http://www.cse.cuhk.edu.hk/~phwl/mt/public/archives/old/msl16/msl16_vhdl.zip
\ The fsys console and the baremetal blink both assemble through this file.

include ../session.4th
fasm-plain
0 fasm-pack? !
0 fasm-print? !
2048 fasm-max !
include words.4th
