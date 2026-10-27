\ Pilot host helper (flua → typical Gforth). Regen:
\   flua fsoc/flua/path_join.lua > fsoc/flua/path_join.4th
\ @forth fjson.str-concat ( a1 u1 a2 u2 -- a3 u3 )
\ @forth fjson.str-free ( a u -- )
\ Join a1/u1 and a2/u2 with "/". Allocated; caller fjson.str-free on result.
\ ( a1 u1 a2 u2 -- r1 r2 )
: fsoc_join { a1 u1 a2 u2 | sa su mid_a mid_u out_a out_u }
  s\" /" to su to sa 
  a1 u1 sa su fjson.str-concat to mid_u to mid_a 
  mid_a mid_u a2 u2 fjson.str-concat to out_u to out_a 
  mid_a mid_u fjson.str-free 
  out_a out_u 
;
