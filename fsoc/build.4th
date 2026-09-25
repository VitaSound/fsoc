\ fsoc/build.4th — the build pipeline. Reads the manifest, resolves task
\ and target in the registry, loads the board, then runs
\ task.emit, target.emit, target.run (--build) or target.load (--load).

\ included resolves names from the source file, not cwd: absolute path.
\ The manifest leaves nothing on the stack; a broken one aborts here.
: fsoc-read-manifest ( - project )
    project-new
    s" target.4th" project@ project.file
    depth >r
    2dup included
    depth r> <> IF true abort" target.4th leaves stack" THEN
    fjson.str-free
    project@ dup project-check ;

\ Task and target are resolved before any emit.
: fsoc-build ( project - )
    >r
    r@ task-of r@ target-of
    r@ project.board@ dup IF board-load ELSE 2drop THEN
    over task.emit @ r@ swap execute
    dup target.emit @ r@ swap execute
    target.run @ r@ swap execute
    drop rdrop ;

: fsoc-load ( project - )
    dup target-of target.load @ execute ;
