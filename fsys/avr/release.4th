\ Roots an AVR release image keeps. The second pass adds every word these names need.

[IFUNDEF] release-root
: release-root ( a u -- ) 2drop ;
[THEN]

s" quit" release-root
s" accept" release-root
s" :" release-root
s" ;" release-root
s" 'BOOT" release-root
s" words" release-root
