\ tests/isa_feat_test.4th — common feature-gate vocabulary.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/common/isa-feat.4th" included

$0001 constant f-core
$0002 constant f-mul
$0004 constant f-movc

\ Named registry.
f-core feat-define core
f-mul  feat-define mul
f-movc feat-define movc

\ Basic have/need.
f-core f-mul or set-feats
f-core have expect-true
f-mul  have expect-true
f-movc have expect-false

\ need passes on present feature.
f-core need

\ need aborts on absent feature (caught via a thunk).
: try-need-f-movc ( -- ) f-movc need ;
: try-need-name-movc ( -- ) s" movc" need-name ;

: absent-aborts? ( -- f )
    ['] try-need-f-movc catch 0<> ;

absent-aborts? expect-true

\ Named lookup (string on stack).
s" core" feat-mask f-core expect=
s" mul" feat-mask f-mul expect=

\ need-name passes for a present feature.
s" core" need-name

\ need-name aborts for absent.
: absent-name-aborts? ( -- f )
    ['] try-need-name-movc catch 0<> ;
absent-name-aborts? expect-true

test-finish
expect-stack-clean
cr ." isa_feat_test ok" cr
