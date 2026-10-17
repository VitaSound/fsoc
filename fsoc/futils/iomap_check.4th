\ fsoc/futils/iomap_check.4th
\ Gforth-порт tests/iomap_check.py — сверка csr.json / iomap.vh / csr.fs.
\
\ Использование:
\   s" /path/to/dir" imap-check        ( -- status )
\   status: 0 = все совпадают; 1 = bus; 2 = regions; 3 = count;
\            4 = json (device name/bit/addr или отсутствующее поле);
\            5 = vh; 6 = fs
\
\ Инфраструктура:
\   fenum-bs — таблица imap-dev[N] (имя/bit/адрес) на begin-structure.
\   Собственный JSON-парсер (begin/while) — fjson НЕ используется.
\
\ Gforth-quirks этой сборки (0.7.9_20250101, проверено):
\   * DO/??DO сломаны — только begin/while/repeat.
\   * `cpeek 32 = 9 = or` — underflow: `=` ждёт 2, а после первого
\     сравнения остался 1; а `dup 32 = dup 9 =` сравнивает РЕЗУЛЬТАТ.
\     Надёжно: `cpeek imap-cw !`, затем сравнения `imap-cw @ X =`.
\   * begin-structure: запись ( value struct-addr field ! ),
\     чтение ( struct-addr field @ ).
\   * s" только top-level; в рантайме — статические create-буферы.
\   * `create N allot > 8192` режет pad.
\   * `exit` из begin/while коррит стек — выход через флаг.
[IFUNDEF] iomap-check-loaded

    require ../../forth-packages/fenum/0.1.1/fenum-bs.4th

    \ ------------------------------------------------------------------
    \ Статические строки (top-level s" + swap cmove)
    \ ------------------------------------------------------------------
    create imap-k-bus      4 allot
    create imap-k-regions  8 allot
    create imap-k-devices  8 allot
    create imap-k-name     5 allot
    create imap-k-bit      4 allot
    create imap-k-addr     5 allot
    create imap-s-j1io     6 allot
    3 constant imap-l-k-bus
    7 constant imap-l-k-regions
    7 constant imap-l-k-devices
    4 constant imap-l-k-name
    3 constant imap-l-k-bit
    4 constant imap-l-k-addr
    5 constant imap-l-s-j1io
    s" bus"      imap-k-bus swap cmove
    s" regions"  imap-k-regions swap cmove
    s" devices"  imap-k-devices swap cmove
    s" name"     imap-k-name swap cmove
    s" bit"      imap-k-bit swap cmove
    s" addr"     imap-k-addr swap cmove
    s" j1-io"    imap-s-j1io swap cmove

    create imap-suf-json 10 allot
    create imap-suf-vh   10 allot
    create imap-suf-fs    8 allot
    9 constant imap-l-suf-json
    9 constant imap-l-suf-vh
    7 constant imap-l-suf-fs
    s" /csr.json" imap-suf-json swap cmove
    s" /iomap.vh" imap-suf-vh   swap cmove
    s" /csr.fs"   imap-suf-fs   swap cmove

    \ ------------------------------------------------------------------
    \ fenum-таблица: по слоту на устройство (макс. 8).
    \ imd-name — адрес строки имени в imap-json; imd-nlen — длина.
    \ ------------------------------------------------------------------
    begin-structure imap-devrec%
        field: imd-name
        field: imd-nlen
        field: imd-bit
        field: imd-addr
    end-structure
    variable imap-dev-n
    create imap-dev 8 imap-devrec% * allot

    \ ------------------------------------------------------------------
    \ Буферы
    \ ------------------------------------------------------------------
    create imap-json  8192 allot
    variable imap-json-l
    create imap-vhbuf 8192 allot
    variable imap-vh-l
    create imap-fsbuf 8192 allot
    variable imap-fs-l
    variable imap-fid

    create imap-patha 1024 allot
    variable imap-pf-a
    variable imap-pf-u

    \ imap-cmove ( src dst n -- ) — byte-копирование (begin/while)
    variable imap-msrc
    variable imap-mdst
    variable imap-mn
    variable imap-mi
    : imap-cmove ( src dst n -- )
        imap-mn !
        imap-mdst !
        imap-msrc !
        0 imap-mi !
        begin
            imap-mi @ imap-mn @ u< while
                imap-msrc @ imap-mi @ + c@
                imap-mdst @ imap-mi @ + c!
                1 imap-mi +!
            repeat ;

    \ imap-dir-a/imap-dir-u — базовый каталог (запоминается один раз)
    variable imap-dir-a
    variable imap-dir-u
    variable imap-sa
    variable imap-su
    : imap-store-dir ( dir-a dir-u -- )
        imap-dir-u !
        imap-dir-a ! ;
    \ ( suffix-a suffix-u -- ) — собрать путь из запомненного каталога
    : imap-path ( suffix-a suffix-u -- )
        imap-su !
        imap-sa !
        imap-dir-a @  imap-patha  imap-dir-u @  imap-cmove
        imap-sa @  imap-patha imap-dir-u @ +  imap-su @  imap-cmove
        imap-dir-u @ imap-su @ +
        imap-pf-u !
        imap-patha imap-pf-a ! ;

    : imap-read-json ( pf-a pf-u -- )
        r/o open-file throw imap-fid !
        imap-json 8192 imap-fid @ read-file
        drop imap-json-l !
        imap-fid @ close-file drop ;
    : imap-read-vh ( pf-a pf-u -- )
        r/o open-file throw imap-fid !
        imap-vhbuf 8192 imap-fid @ read-file
        drop imap-vh-l !
        imap-fid @ close-file drop ;
    : imap-read-fs ( pf-a pf-u -- )
        r/o open-file throw imap-fid !
        imap-fsbuf 8192 imap-fid @ read-file
        drop imap-fs-l !
        imap-fid @ close-file drop ;

    \ ------------------------------------------------------------------
    \ Статические маркеры vh / fs / device-имена (top-level)
    \ ------------------------------------------------------------------
    create imap-m-led      16 allot
    create imap-m-timer    18 allot
    create imap-m-dt       22 allot
    create imap-m-ds       24 allot
    16 constant imap-l-m-led
    18 constant imap-l-m-timer
    22 constant imap-l-m-dt
    24 constant imap-l-m-ds
    s" IO_LED_BIT = 10;"             imap-m-led  swap cmove
    s" IO_TIMER_BIT = 11;"           imap-m-timer swap cmove
    s" IO_UART_DATA_BIT = 12;"       imap-m-dt   swap cmove
    s" IO_UART_STATUS_BIT = 13;"     imap-m-ds   swap cmove

    create imap-m-fs-led   20 allot
    create imap-m-fs-timer 22 allot
    create imap-m-fs-dt    27 allot
    create imap-m-fs-ds    29 allot
    20 constant imap-l-m-fs-led
    22 constant imap-l-m-fs-timer
    27 constant imap-l-m-fs-dt
    29 constant imap-l-m-fs-ds
    s" $400 constant IO-LED"         imap-m-fs-led   swap cmove
    s" $800 constant IO-TIMER"       imap-m-fs-timer swap cmove
    s" $1000 constant IO-UART-DATA"  imap-m-fs-dt    swap cmove
    s" $2000 constant IO-UART-STATUS" imap-m-fs-ds   swap cmove

    create imap-n-led    4 allot
    create imap-n-timer  5 allot
    create imap-n-dt     9 allot
    create imap-n-ds    11 allot
    3  constant imap-l-n-led
    5  constant imap-l-n-timer
    9  constant imap-l-n-dt
    11 constant imap-l-n-ds
    s" led"         imap-n-led   swap cmove
    s" timer"       imap-n-timer swap cmove
    s" uart_data"   imap-n-dt    swap cmove
    s" uart_status" imap-n-ds    swap cmove

    \ ------------------------------------------------------------------
    \ Поиск подстроки (begin/while, как в uart_check.4th)
    \ ( na nu pos -- idx|-1 )
    \ ------------------------------------------------------------------
    variable imap-hay
    variable imap-hay-l
    variable imap-na
    variable imap-nu
    variable imap-fi
    variable imap-fj
    variable imap-pm
    variable imap-found
    variable imap-idx

    : imap-match-at ( -- f )
        1 imap-pm !
        0 imap-fj !
        begin
            imap-pm @ 1 and
            imap-fj @ imap-nu @ u<
            and
            while
                imap-hay @ imap-fi @ + imap-fj @ + c@
                imap-na @ imap-fj @ + c@
                = if ( 1 ) else 0 imap-pm ! then
                1 imap-fj +!
            repeat
        imap-pm @ ;

    : imap-find-str ( na nu pos -- idx|-1 )
        imap-fi !
        imap-nu !
        imap-na !
        0 imap-idx !
        0 imap-found !
        begin
            imap-found @ 0=
            imap-fi @ imap-hay-l @ imap-nu @ - u<=
            and
            while
                imap-match-at if
                    imap-fi @ imap-idx !
                    1 imap-found !
                then
                1 imap-fi +!
            repeat
        imap-found @ if  imap-idx @  else -1  then ;

    variable imap-nd-na
    variable imap-nd-nu
    : imap-needle? ( hay-a hay-l na nu -- found? )
        imap-nd-nu !     \ A L N
        imap-nd-na !     \ A L
        imap-hay-l !     \ A
        imap-hay !       \
        imap-nd-na @ imap-nd-nu @ 0
        imap-find-str 0< 0= ;

    \ ( a u b vb -- f ) — сравнение строк
    variable imap-sa2
    variable imap-su2
    variable imap-sb2
    variable imap-sbu2
    variable imap-ci2
    variable imap-cok2
    : imap-str= ( a u b vb -- f )
        imap-sbu2 !
        imap-sb2 !
        imap-su2 !
        imap-sa2 !
        imap-su2 @ imap-sbu2 @ = if
            0 imap-ci2 !
            1 imap-cok2 !
            begin
                imap-cok2 @ 1 and
                imap-ci2 @ imap-su2 @ u<
                and
                while
                    imap-sa2 @ imap-ci2 @ + c@
                    imap-sb2 @ imap-ci2 @ + c@
                    = if ( 1 ) else 0 imap-cok2 ! then
                    1 imap-ci2 +!
                repeat
            imap-cok2 @
        else
            0
        then ;

    \ ( rec* a u -- name? ) — имя устройства == (a u)?
    : imd-name= ( rec* a u -- f )
        rot                \ a u rec*
        >r                 \ a u         [rec*]
        r> dup             \ a u rec* rec*
           imd-name @       \ a u rec* name-ptr
        swap               \ a u name-ptr rec*
           imd-nlen @       \ a u name-ptr nlen
        imap-str= ;

    \ ------------------------------------------------------------------
    \ JSON-парсер (рекурсивный, begin/while)
    \ imap-p — текущая позиция в imap-json
    \ ------------------------------------------------------------------
    variable imap-p
    variable imap-cw        \ "current char" для сравнений (без stack-цепей)
    variable imap-err
    variable imap-dbit
    variable imap-daddr
    variable imap-dname-a
    variable imap-dname-u
    variable imap-ba2
    variable imap-bu2
    variable imap-sl
    variable imap-depth
    variable imap-mask
    variable imap-pj-done
    variable imap-sdone
    variable imap-cur

    : jmp   ( -- )  1 imap-p +! ;
    : cget  ( -- c )
        imap-p @
        dup imap-json-l @ u>= if  0
        else  imap-json + c@
        then ;
    : cpeek ( -- c )
        imap-p @
        dup imap-json-l @ u>= if  0
        else  imap-json + c@
        then ;
    : cpeek! ( -- )  cpeek imap-cw ! ;
    : skip-ws
        begin
            cpeek!
            imap-cw @ 32 =
            imap-cw @ 9  = or
            imap-cw @ 13 = or
            imap-cw @ 10 = or
            while
            jmp
        repeat ;

    \ ( -- a u )  c"..." — (a u) из imap-json; imap-p после закрывающей "
    : parse-string ( -- a u )
        jmp
        imap-json imap-p @ + imap-ba2 !
        0 imap-sl !
        0 imap-sdone !
        begin
            imap-sdone @ 0=
            while
                cpeek!
                imap-cw @ 92 = if
                    jmp jmp
                    2 imap-sl +!
                else
                    imap-cw @ 34 = if
                        1 imap-sdone !
                    else
                        jmp
                        1 imap-sl +!
                    then
                then
            repeat
        jmp
        imap-ba2 @
        imap-sl @ ;

    \ ( -- )  пропустить c"..." (imap-p после закрывающей ")
    : skip-str
        jmp
        0 imap-sdone !
        begin
            imap-sdone @ 0=
            while
                cpeek!
                imap-cw @ 92 = if
                    jmp jmp
                else
                    imap-cw @ 34 = if
                        1 imap-sdone !
                    else
                        jmp
                    then
                then
            repeat
        jmp ;

    \ ( -- n )  целое число (знак опционален)
    : imap-num ( -- n )
        0 >r
        cpeek!
        imap-cw @ 45 = if  jmp  then
        begin
            cpeek!
            imap-cw @ 48 - 10 u<
            while
                r> 10 * imap-cw @ 48 - + >r
                jmp
            repeat
        r> ;

    \ ( -- )  пропустить любое значение (imap-p перед ним)
    : skip-value
        skip-ws
        cpeek!
        imap-cw @ 34 = if
            skip-str
        else
            cpeek!
            imap-cw @ 123 =
            imap-cw @ 91  = or if
                jmp
                1 imap-depth !
                begin
                    imap-depth @ 0<>
                    imap-err @ 0=
                    and
                    imap-p @ imap-json-l @ u<
                    and
                    while
                        cpeek!
                        imap-cw @ 91  =
                        imap-cw @ 123 = or if
                            jmp
                            1 imap-depth +!
                        else
                            imap-cw @ 93  =
                            imap-cw @ 125 = or if
                                1 imap-depth negate +!
                                jmp
                            else
                                imap-cw @ 34 = if
                                    skip-str
                                else
                                    imap-cw @ 44 = if  jmp  then
                                    jmp
                                then
                            then
                        then
                    repeat
            else
                begin
                    imap-err @ 0=
                    imap-p @ imap-json-l @ u<
                    and
                    cpeek!
                    imap-cw @ 44  =
                    imap-cw @ 125 = or
                    imap-cw @ 93  = or
                    imap-cw @ 10  = or
                    0=
                    while
                    jmp
                repeat
            then
        then ;

    \ ( -- )  device object -> запись в imap-dev
    : parse-device
        0 imap-mask !
        jmp                                \ {
        begin
            cpeek!
            imap-cw @ 125 = 0=
            while
                skip-ws
                parse-string
                drop drop
                skip-ws
                cget drop                  \ :
                jmp
                skip-ws
                imap-ba2 @ imap-sl @
                imap-k-name imap-l-k-name imap-str= if
                    parse-string
                    imap-dname-u !
                    imap-dname-a !
                    1 imap-mask +!
                else
                    imap-ba2 @ imap-sl @
                    imap-k-bit imap-l-k-bit imap-str= if
                        imap-num
                        imap-dbit !
                        2 imap-mask +!
                    else
                        imap-ba2 @ imap-sl @
                        imap-k-addr imap-l-k-addr imap-str= if
                            imap-num
                            imap-daddr !
                            4 imap-mask +!
                        else
                            skip-value
                        then
                    then
                then
                skip-ws
                cpeek!
                imap-cw @ 44 = if  jmp  then
                skip-ws
            repeat
        jmp                                \ }
        imap-mask @
        7 = if  \ name(1)+bit(2)+addr(4)
            \ rec* = base + n*size:  ( -- rec* )
            imap-dev
            imap-dev-n @
            imap-devrec%
            *
            +
            imap-cur !
            imap-dname-a @  imap-cur @ imd-name !
            imap-dname-u @  imap-cur @ imd-nlen !
            imap-dbit  @    imap-cur @ imd-bit  !
            imap-daddr @    imap-cur @ imd-addr !
            1 imap-dev-n +!
        else
            4 imap-err +!
        then ;

    \ ( key-a key-u -- )  значение по ключу (imap-p перед значением)
    : parse-kv
        imap-bu2 !
        imap-ba2 !
        imap-ba2 @ imap-bu2 @
        imap-k-bus imap-l-k-bus imap-str= if
            cpeek!
            imap-cw @ 34 = if
                parse-string
                imap-s-j1io imap-l-s-j1io imap-str= 0= if
                    1 imap-err +!
                then
            else
                skip-value
                1 imap-err +!
            then
        else
            imap-ba2 @ imap-bu2 @
            imap-k-regions imap-l-k-regions imap-str= if
                cpeek!
                imap-cw @ 91 = if
                    jmp
                    skip-ws
                    cpeek!
                    imap-cw @ 93 = if
                        jmp
                    else
                        2 imap-err +!
                        1 imap-pj-done !
                    then
                else
                    skip-value
                    2 imap-err +!
                then
            else
                imap-ba2 @ imap-bu2 @
                imap-k-devices imap-l-k-devices imap-str= if
                    cpeek!
                    imap-cw @ 91 = 0= if
                        3 imap-err +!
                    else
                        jmp
                        skip-ws
                        cpeek!
                        imap-cw @ 93 = if
                            jmp
                        else
                            begin
                                cpeek!
                                imap-cw @ 93 = 0=
                                while
                                    parse-device
                                    skip-ws
                                    cpeek!
                                    imap-cw @ 44 = if
                                        jmp
                                        skip-ws
                                    then
                                repeat
                            jmp
                        then
                    then
                else
                    skip-value
                then
            then
        then ;

    \ ( -- status )  разбор csr.json
    : imap-parse-json ( -- status )
        0 imap-err !
        0 imap-dev-n !
        0 imap-p !
        0 imap-pj-done !
        skip-ws
        cpeek!
        imap-cw @ 123 = 0= if
            1 imap-err +!
            1 imap-pj-done !
        then
        imap-pj-done @ 0= if
            jmp
            begin
                cpeek!
                imap-cw @ 125 = 0=
                imap-cw @ 93  = 0=
                and
                imap-err @ 0=
                and
                imap-pj-done @ 0=
                and
                while
                    skip-ws
                    parse-string
                    skip-ws
                    cget drop
                    jmp
                    skip-ws
                    parse-kv
                    skip-ws
                    imap-cw @ 44 = if  jmp  then
                    skip-ws
                repeat
            jmp
        then
        imap-err @ 0=
        imap-dev-n @ 4 = 0=
        and if  3 imap-err +!  then
        imap-err @ ;

    \ ------------------------------------------------------------------
    \ Поиск устройства
    \ ( a u -- rec*|0 )
    \ ------------------------------------------------------------------
    variable imap-dfound
    variable imap-di
    : imap-dev-by-name ( a u -- rec*|0 )
        imap-su2 !
        imap-sa2 !
        0 imap-di !
        0 imap-dfound !
        begin
            imap-dfound @ 0=
            imap-di @ imap-dev-n @ u<
            and
            while
                \ rec* = base + n*size:  ( -- rec* )
                imap-dev
                imap-di @
                imap-devrec%
                *
                +
                imap-sa2 @ imap-su2 @
                imd-name=
                if  1 imap-dfound !
                else  1 imap-di +!
                then
            repeat
        imap-dfound @
        if
            imap-dev
            imap-di @
            imap-devrec%
            *
            +
        else
            0
        then ;

    \ ------------------------------------------------------------------
    \ Сравнение
    \ ------------------------------------------------------------------
    variable imap-st
    variable imap-mbit
    variable imap-maddr

    \ ( name-a name-u bit addr -- ) — найти устройство и сверить
    variable imap-mrec
    : imap-dev-match ( name-a name-u bit addr -- )
        imap-maddr !
        imap-mbit !
        imap-su2 !
        imap-sa2 !
        imap-sa2 @ imap-su2 @
        imap-dev-by-name
        imap-mrec !
        imap-mrec @ 0= if
            4 imap-st !
        else
            imap-mrec @ imd-bit @  imap-mbit @  =
            imap-mrec @ imd-addr @ imap-maddr @ =
            and 0= if  4 imap-st !  then
        then ;

    : imap-ok? ( -- f )  imap-st @ 0= ;

    : imap-compare ( -- status )
        0 imap-st !
        imap-n-led  imap-l-n-led   10  1024 imap-dev-match
        imap-ok? if
            imap-n-timer imap-l-n-timer 11  2048 imap-dev-match
        then
        imap-ok? if
            imap-n-dt  imap-l-n-dt  12  4096 imap-dev-match
        then
        imap-ok? if
            imap-n-ds  imap-l-n-ds  13  8192 imap-dev-match
        then
        imap-ok? if
            imap-vhbuf imap-vh-l @
            imap-m-led   imap-l-m-led   imap-needle? 0= if  5 imap-st !  then
            imap-vhbuf imap-vh-l @
            imap-m-timer imap-l-m-timer imap-needle? 0= if  5 imap-st !  then
            imap-vhbuf imap-vh-l @
            imap-m-dt    imap-l-m-dt    imap-needle? 0= if  5 imap-st !  then
            imap-vhbuf imap-vh-l @
            imap-m-ds    imap-l-m-ds    imap-needle? 0= if  5 imap-st !  then
        then
        imap-ok? if
            imap-fsbuf imap-fs-l @
            imap-m-fs-led   imap-l-m-fs-led   imap-needle? 0= if  6 imap-st !  then
            imap-fsbuf imap-fs-l @
            imap-m-fs-timer imap-l-m-fs-timer imap-needle? 0= if  6 imap-st !  then
            imap-fsbuf imap-fs-l @
            imap-m-fs-dt    imap-l-m-fs-dt    imap-needle? 0= if  6 imap-st !  then
            imap-fsbuf imap-fs-l @
            imap-m-fs-ds    imap-l-m-fs-ds    imap-needle? 0= if  6 imap-st !  then
        then
        imap-st @ ;

    \ ------------------------------------------------------------------
    \ Публичный драйвер
    \ ------------------------------------------------------------------
    : imap-check ( dir-a dir-u -- status )
        imap-store-dir
        imap-suf-json imap-l-suf-json
        imap-path
        imap-pf-a @ imap-pf-u @ imap-read-json
        imap-parse-json
        dup 0= if
            drop
            imap-suf-vh imap-l-suf-vh
            imap-path
            imap-pf-a @ imap-pf-u @ imap-read-vh
            imap-suf-fs imap-l-suf-fs
            imap-path
            imap-pf-a @ imap-pf-u @ imap-read-fs
            imap-compare
        then ;

    true constant iomap-check-loaded
[THEN]
