\ fsoc/futils/region_check.4th
\ Gforth-порт tests/region_check.py — spiflash-регион в csr.json
\   лежит рядом с bit-устройствами и НЕ является boot ROM.
\
\ Использование:
\   s" /path/to/dir" rc-check        ( -- status )
\   status: 0 = ok; 1 = count (не 1 регион); 2 = name (≠ "spiflash");
\            3 = fields (base/size/mode неверны); 4 = shape (≠ 4 ключа
\                 name/base/size/mode); 5 = reserved (rom/main_ram);
\            6 = led (led.addr ≠ $400 или нет bit)
\
\ Инфраструктура:
\   fenum-bs — структура rc-reg% для первого региона (имя/base/size/mode).
\   Собственный JSON-извлекатель (begin/while) — fjson НЕ используется.
\
\ Gforth-quirks этой сборки (0.7.9_20250101, проверено):
\   * DO/??DO сломаны — только begin/while/repeat.
\   * `and`/`or` — ДВА операнда; три флага: `f1 f2 and f3 and`.
\   * cmove (src dst n).  `!` потребляет (x a).  `c@`/`c!` — (x a) адрес
\     СНИЗУ (ANS).
\   * s" только top-level; в рантайме — статические create-буферы.
\   * `exit` из begin/while коррит стек — выход через флаг.
\   * Чтение за пределами буфера — bounds-guard (rc-cpeek/rc-cget дают 0).
[IFUNDEF] region-check-loaded

    require ../../forth-packages/fenum/0.1.1/fenum-bs.4th

    \ ------------------------------------------------------------------
    \ Статические строки (top-level s" + swap cmove)
    \ ------------------------------------------------------------------
    create rc-k-regions  8 allot
    create rc-k-devices  8 allot
    create rc-k-name     5 allot
    create rc-k-base     5 allot
    create rc-k-size     5 allot
    create rc-k-mode     5 allot
    create rc-k-bit      4 allot
    create rc-k-addr     5 allot
    create rc-k-rom      4 allot
    create rc-k-main     8 allot
    create rc-k-led      4 allot
    create rc-s-spiflash 9 allot
    create rc-s-ro       3 allot
    create rc-suf-json   10 allot
    7 constant rc-l-k-regions
    7 constant rc-l-k-devices
    4 constant rc-l-k-name
    4 constant rc-l-k-base
    4 constant rc-l-k-size
    4 constant rc-l-k-mode
    3 constant rc-l-k-bit
    4 constant rc-l-k-addr
    3 constant rc-l-k-rom
    8 constant rc-l-k-main
    3 constant rc-l-k-led
    8 constant rc-l-s-spiflash
    2 constant rc-l-s-ro
    9 constant rc-l-suf-json
    s" regions"  rc-k-regions  swap cmove
    s" devices"  rc-k-devices  swap cmove
    s" name"     rc-k-name     swap cmove
    s" base"     rc-k-base     swap cmove
    s" size"     rc-k-size     swap cmove
    s" mode"     rc-k-mode     swap cmove
    s" bit"      rc-k-bit      swap cmove
    s" addr"     rc-k-addr     swap cmove
    s" rom"      rc-k-rom      swap cmove
    s" main_ram" rc-k-main     swap cmove
    s" led"      rc-k-led      swap cmove
    s" spiflash" rc-s-spiflash swap cmove
    s" ro"       rc-s-ro       swap cmove
    s" /csr.json" rc-suf-json  swap cmove

    \ ------------------------------------------------------------------
    \ fenum-структура первого региона
    \ ------------------------------------------------------------------
    begin-structure rc-reg%
        field: rr-nlen      \ длина имени
        field: rr-base
        field: rr-size
        field: rr-mlen      \ длина mode
    end-structure
    create rc-regbuf 1 rc-reg% * allot
    create rc-rname 32 allot     \ имя первого региона
    create rc-rmode 8  allot     \ mode первого региона
    variable rc-reg-n            \ кол-во регионов
    variable rc-reg-seen         \ обработан ли первый регион
    variable rc-obj-n

    \ shape: биты 1=name 2=base 4=size 8=mode; счётчик чужих ключей
    variable rc-kflags
    variable rc-unexp

    \ led-устройство
    variable rc-led-addr
    variable rc-led-hasbit
    variable rc-led-found
    variable rc-in-led

    variable rc-reserved   \ true если есть регион rom/main_ram

    \ ------------------------------------------------------------------
    \ Буферы / позиции
    \ ------------------------------------------------------------------
    create rc-json  8192 allot
    variable rc-json-l
    variable rc-p
    variable rc-cw
    variable rc-ba         \ начало строки rc-parse-string
    variable rc-sl         \ длина строки
    variable rc-sdone
    variable rc-arrmode    \ 0=регионы 1=устройства
    variable rc-err

    create rc-patha 1024 allot
    variable rc-pf-a
    variable rc-pf-u
    variable rc-fid

    \ rc-cmove ( src dst n -- )
    variable rc-msrc
    variable rc-mdst
    variable rc-mn
    variable rc-mi
    : rc-cmove ( src dst n -- )
        rc-mn !
        rc-mdst !
        rc-msrc !
        0 rc-mi !
        begin
            rc-mi @ rc-mn @ u<
            while
                rc-msrc @ rc-mi @ + c@
                rc-mdst @ rc-mi @ + c!
                1 rc-mi +!
            repeat ;

    \ rc-store-dir ( dir-a dir-u -- ) — копия в статический буфер
    variable rc-dir-a
    variable rc-dir-u
    create rc-dir-buf 1024 allot
    : rc-store-dir ( dir-a dir-u -- )
        rc-dir-u !
        rc-dir-a !
        rc-dir-a @
        rc-dir-buf
        rc-dir-u @
        cmove
        rc-dir-buf rc-dir-a ! ;

    variable rc-sa
    variable rc-su
    : rc-path ( suffix-a suffix-u -- )
        rc-su !
        rc-sa !
        rc-dir-a @  rc-patha  rc-dir-u @  rc-cmove
        rc-sa @  rc-patha rc-dir-u @ +  rc-su @  rc-cmove
        rc-dir-u @ rc-su @ +
        rc-pf-u !
        rc-patha rc-pf-a ! ;

    : rc-read ( -- )
        rc-pf-a @ rc-pf-u @
        r/o open-file throw rc-fid !
        rc-json 8192 rc-fid @ read-file
        drop rc-json-l !
        rc-fid @ close-file drop ;

    \ ------------------------------------------------------------------
    \ Примитивы (bounds-safe)
    \ ------------------------------------------------------------------
    : rc-jmp   ( -- )  1 rc-p +! ;
    : rc-cget  ( -- c )
        rc-p @
        dup rc-json-l @ u>= if  0
        else  rc-json + c@
        then ;
    : rc-cpeek ( -- c )
        rc-p @
        dup rc-json-l @ u>= if  0
        else  rc-json + c@
        then ;
    : rc-cpeek! ( -- )  rc-cpeek rc-cw ! ;
    : rc-skip-ws
        begin
            rc-cpeek!
            rc-cw @ 32 =
            rc-cw @ 9  = or
            rc-cw @ 13 = or
            rc-cw @ 10 = or
            while
            rc-jmp
        repeat ;

    \ ( a u b vb -- f ) — сравнение строк (begin/while)
    variable rc-sa2
    variable rc-su2
    variable rc-sb2
    variable rc-sbu2
    variable rc-ci2
    variable rc-cok2
    : rc-str= ( a u b vb -- f )
        rc-sbu2 !
        rc-sb2 !
        rc-su2 !
        rc-sa2 !
        rc-su2 @ rc-sbu2 @ = if
            0 rc-ci2 !
            1 rc-cok2 !
            begin
                rc-cok2 @ 1 and
                rc-ci2 @ rc-su2 @ u<
                and
                while
                    rc-sa2 @ rc-ci2 @ + c@
                    rc-sb2 @ rc-ci2 @ + c@
                    = if ( 1 ) else 0 rc-cok2 ! then
                    1 rc-ci2 +!
                repeat
            rc-cok2 @
        else
            0
        then ;

    \ ( -- a u )  c"..." из rc-json; rc-p после закрывающей "
    : rc-parse-string ( -- a u )
        rc-jmp
        rc-json rc-p @ + rc-ba !
        0 rc-sl !
        0 rc-sdone !
        begin
            rc-sdone @ 0=
            rc-p @ rc-json-l @ u<
            and
            while
                rc-cpeek!
                rc-cw @ 92 = if
                    rc-jmp rc-jmp
                    2 rc-sl +!
                else
                    rc-cw @ 34 = if
                        1 rc-sdone !
                    else
                        rc-jmp
                        1 rc-sl +!
                    then
                then
            repeat
        rc-jmp
        rc-ba @
        rc-sl @ ;

    \ ( -- )  пропустить c"..."
    : rc-skip-str
        rc-jmp
        0 rc-sdone !
        begin
            rc-sdone @ 0=
            rc-p @ rc-json-l @ u<
            and
            while
                rc-cpeek!
                rc-cw @ 92 = if
                    rc-jmp rc-jmp
                else
                    rc-cw @ 34 = if
                        1 rc-sdone !
                    else
                        rc-jmp
                    then
                then
            repeat
        rc-jmp ;

    \ ( -- n )  целое (знак опционален)
    : rc-num ( -- n )
        0 >r
        rc-cpeek!
        rc-cw @ 45 = if  rc-jmp  then
        begin
            rc-cpeek!
            rc-cw @ 48 - 10 u<
            while
                r> 10 * rc-cw @ 48 - + >r
                rc-jmp
            repeat
        r> ;

    \ ( -- )  пропустить любое значение
    : rc-skip-value
        rc-skip-ws
        rc-cpeek!
        rc-cw @ 34 = if
            rc-skip-str
        else
            rc-cpeek!
            rc-cw @ 123 =
            rc-cw @ 91  = or if
                rc-jmp
                1 >r
                begin
                    r> 0<>
                    rc-p @ rc-json-l @ u<
                    and
                    while
                        rc-cpeek!
                        rc-cw @ 91  =
                        rc-cw @ 123 = or if
                            rc-jmp
                            1 r> + >r
                        else
                            rc-cw @ 93  =
                            rc-cw @ 125 = or if
                                1 r> - >r
                                rc-jmp
                            else
                                rc-cw @ 34 = if
                                    rc-skip-str
                                else
                                    rc-cw @ 44 = if  rc-jmp  then
                                    rc-jmp
                                then
                            then
                        then
                    repeat
                drop
            else
                begin
                    rc-p @ rc-json-l @ u< if
                        rc-cpeek!
                        rc-cw @ 44  =
                        rc-cw @ 125 = or
                        rc-cw @ 93  = or
                        rc-cw @ 10  = or
                        0=
                    else
                        false
                    then
                while
                    rc-jmp
                repeat
            then
        then ;

    \ ------------------------------------------------------------------
    \ Извлечение значений
    \ ------------------------------------------------------------------
    \ ( -- )  ключ+значение ПЕРВОГО региона (rc-reg-seen = 0)
    : rc-first-region-key ( -- )
        rc-ba @ rc-sl @ rc-k-name rc-l-k-name rc-str=
        if
            rc-parse-string 2drop
            1 rc-kflags +!
            rc-sl @ rc-regbuf rr-nlen !
            rc-ba @ rc-rname rc-sl @ rc-cmove
        else
            rc-ba @ rc-sl @ rc-k-base rc-l-k-base rc-str=
            if
                rc-num
                2 rc-kflags +!
                rc-regbuf rr-base !
            else
                rc-ba @ rc-sl @ rc-k-size rc-l-k-size rc-str=
                if
                    rc-num
                    4 rc-kflags +!
                    rc-regbuf rr-size !
                else
                    rc-ba @ rc-sl @ rc-k-mode rc-l-k-mode rc-str=
                    if
                        rc-parse-string 2drop
                        8 rc-kflags +!
                        rc-sl @ rc-regbuf rr-mlen !
                        rc-ba @ rc-rmode rc-sl @ rc-cmove
                    else
                        1 rc-unexp +!
                        rc-skip-value
                    then
                then
            then
        then ;

    \ ( -- )  ключ+значение ДРУГОГО региона (только имена для reserved)
    : rc-other-region-key ( -- )
        rc-ba @ rc-sl @
        rc-k-name rc-l-k-name rc-str=
        if
            rc-parse-string 2drop
            rc-ba @ rc-sl @
            rc-k-rom rc-l-k-rom rc-str=
            rc-ba @ rc-sl @
            rc-k-main rc-l-k-main rc-str=
            or
            if
                1 rc-reserved !
            then
            exit
        then
        rc-skip-value ;

    \ ( -- )  ключ+значение устройства (ищем led)
    : rc-dev-key ( -- )
        rc-ba @ rc-sl @ rc-k-name rc-l-k-name rc-str=
        if
            rc-parse-string 2drop
            rc-ba @ rc-sl @ rc-k-led rc-l-k-led rc-str=
            if
                1 rc-in-led !
                1 rc-led-found !
            then
        else
            rc-ba @ rc-sl @ rc-k-addr rc-l-k-addr rc-str=
            if
                rc-num
                rc-in-led @ if  rc-led-addr !  else drop  then
            else
                rc-ba @ rc-sl @ rc-k-bit rc-l-k-bit rc-str=
                if
                    rc-skip-value
                    rc-in-led @ if  1 rc-led-hasbit !  then
                else
                    rc-skip-value
                then
            then
        then ;

    \ ( -- )  один объект массива
    : rc-parse-obj ( -- )
        rc-jmp                                \ {
        0 rc-in-led !
        begin
            rc-cpeek!
            rc-cw @ 125 = 0=
            rc-p @ rc-json-l @ u<
            and
            while
                rc-skip-ws
                rc-parse-string
                drop drop
                rc-skip-ws
                rc-cget drop                  \ :
                rc-jmp
                rc-skip-ws
                rc-arrmode @ 0= if
                    rc-obj-n @ 1 =
                    if
                        rc-first-region-key
                    else
                        rc-other-region-key
                    then
                else
                    rc-dev-key
                then
                rc-skip-ws
                rc-cpeek!
                rc-cw @ 44 = if  rc-jmp  then
                rc-skip-ws
            repeat
        rc-jmp                                \ }
        ;

    \ ( -- n )  массив объектов; запоминает count
    : rc-parse-array ( -- )
        0 rc-obj-n !
        rc-cpeek!
        rc-cw @ 91 = 0= if
            0
        else
            rc-jmp
            rc-skip-ws
            rc-cpeek!
            rc-cw @ 93 = if
                rc-jmp
                0
            else
                0 >r
                begin
                    rc-cpeek!
                    rc-cw @ 93 = 0=
                    rc-p @ rc-json-l @ u<
                    and
                    while
                        1 rc-obj-n +!
                        rc-parse-obj
                        1 r> + >r
                        rc-skip-ws
                        rc-cpeek!
                        rc-cw @ 44 = if
                            rc-jmp
                            rc-skip-ws
                        then
                    repeat
                rc-jmp
                r>
            then
        then ;

    \ ------------------------------------------------------------------
    \ Топ-уровневый разбор csr.json
    \ ------------------------------------------------------------------
    : rc-parse-kv ( -- )
        rc-ba @ rc-sl @
        rc-k-regions rc-l-k-regions rc-str=
        if
            0 rc-arrmode !
            rc-cpeek!
            rc-cw @ 91 = 0= if
                1 rc-err +!
            else
                rc-parse-array
                rc-reg-n !
            then
        else
            rc-ba @ rc-sl @
            rc-k-devices rc-l-k-devices rc-str=
            if
                1 rc-arrmode !
                rc-cpeek!
                rc-cw @ 91 = 0= if
                    1 rc-err +!
                else
                    rc-parse-array drop   \ count unused (led walk already done)
                then
            else
                rc-skip-value
            then
        then ;

    : rc-parse-json ( -- status )
        0 rc-err !
        0 rc-reg-n !
        0 rc-reg-seen !
        0 rc-obj-n !
        1 rc-led-found !      \ "led не найден" по умолчанию
        0 rc-led-hasbit !
        0 rc-kflags !
        0 rc-unexp !
        0 rc-reserved !
        0 rc-p !
        rc-skip-ws
        rc-cpeek!
        rc-cw @ 123 = 0= if
            1 rc-err +!
            exit
        then
        rc-jmp
        begin
            rc-cpeek!
            rc-cw @ 125 = 0=
            rc-p @ rc-json-l @ u<
            and
            rc-err @ 0=
            and
            while
                rc-skip-ws
                rc-parse-string 2drop   \ key already in rc-ba/rc-sl for rc-parse-kv
                rc-skip-ws
                rc-cget drop
                rc-jmp
                rc-skip-ws
                rc-parse-kv
                rc-skip-ws
                rc-cpeek!
                rc-cw @ 44 = if  rc-jmp  then
                rc-skip-ws
            repeat
        rc-jmp
        rc-err @ ;

    \ ------------------------------------------------------------------
    \ Валидация + драйвер
    \ ------------------------------------------------------------------
    variable rc-st
    : rc-ok? ( -- f )  rc-st @ 0= ;
    \ ( -- status ) — проверка по уже извлечённым данным
    : rc-validate ( -- status )
        0 rc-st !
        rc-reg-n @ 1 = 0= if  1 rc-st !  then
        rc-ok? if
            rc-kflags @ 15 =
            rc-unexp @ 0=
            and
            0=
            if
                4 rc-st !
            else
                rc-rname rc-regbuf rr-nlen @
                rc-s-spiflash rc-l-s-spiflash rc-str= 0=
                if
                    2 rc-st !
                else
                    rc-regbuf rr-base @ $10000 =
                    rc-regbuf rr-size @ 4194304 =
                    and
                    rc-rmode rc-regbuf rr-mlen @
                    rc-s-ro rc-l-s-ro rc-str=
                    and
                    0=
                    if  3 rc-st !  then
                then
            then
        then
        rc-ok? if
            rc-reserved @
            if  5 rc-st !  then
        then
        rc-ok? if
            rc-led-found @ 0=
            rc-led-hasbit @ 0=
            or
            rc-led-addr @ $400 = 0=
            or
            if  6 rc-st !  then
        then
        rc-st @ ;

    : rc-check ( dir-a dir-u -- status )
        rc-store-dir
        rc-suf-json rc-l-suf-json
        rc-path
        rc-read
        rc-parse-json
        dup 0= if
            drop
            rc-validate
        then ;

    true constant region-check-loaded
[THEN]
