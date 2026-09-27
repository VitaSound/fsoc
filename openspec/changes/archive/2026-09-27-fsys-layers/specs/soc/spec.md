# Spec Delta

## MODIFIED Requirements

### Requirement: Образ собирает кросс-компилятор SwapForth
При пустом `sys:` и при `s" swapforth" sys:` прошивка MUST быть образом SwapForth, собранным Forth-кросс-компилятором из исходников в `swapforth/<id>/`, а не готовым hex и не текстом `j1_prompt`. Сборка MUST загрузить этот образ в память J1. Ядро MUST исполнить его. Байты консоли MUST появиться из этого исполнения. Модуль `j1_prompt` MUST NOT быть их источником. При `s" fsys" sys:` этот абзац MUST NOT требовать образ SwapForth.

#### Scenario: Hex совпадает со сборкой SwapForth
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build` и в `target.4th` нет `sys:`
- **THEN** `firmware.hex` совпадает с выходом сборки SwapForth из `swapforth/j1a`, исходники прошивки остаются Forth-текстом, а в `top.v` нет `j1_prompt`

#### Scenario: fsys не подменяет консоль soc_emul
- **WHEN** временный манифест содержит `s" soc" task:`, `s" emulation" target:`, `s" j1a" cpu:` и `s" fsys" sys:`
- **THEN** `firmware.hex` не совпадает с образом `projects/soc_emul`, собранным без `sys:`

### Requirement: Словарь SwapForth J1a
При пустом `sys:` и при `s" swapforth" sys:` словарь загруженного образа MUST содержать каждое слово ANS CORE, кроме `environment?`. Слова `environment?` в образе MUST NOT требоваться. MUST также быть найдены слова, которые добавляет интерактивный образ J1a: `io@` `io!` `key?` `words` `.s` `.x` `.x2` `nip` `tuck` `-rot` `false` `true` `u>` `within` `erase` `.(` `hex` `marker` `pad` `unused` `see` `dump` `ms` `leds` `new` `.xt` `case` `of` `endof` `endcase` `save-input` `restore-input` `convert` `[compile]`.

ANS CORE, который MUST присутствовать: `!` `#` `#>` `#s` `'` `(` `*` `*/` `*/mod` `+` `+!` `+loop` `,` `-` `.` `."` `/` `/mod` `0<` `0=` `1+` `1-` `2!` `2*` `2/` `2@` `2drop` `2dup` `2over` `2swap` `:` `;` `<` `<#` `=` `>` `>body` `>in` `>number` `>r` `?dup` `@` `abort` `abort"` `abs` `accept` `align` `aligned` `allot` `and` `base` `begin` `bl` `c!` `c,` `c@` `cell+` `cells` `char` `char+` `chars` `constant` `count` `cr` `create` `decimal` `depth` `do` `does>` `drop` `dup` `else` `emit` `evaluate` `execute` `exit` `fill` `find` `fm/mod` `here` `hold` `i` `if` `immediate` `invert` `j` `key` `leave` `literal` `loop` `lshift` `m*` `max` `min` `mod` `move` `negate` `or` `over` `postpone` `quit` `r>` `r@` `recurse` `repeat` `rot` `rshift` `s"` `s>d` `sign` `sm/rem` `source` `space` `spaces` `state` `swap` `then` `type` `u<` `um*` `um/mod` `unloop` `until` `variable` `while` `word` `xor` `[` `[']` `[char]` `]`.

При `s" fsys" sys:` этот список MUST NOT требоваться. Словарь fsys задаёт спецификация `fsys`.

#### Scenario: words печатает словарь
- **WHEN** после рукопожатия загрузки образа SwapForth подана строка `words`
- **THEN** в журнале передачи есть имя каждого слова из этого требования

#### Scenario: Определение с ветвлением
- **WHEN** после рукопожатия образа SwapForth поданы строка `: P 0 if 1 else 2 then . ;` и затем строка `P`
- **THEN** в журнале после второй строки есть байт `2`, пробел и ответ ` ok`

### Requirement: Образ прошивки собирает отдельный шаг
Задача `soc` MUST вызвать один шаг выбранного `sys:` и MUST NOT сама вызывать кросс SwapForth. При пустом `sys:` и при `s" swapforth" sys:` этот шаг MUST создать `firmware.hex` отдельным `feed`, отделённым от интерактивного просмотра: билдер MUST подготовить плоский файл подачи (раскрыв `include` из `swapforth/`), запустить `feed` и получить `firmware.hex` из обёртки. При `s" fsys" sys:` hex MUST записать шаг fsys; подача по UART MUST выполняться только если инструмент оставил Форт, который её принимает. Переменная `FSOC_EMU_SNAPSHOT` MUST NOT использоваться. Интерактивный просмотр MUST только загрузить готовый `firmware.hex`.

#### Scenario: Сборка образа без интерактивного main
- **WHEN** в `projects/soc_blink` выполняется `fsoc --build` и в манифесте нет `sys:`
- **THEN** в каталоге появляются плоский файл подачи, `obj_dir/Vtop_feed` и `firmware.hex` на 4096 строк, а `rg FSOC_EMU_SNAPSHOT fsoc/ emu/ targets/` пусто

#### Scenario: Задача не содержит имя swapforth
- **WHEN** читается слово сборки задачи `soc`
- **THEN** в нём нет литерала `cpu/j1/swapforth` и нет прямого вызова кросса; каталог даёт выбранный `sys:`
