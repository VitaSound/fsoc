\ ------------------------------------------------------------------
\ Тесты fsoc/futils/hex_patch.4th
\ ------------------------------------------------------------------
\ Gforth 0.7.9_20250101 (ANS-порядок, подтверждено пробами):
\   c! : ( c a-addr -- )   — значение СВЕРХУ
\   c@ : ( a-addr -- c )
\
\ Своя assert-обвязка (без ttester/ERROR/abort на каждом шаге):
\ каждый провал инкрементит t-failed; все группы доходят до конца,
\ test-finish печатает сводку и завершается abort" при провалах
\ (ненулевой exit code).
\ ------------------------------------------------------------------

s" ../../fsoc/futils/hex_patch.4th" included
s" helper.4th" included

: buffer-reset ( -- )
    hex-buffer 65536 erase
    0 hex-len ! ;
\ ------------------------------------------------------------------
\ Данные
\ ------------------------------------------------------------------
\ "FF":       ASCII 70 70
\ "FF\nAB\n": ASCII 70 70 10 65 66 10    (6 байт)
create data_FF       70 c, 70 c,
create data_buf1     70 c, 70 c, 10 c, 65 c, 66 c, 10 c,
create pat_ff        255 c,
create pat_cc        204 c, 204 c,

\ ------------------------------------------------------------------
\ t-parse-byte: parse-hex-byte  ( addr len -- byte | -1 )
\ ------------------------------------------------------------------
: t-parse-byte
    data_FF 2 parse-hex-byte    0xFF Aeq
    s" 42" parse-hex-byte       0x42 Aeq
    s" AB" parse-hex-byte       0xAB Aeq
    s" aa" parse-hex-byte       0xAA Aeq
    s" GG" parse-hex-byte       -1     Aeq ;

\ ------------------------------------------------------------------
\ t-hexdigit: hex-digit  ( c -- digit true | 0 false )
\ ------------------------------------------------------------------
: t-hexdigit
    [char] 0 hex-digit  AtTrue  0  Aeq
    [char] F hex-digit  AtTrue  15 Aeq
    [char] a hex-digit  AtTrue  10 Aeq
    [char] 9 hex-digit  AtTrue  9  Aeq
    [char] G hex-digit  drop Afs ;

\ ------------------------------------------------------------------
\ t-intel?: hex-line-is-intel?  ( addr len -- flag )
\ ------------------------------------------------------------------
: t-intel?
    s" :00000001FF00" hex-line-is-intel?  AtTrue
    s" FF"            hex-line-is-intel?  Afs
    data_FF 0               hex-line-is-intel?  Afs ;

\ ------------------------------------------------------------------
\ t-parse-line: hex-parse-line  ( addr len -- )
\ ------------------------------------------------------------------
: t-parse-line
    buffer-reset
    data_FF 2 hex-parse-line
    1  hex-len @ Aeq
    hex-buffer 0 + c@  0xFF Aeq ;

\ ------------------------------------------------------------------
\ t-parse-buf: hex-parse-buffer  ( buf-addr buf-len -- )
\ "FF\nAB\n" -> 0xFF 0xAB
\ ------------------------------------------------------------------
: t-parse-buf
    buffer-reset
    data_buf1 6 hex-parse-buffer
    2  hex-len @ Aeq
    hex-buffer 0 + c@  0xFF Aeq
    hex-buffer 1 + c@  0xAB Aeq ;

\ ------------------------------------------------------------------
\ t-find-pat: hex-find-pattern  ( pat-addr pat-len -- addr | -1 )
\ ------------------------------------------------------------------
: t-find-pat
    buffer-reset
    data_buf1 6 hex-parse-buffer
    pat_ff 1 hex-find-pattern  0 Aeq    \ 0xFF на месте 0
    ;

: t-find-pat-miss
    buffer-reset
    data_buf1 6 hex-parse-buffer
    pat_cc 2 hex-find-pattern  -1 Aeq   \ 0xCC 0xCC нет в буфере
    ;

\ ------------------------------------------------------------------
\ t-patch-byte: hex-patch-at  ( byte addr -- )
\ ------------------------------------------------------------------
: t-patch-byte
    buffer-reset
    0x77 5 hex-patch-at
    hex-buffer 5 + c@  0x77 Aeq ;

\ ------------------------------------------------------------------
\ t-patch-word: hex-patch-word-at  ( word addr -- )  little-endian
\ ------------------------------------------------------------------
: t-patch-word
    buffer-reset
    0x1234 10 hex-patch-word-at
    hex-buffer 10 + c@  0x34 Aeq
    hex-buffer 11 + c@  0x12 Aeq ;

\ ------------------------------------------------------------------
\ t-find-call: hex-find-call-zbranch  ( zaddr -- call | -1 )
\ Буфер: CD D3 00 00 C3 20 00 — CALL 0x0D3 @0, JP 0x020 @4
\ ------------------------------------------------------------------
: t-find-call
    buffer-reset
    0xCD 0 hex-patch-at  0xD3 1 hex-patch-at  0x00 2 hex-patch-at
    0xC3 4 hex-patch-at  0x20 5 hex-patch-at  0x00 6 hex-patch-at
    7 hex-len !
    0x0D3 hex-find-call-zbranch  0 Aeq
    0x0FF hex-find-call-zbranch  -1 Aeq ;

\ ------------------------------------------------------------------
\ t-find-jp: hex-find-jp-after  ( start -- jp-addr target-addr | -1 -1 )
\ jp-addr снизу, target-addr сверху.
\ ------------------------------------------------------------------
: t-find-jp
    buffer-reset
    0xCD 0 hex-patch-at  0xD3 1 hex-patch-at  0x00 2 hex-patch-at
    0xC3 4 hex-patch-at  0x20 5 hex-patch-at  0x00 6 hex-patch-at
    7 hex-len !
    0 hex-find-jp-after
    0x020 Aeq          \ target (верх)
    4     Aeq          \ jp    (низ)
    ;

\ ------------------------------------------------------------------
\ t-find-jrnz: hex-find-jr-nz-after  ( start -- jr | -1 )
\ backward JR NZ (0x20, off>=0x80)
\ ------------------------------------------------------------------
: t-find-jrnz
    buffer-reset
    0x20 8 hex-patch-at  0xFF 9 hex-patch-at
    10 hex-len !
    8     hex-find-jr-nz-after  8 Aeq
    0x100 hex-find-jr-nz-after  -1 Aeq ;

\ ------------------------------------------------------------------
\ t-find-else: hex-find-else-body  ( call -- else | -1 )
\ ------------------------------------------------------------------
: t-find-else
    buffer-reset
    0xCD 0 hex-patch-at  0xD3 1 hex-patch-at  0x00 2 hex-patch-at
    0xC3 4 hex-patch-at  0x20 5 hex-patch-at  0x00 6 hex-patch-at
    7 hex-len !
    0 hex-find-else-body  0x020 Aeq ;

\ ------------------------------------------------------------------
\ t-patch-zbr: hex-patch-zbranch  ( zaddr new -- ok? )
\ CALL 0x0D3 @0, JP 0x020 @4 -> target 0x044 в байтах 5,6
\ ------------------------------------------------------------------
: t-patch-zbr
    buffer-reset
    0xCD 0 hex-patch-at  0xD3 1 hex-patch-at  0x00 2 hex-patch-at
    0xC3 4 hex-patch-at  0x20 5 hex-patch-at  0x00 6 hex-patch-at
    7 hex-len !
    0x0D3 0x044 hex-patch-zbranch  AtTrue  \ (zbranch-addr new-addr --)
    hex-buffer 5 + c@  0x44 Aeq
    hex-buffer 6 + c@  0x00 Aeq ;

: t-patch-zbr-miss
    buffer-reset
    0x9999 0x044 hex-patch-zbranch  Afs ;

\ ------------------------------------------------------------------
\ t-dump: hex-dump — печатает hex-байты (не падает)
\ ------------------------------------------------------------------
: hp-dump
    buffer-reset
    0xCD 0 hex-patch-at  0xD3 1 hex-patch-at  0x00 2 hex-patch-at
    0xC3 4 hex-patch-at  0x20 5 hex-patch-at  0x00 6 hex-patch-at
    7 hex-len !
    hex-buffer 7 hex-dump
    ;

\ ------------------------------------------------------------------
\ Запуск
\ ------------------------------------------------------------------
: hp-run-all
    t-parse-byte
    t-hexdigit
    t-intel?
    t-parse-line
    t-parse-buf
    t-find-pat
    t-find-pat-miss
    t-patch-byte
    t-patch-word
    t-find-call
    t-find-jp
    t-find-jrnz
    t-find-else
    t-patch-zbr
    t-patch-zbr-miss
    hp-dump
    futils-test-finish
    ;
hp-run-all
