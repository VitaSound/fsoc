\ fsoc/registry.4th — tasks and targets register their words here.
\ The CLI finds them by the names in the manifest and executes them.

begin-structure task%
    field: task.name$
    field: task.emit
end-structure

begin-structure target%
    field: target.name$
    field: target.emit
    field: target.run
    field: target.load
    field: target.sim
end-structure

variable fsoc-tasks
variable fsoc-targets
ulist-new fsoc-tasks !
ulist-new fsoc-targets !

: task-register ( name-a name-u emit-xt -- )
    task% allocate throw >r
    r@ task.emit !
    fsoc-store r@ task.name$ !
    r> fsoc-tasks @ ulist-add ;

\ Set immediately before target-register. Only the emulation target does.
variable target-reg-sim
: target-sim ( -- ) true target-reg-sim ! ;

: target-register ( name-a name-u emit-xt run-xt load-xt -- )
    target% allocate throw >r
    r@ target.load !
    r@ target.run !
    r@ target.emit !
    target-reg-sim @ r@ target.sim !
    0 target-reg-sim !
    fsoc-store r@ target.name$ !
    r> fsoc-targets @ ulist-add ;

variable reg-find-a
variable reg-find-u
variable reg-find-r

\ task% and target% both start with name$.
: reg-match ( entry -- )
    dup @ fsoc-fetch reg-find-a @ reg-find-u @ compare 0= IF
        reg-find-r !
    ELSE drop THEN ;

: reg-find ( name-a name-u lst -- entry|0 )
    >r reg-find-u ! reg-find-a !
    0 reg-find-r !
    ['] reg-match r> ulist-each
    reg-find-r @ ;

: task-find ( name-a name-u -- task|0 )
    fsoc-tasks @ reg-find ;

: target-find ( name-a name-u -- target|0 )
    fsoc-targets @ reg-find ;

: task-of ( project -- task )
    project.task@ task-find dup 0= IF true abort" unknown task" THEN ;

: target-of ( project -- target )
    project.target@ target-find dup 0= IF true abort" unknown target" THEN ;
