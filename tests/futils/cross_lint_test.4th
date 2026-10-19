\ ------------------------------------------------------------------
\ Тесты fsoc/futils/cross_lint.4th (порт tools/cross_lint.py)
\ ------------------------------------------------------------------
\ Запуск: gforth -e 's" tests/futils/cross_lint_test.4th" included'
\ ------------------------------------------------------------------

s" ../../fsoc/futils/cross_lint.4th" included
s" helper.4th" included

\ ------------------------------------------------------------------
\ FIXTURE: каталог с cross-файлом и ядром (все ок)
\ ------------------------------------------------------------------

\ good
s" tests/futils/cross_lint_fixtures/good/cross.4th"
s" tests/futils/cross_lint_fixtures/good/cross.4th"
s" tests/futils/cross_lint_fixtures/good"
s" tests/futils/cross_lint_fixtures/good"
cross-lint 0 Aeq

\ ------------------------------------------------------------------
\ FIXTURE: отсутствует bx-call
\ ------------------------------------------------------------------

s" tests/futils/cross_lint_fixtures/miss_call/cross.4th"
s" tests/futils/cross_lint_fixtures/miss_call/cross.4th"
s" tests/futils/cross_lint_fixtures/miss_call"
s" tests/futils/cross_lint_fixtures/miss_call"
cross-lint 1 Aeq

\ ------------------------------------------------------------------
\ FIXTURE: отсутствует bx-lit
\ ------------------------------------------------------------------

s" tests/futils/cross_lint_fixtures/miss_lit/cross.4th"
s" tests/futils/cross_lint_fixtures/miss_lit/cross.4th"
s" tests/futils/cross_lint_fixtures/miss_lit"
s" tests/futils/cross_lint_fixtures/miss_lit"
cross-lint 1 Aeq

\ ------------------------------------------------------------------
\ FIXTURE: отсутствует bx-ret
\ ------------------------------------------------------------------

s" tests/futils/cross_lint_fixtures/miss_ret/cross.4th"
s" tests/futils/cross_lint_fixtures/miss_ret/cross.4th"
s" tests/futils/cross_lint_fixtures/miss_ret"
s" tests/futils/cross_lint_fixtures/miss_ret"
cross-lint 1 Aeq

\ ------------------------------------------------------------------
\ FIXTURE: эмитит machine-код (dw,), проверки на примитивы пропускаются
\ ------------------------------------------------------------------

s" tests/futils/cross_lint_fixtures/emit_machine/cross.4th"
s" tests/futils/cross_lint_fixtures/emit_machine/cross.4th"
s" tests/futils/cross_lint_fixtures/emit_machine"
s" tests/futils/cross_lint_fixtures/emit_machine"
cross-lint 0 Aeq

\ ------------------------------------------------------------------
\ FIXTURE: bx-слова есть, но нет примитивов ядра (warnings, но rc=0)
\ ------------------------------------------------------------------

s" tests/futils/cross_lint_fixtures/miss_kprim/cross.4th"
s" tests/futils/cross_lint_fixtures/miss_kprim/cross.4th"
s" tests/futils/cross_lint_fixtures/miss_kprim"
s" tests/futils/cross_lint_fixtures/miss_kprim"
cross-lint 0 Aeq

\ ------------------------------------------------------------------
\ Запуск
\ ------------------------------------------------------------------

futils-test-finish