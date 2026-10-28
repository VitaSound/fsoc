\ fsys/fasm/8051/chip.4th — part defaults until a model file runs.

[IFUNDEF] mcs-flash
8192 value mcs-flash
128  value mcs-iram
0    value mcs-xram
2variable mcs-part$
: mcs-part! ( c-addr u -- ) mcs-part$ 2! ;
: mcs-part@ ( -- c-addr u ) mcs-part$ 2@ ;
s" at89c52" mcs-part!
[THEN]
\ Separate from mcs-flash: kernel re-includes fasm; a nested `0 value`
\ here was wiping the hard-Proteus IRAM flag set by cg-8051.
[IFUNDEF] mcs-iram-vm
0 value mcs-iram-vm
[THEN]

\ Feature gates (D2): mul/div and MOVC are MCS-52 / AT89C52 class.
include ../common/isa-feat.4th
[IFUNDEF] mcs-muldiv
$0001 constant mcs-muldiv
$0002 constant mcs-movc
mcs-muldiv feat-define mcs_muldiv
mcs-movc   feat-define mcs_movc
\ Default part is at89c52 — both features on. Smaller cores clear via set-feats.
mcs-muldiv mcs-movc or set-feats
[THEN]
