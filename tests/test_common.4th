\ tests/test_common.4th

[IFUNDEF] expect-true
    s" ../forth-packages/ttester/1.2.1/ttester.4th" included
    s" ../forth-packages/ttester/1.2.1/ttester-ext.4th" included
[THEN]

[IFDEF] expect= [ELSE]
: expect= ( a b - ) expect-eq ;
[THEN]
