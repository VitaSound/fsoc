\ tests/csr_test.4th

s" test_common.4th" included
s" load.4th" included

cores-minimal-soc
csr-count 12 expect=

s" mkdir -p build/soc/software" system
s" build/soc/software/csr.4th" csr-export-4th
s" build/soc/software/csr.json" csr-export-json

s" test -f build/soc/software/csr.4th" system
$? 0= expect-true
s" test -f build/soc/software/csr.json" system
$? 0= expect-true
s" grep -q CSR-uart-rxtx build/soc/software/csr.4th" system
$? 0= expect-true
s" grep -q uart_rxtx build/soc/software/csr.json" system
$? 0= expect-true

cr ." csr_test ok" cr
