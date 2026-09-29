\ One host image. Prints "<used> <ram>". FSOC_HOME must be set.
\ FSOC_SIZE_CPU is j1a or j1b. FSOC_SIZE_MODE is debug or release.
\ FSOC_SIZE_LAMP is 1 when the row is soc+blink.
\ Release and lamp also set FSOC_SIZE_KEEP and FSOC_SIZE_IMAGE.
\ FSOC_SIZE_DIR holds a copy of lamp.fs. The run writes csr.fs there from iomap-soc.

s" FSOC_HOME" getenv s" /tests/load.4th" s+ included

: size-env ( c-addr u -- c-addr2 u2 )
    getenv save-mem dup 0= abort" size env unset" ;

variable cpu-a
variable cpu-u
variable mode-a
variable mode-u
variable size-lamp
variable size-rel

s" FSOC_SIZE_CPU" size-env cpu-u ! cpu-a !
s" FSOC_SIZE_MODE" size-env mode-u ! mode-a !
s" FSOC_SIZE_LAMP" size-env s" 1" compare 0= size-lamp !

mode-a @ mode-u @ s" release" compare 0=
size-lamp @ and size-rel !

: size-cpu ( -- cpu )
    cpu-a @ cpu-u @ cpu-find dup 0= IF true abort" size cpu" THEN ;

: size-xt ( c-addr u -- xt )
    find-name dup 0= IF true abort" size word missing" THEN
    name>interpret ;

: size-xc ( c-addr u -- )
    s" xc-load" size-xt execute ;

: size-here ( -- n )
    s" xc-here@" size-xt execute ;

size-cpu cpu.kit @
dup kit.width @ 8 / swap kit.ram @ * value size-cap

: size-run ( -- )
    size-rel @ IF
        s" fsys/host/keep.4th" fsoc-path included
        s" FSOC_SIZE_KEEP" size-env included
    THEN
    s" fsys/kernel/" cpu-a @ cpu-u @ s+ s" /kernel.4th" s+
    fsoc-path included
    s" fsys/host/cross.4th" fsoc-path included
    size-rel @ IF
        s" FSOC_SIZE_IMAGE" size-env size-xc
    ELSE
        s" fsys/common/common.4th" fsoc-path size-xc
        s" fsys/common/core.4th" fsoc-path size-xc
        cpu-a @ cpu-u @ s" j1b" compare 0= IF
            s" fsys/j1b/extra.4th" fsoc-path size-xc
        THEN
    THEN
    size-lamp @ IF
        s" FSOC_SIZE_DIR" size-env s" /csr.fs" s+ iomap-export-fs
        s" FSOC_SIZE_DIR" size-env s" /lamp.fs" s+
        s" FSOC_SIZE_DIR" size-env s" /feed.fs" s+
        soc-flatten
        s" FSOC_SIZE_DIR" size-env s" /feed.fs" s+ size-xc
    THEN
    size-here . size-cap . cr ;

size-run
bye
