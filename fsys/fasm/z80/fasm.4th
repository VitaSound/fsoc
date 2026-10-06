\ fsys/fasm/z80/fasm.4th — Z80 comma words. One byte per cell, 65536 bytes.

include ../session.4th
fasm-plain
0 fasm-pack? !
0 fasm-print? !
65536 fasm-max !
include words.4th
