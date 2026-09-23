\ targets/base_soc.4th — J1 + UART + GPIO + timer + ctrl

s" ../fsoc/load.4th" included
s" ../boards/vitasound_ep4ce10.4th" included

s" clk50" 0 request
s" user_led" 0 request
s" serial" 0 request

cores-minimal-soc
s" mkdir -p ../build/soc/software" system
s" ../build/soc/software/csr.4th" csr-export-4th
s" ../build/soc/software/csr.json" csr-export-json
cr ." base SoC CSR written to build/soc/software" cr
