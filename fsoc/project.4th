\ fsoc/project.4th — project manifest. target.4th fills it with
\ task: target: board: design: option: . The CLI reads only this.

begin-structure opt%
    field: opt.name$
    field: opt.value$
end-structure

begin-structure project%
    field: project.task$
    field: project.target$
    field: project.board$
    field: project.design$
    field: project.dir$
    field: project.harness$
    field: project.opts
end-structure

variable current-project

: project@ ( -- project )
    current-project @ dup 0= IF true abort" no current project" THEN ;

\ The project directory is the current directory, read once.
: project-new ( -- )
    project% allocate throw >r
    r@ project% erase
    ulist-new r@ project.opts !
    cwd@ fsoc-store r@ project.dir$ !
    r> current-project ! ;

: task:    ( c-addr u -- ) project@ project.task$    fsoc-store! ;
: target:  ( c-addr u -- ) project@ project.target$  fsoc-store! ;
: board:   ( c-addr u -- ) project@ project.board$   fsoc-store! ;
: design:  ( c-addr u -- ) project@ project.design$  fsoc-store! ;
: harness: ( c-addr u -- ) project@ project.harness$ fsoc-store! ;

: option: ( name-a name-u value-a value-u -- )
    opt% allocate throw >r
    fsoc-store r@ opt.value$ !
    fsoc-store r@ opt.name$ !
    r> project@ project.opts @ ulist-add ;

: project.task@    ( project -- c-addr u ) project.task$    @ fsoc-fetch ;
: project.target@  ( project -- c-addr u ) project.target$  @ fsoc-fetch ;
: project.board@   ( project -- c-addr u ) project.board$   @ fsoc-fetch ;
: project.design@  ( project -- c-addr u ) project.design$  @ fsoc-fetch ;
: project.dir@     ( project -- c-addr u ) project.dir$     @ fsoc-fetch ;
: project.harness@ ( project -- c-addr u ) project.harness$ @ fsoc-fetch ;

\ <dir>/<name>, allocated.
: project.file ( name-a name-u project -- c-addr u )
    project.dir@ s" /" fjson.str-concat
    2swap fsoc-cat+ ;

\ Copy FSOC_HOME/<rel> into the project dir under its base name.
: project-copy-in ( rel-a rel-u project -- )
    >r
    2dup fsoc-basename r> project.file
    2swap fsoc-path
    2swap
    2over 2over sh-cp
    fjson.str-free fjson.str-free ;

\ Copy an absolute source into the project dir under name.
: project-copy-as ( src-a src-u name-a name-u project -- )
    project.file
    2dup 2>r sh-cp 2r> fjson.str-free ;

variable opt-find-a
variable opt-find-u
variable opt-find-r

: opt-match ( opt -- )
    dup opt.name$ @ fsoc-fetch opt-find-a @ opt-find-u @ compare 0= IF
        opt-find-r !
    ELSE drop THEN ;

\ Value of an option, or 0 0 when absent.
: project.opt@ ( name-a name-u project -- value-a value-u | 0 0 )
    >r opt-find-u ! opt-find-a !
    0 opt-find-r !
    ['] opt-match r> project.opts @ ulist-each
    opt-find-r @ dup IF opt.value$ @ fsoc-fetch ELSE drop 0 0 THEN ;

: project.opt? ( name-a name-u project -- flag )
    project.opt@ nip 0<> ;

\ Manifest must name a task and a target.
: project-check ( project -- )
    dup project.task@ nip 0= IF true abort" target.4th has no task" THEN
    project.target@ nip 0= IF true abort" target.4th has no target" THEN ;
