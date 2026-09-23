\ fsoc/soc/cores.4th — uart, gpio, timer, ctrl CSR cores

: cores-uart ( - )
    s" uart" csr-core-begin
    s" rxtx" 32 csr-storage
    s" txfull" 1 csr-status
    s" rxempty" 1 csr-status
    csr-core-end ;

: cores-gpio ( - )
    s" gpio" csr-core-begin
    s" oe" 32 csr-storage
    s" out" 32 csr-storage
    s" in" 32 csr-status
    csr-core-end ;

: cores-timer ( - )
    s" timer" csr-core-begin
    s" load" 32 csr-storage
    s" value" 32 csr-status
    s" en" 1 csr-storage
    csr-core-end ;

: cores-ctrl ( - )
    s" ctrl" csr-core-begin
    s" reset" 1 csr-storage
    s" scratch" 32 csr-storage
    s" bus_errors" 32 csr-status
    csr-core-end ;

: cores-minimal-soc ( - )
    csr-reset
    cores-ctrl
    cores-uart
    cores-gpio
    cores-timer ;
