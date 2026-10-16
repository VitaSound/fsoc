\ fsoc/futils/uart_check.4th
\ Gforth-порт tests/z80_blink_uart.py (byte-уровень; для ASCII-маркеров
\ эквивалентно decode utf-8 with replace).
\ Использование:
\   s" /path/log.txt" 3 uart-blink-check  ( -- ok? )
\
\ fenum (begin-structure backend, как в fsoc/core.4th) — общая
\ инфраструктура, загружается здесь; состояния маркеров
\ ("blink on"/"blink off") хранят фиксированные byte-массивы, а не
\ динамический список (устойчиво к quirk'ам сборки).
\
\ Gforth-особенности (проверено): i живёт только в do/loop; во внешних
\ begin/while-циклах — переменные-счётчики. s" \000" — НЕ байт 0x00,
\ а литерал обратного слэша (C-escape не поддерживаются).
[IFUNDEF] uart-check-loaded

    require ../../forth-packages/fenum/0.1.1/fenum-bs.4th

    \ ------------------------------------------------------------------
    \ fenum-запись маркера (begin-structure backend):
    \   addr — позиция маркера в uc-log; kind — 0 = "off", 1 = "on".
    \ ------------------------------------------------------------------
    begin-structure uc-marker%
        field: ucm-addr
        field: ucm-kind
    end-structure

    create uc-markers 256 uc-marker% allot

    \ ------------------------------------------------------------------
    \ File I/O (byte)
    \ ------------------------------------------------------------------
    create uc-log 65536 allot
    variable uc-log-len
    variable uc-fid

    \ ( patha pathu -- len )
    : uc-read-log ( patha pathu -- len )
        r/o open-file throw uc-fid !
        uc-log 65536 uc-fid @ read-file
        drop uc-log-len !
        uc-fid @ close-file drop
        uc-log-len @ ;

    \ ------------------------------------------------------------------
    \ Byte search: needle (na nu) in log from pos. (na nu pos -- idx|-1)
    \ ------------------------------------------------------------------
    variable uc-fi   \ сдвиг окна
    variable uc-fj   \ индекс совпавшего байта
    variable uc-na   \ адрес needle
    variable uc-nu   \ длина needle
    variable uc-pm   \ флаг совпадения
    variable uc-found
    variable uc-idx
    \ Совпадает ли needle с log в позиции uc-fi: ( -- flag ).
    \ ВНИМАНИЕ: в этой сборке Gforth 0.7.9_20250101 `exit` из begin/while
    \ коррует стек (проверено). Выход через флаг + while — как
    \ pat-match? в hex_patch.4th.
    : uc-match-at ( -- flag )
        1 uc-pm !
        0 uc-fj !
        begin
            uc-pm @ 1 and uc-fj @ uc-nu @ u< and while
                uc-fi @ uc-fj @ + uc-log + c@   \ log[fi+j]
                uc-na @ uc-fj @ + c@            \ needle[j]
                = if ( keep 1 ) else 0 uc-pm ! then
                1 uc-fj +!
            repeat
        uc-pm @ ;
    : uc-find-str ( na nu pos -- idx|-1 )
        uc-fi !            \ (na nu)  -> pos
        uc-nu !            \ (na)     -> nu
        uc-na !            \ ()       -> na
        0 uc-idx !
        0 uc-found !
        begin
            uc-found @ 0= uc-fi @ uc-log-len @ uc-nu @ - u<= and while
                uc-match-at if
                    uc-fi @ uc-idx !
                    1 uc-found !
                then
                1 uc-fi +!
            repeat
        uc-found @ if  uc-idx @  else -1 then ;

    \ ------------------------------------------------------------------
    \ NUL before blink: поиск байт 00 62 6c 69 6e 6b 20 ("\000blink ")
    \ needle собирается вручную — s" не разбирает \000.
    \ Статические нуджи: s" вызывается только при скомпилировании
    \ файла (не в рантайме) — временные буферы s" в циклах этой сборки
    \ Gforth корруют стек.
    \ ------------------------------------------------------------------
    create uc-nul-needle 7 allot
    create uc-needle-on  8 allot
    create uc-needle-off 9 allot
    variable uc-len-on
    variable uc-len-off
    8 uc-len-on  !  9 uc-len-off !
    0 uc-nul-needle c!                       \ [0] = NUL
    s" blink " uc-nul-needle 1 + swap cmove    \ [1..6] = "blink "  (src dst n)
    s" blink on"  uc-needle-on  swap cmove
    s" blink off" uc-needle-off swap cmove
    : uc-nul-blink? ( -- f )
        uc-nul-needle 7 0 uc-find-str 0< 0= ;

    \ ------------------------------------------------------------------
    \ Сбор маркеров: последовательный скан (как Python re.findall).
    \ uc-blink-on(n) — 1 если маркер "on", 0 если "off";
    \ uc-blink-n — число маркеров. Нуджи — статические (см. выше).
    \ ------------------------------------------------------------------
    variable uc-pos
    variable uc-b-on
    variable uc-b-off
    variable uc-blink-n
    variable uc-blink-addr

    \ min valid of two -1-positions; b сверху. ( a b -- m )
    : uc-minpos ( a b -- m )
        dup 0< if  drop exit then        \ b neg -> a
        over 0< if  swap drop exit then  \ a neg -> b
        min ;

    \ Длина найденного маркера: 8 если "on" (uc-b-on = min), иначе 9.
    \ ( min -- len )
    : uc-marker-len ( min -- len )
        uc-b-on @ = if  uc-len-on @  else  uc-len-off @  then ;

    \ Следующий маркер с uc-pos: запись в uc-markers[uc-blink-n],
    \ на стек — следующая позиция поиска (min + len, без перекрытия —
    \ как re.findall). 0 = маркеров больше нет. ( pos -- nextpos|0 )
    : uc-next-blink ( pos -- nextpos|0 )
        uc-pos !
        uc-needle-on  uc-len-on @  uc-pos @ uc-find-str  uc-b-on !
        uc-needle-off uc-len-off @ uc-pos @ uc-find-str  uc-b-off !
        uc-b-on @ uc-b-off @ uc-minpos          \ min
        dup 0< if  drop 0 exit  then           \ min
        dup uc-blink-addr !                    \ min
        \ запись addr: begin-structure (value struct) — min снизу, rec сверху
        uc-blink-addr @                        \ min
        uc-markers uc-blink-n @ uc-marker% * + \ min rec
        ucm-addr !                             \ min
        \ запись kind: (value struct)
        uc-blink-addr @ uc-b-on @ = if 1 else 0 then   \ min kind
        uc-markers uc-blink-n @ uc-marker% * + \ min kind rec
        ucm-kind !                             \ min
        1 uc-blink-n +!                        \ min
        dup uc-marker-len + ;                    \ min+len

    variable uc-blink-done
    : uc-blink-states ( -- )
        0 uc-blink-n !
        0 uc-pos !
        0 uc-blink-done !
        begin
            uc-blink-done @ 0= while
                uc-pos @ uc-next-blink
                dup 0= if
                    drop
                    1 uc-blink-done !
                else
                    uc-pos !
                then
            repeat ;

    \ ------------------------------------------------------------------
    \ Alternation: из первых 2*pairs маркеров — каждая пара соседних
    \ чередуется (старт на "on" или "off"). ( pairs -- f )
    \ ------------------------------------------------------------------
    variable uc-pairs
    variable uc-alt-n
    variable uc-alt-i
    variable uc-alt-ok
    : uc-blink-alt? ( pairs -- f )
        2 * 1 - uc-alt-n !           \ n = 2*pairs - 1
        0 uc-alt-i !
        1 uc-alt-ok !
        begin
            uc-alt-ok @ 1 and uc-alt-i @ uc-alt-n @ u< and while
                uc-markers uc-alt-i @ uc-marker% * + ucm-kind @
                uc-markers uc-alt-i @ 1 + uc-marker% * + ucm-kind @
                = if  0 uc-alt-ok !  then
                1 uc-alt-i +!
            repeat
        uc-alt-ok @ ;

    \ ------------------------------------------------------------------
    \ Driver. uc-check-buffer — проверка содержимого uc-log (len =
    \ uc-log-len) без file I/O; uart-blink-check — обёртка с файлом.
    \ ------------------------------------------------------------------
    \ ( pairs -- ok? ) — проверка текущего uc-log, без file I/O.
    : uc-check-buffer ( pairs -- ok? )
        uc-pairs !
        uc-nul-blink? if  false exit  then
        uc-blink-states
        uc-blink-n @
        uc-pairs @ 2 * u< if  false exit  then
        uc-pairs @ uc-blink-alt? ;
    \ ( patha pathu pairs -- ok? ) — обёртка: прочитать файл, затем
    \ uc-check-buffer.
    : uart-blink-check ( patha pathu pairs -- ok? )
        uc-pairs !                \ (patha pathu)
        uc-read-log drop          \ ()
        uc-pairs @ uc-check-buffer ;   \ (pairs -- ok?)

[THEN]
