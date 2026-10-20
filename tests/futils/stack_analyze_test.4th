\ tests/futils/stack_analyze_test.4th
\ Тесты для fsoc/futils/stack_analyze.4th

    require ../../forth-packages/fenum/0.1.1/fenum-bs.4th
    require ../../fsoc/futils/stack_analyze.4th
    require ./helper.4th

    \ ------------------------------------------------------------------
    \ Тестовые данные
    \ ------------------------------------------------------------------

    \ Пример мини-ядра для тестирования
    s" \\ A minimal kernel for testing\\n"
    s" : test-word1 ( a u -- ) ." s" \\n"
    s" : test-word2 ( -- n ) 123 ." s" \\n"
    s" : k-word_test1 ( x y -- z ) + ." s" \\n"
    s" : jb-word_test2 ( a b -- ) ." s" \\n"
    s" \\ ( this is a comment )\\n"
    s" : test-word3 ( -- ) cr ." s" \\n"
    s" \\ end of file"
    constant test-kern-data
    variable test-kern-addr
    variable test-kern-len

    \ ------------------------------------------------------------------
    \ Создание временного файла с тестовыми данными
    \ ------------------------------------------------------------------
    : create-test-kernel ( -- )
        test-kern-data count   \ ( a u )
        >r >r                  \ R: u, a
        tmp-dir-path dup s" /test_kernel.4th" append-path \ ( path-a path-u )
        >r                     \ R: u, a, path-a
        swap >r                \ R: u, a, path-a, path-u
        count                  \ ( a u )
        0 swap write-file throw \ ( ) — создали файл
        r@ count               \ ( path-a path-u a u )
        r>                     \ ( path-a path-u a u )
        swap r>                \ ( path-a path-u a u )
        r>                     \ ( path-a path-u a u )
        swap >r                \ R: u, a, path-a
        r@                     \ ( path-u )
        r>                     \ ( path-u )
        r>                     \ ( path-u )
        r@                     \ ( path-u )
        swap                   \ ( path-u path-u )
        >r >r                  \ R: u, a, path-a, path-u
        r@                     \ ( path-a )
        r>                     \ ( path-a )
        r>                     \ ( path-a )
        r>                     \ ( path-a )
        swap                   \ ( path-a path-u )
        test-kern-addr ! test-kern-len !
    ;

    \ ------------------------------------------------------------------
    \ Очистка временных файлов
    \ ------------------------------------------------------------------
    : cleanup-test-kernel ( -- )
        test-kern-addr @ 0= if exit then
        test-kern-addr @ test-kern-len @ delete-file drop
        0 test-kern-addr ! 0 test-kern-len !
    ;

    \ ------------------------------------------------------------------
    \ Тестовый случай: базовое сканирование
    \ ------------------------------------------------------------------
    : test-basic-scan ( -- )
        ." Running basic scan test..." cr
        create-test-kernel
        test-kern-addr @ test-kern-len @ stack-analyze
        ." Basic scan test finished." cr
        cleanup-test-kernel
    ;

    \ ------------------------------------------------------------------
    \ Тестовый случай: сканирование с комментариями и кавычками
    \ ------------------------------------------------------------------
    s" \\ A kernel with comments\\n"
    s" : k-word_comment ( x -- ) \\ comment\\n"
    s" : jb-word_quoted \" this is quoted \" ( a -- ) ." s" \\n"
    s" \\ another comment line\\n"
    constant test-kern-data-comment
    variable test-kern-addr-comment
    variable test-kern-len-comment

    : create-test-kernel-comment ( -- )
        test-kern-data-comment count   \ ( a u )
        >r >r
        tmp-dir-path dup s" /test_kernel_comment.4th" append-path
        >r
        swap >r
        count
        0 swap write-file throw
        r@ count
        r>
        swap r>
        r>
        swap >r
        r@
        r>
        r>
        r>
        swap
        >r >r
        r@
        r>
        r>
        r>
        swap
        test-kern-addr-comment ! test-kern-len-comment !
    ;

    : cleanup-test-kernel-comment ( -- )
        test-kern-addr-comment @ 0= if exit then
        test-kern-addr-comment @ test-kern-len-comment @ delete-file drop
        0 test-kern-addr-comment ! 0 test-kern-len-comment !
    ;

    : test-comment-and-quotes ( -- )
        ." Running comment and quotes test..." cr
        create-test-kernel-comment
        test-kern-addr-comment @ test-kern-len-comment @ stack-analyze
        ." Comment and quotes test finished." cr
        cleanup-test-kernel-comment
    ;

    \ ------------------------------------------------------------------
    \ Основной тестовый блок
    \ ------------------------------------------------------------------
    : run-tests ( -- )
        test-basic-scan
        test-comment-and-quotes
    ;

\ Запуск тестов
run-tests bye
