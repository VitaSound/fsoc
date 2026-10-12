\ tests/tools_test.4th — the AI-assisted CPU tools run clean across the board.

s" test_common.4th" included
s" fixture.4th" included

\ run_all_tools.py auto-discovers every CPU with a kernel and runs the tools
\ that have the required inputs (stack_analyze, cross_lint, con_words_gen,
\ isa_to_fasm), and validates that every tools/isa_specs/*.json is well-formed.
\ Exit 0 means no tool errored and no spec is corrupt; warnings are not errors.
\ The on-disk stack report is redirected to /tmp so the run never dirties the
\ committed tools/stack_analysis_report.json.
s" python3 " fsoc-root fjson.str-concat s" /tools/run_all_tools.py" fsoc-cat+
2dup system fjson.str-free $? 0= expect-true
