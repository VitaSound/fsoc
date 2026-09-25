\ fsoc/log.4th — build log line: fsoc: <project dir name> - <text>

: fsoc-note ( c-addr u -- )
    cr ." fsoc: "
    cwd@ fsoc-basename type
    ."  - " type cr ;
