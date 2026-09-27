: else ahead swap resolve ; immediate
: while mark-if swap ; immediate
: repeat jump resolve ; immediate
: /mod um/mod ;
: mod /mod drop ;
: / /mod swap drop ;
: create parse-name drop header here 2 cells + literal compile-exit ;
: variable create 0 , ;
: constant parse-name drop header literal compile-exit ;
: type begin dup while over @ emit swap cell+ swap 1 - repeat drop drop ;
: ." begin tibc dup 34 = 0 = while literal compile-emit repeat drop ; immediate
