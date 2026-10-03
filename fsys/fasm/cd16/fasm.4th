\ fsys/fasm/cd16/fasm.4th — CD16 host assembler. 65536 instruction words.
\ Brad Eckert, CD16/CD16.VHD revision 6. Comma words for the fsys image.

include ../session.4th
fasm-plain
0 fasm-pack? !
0 fasm-print? !
65536 fasm-max !
include words.4th
