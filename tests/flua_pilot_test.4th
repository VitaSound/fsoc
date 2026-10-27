\ Pilot: helpers from fsoc/flua/*.lua (flua → typical Gforth).
\ From repo root: gforth tests/flua_pilot_test.4th

s" test_common.4th" included

\ fpath for fjson/fenum is CWD-relative (repo root when invoked as above)
fpath path+ forth-packages/fjson/0.2.5/fjson
fpath path+ forth-packages/fenum/0.1.1
s" ../forth-packages/fjson/0.2.5/fjson.4th" included

s" ../fsoc/flua/path_join.4th" included
s" ../fsoc/flua/json_has.4th" included

: flua-join-ok? ( -- f )
    s" a" s" b" fsoc_join { ja ju }
    s" a/b" ja ju compare 0=
    ja ju fjson.str-free ;

T{ flua-join-ok? -> true }T
T{ s" hello" s" ell" fsoc_json_has -> -1 }T
T{ s" hello" s" xyz" fsoc_json_has -> 0 }T

#ERRORS @ 0= [IF]
    ." ALL FLUA PILOT TESTS PASSED" cr
[ELSE]
    ." FLUA PILOT TESTS FAILED: " #ERRORS @ . cr
[THEN]
bye
