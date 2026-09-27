\ fsys/fasm/j1b/fasm.4th — one-instruction J1b words, comma at the end.
\ Shared encodings live in j1a. This file adds the J1b ALU and packs
\ two instructions into each output word.

include ../session.4th
16384 fasm-max !
-1 fasm-pack? !
include ../j1a/words.4th

$0900 constant N>>T
$0a00 constant N<<T
$0c00 constant [T]

: rshift, ( -- ) N>>T d-1 alu, ;
: lshift, ( -- ) N<<T d-1 alu, ;
: depths, ( -- ) status T->N d+1 alu, ;
: 2duprshift, ( -- ) N>>T T->N d+1 alu, ;
: dup@, ( -- ) [T] T->N d+1 alu, ;
: @, ( -- ) [T] alu, ;
