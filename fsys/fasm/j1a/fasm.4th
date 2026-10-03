\ fsys/fasm/j1a/fasm.4th — one-instruction J1a words, comma at the end.

include ../session.4th
fasm-plain
4096 fasm-max !
0 fasm-pack? !
include words.4th

\ J1a ALU slots. On j1b these opcodes are shifts and fetch.
$0900 constant T2/
$0a00 constant T2*
$0c00 constant N-T

: -, ( -- ) N-T d-1 alu, ;
: 2/, ( -- ) T2/ alu, ;
: 2*, ( -- ) T2* alu, ;
: depth, ( -- ) status T->N d+1 alu, ;
: hack, ( -- ) T N->io[T] alu, ;
