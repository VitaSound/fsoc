\ fsoc/sys.4th — image tool named by the manifest field sys:.

begin-structure sys%
    field: sys.id$
    field: sys.step
end-structure

variable fsoc-syss
ulist-new fsoc-syss !

\ ( c-addr u xt -- )
: sys-register ( c-addr u xt -- )
    sys% allocate throw >r
    r@ sys.step !
    fsoc-store r@ sys.id$ !
    r> fsoc-syss @ ulist-add ;

: sys-find ( c-addr u -- sys|0 )
    fsoc-syss @ reg-find ;
