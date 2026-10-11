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
