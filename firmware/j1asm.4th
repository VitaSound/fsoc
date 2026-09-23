\ firmware/j1asm.4th — J1 instruction encoder (swapforth field layout)

variable j1-here
create j1-mem 64 cells allot

: j1-org ( u - ) j1-here ! ;

: j1-comma ( u - )
    j1-mem j1-here @ cells + !
    1 j1-here +! ;

\ bit 15 set: push a 15-bit literal
: j1-lit ( u - ) $8000 or j1-comma ;

\ 15:13 = 000, low 13 bits are the target word address
: j1-jump ( u - ) $1fff and j1-comma ;

\ 15:13 = 001, branch when T is zero (the CPU drops T)
: j1-0branch ( u - ) $1fff and $2000 or j1-comma ;

\ ALU: T becomes io_din, io_rd strobe, stack depth unchanged
: j1-io@ ( - ) $6d50 j1-comma ;

\ ALU: T & N, drop
: j1-and ( - ) $6303 j1-comma ;

\ ALU: write N to io[T], drop the address
: j1-iow ( - ) $6043 j1-comma ;

\ ALU: T becomes N, drop
: j1-drop ( - ) $6103 j1-comma ;
