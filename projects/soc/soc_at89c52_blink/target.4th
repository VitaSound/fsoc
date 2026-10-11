\ projects/soc/soc_at89c52_blink/target.4th — blink app Intel HEX for Proteus
\ Needs external XRAM from $2000 (see doc/at89c52-proteus.md).

s" soc" task:
s" proteus" target:
s" 8051" cpu:
s" fsys" sys:
s" blink" s" 1" option:
s" xram" s" 8192" option:
