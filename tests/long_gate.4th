\ tests/long_gate.4th — pre-push sets FSOC_SKIP_LONG=1.
\ A normal `fmix test` leaves the variable unset and the file runs.

: long-gate ( -- )
   s" FSOC_SKIP_LONG" getenv nip if
      cr ." long test skipped" cr
      bye
   then ;
long-gate
