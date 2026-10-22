\ tests/futils/stack_analyze_test.4th — тест fsoc/futils/stack_analyze.4th
\ Пути: include резолвится от каталога включающего файла, runtime-путь
\ (stack-analyze → open-file) — от CWD (корень репо, pre-commit делает cd).
\ Фикстура — реальное ядро bcpu: 64 строки формата `s" name" ... k-pc k-word`.

s" ../../fsoc/futils/stack_analyze.4th" included
s" helper.4th" included

\ sa-has ( na nu -- f ) — найдено ли имя среди извлечённых k-слов
variable t-qa   variable t-qu   variable t-found
: sa-has ( na nu -- f )
    t-qu !   t-qa !   0 t-found !
    sa-kw-n @ 0 ?do
        t-found @ 0= if
            i 64 * sa-kw-names +    \ (name-a)
            i sa-kw-lens + c@       \ (name-a name-u)
            t-qa @ t-qu @           \ (name-a name-u query-a query-u)
            sa-str=                 \ (f)
            if 1 t-found ! then
        then
    loop
    t-found @ ;

\ FIXTURE: bcpu kernel.4th — печать отчёта + извлечение имён
s" fsys/kernel/bcpu/kernel.4th" stack-analyze

\ Паритет с python: grep -cE '^s" .* k-pc k-word$' = 64
sa-kw-n @ 64 Aeq

\ Символические и обычные имена присутствуют в массиве
s" dup"  sa-has AtTrue
s" drop" sa-has AtTrue
s" +"    sa-has AtTrue

futils-test-finish
