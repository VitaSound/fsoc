\ fsoc/futils/gen_golden.4th — порт tools/gen_golden.py
\ Генерация golden-эталонов ISA: запускает драйвер golden-src подпроцессом
\ gforth (bootstrap — как subprocess.run в оригинале), парсит строки IMAGE,
\ сортирует через fenum enum-sort, пишет tests/golden/<arch>.json
\ (паритет json.dumps(indent=2)) и tests/golden/<arch>-golden.4th.
\
\ Режим --external (внешний ассемблер) — отказ, как SystemExit в Python.
\
\ Использование:
\   s" mcs51" gen-golden         ( -- )   \ запись в tests/golden/
\   s" mcs51" s" /tmp" gen-golden-to ( -- ) \ запись в произвольный каталог
\   s" mcs51" gen-golden-external ( -- )  \ отказ (offline-only)
\
\ Стиль (уроки isa_to_fasm): без { }-локалов (ломают rstack в циклах и
\ ulist-each), pad не хранит долговременные данные, запись через
\ w/o create-file, имена слов с префиксом gg- (нет конфликта с
\ o-type и пр. из isa_to_fasm при общем futils-load).

\ ------------------------------------------------------------------
\ Зависимости
\ ------------------------------------------------------------------
require ../../forth-packages/fenum/0.1.1/fenum-bs.4th

\ ------------------------------------------------------------------
\ Запись образа (struct как в fjson/node.4th)
\ g-name указывают во входной буфер (живёт всю генерацию);
\ g-hex — отдельный выделенный буфер на образ.
\ ------------------------------------------------------------------
\ struct/field/constant на верхнем уровне оставляет мусор на стеке —
\ по образцу fjson/node.4th: mark глубины, drop лишнего после определения
variable gg-depth
: gg-mark ( -- ) depth gg-depth ! ;
: gg-unmark ( -- ) depth gg-depth @ - 0 ?do drop loop ;

gg-mark
struct
    cell% field g-name-a
    cell% field g-name-u
    cell% field g-hex-a
    cell% field g-hex-u
constant image%
gg-unmark

\ ------------------------------------------------------------------
\ Буферы и состояние
\ ------------------------------------------------------------------
create gg-in 65536 allot            \ stdout подпроцесса
variable gg-in-l
create gg-hex 65536 allot           \ аккумулятор hex текущего образа
variable gg-hex-l
create gg-path 256 allot            \ путь temp-файла / выходной путь
variable gg-path-l
create gg-cmd 640 allot              \ строка команды подпроцесса
variable gg-cmd-len
create gg-out 65536 allot           \ буфер генерируемого текста
variable gg-out-l
variable gg-arch-a variable gg-arch-u
variable gg-outdir-a variable gg-outdir-u
variable gg-images                   \ ulist image% записей

: gg-path-reset ( -- ) 0 gg-path-l ! ;
: gg-path-add ( a u -- )
    dup gg-path-l @ + 256 u>= abort" gen_golden: path too long"
    >r gg-path gg-path-l @ + r@ move r> gg-path-l +!
    ;
: gg-path@ ( -- a u ) gg-path gg-path-l @ ;

: gg-cmd-reset ( -- ) 0 gg-cmd-len ! ;
: gg-cmd-add ( a u -- )
    dup gg-cmd-len @ + 640 u>= abort" gen_golden: cmd too long"
    >r gg-cmd gg-cmd-len @ + r@ move r> gg-cmd-len +!
    ;
: gg-cmd@ ( -- a u ) gg-cmd gg-cmd-len @ ;

\ эмиссия в gg-out
: gg-emit ( a u -- )
    dup gg-out-l @ + 65536 u>= abort" gen_golden: out overflow"
    >r gg-out gg-out-l @ + r@ move r> gg-out-l +!
    ;
create gg-scratch 1 allot
: gg-emit-c ( c -- ) gg-scratch c! gg-scratch 1 gg-emit ;   \ одиночный символ
: gg-emit-cr ( -- ) 10 gg-emit-c ;
: gg-out-reset ( -- ) 0 gg-out-l ! ;

: gg-save ( bufa bufu patha pathu -- )
    w/o create-file throw >r
    r@ write-file throw
    r> close-file throw
    ;

\ ------------------------------------------------------------------
\ Этап 1: запуск драйвера golden-src и чтение его stdout
\ ------------------------------------------------------------------
: gg-run-driver ( -- )               \ использует gg-arch-a/u
    \ временный файл вывода
    gg-path-reset
    s" /tmp/fsoc-gen-golden-" gg-path-add
    gg-arch-a @ gg-arch-u @ gg-path-add
    s" .txt" gg-path-add
    \ команда: stdout+stderr подпроцесса -> файл (как capture_output в Python)
    gg-cmd-reset
    s" FSOC_HOME=$PWD gforth tests/golden-src/" gg-cmd-add
    gg-arch-a @ gg-arch-u @ gg-cmd-add
    s" /programs.4th > " gg-cmd-add
    gg-path@ gg-cmd-add
    s"  2>&1" gg-cmd-add
    gg-cmd@ system
    $? 0 <> if
        cr ." gen_golden: gforth failed:" cr
        gg-path@ type cr
        true abort" gen_golden: driver failed"
    then
    \ чтение вывода в gg-in
    gg-path@ r/o open-file throw >r
    gg-in 65536 r@ read-file
    >r gg-in-l ! r> drop
    r> close-file throw
    ;

\ ------------------------------------------------------------------
\ Этап 1: парсинг строк IMAGE -> ulist записей image%
\ ------------------------------------------------------------------
variable gpm-idx variable gpm-pa variable gpm-pu
: gg-match? ( idx pa pu -- f )       \ gg-in[idx..] начинается с (pa pu)?
    gpm-pu ! gpm-pa ! gpm-idx !
    gpm-idx @ gpm-pu @ + gg-in-l @ > if 0 exit then
    -1 gpm-pu @ 0 ?do
        gg-in gpm-idx @ + i + c@ gpm-pa @ i + c@ <> if drop 0 leave then
    loop
    ;

variable gll-idx
: gg-line-len ( idx -- len )         \ длина строки от idx (без LF)
    gll-idx !
    gll-idx @
    begin dup gg-in-l @ < while
        dup gg-in + c@ 10 = if gll-idx @ - exit then
        1+
    repeat
    gll-idx @ -
    ;

variable gia-na variable gia-nu variable gia-irec variable gia-hbuf
: gg-add-image ( name-a name-u -- )  \ hex из gg-hex/gg-hex-l
    gia-nu ! gia-na !
    image% allocate throw gia-irec !
    gia-na @ gia-irec @ g-name-a !
    gia-nu @ gia-irec @ g-name-u !
    gg-hex-l @ 1+ allocate throw gia-hbuf !
    gg-hex gia-hbuf @ gg-hex-l @ move
    gia-hbuf @ gia-irec @ g-hex-a !
    gg-hex-l @ gia-irec @ g-hex-u !
    gia-irec @ gg-images @ ulist-add
    ;

variable gpi-sidx variable gpi-slen
variable gpi-nstart variable gpi-nlen
variable gpi-hstart variable gpi-hlen
variable gpi-icur variable gpi-iend
variable gh-c

: gh-hex? ( c -- f )
    dup [char] 0 [char] 9 1+ within
    over [char] A [char] F 1+ within or
    over [char] a [char] f 1+ within or
    nip
    ;

: gg-parse-image ( sidx slen -- )    \ строка sidx..sidx+slen, префикс IMAGE уже проверен
    gpi-slen ! gpi-sidx !
    gpi-sidx @ 6 + gpi-nstart !      \ после "IMAGE "
    0 gpi-nlen !
    \ имя до первого пробела (while-цикл, без ?do)
    gpi-sidx @ 6 + gpi-icur !
    gpi-sidx @ gpi-slen @ + gpi-iend !
    begin gpi-icur @ gpi-iend @ < while
        gpi-nlen @ 0= if
            gg-in gpi-icur @ + c@ 32 = if
                gpi-icur @ gpi-sidx @ 6 + - gpi-nlen !
            then
        then
        1 gpi-icur +!
    repeat
    gpi-nlen @ 0= if exit then
    gpi-nstart @ gpi-nlen @ + gpi-hstart !
    gpi-sidx @ gpi-slen @ + gpi-hstart @ - gpi-hlen !
    0 gg-hex-l !                     \ аккумулятор: только hex-символы хвоста
    gpi-hstart @ gpi-icur !          \ перепользуем icur
    gpi-hstart @ gpi-hlen @ + gpi-iend !
    begin gpi-icur @ gpi-iend @ < while
        gg-in gpi-icur @ + c@ dup gh-hex? if
            gg-hex gg-hex-l @ + c! 1 gg-hex-l +!
        else
            drop
        then
        1 gpi-icur +!
    repeat
    gg-in gpi-nstart @ + gpi-nlen @ gg-add-image
    ;

: gg-parse-out ( -- )                \ gg-in -> gg-images
    ulist-new gg-images !
    0
    begin dup gg-in-l @ < while
        dup s" IMAGE " gg-match? if
            dup gg-line-len 2dup gg-parse-image + 1+
        else
            dup gg-line-len + 1+
        then
    repeat
    drop
    gg-images @ ulist-len 0= abort" gen_golden: no IMAGE lines"
    ;

\ ------------------------------------------------------------------
\ Этап 2: сортировка по имени через fenum enum-sort
\ (cmp = «порядок правилен», как %asc в тестах fenum)
\ ------------------------------------------------------------------
variable gc-ia variable gc-ib
: gg-cmp-name ( ia ib -- flag )
    gc-ib ! gc-ia !
    gc-ia @ g-name-a @ gc-ia @ g-name-u @
    gc-ib @ g-name-a @ gc-ib @ g-name-u @
    compare 0<=
    ;

: gg-sort-images ( -- )
    gg-images @ >r
    ['] gg-cmp-name gg-images @ enum-sort gg-images !
    r> ulist-dispose
    ;

\ ------------------------------------------------------------------
\ Этап 3: эмиссия JSON (паритет json.dumps(indent=2) + LF)
\ ------------------------------------------------------------------
variable gje-i
variable gg-jnode

: gg-emit-json ( -- )
    gg-out-reset
    s" {" gg-emit gg-emit-cr
    s"   " gg-emit [char] " gg-emit-c s" arch" gg-emit [char] " gg-emit-c
    s" : " gg-emit [char] " gg-emit-c
    gg-arch-a @ gg-arch-u @ gg-emit
    [char] " gg-emit-c s" ," gg-emit gg-emit-cr
    s"   " gg-emit [char] " gg-emit-c s" generator" gg-emit [char] " gg-emit-c
    s" : " gg-emit [char] " gg-emit-c
    s" bootstrap: fsoc fasm (gforth) \u2014 seed before external run" gg-emit
    [char] " gg-emit-c s" ," gg-emit gg-emit-cr
    s"   " gg-emit [char] " gg-emit-c s" images" gg-emit [char] " gg-emit-c
    s" : [" gg-emit gg-emit-cr
    gg-images @ ulist-len 0 ?do
        i gg-images @ ulist-nth-addr gg-jnode !
        s"     {" gg-emit gg-emit-cr
        s"       " gg-emit [char] " gg-emit-c s" name" gg-emit [char] " gg-emit-c
        s" : " gg-emit [char] " gg-emit-c
        gg-jnode @ g-name-a @ gg-jnode @ g-name-u @ gg-emit
        [char] " gg-emit-c s" ," gg-emit gg-emit-cr
        s"       " gg-emit [char] " gg-emit-c s" bytes" gg-emit [char] " gg-emit-c
        s" : " gg-emit [char] " gg-emit-c
        gg-jnode @ g-hex-a @ gg-jnode @ g-hex-u @ gg-emit
        [char] " gg-emit-c gg-emit-cr
        s"     }" gg-emit
        i gg-images @ ulist-len 1- < if [char] , gg-emit-c then
        gg-emit-cr
    loop
    s"   ]" gg-emit gg-emit-cr
    s" }" gg-emit gg-emit-cr
    ;

\ ------------------------------------------------------------------
\ Этап 3: эмиссия <arch>-golden.4th
\ ------------------------------------------------------------------
: gg-emit-4th ( -- )
    gg-out-reset
    s" \ tests/golden/" gg-emit
    gg-arch-a @ gg-arch-u @ gg-emit
    s" -golden.4th — auto-generated by gen_golden.py." gg-emit gg-emit-cr
    s" \ Do not edit; regenerate with `python3 tools/gen_golden.py " gg-emit
    gg-arch-a @ gg-arch-u @ gg-emit
    s" `." gg-emit gg-emit-cr
    gg-emit-cr
    gg-images @ ulist-len 0 ?do
        i gg-images @ ulist-nth-addr gg-jnode !
        [char] s gg-emit-c [char] " gg-emit-c 32 gg-emit-c    \ s" + пробел
        gg-jnode @ g-hex-a @ gg-jnode @ g-hex-u @ gg-emit
        [char] " gg-emit-c                         \ закрывающая кавычка
        s"  2constant golden:" gg-emit
        gg-jnode @ g-name-a @ gg-jnode @ g-name-u @ gg-emit
        gg-emit-cr
    loop
    ;

\ ------------------------------------------------------------------
\ Этап 4: CLI
\ ------------------------------------------------------------------
: gg-external-tools ( a u -- a u )  \ имя тулчейна для арх (как EXTERNAL в Python)
    2dup s" mcs51" compare 0= if 2drop s" sdas8051" exit then
    2dup s" avr"   compare 0= if 2drop s" avr-gcc" exit then
    2dup s" z80"   compare 0= if 2drop s" z80asm" exit then
    2drop s" <none>"
    ;

: gen-golden-external ( a u -- )    \ отказ, как SystemExit в Python
    gg-external-tools
    cr ." external golden generation requires the offline toolchain ("
    type
    cr ." ); run it where the assembler is installed."
    true abort" gen_golden: external mode unavailable"
    ;

: gen-golden-to ( arch outdir -- )
    gg-outdir-u ! gg-outdir-a !
    gg-arch-u ! gg-arch-a !
    \ output_dir.mkdir(parents=True, exist_ok=True) из Python
    gg-cmd-reset
    s" mkdir -p " gg-cmd-add
    gg-outdir-a @ gg-outdir-u @ gg-cmd-add
    gg-cmd@ system $? 0<> abort" gen_golden: mkdir failed"
    gg-run-driver
    gg-parse-out
    gg-sort-images
    \ JSON
    gg-emit-json
    gg-path-reset
    gg-outdir-a @ gg-outdir-u @ gg-path-add
    s" /" gg-path-add
    gg-arch-a @ gg-arch-u @ gg-path-add
    s" .json" gg-path-add
    gg-out gg-out-l @ gg-path@ gg-save
    cr ." wrote " gg-path@ type
    ."  (" gg-images @ ulist-len . ." images)" cr
    \ golden .4th
    gg-emit-4th
    gg-path-reset
    gg-outdir-a @ gg-outdir-u @ gg-path-add
    s" /" gg-path-add
    gg-arch-a @ gg-arch-u @ gg-path-add
    s" -golden.4th" gg-path-add
    gg-out gg-out-l @ gg-path@ gg-save
    cr ." wrote " gg-path@ type cr
    ;

: gen-golden ( arch -- )             \ запись в tests/golden (как Python)
    s" tests/golden" gen-golden-to
    ;

[IFUNDEF] gen-golden-loaded
    : gen-golden-load
        ." gen_golden module loaded"
    ;
    true constant gen-golden-loaded
[THEN]
