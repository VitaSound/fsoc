\ fsys/fasm/avr/at89c52.4th — AT89C52 chip definitions.
\ Auto-generated from ISA spec. DO NOT EDIT MANUALLY.

include avr/words.4th

\ Variant-specific register addresses.
$87 constant PCON
$88 constant TCON
$89 constant TMOD
$8A constant TL0
$8B constant TL1
$8C constant TH0
$8D constant TH1
$90 constant P1
$98 constant SCON
$99 constant SBUF
$A8 constant IE
$B0 constant P3
$D0 constant PSW
$E0 constant ACC
$F0 constant B

\ Memory configuration.
8192 constant FLASH
256 constant RAM
0 constant XRAM
