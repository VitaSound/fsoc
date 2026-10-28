\ fsoc/futils/isa_to_fasm.4th — ISA Specification -> FASM Comma Word Generator
\ Port of tools/isa_to_fasm.py — генерирует words.4th и chip-варианты из
\ JSON-спецификации ISA через fjson (forth-packages/fjson/0.2.5/).
\ Паритет с generate_words_4th / generate_chip_4th: байт-в-байт.
\
\ Использование:
\   s" <spec.json>" isa-load-spec            ( -- node|0 )
\   dup 0= abort" spec load failed" drop
\   s" <out>/words.4th" isa-gen-words4th     ( -- )   \ words.4th в файл
\   s" <out>" isa-gen-chip4th                ( -- )   \ <variant>.4th на каждый вариант
\   isa-out isa-out-len @ type               ( -- )   \ содержимое буфера (после emit)
\
\ Правила вывода (как в Python):
\   - Каждая логическая строка заканчивается LF; последняя строка файла — без LF.
\   - words.4th: хедер, регистры, биты, helpers, инструкции, span.
\   - chip: на каждый вариант chip_variants отдельный файл.

\ ------------------------------------------------------------------
\ Зависимости
\ ------------------------------------------------------------------
require ../../forth-packages/fenum/0.1.1/fenum-bs.4th
require ../../forth-packages/fjson/0.2.5/fjson/util.4th
require ../../forth-packages/fjson/0.2.5/fjson/read.4th
require ../../forth-packages/fjson/0.2.5/fjson/node.4th
require ../../forth-packages/fjson/0.2.5/fjson/tree.4th
require ../../forth-packages/fjson/0.2.5/fjson/parse.4th

\ ------------------------------------------------------------------
\ Буферизованный вывод
\ ------------------------------------------------------------------
create isa-out 65536 allot
variable isa-out-len
create o-ch1 1 allot

: o-type ( a u -- )
    dup isa-out-len @ + 65536 u>= abort" isa-out overflow"
    >r isa-out isa-out-len @ + r@ move r> isa-out-len +!
    ;
: o-ch ( c -- ) o-ch1 c! o-ch1 1 o-type ;
: o-cr ( -- ) 10 o-ch ;
: o-space ( -- ) 32 o-ch ;
: o-reset ( -- ) 0 isa-out-len ! ;

: o-hex ( u -- )          \ минимум 2 цифры, полное значение (как %02X)
    base @ >r hex
    dup 0 256 within if s>d <# # # #> else s>d <# #s #> then
    r> base ! o-type
    ;
: o-dec ( u -- )          \ десятичный (как f"{v}")
    base @ >r decimal s>d <# #s #> r> base ! o-type
    ;

create isa-up 256 allot
variable ou-src variable ou-u
: o-upper ( a u -- )      \ ВЕРХНИЙ РЕГИСТР в выход (без мутации спецификации)
    ou-u ! ou-src !
    ou-u @ 0 ?do
        ou-src @ i + c@ dup [char] a [char] z 1+ within if
            [char] a - [char] A + isa-up i + c!
        else
            isa-up i + c!
        then
    loop
    isa-up ou-u @ o-type
    ;

: isa-out-write ( pa pu -- )   \ записать буфер в файл (создаёт/перезаписывает)
    w/o create-file throw >r
    isa-out isa-out-len @ r@ write-file throw
    r> close-file throw
    ;

\ ------------------------------------------------------------------
\ Загрузка спецификации
\ ------------------------------------------------------------------
create isa-buf 8192 allot
variable isa-fid
variable isa-root-node

\ ------------------------------------------------------------------
\ Дробные "bytes" (mсl16: 0.25) fjson не парсит (валидный JSON, но парсер
\ целочисленный). Семантика python не страдает: check сравнивает bytes != 1,
\ и 0, и 0.25 дают один и тот же пропуск (0 != 1 -> skip в gap-цикле).
\ Замена "0.25" -> "0   " (0 + три пробела = whitespace, валидный JSON)
\ сохраняет длину файла и не трогает никакие смещения. 0.25 встречается
\ только в tools/isa_specs/msl16_isa.json и только в поле "bytes" (15 шт.).
\ ------------------------------------------------------------------
variable ic-fba variable ic-fln variable ic-fb variable ic-fe
: isa-fix-dfrac ( a u -- a u )
    ic-fln ! ic-fba !
    ic-fba @ ic-fln @ + ic-fe !
    ic-fba @ ic-fb !
    begin ic-fb @ ic-fe @ 4 - < while
        ic-fb @ c@ [char] 0 = if
            ic-fb @ 1 + c@ [char] . = if
                ic-fb @ 2 + c@ [char] 2 = if
                    ic-fb @ 3 + c@ [char] 5 = if
                        \ "0.25" -> "0   " (первый символ уже '0')
                        bl ic-fb @ 1 + c!
                        bl ic-fb @ 2 + c!
                        bl ic-fb @ 3 + c!
                    then
                then
            then
        then
        1 ic-fb +!
    repeat
    ic-fba @ ic-fln @ ;

: isa-load-spec ( path -- node|0 )
    r/o open-file throw
    isa-fid !
    \ Полное чтение файла: спеки до 55KB, старые 8192 обрезали JSON
    \ (фикстура 3282 байта маскировала баг; big specs → parse failed).
    isa-fid @ file-size throw d>s      \ ( size )
    dup allocate throw                 \ ( size buf )
    2dup swap isa-fid @ read-file throw \ ( size buf n )
    rot drop                           \ ( buf n )
    isa-fix-dfrac                      \ ( buf n ) 0.25 -> "0   " (см. выше)
    fjson.parse
    dup isa-root-node !
    isa-fid @ close-file throw
    ;

\ ------------------------------------------------------------------
\ Доступ к строковому полю JSON: (obj key-a key-u -- a u | 0 0) через rot
\ ------------------------------------------------------------------
: isa-get-str ( obj key-a key-u -- a u | 0 0 )
    rot fjson.object-get
    dup 0= if 2drop 0 0 exit then
    fjson.node-str@
    ;

\ ------------------------------------------------------------------
\ arch / prefix (mcs для mcs51, иначе arch)
\ ------------------------------------------------------------------
create isa-arch 32 allot variable isa-arch-l
create isa-prefix 32 allot variable isa-prefix-l

: isa-set-arch ( a u -- )
    dup isa-arch-l !
    isa-arch swap move
    isa-arch isa-arch-l @ s" mcs51" compare 0= if
        s" mcs"
    else
        isa-arch isa-arch-l @
    then
    dup isa-prefix-l !
    isa-prefix swap move
    ;
: o-prefix ( -- ) isa-prefix isa-prefix-l @ o-type ;
: o-arch ( -- ) isa-arch isa-arch-l @ o-type ;

\ ------------------------------------------------------------------
\ Десятичный разбор строки (ключи битов "0".."7")
\ ------------------------------------------------------------------
variable isa-si variable si-src variable si-u
: isa-str2int ( a u -- u )
    si-u ! si-src !
    0 isa-si !
    si-u @ 0 ?do
        isa-si @ 10 * si-src @ i + c@ [char] 0 - + isa-si !
    loop
    isa-si @
    ;

\ ------------------------------------------------------------------
\ Имя инструкции: stage1 (.-> _ , @-> a , #-> num) -> pad (_ -> -) + суффикс
\ ------------------------------------------------------------------
create isa-mnem1 256 allot variable isa-mnem1-l
variable isa-ni

variable st-src variable st-u
: isa-stage1 ( a u -- )
    st-u ! st-src !
    0 isa-ni !
    st-u @ 0 ?do
        st-src @ i + c@ dup [char] . = if
            drop [char] _ isa-ni @ isa-mnem1 + c! 1 isa-ni +!
        else dup [char] @ = if
            drop [char] a isa-ni @ isa-mnem1 + c! 1 isa-ni +!
        else dup [char] # = if
            drop
            [char] n isa-ni @ isa-mnem1 + c!
            [char] u isa-ni @ 1+ isa-mnem1 + c!
            [char] m isa-ni @ 2 + isa-mnem1 + c!
            3 isa-ni +!
        else
            isa-ni @ isa-mnem1 + c! 1 isa-ni +!
        then then then
    loop
    isa-ni @ isa-mnem1-l !
    ;

variable isa-name-l
: isa-make-name ( imm -- a u )   \ в pad: mnem1 с _ -> "-", imm -> "#," иначе ","
    isa-mnem1-l @ 0 ?do
        isa-mnem1 i + c@ dup [char] _ = if drop [char] - then
        i pad + c!
    loop
    isa-mnem1-l @ isa-name-l !
    if [char] # isa-name-l @ pad + c! 1 isa-name-l +! then
    [char] , isa-name-l @ pad + c! 1 isa-name-l +!
    pad isa-name-l @
    ;

\ ------------------------------------------------------------------
\ Состояние спецификации
\ ------------------------------------------------------------------
variable isa-regs        \ массив registers
variable isa-instr-arr   \ массив instructions
variable isa-cur-reg     \ текущий регистр (для битов)
variable isa-cur-bits    \ текущий объект bits

\ ------------------------------------------------------------------
\ Секция регистров: $XX constant NAME (r+цифры -> как есть, иначе ВЕРХНИЙ)
\ ------------------------------------------------------------------
variable isa-rn-a variable isa-rn-l variable isa-reg-addr

variable rn2-a variable rn2-u
: isa-rn-name? ( a u -- f )    \ начинается на 'r', дальше только цифры (u>1)
    rn2-u ! rn2-a !
    rn2-u @ 1 <= if 0 exit then
    rn2-a @ c@ [char] r <> if 0 exit then
    -1 rn2-u @ 1 ?do
        rn2-a @ i + c@ [char] 0 [char] 9 1+ within 0= if drop 0 leave then
    loop
    ;

\ база адреса регистра (для битов)
variable isa-reg-base
: isa-emit-bit ( pair -- )
    dup pair-val @ fjson.node-str@ isa-rn-l ! isa-rn-a !
    dup pair-key-a @ swap pair-key-u @ isa-str2int isa-reg-base @ + isa-reg-addr !
    [char] $ o-ch isa-reg-addr @ o-hex s"  constant " o-type
    isa-rn-a @ isa-rn-l @ o-upper o-cr
    ;

: isa-emit-one-reg ( reg-node -- )
    dup isa-cur-reg !
    dup s" name" rot fjson.object-get fjson.node-str@ isa-rn-l ! isa-rn-a !
    s" address" rot fjson.object-get fjson.node-num@ dup isa-reg-base ! isa-reg-addr !
    [char] $ o-ch isa-reg-addr @ o-hex s"  constant " o-type
    isa-rn-a @ isa-rn-l @ 2dup isa-rn-name? if o-type else o-upper then o-cr
    \ биты — отдельной секцией после всех регистров (как в Python)
    ;

: isa-any-bits? ( -- f )
    0
    isa-regs @ fjson.array-len 0 ?do
        i isa-regs @ fjson.array-nth s" bits" rot fjson.object-get
        dup 0= if drop else fjson.object-len 0> if drop -1 leave then then
    loop
    ;

\ ------------------------------------------------------------------
\ Helpers (паритет с _generate_helpers): abort" {arch}: ..." 
\ ------------------------------------------------------------------
variable isa-hl

: isa-emit-helpers ( -- )
    s" : " o-type o-prefix s" -u8 ( u -- u )" o-type o-cr
    s"    dup 0 256 within 0= abort" o-type [char] " o-ch
    o-space o-arch s" : byte" o-type [char] " o-ch s"  ;" o-type o-cr
    o-cr
    s" : " o-type o-prefix s" -rn ( u -- u )" o-type o-cr
    s"    dup 0 8 within 0= abort" o-type [char] " o-ch
    o-space o-arch s" : Rn" o-type [char] " o-ch s"  ;" o-type o-cr
    o-cr
    s" : " o-type o-prefix s" -rel ( dest -- u )" o-type o-cr
    s"    fasm-pc @ 1+ -" o-type o-cr
    s"    dup -128 128 within 0= abort" o-type [char] " o-ch
    o-space o-arch s" : rel" o-type [char] " o-ch o-cr
    s"    $FF and ;" o-type o-cr
    o-cr
    s" : db, ( u -- ) " o-type o-prefix s" -u8 fasm-emit ;" o-type o-cr
    s" : dw, ( u -- )" o-type o-cr
    s"    dup $FF and fasm-emit" o-type o-cr
    s"    8 rshift fasm-emit ;" o-type o-cr
    o-cr
    s" : " o-type o-prefix s" -op1 ( opc " o-type [char] " o-ch
    s" name" o-type [char] " o-ch s"  -- )" o-type o-cr
    s"    create ," o-type o-cr
    s"    does> ( -- ) @ fasm-emit ;" o-type o-cr
    o-cr
    ;

\ ------------------------------------------------------------------
\ Состояние инструкции
\ ------------------------------------------------------------------
variable isa-instr      \ текущая инструкция (node)
variable isa-ma         \ сырой mnemonic (a)
variable isa-ml         \ сырой mnemonic (u)
variable isa-opnode     \ узел opcode (0 = переменный)
variable isa-opc        \ значение opcode
variable isa-ops        \ массив operands (0 = нет)
variable isa-opcount
variable isa-hasimm
variable isa-bytes

: isa-analyze-instr ( node -- )
    isa-instr !
    isa-instr @ s" mnemonic" rot fjson.object-get fjson.node-str@ isa-ml ! isa-ma !
    isa-ma @ isa-ml @ isa-stage1
    isa-instr @ s" bytes" rot fjson.object-get fjson.node-num@ isa-bytes !
    isa-instr @ s" opcode" rot fjson.object-get dup isa-opnode !
    dup 0= if drop 0 isa-opc ! else fjson.node-num@ isa-opc ! then
    isa-instr @ s" operands" rot fjson.object-get dup isa-ops !
    dup 0= if drop 0 isa-opcount ! 0 isa-hasimm ! exit then
    fjson.array-len isa-opcount !
    0 isa-hasimm !
    isa-opcount @ 0 ?do
        i isa-ops @ fjson.array-nth fjson.node-str@
        2dup s" num" compare 0= if 1 isa-hasimm ! then
        2dup s" di" compare 0= if 1 isa-hasimm ! then
        2dup s" addr" compare 0= if 1 isa-hasimm ! then
        2dup s" dptr" compare 0= if 1 isa-hasimm ! then
        2drop
    loop
    ;

\ stack comment: ( rn u -- ) — num -> u
: isa-emit-stack-comment ( -- )
    o-space [char] ( o-ch
    isa-opcount @ 0 ?do
        o-space
        i isa-ops @ fjson.array-nth fjson.node-str@
        2dup s" num" compare 0= if 2drop s" u" o-type else o-type then
    loop
    s"  -- )" o-type
    ;

\ сырой stack comment для stub: ( op op -- ) без замен
\ (isa-emit-stack-comment-raw удалён: после переноса stub-ветки на собственный
\ вывод комментария у слова не осталось вызовов.)

\ кусок тела по операнду (паритет с _generate_instruction_word)
variable op-a variable op-u
: isa-operand-piece ( a u -- )
    op-u ! op-a !
    op-a @ op-u @ s" rn" compare 0= if s" swap " o-type o-prefix s" -rn fasm-emit" o-type exit then
    op-a @ op-u @ s" di" compare 0= if s" swap " o-type o-prefix s" -u8 fasm-emit" o-type exit then
    op-a @ op-u @ s" bit" compare 0= if s" swap " o-type o-prefix s" -u8 fasm-emit" o-type exit then
    op-a @ op-u @ s" num" compare 0= if o-prefix s" -u8 fasm-emit" o-type exit then
    op-a @ op-u @ s" dest" compare 0= if o-prefix s" -rel fasm-emit" o-type exit then
    op-a @ op-u @ s" dptr" compare 0= if s" dup 8 rshift $FF and fasm-emit" o-type exit then
    op-a @ op-u @ s" addr" compare 0= if s" dup 8 rshift $FF and fasm-emit" o-type exit then
    s" \ TODO: operand " o-type op-a @ op-u @ o-type
    ;

: isa-emit-instr ( -- )   \ по результатам isa-analyze-instr
    isa-opnode @ 0= if
        \ --- переменное кодирование: stub ---
        s" \ TODO: " o-type isa-mnem1 isa-mnem1-l @ o-type
        s"  has a variable/complex encoding (" o-type
        isa-bytes @ o-dec s" -byte)" o-type o-cr
        s" \         not auto-generated. See fsys/fasm/" o-type
        o-arch s" /words.4th." o-type o-cr
        s" : " o-type isa-hasimm @ isa-make-name o-type
        \ python stub: " (" + " ".join(operands) + " -- )" — БЕЗ пробела после (
        o-space [char] ( o-ch
        isa-opcount @ 0 ?do
            i 0 > if o-space then
            i isa-ops @ fjson.array-nth fjson.node-str@ o-type
        loop
        s"  -- )" o-type o-cr
        \ ведущий пробел в s" gforth съедает: контент должен быть
        \ "   \ TODO: implement " (3sp) и " ;", как в python
        s"    \ TODO: implement " o-type isa-ma @ isa-ml @ o-type s"  ;" o-type o-cr
        exit
    then
    isa-opcount @ 0= if
        \ --- без операндов: $XX prefix-op1 name ---
        [char] $ o-ch isa-opc @ o-hex o-space o-prefix s" -op1 " o-type
        isa-hasimm @ isa-make-name o-type o-cr
        exit
    then
    \ --- с операндами ---
    s" : " o-type isa-hasimm @ isa-make-name o-type
    isa-emit-stack-comment o-cr
    s"    " o-type
    isa-ma @ isa-ml @ s" mov_rn" compare 0= if
        s" swap " o-type o-prefix s" -rn " o-type
        [char] $ o-ch isa-opc @ o-hex s" + fasm-emit " o-type
        o-prefix s" -u8 fasm-emit" o-type
    else
        [char] $ o-ch isa-opc @ o-hex s"  fasm-emit" o-type
        isa-opcount @ 0 ?do
            o-space
            i isa-ops @ fjson.array-nth fjson.node-str@ isa-operand-piece
        loop
    then
    s"  ;" o-type o-cr
    ;

\ ------------------------------------------------------------------
\ Инструкции: цикл
\ ------------------------------------------------------------------
: isa-emit-instructions ( -- )
    isa-root-node @ s" instructions" rot fjson.object-get
    dup 0= if drop exit then
    isa-instr-arr !
    s" \ Instruction comma words." o-type o-cr
    isa-instr-arr @ fjson.array-len 0 ?do
        i isa-instr-arr @ fjson.array-nth isa-analyze-instr
        isa-emit-instr
    loop
    ;

\ ------------------------------------------------------------------
\ span (паритет с _generate_span_function)
\ ------------------------------------------------------------------
variable isa-bc
variable isa-span-first

: isa-has-bytes? ( bc -- f )
    isa-bc !
    0
    isa-instr-arr @ fjson.array-len 0 ?do
        i isa-instr-arr @ fjson.array-nth s" bytes" rot fjson.object-get fjson.node-num@
        isa-bc @ = if drop -1 leave then
    loop
    ;

: isa-max-bytes ( -- u )
    0
    isa-instr-arr @ fjson.array-len 0 ?do
        i isa-instr-arr @ fjson.array-nth s" bytes" rot fjson.object-get fjson.node-num@ max
    loop
    ;

: isa-span-cond ( instr-node -- )   \ `2dup s" name," compare 0=` (plain ",", без #)
    s" mnemonic" rot fjson.object-get fjson.node-str@ isa-stage1
    0 isa-make-name
    s" 2dup s" o-type [char] " o-ch o-space o-type [char] " o-ch s"  compare 0=" o-type
    ;

: isa-span-group ( bc -- )
    isa-bc !
    isa-bc @ isa-has-bytes? 0= if exit then
    s"    " o-type
    1 isa-span-first !
    isa-instr-arr @ fjson.array-len 0 ?do
        i isa-instr-arr @ fjson.array-nth
        dup s" bytes" rot fjson.object-get fjson.node-num@ isa-bc @ <> if
            drop
        else
            isa-span-first @ 0= if s"  r> or >r " o-type then
            0 isa-span-first !
            isa-span-cond
        then
    loop
    o-cr
    s"    if 2drop " o-type isa-bc @ o-dec s"  exit then" o-type o-cr
    s"    r> drop" o-type o-cr
    ;

: isa-emit-span ( -- )
    s" : " o-type o-prefix s" -span ( c-addr u -- n )" o-type o-cr
    isa-max-bytes 1+ 2 ?do i isa-span-group loop
    s"    2drop 1 ;" o-type         \ последняя строка файла — БЕЗ o-cr
    ;

\ ------------------------------------------------------------------
\ words.4th: полная генерация в буфер
\ ------------------------------------------------------------------
: isa-emit-words4th ( -- )
    isa-root-node @ s" arch" rot fjson.object-get fjson.node-str@ isa-set-arch
    o-reset
    \ --- хедер ---
    s" \ fsys/fasm/" o-type o-arch s" /words.4th — " o-type
    isa-arch isa-arch-l @ o-upper s"  opcodes as comma words." o-type o-cr
    s" \ Auto-generated from ISA spec. DO NOT EDIT MANUALLY." o-type o-cr
    o-cr
    s" [IFUNDEF] mcs-wl" o-type o-cr
    s" wordlist constant mcs-wl" o-type o-cr
    s" get-current" o-type o-cr
    s" mcs-wl set-current" o-type o-cr
    s" mcs-wl >order" o-type o-cr
    o-cr
    \ --- регистры ---
    isa-root-node @ s" registers" rot fjson.object-get
    dup 0= if drop else
        dup isa-regs !
        fjson.array-len 0> if
            s" \ Register/SFR constants." o-type o-cr
            isa-regs @ fjson.array-len 0 ?do
                i isa-regs @ fjson.array-nth isa-emit-one-reg
            loop
            o-cr
        then
    then
    \ --- биты ---
    isa-regs @ 0<> if
        isa-any-bits? if
            s" \ Bit address constants." o-type o-cr
            isa-regs @ fjson.array-len 0 ?do
                i isa-regs @ fjson.array-nth
                dup s" address" rot fjson.object-get fjson.node-num@ isa-reg-base !
                s" bits" rot fjson.object-get
                dup 0= if drop else
                    ['] isa-emit-bit swap j-child @ ulist-each
                then
            loop
            o-cr
        then
    then
    isa-emit-helpers
    isa-emit-instructions
    isa-emit-span
    ;

: isa-gen-words4th ( pa pu -- )
    isa-emit-words4th
    isa-out-write
    ;

\ ------------------------------------------------------------------
\ chip: по одному файлу на каждый вариант chip_variants
\ ------------------------------------------------------------------
variable isa-outdir-a variable isa-outdir-l
create isa-path 512 allot variable isa-path-l

: isa-path-add ( a u -- )
    dup isa-path-l @ + 512 u>= abort" isa path too long"
    >r isa-path isa-path-l @ + r@ move r> isa-path-l +!
    ;

: isa-emit-chip-reg ( pair -- )
    dup pair-val @ fjson.node-num@ >r
    dup pair-key-a @ swap pair-key-u @
    [char] $ o-ch r> o-hex s"  constant " o-type
    o-upper o-cr
    ;
: isa-emit-chip-mem ( pair -- )
    dup pair-val @ fjson.node-num@ >r
    dup pair-key-a @ swap pair-key-u @
    r> o-dec s"  constant " o-type
    o-upper o-cr
    ;

variable cv-a variable cv-u variable cv-obj
: isa-emit-chip ( va vu vobj -- )   \ в буфер (предполагается o-reset)
    cv-obj ! cv-u ! cv-a !
    s" \ fsys/fasm/" o-type o-arch s" /" o-type cv-a @ cv-u @ o-type
    s" .4th — " o-type cv-a @ cv-u @ o-upper s"  chip definitions." o-type o-cr
    s" \ Auto-generated from ISA spec. DO NOT EDIT MANUALLY." o-type o-cr
    o-cr
    s" include " o-type o-arch s" /words.4th" o-type o-cr
    o-cr
    cv-obj @ s" registers" rot fjson.object-get
    dup 0= if drop else
        s" \ Variant-specific register addresses." o-type o-cr
        ['] isa-emit-chip-reg swap j-child @ ulist-each
        o-cr
    then
    cv-obj @ s" memory" rot fjson.object-get
    dup 0= if drop else
        s" \ Memory configuration." o-type o-cr
        ['] isa-emit-chip-mem swap j-child @ ulist-each
        \ последняя секция: "" в Python даёт только завершающий LF (уже o-cr в строках)
    then
    ;

variable isa-va variable isa-vu variable isa-vobj

: isa-do-variant ( pair -- )
    dup pair-key-a @ isa-va !
    dup pair-key-u @ isa-vu !
    pair-val @ isa-vobj !
    o-reset
    isa-va @ isa-vu @ isa-vobj @ isa-emit-chip
    \ путь: outdir/variant.4th — строим заново на каждый вариант
    0 isa-path-l !
    isa-outdir-a @ isa-outdir-l @ isa-path-add
    s" /" isa-path-add
    isa-va @ isa-vu @ isa-path-add
    s" .4th" isa-path-add
    isa-path isa-path-l @ isa-out-write
    ;

: isa-gen-chip4th ( pa pu -- )   \ outdir
    isa-outdir-l ! isa-outdir-a !
    0 isa-path-l !
    isa-root-node @ s" arch" rot fjson.object-get fjson.node-str@ isa-set-arch
    isa-root-node @ s" chip_variants" rot fjson.object-get
    dup 0= if drop
        \ нет вариантов -> chip.4th (default): заголовок + include
        o-reset
        s" \ fsys/fasm/" o-type o-arch s" /default.4th — " o-type
        s" DEFAULT" o-type s"  chip definitions." o-type o-cr
        s" \ Auto-generated from ISA spec. DO NOT EDIT MANUALLY." o-type o-cr
        o-cr
        s" include " o-type o-arch s" /words.4th" o-type o-cr
        isa-outdir-a @ isa-outdir-l @ isa-path-add
        s" /chip.4th" isa-path-add
        isa-path isa-path-l @ isa-out-write
    else
        ['] isa-do-variant swap j-child @ ulist-each
    then
    ;

\ ------------------------------------------------------------------
\ ------------------------------------------------------------------
\ isa-check — дрейф-гейт spec ↔ words.4th (порт tools/isa_to_fasm.py --check)
\   isa-check ( spec-a spec-u words-a words-u -- rc )
\ rc: 0 = full coverage; 1 = drift/gap. Throw вызывающий нормализует в 1
\ (как traceback Python при битых файлах — без печати, как python).
\ Порядок паритета: load spec -> парсер words.4th (op1-фаза, colon-фаза)
\ -> подсчёт drift/gap -> печать header, (alias) info, FAIL DRIFT/GAP или OK.
\ ------------------------------------------------------------------
512 constant ic-max                 \ слов в words.4th (max ~149)
256 constant ic-imax                \ инструкций в спеке (max ~145)
create ic-src 65536 allot           \ содержимое words.4th
variable ic-src-l
create ic-na ic-max cells allot     \ ключ opcodes: имя-адрес в ic-src
create ic-nl ic-max allot           \ имя-длина (байт)
create ic-nv ic-max cells allot     \ opcode
variable ic-nop
create ic-ua ic-max cells allot     \ unparseable: адреса (в ic-src)
create ic-ul ic-max allot           \ и длины
variable ic-nunp
create ic-lv ic-max cells allot     \ loose: значения хелпер-форм (только coverage, как python loose)
variable ic-nlv
create ic-body 8192 allot            \ тело colon-слова (склейка как python)
variable ic-body-l
create ic-nbuf 256 allot             \ рабочее имя / mnemonic / scratch
variable ic-nbufn
create ic-z80skip 1024 allot         \ haystack z80-макро-имён
variable ic-z80skip-l
create ic-hexbuf 16 allot            \ разряды для ic-px
variable ic-hexbuf-n
\ индекс спеки в порядке следования JSON
create ic-ia ic-imax cells allot     \ mnemonic-адрес (в буфере спеки)
create ic-il ic-imax cells allot     \ mnemonic-длина
create ic-iopc ic-imax cells allot   \ opcode, -1 = нет поля (variable encoding)
create ic-ibytes ic-imax cells allot \ bytes
variable ic-in
variable ic-arr
variable ic-arch-a variable ic-arch-u
variable ic-spec-a variable ic-spec-u
variable ic-words-a variable ic-words-u
variable ic-fa variable ic-fu        \ аргументы поиска по имени
variable ic-fidx
variable ic-i variable ic-i2
variable ic-p                         \ курсор по строкам ic-src
variable ic-s variable ic-e           \ текущая строка [s,e)
variable ic-q                         \ курсор внутри строки/тела
variable ic-t0                        \ начало токена
variable ic-n0 variable ic-ne         \ имя [n0,ne)
variable ic-l                         \ длина hex-подстроки / ic-hexval
variable ic-found
variable ic-ch
variable ic-ta variable ic-tu         \ аргументы translit/сканов
variable ic-ti
variable ic-z                         \ рабочий указатель ic-eol
variable ic-ins                       \ индекс/счётчик вставки
variable ic-drift                     \ число drift-ошибок
variable ic-gap                       \ число coverage-дыр
variable ic-opval                     \ рабочее значение
variable ic-ha variable ic-hn variable ic-hv  \ ic-hexval
variable ic-bi variable ic-ll variable ic-qs  \ ic-emit-here
variable ic-fi                        \ итератор ic-spec-find
variable ic-pj                        \ итератор ic-op-present?
variable ic-xa variable ic-xb         \ параметры ic-swap2
variable ic-si variable ic-sj         \ пузырёк ic-sort
variable ic-vmode                     \ 0=подсчёт, 1=печать (gap)

s"  add_r adc_r sub_r sbc_r and_r xor_r or_r cp_r inc_r dec_r inc_rp dec_rp add_a_r add_a_immediate sub_immediate push_rp pop_rp jp_nn call_nn jr_rel jp_cc_nn call_cc_nn ret_cc djnz_rel rst_n in_a_n out_n_a add_hl_rp neg ex_de_hl ld_r_hl ld_hl_r  "
    dup ic-z80skip-l ! ic-z80skip swap move

\ ------------------------------------------------------------------
\ Символьные классы (паритет классов python-regex)
\ ------------------------------------------------------------------
\ Символьные классы — явные ASCII-коды (конструкции [char] x1+ слитно
\ давали неверный разбор: 'z' не распознавался в ic-wordc?)
: ic-hexd? ( c -- f )
    ic-ch !
    ic-ch @ 48 58 within if -1 exit then
    ic-ch @ 97 103 within if -1 exit then
    ic-ch @ 65 71 within ;

: ic-hexv ( c -- u )
    ic-ch !
    ic-ch @ 48 58 within if ic-ch @ 48 - exit then
    ic-ch @ 97 103 within if ic-ch @ 97 - 10 + exit then
    ic-ch @ 65 - 10 + ;

: ic-sp? ( c -- f )
    ic-ch ! ic-ch @ 32 = ic-ch @ 9 = or ;

: ic-ws? ( c -- f )
    ic-ch ! ic-ch @ ic-sp? if -1 exit then
    ic-ch @ 13 = if -1 exit then
    ic-ch @ 11 = if -1 exit then
    ic-ch @ 12 = ;

: ic-wordc? ( c -- f )
    ic-ch !
    ic-ch @ 48 58 within if -1 exit then
    ic-ch @ 65 91 within if -1 exit then
    ic-ch @ 97 123 within if -1 exit then
    ic-ch @ 95 = ;

: ic-lalnum? ( c -- f )
    ic-ch !
    ic-ch @ 48 58 within if -1 exit then
    ic-ch @ 97 123 within ;

: ic-npushc ( c -- )
    ic-nbuf ic-nbufn @ + c!
    1 ic-nbufn +! ;

: ic-npushs ( a u -- )
    dup >r                          \ сохранить длину
    ic-nbuf ic-nbufn @ + swap       \ ( a dest u )
    move
    r> ic-nbufn +! ;

: ic-bpush ( a u -- )              \ append в ic-body
    dup ic-body-l @ + 8192 u>= abort" isa-check: body too long"
    dup >r ic-body ic-body-l @ + swap move
    r> ic-body-l +! ;

: ic-bpushc ( c -- )
    ic-body ic-body-l @ + c!
    1 ic-body-l +! ;

: ic-read-words ( path-a path-u -- ) \ файл -> ic-src (паритет read_text)
    r/o open-file throw >r
    r@ file-size throw d>s
    dup 65536 u> if r> close-file throw abort" isa-check: words.4th too big" then
    dup ic-src swap r@ read-file throw   \ ( size n )
    2dup <> if r> close-file throw drop abort" isa-check: short read" then
    drop
    r> close-file throw
    ic-src-l !
    \ свежий парсер на каждый вызов (python: opcodes={} на каждый --check)
    \ без этого ic-nop/ic-nunp накапливались через запятую по сеансу
    0 ic-nop ! 0 ic-nunp ! 0 ic-nlv !
    ;

: ic-eol ( p -- e )                \ позиция \n после p либо конец
    ic-z !
    begin ic-z @ ic-src-l @ < while
        ic-src ic-z @ + c@ 10 = if ic-z @ exit then
        1 ic-z +!
    repeat
    ic-z @ ;

: ic-scan-semi ( a u -- f )        \ ';' в диапазоне
    ic-tu ! ic-ta !
    0 ic-i2 !
    begin ic-i2 @ ic-tu @ < while
        ic-ta @ ic-i2 @ + c@ [char] ; = if -1 exit then
        1 ic-i2 +!
    repeat
    0 ;

: ic-hexval ( a u -- val )         \ u hex-цифр по адресу -> val
    ic-hn ! ic-ha !
    0 ic-hv ! 0 ic-i2 !
    begin ic-i2 @ ic-hn @ < while
        ic-hv @ 16 * ic-ha @ ic-i2 @ + c@ ic-hexv + ic-hv !
        1 ic-i2 +!
    repeat
    ic-hv @ ;

: ic-basename ( a u -- b u )       \ последний сегмент пути (python Path.name)
    ic-tu ! ic-ta !
    0 ic-i2 ! 0 ic-ins !
    begin ic-i2 @ ic-tu @ < while
        ic-ta @ ic-i2 @ + c@ [char] / = if ic-i2 @ 1 + ic-ins ! then
        1 ic-i2 +!
    repeat
    ic-ta @ ic-ins @ +  ic-tu @ ic-ins @ - ;

\ ------------------------------------------------------------------
\ Числа на печать: десятичное без пробела, верхний hex с паддингом
\ (паритет python str(int) / 0x{v:02X} / 0x{v:04X})
\ ------------------------------------------------------------------
: ic-pn ( n -- )                   \ одиночное число -> десятичная строка (python str(int))
    s>d <# #s #> type ;

variable ic-hmin
: ic-px ( u minw -- )
    ic-hmin !
    0 ic-hexbuf-n !
    begin dup 0> while
        dup 15 and dup 9 u> if 7 + then [char] 0 +
        ic-hexbuf ic-hexbuf-n @ + c!
        1 ic-hexbuf-n +!
        4 rshift
    repeat drop
    ic-hmin @ ic-hexbuf-n @ -                 \ паддинг нулями (minw - len)
    begin dup 0> while [char] 0 emit 1- repeat drop
    ic-hexbuf-n @ 0 ?do                        \ цифры младшей-старшей
        ic-hexbuf ic-hexbuf-n @ 1- i - + c@ emit
    loop ;

\ ------------------------------------------------------------------
\ Правила имени fasm-слова -> mnemonic (паритет fasm_name_to_mnemonic)
\ ------------------------------------------------------------------
: ic-translit ( a u -- b u )      \ @-lookbehind -> _a_, '+'/'-' -> '_'
    ic-tu ! ic-ta !
    0 ic-ti ! 0 ic-nbufn !
    begin ic-ti @ ic-tu @ < while
        ic-ta @ ic-ti @ + c@ ic-ch !
        ic-ch @ [char] @ = if
            ic-ti @ 0> if ic-ta @ ic-ti @ 1- + c@ ic-lalnum? else 0 then
            if s" _a_" ic-npushs else [char] @ ic-npushc then
        else ic-ch @ [char] + = if
            [char] _ ic-npushc
        else ic-ch @ [char] - = if
            [char] _ ic-npushc
        else
            ic-ch @ ic-npushc
        then then then
        1 ic-ti +!
    repeat
    ic-nbuf ic-nbufn @ ;

: ic-mnem ( word-a word-u -- b u )
    \ base = word без хвостовых запятых (python rstrip(","));
    \ маппинг (#/-суффикс, z80_map, translit) выполняется ВСЕГДА, как в python.
    \ Было `if exit` на первом не-',' — слово возвращалось без транслита,
    \ ic-spec-find не находил mnemonic и дрейф не срабатывал никогда.
    begin dup 0> if
         2dup 1- + c@ [char] , = else 0
    then while 1- repeat
    ic-tu ! ic-ta !
    \ '#'-суффикс: base[:-1].replace("-","_") + "_num"
    ic-tu @ 0> if ic-ta @ ic-tu @ 1- + c@ [char] # = if
        0 ic-nbufn ! 0 ic-ti !
        begin ic-ti @ ic-tu @ 1- < while
            ic-ta @ ic-ti @ + c@ dup [char] - = if drop [char] _ then
            ic-npushc
            1 ic-ti +!
        repeat
        s" _num" ic-npushs
        ic-nbuf ic-nbufn @ exit
    then then
    \ z80_map (точное совпадение base)
    ic-ta @ ic-tu @ s" and"   compare 0= if s" and_r" exit then
    ic-ta @ ic-tu @ s" xor"   compare 0= if s" xor_r" exit then
    ic-ta @ ic-tu @ s" or"    compare 0= if s" or_r" exit then
    ic-ta @ ic-tu @ s" cp"    compare 0= if s" cp_r" exit then
    ic-ta @ ic-tu @ s" push"  compare 0= if s" push_rp" exit then
    ic-ta @ ic-tu @ s" pop"   compare 0= if s" pop_rp" exit then
    ic-ta @ ic-tu @ s" retcc" compare 0= if s" ret_cc" exit then
    ic-ta @ ic-tu @ s" rst"   compare 0= if s" rst_n" exit then
    ic-ta @ ic-tu @ s" addhl" compare 0= if s" add_hl_rp" exit then
    ic-ta @ ic-tu @ s" neg"   compare 0= if s" neg" exit then
    ic-ta @ ic-tu @ ic-translit ;

\ ------------------------------------------------------------------
\ Индекс спеки и поиск mnemonic (последнее совпадение = python dict)
\ ------------------------------------------------------------------
: ic-spec-find ( a u -- idx|-1 )   \ последний слот с точным mnemonic
    ic-fu ! ic-fa !
    -1 ic-fidx !
    0 ic-fi !
    begin ic-fi @ ic-in @ < while
        ic-fa @ ic-fu @ ic-ia ic-fi @ cells + @ ic-il ic-fi @ cells + @
        compare 0= if ic-fi @ ic-fidx ! then
        1 ic-fi +!
    repeat
    ic-fidx @ ;

: ic-build-index ( -- )            \ после isa-load-spec
    isa-root-node @ s" arch" isa-get-str ic-arch-u ! ic-arch-a !
    isa-root-node @ s" instructions" rot fjson.object-get
    dup 0= if drop abort" isa-check: no instructions" then
    ic-arr !
    ic-arr @ fjson.array-len ic-in !
    0 ic-i2 !
    begin ic-i2 @ ic-in @ < while
        ic-i2 @ ic-arr @ fjson.array-nth isa-analyze-instr
        ic-ia ic-i2 @ cells + isa-ma @ swap !
        ic-il ic-i2 @ cells + isa-ml @ swap !
        isa-opnode @ 0= if -1 else isa-opc @ then
        ic-iopc ic-i2 @ cells + !
        isa-bytes @ ic-ibytes ic-i2 @ cells + !
        1 ic-i2 +!
    repeat ;

\ ------------------------------------------------------------------
\ Парсер words.4th: фаза1 op1, фаза2 colon (воспроизведение check_fasm)
\ ------------------------------------------------------------------
: ic-rdname ( -- f )               \ [^,\s]+ до ',' от ic-q: f=-1, ic-q на ','
    ic-q @ ic-n0 !
    begin ic-q @ ic-e @ < while
        ic-src ic-q @ + c@ dup [char] , = if drop -1 exit then
        dup ic-ws? if drop 0 exit then
        drop 1 ic-q +!
    repeat
    0 ;

: ic-op-add ( a u val -- )         \ добавить/перезаписать (python dict)
    ic-opval ! ic-tu ! ic-ta !
    0 ic-i2 !
    begin ic-i2 @ ic-nop @ < while
        ic-ta @ ic-tu @ ic-na ic-i2 @ cells + @ ic-nl ic-i2 @ + c@
        compare 0= if
            ic-nv ic-i2 @ cells + ic-opval @ swap !
            exit
        then
        1 ic-i2 +!
    repeat
    ic-na ic-nop @ cells + ic-ta @ swap !
    ic-tu @ ic-nl ic-nop @ + c!
    ic-nv ic-nop @ cells + ic-opval @ swap !
    1 ic-nop +! ;

: ic-op-exists ( a u -- f )
    ic-fu ! ic-fa !
    0 ic-i2 !
    begin ic-i2 @ ic-nop @ < while
        ic-fa @ ic-fu @ ic-na ic-i2 @ cells + @ ic-nl ic-i2 @ + c@
        compare 0= if -1 exit then
        1 ic-i2 +!
    repeat
    0 ;

: ic-hexrun ( -- )                  \ длина hex-подстроки от ic-q -> ic-l, ic-q за ней
    0 ic-l !
    begin ic-q @ ic-e @ < while
        ic-src ic-q @ + c@ ic-hexd? 0= if exit then
        1 ic-l +! 1 ic-q +!
    repeat ;

: ic-hexrun-b ( -- )                 \ как ic-hexrun, но из тела ic-body (emit-here)
    0 ic-l !
    begin ic-q @ ic-body-l @ < while
        ic-body ic-q @ + c@ ic-hexd? 0= if exit then
        1 ic-l +! 1 ic-q +!
    repeat ;

: ic-spskip ( -- )                   \ пропуск [ \t]+ от ic-q (выход на не-пробел/конец)
    begin ic-q @ ic-e @ < while
        ic-src ic-q @ + c@ ic-sp? 0= if exit then
        1 ic-q +!
    repeat ;

: ic-tokrun ( -- )                   \ токен без [ \t] от ic-q -> ic-q на конце токена
    begin ic-q @ ic-e @ < while
        ic-src ic-q @ + c@ ic-sp? if exit then
        1 ic-q +!
    repeat ;

: ic-try-op1 ( -- )                \ строка [s,e) в op1-форме -> opcodes
    ic-src ic-s @ + c@ [char] $ <> if exit then
    ic-s @ 1 + ic-q !
    ic-hexrun
    \ длина ровно 2 или 4 (два regex python отдельно)
    ic-l @ 2 = ic-l @ 4 = or 0= if exit then
    \ [ \t]+ после hex
    ic-q @ ic-e @ >= if exit then
    ic-src ic-q @ + c@ ic-sp? 0= if exit then
    ic-spskip
    \ токен ...-op1
    ic-q @ ic-t0 !
    ic-tokrun
    ic-q @ ic-t0 @ - 4 < if exit then
    ic-src ic-q @ 1 - + c@ [char] 1 <> if exit then
    ic-src ic-q @ 2 - + c@ [char] p <> if exit then
    ic-src ic-q @ 3 - + c@ [char] o <> if exit then
    ic-src ic-q @ 4 - + c@ [char] - <> if exit then
    \ префикс токена — \w (паритет \w*-op1)
    ic-t0 @ begin dup ic-q @ 4 - < while
        ic-src over + c@ ic-wordc? 0= if drop exit then
        1+
    repeat drop
    \ [ \t]+ после токена
    ic-q @ ic-e @ >= if exit then
    ic-src ic-q @ + c@ ic-sp? 0= if exit then
    ic-spskip
    \ имя [^,\s]+ с обязательной запятой
    ic-rdname 0= if exit then
    ic-q @ ic-n0 @ = if exit then
    ic-q @ 1 + ic-ne !                \ имя с запятой (python group(","))
    ic-src ic-s @ 1 + + ic-l @ ic-hexval
    ic-src ic-n0 @ + ic-ne @ ic-n0 @ - rot  \ ( a u val )
    ic-op-add ;

\ ------------------------------------------------------------------
\ Фаза2: colon-слова (паритет colon-прохода check_fasm)
\ ------------------------------------------------------------------
: ic-skipws-str ( -- )              \ \s* от ic-q внутри строки [s,e)
    begin ic-q @ ic-e @ < while
        ic-src ic-q @ + c@ ic-ws? 0= if exit then
        1 ic-q +!
    repeat ;

: ic-trimtail-str ( -- )            \ конец непробельного в [s,e) с конца -> ic-t0
    ic-e @ ic-t0 !
    begin ic-t0 @ ic-s @ > while
        ic-src ic-t0 @ 1- + c@ ic-ws? 0= if exit then
        ic-t0 @ 1- ic-t0 !
    repeat ;

: ic-skipws-body ( -- )             \ [ \t]* от ic-q внутри ic-body
    begin ic-q @ ic-body-l @ < while
        ic-body ic-q @ + c@ ic-sp? 0= if exit then
        1 ic-q +!
    repeat ;

: ic-ws1 ( -- f )                   \ >=1 ws от ic-q в body, со сдвигом
    ic-q @ ic-body-l @ >= if 0 exit then
    ic-body ic-q @ + c@ ic-ws? 0= if 0 exit then
    begin ic-q @ ic-body-l @ < while
        ic-body ic-q @ + c@ ic-ws? 0= if -1 exit then
        1 ic-q +!
    repeat
    -1 ;

: ic-memit ( -- f )                 \ "fasm-emit" по ic-q
    ic-q @ 9 + ic-body-l @ > if 0 exit then
    ic-body ic-q @ + 9 s" fasm-emit" compare 0= if -1 else 0 then ;

: ic-emit-here ( -- u f )           \ greedy-перебор длины hex (4..2) на позиции ic-bi
    ic-bi @ 1 + ic-q !
    ic-hexrun-b                        \ L=0/1 отсекается ll-циклом (< 2)
    ic-l @ 4 min ic-ll !
    begin ic-ll @ 2 >= while
        \ альт1: \s+ fasm-emit
        ic-bi @ 1 + ic-ll @ + ic-q !
        ic-ws1 if
            ic-q @ ic-qs !
            ic-memit if ic-body ic-bi @ 1 + + ic-ll @ ic-hexval -1 exit then
            ic-qs @ ic-q !
        then
        \ альт2: \s+ + [ \t]* fasm-emit
        ic-bi @ 1 + ic-ll @ + ic-q !
        ic-ws1 if
            ic-q @ ic-qs !
            ic-q @ ic-body-l @ < if
                ic-body ic-q @ + c@ [char] + = if
                    1 ic-q +!
                    ic-skipws-body
                    ic-memit if ic-body ic-bi @ 1 + + ic-ll @ ic-hexval -1 exit then
                then
            then
            ic-qs @ ic-q !
        then
        \ альт3: \s+ or [ \t]* fasm-emit — вычисляемые маски ($01 or fasm-emit)
        \ ajmp/acall/bset; python: (?:\s+(?:or|\+))*\s*fasm-emit
        ic-bi @ 1 + ic-ll @ + ic-q !
        ic-ws1 if
            ic-q @ ic-qs !
            ic-q @ 2 + ic-body-l @ < if
                ic-body ic-q @ + 2 s" or" compare 0= if
                    ic-q @ 2 + ic-body-l @ < if
                        ic-body ic-q @ + 2 + c@ ic-ws? if
                            2 ic-q +!
                            ic-skipws-body
                            ic-memit if ic-body ic-bi @ 1 + + ic-ll @ ic-hexval -1 exit then
                        then
                    then
                then
            then
            ic-qs @ ic-q !
        then
        -1 ic-ll +!
    repeat
    0 0 ;

: ic-find-emit ( -- u f )           \ первый $hex + fasm-emit в body
    0 ic-bi !
    begin ic-bi @ ic-body-l @ 1- < while
        ic-body ic-bi @ + c@ [char] $ = if
            ic-emit-here if -1 exit then
            drop
        then
        1 ic-bi +!
    repeat
    0 0 ;

: ic-unp-name ( -- )                \ имя [n0,ne) -> unparseable (паритет unparseable.append)
    ic-ua ic-nunp @ cells + ic-src ic-n0 @ + swap !
    ic-ne @ ic-n0 @ - ic-ul ic-nunp @ + c!
    1 ic-nunp +! ;

: ic-zero-emit? ( -- f )            \ "0 fasm-emit" (nop): 0 с ws-границей + fasm-emit
    0 ic-bi !
    begin ic-bi @ ic-body-l @ 1- < while
        ic-body ic-bi @ + c@ [char] 0 = if
            ic-bi @ 0= if -1 else ic-body ic-bi @ 1- + c@ ic-ws? then if
                ic-bi @ 1 + ic-q !
                ic-ws1 if ic-memit if -1 exit then then
            then
        then
        1 ic-bi +!
    repeat
    0 ;

: ic-find-lasthex ( -- u f )        \ последний $hex в body (loose; python findall()[-1])
    0 ic-bi !
    0 ic-opval !  0 ic-found !
    begin ic-bi @ ic-body-l @ 1- < while
        ic-body ic-bi @ + c@ [char] $ = if
            ic-bi @ 1 + ic-q !
            ic-hexrun-b
            ic-l @ 4 min ic-ll !
            ic-ll @ 2 >= if
                ic-body ic-bi @ 1 + + ic-ll @ ic-hexval ic-opval !
                -1 ic-found !
            then
        then
        1 ic-bi +!
    repeat
    ic-found @ if ic-opval @ -1 else 0 0 then ;

: ic-colon-body ( -- f )            \ тело от ic-q до конца строки с ';' (склейка python)
    ic-e @ ic-q @ - ic-body-l !
    ic-src ic-q @ + ic-body ic-body-l @ move
    ic-body ic-body-l @ ic-scan-semi if -1 exit then
    begin
        ic-e @ 1 + ic-src-l @ < 0= if 0 exit then
        ic-e @ 1 + ic-s !
        ic-s @ ic-eol ic-e !
        bl ic-bpushc                    \ " " между строками как python
        ic-s @ ic-q ! ic-skipws-str     \ ведущие ws
        ic-trimtail-str                 \ ic-t0 = конец непробельного
        ic-t0 @ ic-q @ > if
            ic-src ic-q @ + ic-t0 @ ic-q @ - ic-bpush
        then
        ic-body ic-body-l @ ic-scan-semi if -1 exit then
    again ;

: ic-zskip? ( a u -- f )            \ " <mnem> " в haystack z80-макро
    ic-fu ! ic-fa !
    0 ic-nbufn !
    32 ic-npushc
    ic-fa @ ic-fu @ ic-npushs
    32 ic-npushc
    ic-z80skip ic-z80skip-l @ ic-nbuf ic-nbufn @ search
    if 2drop -1 else 2drop 0 then ;

: ic-op-present? ( opc -- f )       \ opc есть среди значений opcodes ∪ loose
    ic-opval !
    0 ic-pj !
    begin ic-pj @ ic-nop @ < while
        ic-nv ic-pj @ cells + @ ic-opval @ = if -1 exit then
        1 ic-pj +!
    repeat
    0 ic-pj !
    begin ic-pj @ ic-nlv @ < while
        ic-lv ic-pj @ cells + @ ic-opval @ = if -1 exit then
        1 ic-pj +!
    repeat
    0 ;

: ic-pass1 ( -- )                   \ op1-фаза: все строки файла
    0 ic-p !
    begin ic-p @ ic-src-l @ < while
        ic-p @ dup ic-s ! ic-eol ic-e !
        ic-try-op1
        ic-e @ 1 + ic-p !
    repeat ;

: ic-try-colon ( -- )               \ двигает ic-p всегда (следующая строка / после ';')
    ic-src ic-s @ + c@ $3A <> if ic-e @ 1 + ic-p ! exit then   \ colon compare, не [char] : — ломает flint
    ic-s @ 1 + ic-q !
    ic-skipws-str
    ic-rdname 0= if ic-e @ 1 + ic-p ! exit then
    ic-q @ ic-n0 @ = if ic-e @ 1 + ic-p ! exit then
    ic-q @ 1 + ic-ne !                \ имя с запятой
    1 ic-q +!
    ic-skipws-str
    ic-q @ ic-e @ >= if ic-e @ 1 + ic-p ! exit then
    ic-src ic-q @ + c@ [char] ( <> if ic-e @ 1 + ic-p ! exit then
    1 ic-q +!
    ic-colon-body 0= if abort" isa-check: unterminated colon word" then
    \ пропуск: db, / dw, / уже в opcodes (python: i=j; continue)
    ic-src ic-n0 @ + ic-ne @ ic-n0 @ - 2dup s" db," compare 0= if 2drop ic-e @ 1 + ic-p ! exit then
    2dup s" dw," compare 0= if 2drop ic-e @ 1 + ic-p ! exit then
    2dup ic-op-exists if 2drop ic-e @ 1 + ic-p ! exit then
    2drop
    ic-find-emit
    if
        ic-opval !
        ic-src ic-n0 @ + ic-ne @ ic-n0 @ - ic-opval @ ic-op-add
    else
        drop
        \ python-цепочка: strict-hex -> `0 fasm-emit` -> (есть fasm-emit?
        \ unparseable : loose=последний $hex)
        ic-zero-emit? if
            ic-src ic-n0 @ + ic-ne @ ic-n0 @ - 0 ic-op-add
        else
            ic-body ic-body-l @ s" fasm-emit" search if
                2drop ic-unp-name
            else
                2drop
                ic-find-lasthex if
                    ic-lv ic-nlv @ cells + !  1 ic-nlv +!
                else
                    ic-unp-name
                then
            then
        then
    then
    ic-e @ 1 + ic-p ! ;

: ic-pass2 ( -- )                   \ colon-фаза: ic-try-colon двигает ic-p сам
    0 ic-p !
    begin ic-p @ ic-src-l @ < while
        ic-p @ dup ic-s ! ic-eol ic-e !
        ic-try-colon
    repeat ;

\ ------------------------------------------------------------------
\ Сортировка и прогон проверок (паритет spec_matches/ spec_missing)
\ ------------------------------------------------------------------
: ic-swap2 ( i j -- )
    ic-xb ! ic-xa !
    ic-na ic-xa @ cells + @ >r
    ic-na ic-xb @ cells + @
    ic-na ic-xa @ cells + !
    r> ic-na ic-xb @ cells + !
    ic-nl ic-xa @ + c@ >r
    ic-nl ic-xb @ + c@ ic-nl ic-xa @ + c!
    r> ic-nl ic-xb @ + c!
    ic-nv ic-xa @ cells + @ >r
    ic-nv ic-xb @ cells + @
    ic-nv ic-xa @ cells + !
    r> ic-nv ic-xb @ cells + ! ;

: ic-sort ( -- )                    \ пузырёк по имени (compare 0<=, как %asc fenum)
    ic-nop @ 2 < if exit then
    ic-nop @ 1- ic-si !
    begin ic-si @ 0 > while
        0 ic-sj !
        begin ic-sj @ ic-si @ < while
            ic-na ic-sj @ cells + @ ic-nl ic-sj @ + c@
            ic-na ic-sj @ 1 + cells + @ ic-nl ic-sj @ 1 + + c@
            compare 0> if ic-sj @ ic-sj @ 1 + ic-swap2 then
            1 ic-sj +!
        repeat
        -1 ic-si +!
    repeat ;

: ic-drift-run ( mode -- )          \ 0=подсчёт, 1=печать строк дрейфа
    ic-vmode !
    0 ic-i2 !
    begin ic-i2 @ ic-nop @ < while
        ic-na ic-i2 @ cells + @ ic-nl ic-i2 @ + c@ ic-mnem ic-spec-find
        ic-ins !
        ic-ins @ 0< 0= if
            ic-ins @ cells ic-iopc + @ ic-opval !
            ic-opval @ 0< 0= if
                ic-nv ic-i2 @ cells + @ dup ic-opval @ <> if
                    ic-vmode @ if
                        s"   - " type
                        ic-na ic-i2 @ cells + @ ic-nl ic-i2 @ + c@ type
                        s" : fasm=0x" type
                        2 ic-px
                        s"  spec=0x" type
                        ic-opval @ 2 ic-px
                        s"  (" type
                        ic-ia ic-ins @ cells + @ ic-il ic-ins @ cells + @ type
                        [char] ) emit cr
                    else
                        drop 1 ic-drift +!
                    then
                else
                    drop
                then
            then
        then
        1 ic-i2 +!
    repeat ;

: ic-gap-run ( mode -- )            \ 0=подсчёт, 1=печать (фильтры python:
    \ opcode-None, bytes=1, z80-macro, low-byte для >0xFF)
    ic-vmode !
    0 ic-i2 !
    begin ic-i2 @ ic-in @ < while
        ic-iopc ic-i2 @ cells + @        \ ( opc | -1 )
        dup 0< if
            drop                          \ variable encoding -> skip
        else
            ic-ibytes ic-i2 @ cells + @ 1 = if
                ic-arch-a @ ic-arch-u @ s" z80" compare 0= if
                    ic-ia ic-i2 @ cells + @ ic-il ic-i2 @ cells + @ ic-zskip?
                else
                    0
                then
                0= if                      \ не z80-macro -> проверять present
                    dup 255 u<= if
                        dup ic-op-present? 0= if
                            ic-vmode @ if
                                s"   - " type
                                ic-ia ic-i2 @ cells + @ ic-il ic-i2 @ cells + @ type
                                s"  (0x" type
                                4 ic-px
                                [char] ) emit cr
                            else
                                drop 1 ic-gap +!
                            then
                        else
                            drop
                        then
                    else
                        \ python: точное совпадение прежде; low-byte — fallback
                        dup ic-op-present? 0= if
                            dup 255 and ic-op-present? 0= if
                                ic-vmode @ if
                                    s"   - " type
                                    ic-ia ic-i2 @ cells + @ ic-il ic-i2 @ cells + @ type
                                    s"  (0x" type
                                    4 ic-px
                                    [char] ) emit cr
                                else
                                    drop 1 ic-gap +!
                                then
                            else
                                drop
                            then
                        else
                            drop
                        then
                    then
                else
                    drop
                then
            else
                drop
            then
        then
        1 ic-i2 +!
    repeat ;

\ ------------------------------------------------------------------
\ isa-check: точка входа --check (порядок печати python)
\ ------------------------------------------------------------------
: ic-check ( spec-a spec-u words-a words-u -- rc )
    ic-words-u ! ic-words-a ! ic-spec-u ! ic-spec-a !
    ic-spec-a @ ic-spec-u @ isa-load-spec
    dup 0= if drop abort" isa-check: bad spec" then drop
    ic-build-index
    ic-words-a @ ic-words-u @ ic-read-words
    ic-pass1 ic-pass2
    \ подсчёт до печати (python: errors/missing вычислены до print);
    \ счётчики свежие на каждый вызов — повторный ic-check в одном сеансе
    \ обязан считать так же, как первый (run_all_tools зовёт его per-cpu)
    0 ic-drift ! 0 ic-gap !
    0 ic-drift-run
    0 ic-gap-run
    \ header
    ic-words-a @ ic-words-u @ ic-basename type
    s" : " type ic-nop @ ic-pn
    s"  comma words with opcode, " type ic-nunp @ ic-pn
    s"  alias/helper (info, not errors)" type cr
    ic-nunp @ 0 ?do
        s"   (alias) " type
        ic-ua i cells + @ ic-ul i + c@ type cr
    loop
    ic-drift @ 0> if
        ic-sort
        cr ." FAIL SPEC/FASM DRIFT:" cr
        1 ic-drift-run
        1 exit
    then
    ic-gap @ 0> if
        cr ." FAIL SPEC COVERAGE GAP (" ic-gap @ ic-pn
        ."  unimplemented):" cr
        1 ic-gap-run
        1 exit
    then
    s" OK spec matches fasm opcodes (full coverage)" type cr
    0 ;

\ ------------------------------------------------------------------
\ Точка входа
\ ------------------------------------------------------------------
include disasm_gen.4th

: isa-help
    cr ." ISA-to-FASM utilities (port of tools/isa_to_fasm.py):"
    cr ."   Load spec: " [char] " emit s" <spec.json>" [char] " emit
    s" isa-load-spec" o-type cr
    cr ."   isa-gen-words4th  <out>/words.4th   ( -- )"
    cr ."   isa-gen-chip4th   <out>              ( -- )"
    cr ."   isa-gen-disasm    <out>/disasm.4th  ( -- )"
    cr ."   isa-help                            ( -- )"
    ;

[IFUNDEF] isa-fasm-loaded
    : isa-fasm-load
        ." ISA-to-FASM: fjson-based module loaded"
    ;
    true constant isa-fasm-loaded
[THEN]
