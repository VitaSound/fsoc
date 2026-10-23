\ fsoc/futils/__init__.4th — Модуль Forth-утилит (futils)
\ Предоставляет build-time инструменты, зеркалирующие Python-утилиты tools/
\ Использование: s" fsoc/futils" included

[IFUNDEF] futils-loaded
    : futils-load ( -- )
        \ Загружает все доступные модули futils
        s" fsoc/futils/hex_patch.4th" included
        s" fsoc/futils/patch_firmware.4th" included
        s" fsoc/futils/uart_check.4th" included
        s" fsoc/futils/iomap_check.4th" included
        s" fsoc/futils/region_check.4th" included
        s" fsoc/futils/cross_lint.4th" included
        s" fsoc/futils/con_words_gen.4th" included
        s" fsoc/futils/stack_analyze.4th" included
        s" fsoc/futils/isa_to_fasm.4th" included
    ;
    true constant futils-loaded
[THEN]