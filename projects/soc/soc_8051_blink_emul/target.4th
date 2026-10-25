\ projects/soc/soc_8051_blink_emul/target.4th — Forth LED loop on the soft R8051 (Verilator emulation).
\
\ Парный проект к projects/soc/soc_8051 (там fsys-консоль): оба — task: soc,
\ target: emulation, cpu: 8051, различие только в опции blink.
\ Работает ТОЛЬКО в эмуляции; Intel HEX для Proteus даёт soc_8051_blink.
\
\ Прошивка: firmware/8051_blink.fs — цикл 0/1 p1! (P1.0 = LED) + dly.
\ Проверка (см. AGENTS.md):
\   FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 fsoc --build
\ В логе: pin led 0 и pin led 1 (каждый ≥ 2 раз).

s" soc" task:
s" emulation" target:
s" 8051" cpu:
s" fsys" sys:
s" blink" s" 1" option:
