\ tests/load.4th — the builder library for tests. fmix test runs from
\ the repo root; without FSOC_HOME the root is the current directory.
\ fsoc/paths.4th reads FSOC_HOME when it loads and aborts when the
\ variable is missing, so the fallback must run before ../fsoc/load.4th.
create fsoc-test-cwd 1024 allot
s" FSOC_HOME" getenv dup 0= [IF]
    2drop s" FSOC_HOME" fsoc-test-cwd 1024 get-dir 1 setenv drop
[ELSE]
    2drop
[THEN]

s" ../fsoc/load.4th" included
fsoc-root$ 2@ nip 0= [IF] cwd@ fsoc-root! [THEN]
