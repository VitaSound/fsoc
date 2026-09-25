\ tests/load.4th — the builder library for tests. fmix test runs from
\ the repo root; without FSOC_HOME the root is the current directory.

s" ../fsoc/load.4th" included
fsoc-root$ 2@ nip 0= [IF] cwd@ fsoc-root! [THEN]
