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

: isa-load-spec ( path -- node|0 )
    r/o open-file throw
    isa-fid !
    8192 allocate throw
    dup 8192 isa-fid @ read-file
    drop
    fjson.parse
    dup isa-root-node !
    isa-fid @ close-file throw
    ;

\ ------------------------------------------------------------------
\ Доступ к полям JSON: (obj key-a key-u -- val|0) через rot
\ ------------------------------------------------------------------
: isa-get-str ( obj key-a key-u -- a u | 0 0 )
    rot fjson.object-get
    dup 0= if 2drop 0 0 exit then
    fjson.node-str@
    ;
: isa-get-num ( obj key-a key-u -- u | 0 )
    rot fjson.object-get
    dup 0= if drop 0 exit then
    fjson.node-num@
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
: isa-emit-stack-comment-raw ( -- )
    o-space [char] ( o-ch
    isa-opcount @ 0 ?do
        o-space
        i isa-ops @ fjson.array-nth fjson.node-str@ o-type
    loop
    s"  -- )" o-type
    ;

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
        isa-emit-stack-comment-raw o-cr
        s"   \ TODO: implement " o-type isa-ma @ isa-ml @ o-type s" ;" o-type o-cr
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
\ Точка входа
\ ------------------------------------------------------------------
: isa-help
    cr ." ISA-to-FASM utilities (port of tools/isa_to_fasm.py):"
    cr ."   Load spec: " [char] " emit s" <spec.json>" [char] " emit
    s" isa-load-spec" o-type cr
    cr ."   isa-gen-words4th  <out>/words.4th   ( -- )"
    cr ."   isa-gen-chip4th   <out>              ( -- )"
    cr ."   isa-help                            ( -- )"
    ;

[IFUNDEF] isa-fasm-loaded
    : isa-fasm-load
        ." ISA-to-FASM: fjson-based module loaded"
    ;
    true constant isa-fasm-loaded
[THEN]
