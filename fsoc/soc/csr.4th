\ fsoc/soc/csr.4th — CSR layout, csr.4th HAL, csr.json

begin-structure csr%
    field: csr.name$
    field: csr.width
    field: csr.kind
    field: csr.addr
    field: csr.core$
end-structure

variable csr-list
variable csr-next-addr
variable csr-core-a
variable csr-core-u

0 constant csr/storage
1 constant csr/status

: csr-reset ( - )
    ulist-new csr-list !
    0 csr-next-addr ! ;

: csr-core-begin ( c-addr u - )
    csr-core-u ! csr-core-a ! ;

: csr-add ( c-addr u width kind - )
    csr% allocate throw >r
    r@ csr.kind !
    r@ csr.width !
    fsoc-store r@ csr.name$ !
    csr-core-a @ csr-core-u @ fsoc-store r@ csr.core$ !
    csr-next-addr @ r@ csr.addr !
    4 csr-next-addr +!
    r@ csr-list @ ulist-add
    r> drop ;

: csr-storage ( c-addr u width - ) csr/storage csr-add ;
: csr-status  ( c-addr u width - ) csr/status csr-add ;

: csr-core-end ( - )
    0 csr-core-u ! 0 csr-core-a ! ;

: csr-count ( - n )
    csr-list @ ulist-len ;

variable csr-out-a
variable csr-out-u

: csr-out-put ( c-addr u - )
    csr-out-a @ csr-out-u @ 2swap fsoc-append
    csr-out-a @ csr-out-u @ fsoc-str-free
    csr-out-u ! csr-out-a ! ;

: csr-export-4th-body ( - c-addr u )
    s" \\ generated CSR HAL" fsoc-str-dup csr-out-u ! csr-out-a !
    s\" \n" csr-out-put
    csr-list @ ulist-head @
    begin dup while
        dup >r unode-addr @
        s" $ " csr-out-put
        dup csr.addr @ fsoc-u>str csr-out-put
        s"  constant CSR-" csr-out-put
        dup csr.core$ @ fsoc-fetch csr-out-put
        s" -" csr-out-put
        csr.name$ @ fsoc-fetch csr-out-put
        s\" \n" csr-out-put
        r> unode-next @
    repeat drop
    csr-out-a @ csr-out-u @ ;

: csr-export-4th ( c-addr-path u - )
    csr-export-4th-body fsoc-write-file ;

: csr-export-json-body ( - c-addr u )
    s\" {\"csr\":[" fsoc-str-dup csr-out-u ! csr-out-a !
    csr-list @ ulist-head @
    begin dup while
        dup >r unode-addr @
        s\" {\"name\":\"" csr-out-put
        dup csr.core$ @ fsoc-fetch csr-out-put
        s" _" csr-out-put
        dup csr.name$ @ fsoc-fetch csr-out-put
        s\" \",\"addr\":" csr-out-put
        csr.addr @ fsoc-u>str csr-out-put
        s" }" csr-out-put
        r@ unode-next @ IF s" ," csr-out-put THEN
        r> unode-next @
    repeat drop
    s" ]}" csr-out-put
    csr-out-a @ csr-out-u @ ;

: csr-export-json ( c-addr-path u - )
    csr-export-json-body fsoc-write-file ;
