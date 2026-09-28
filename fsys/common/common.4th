: else ahead swap resolve ; immediate
: while mark-if swap ; immediate
: repeat jump resolve ; immediate
\ ( dest -- ) dest is the byte address begin left.
: until 1 rshift branch0 ; immediate
: create parse-name drop header here 2 cells + literal compile-exit ;
: variable create 0 , ;
: constant parse-name drop header literal compile-exit ;
