\ tests/platform_test.4th

s" test_common.4th" included
s" load.4th" included
s" ../boards/vitasound_ep4ce10.4th" included

plat.name@ s" vitasound_ep4ce10" fsoc-streq expect-true
plat.device@ s" EP4CE10E22C8" fsoc-streq expect-true
plat.ios-len 7 expect=

s" clk50" 0 io-find 0<> expect-true
s" user_led" 0 io-find 0<> expect-true
s" nosuch" 0 io-find 0= expect-true

s" clk50" 0 request
s" user_led" 0 request
plat.reqs-len 2 expect=

s" ../boards/rz_easyfpga.4th" included
plat.name@ s" rz_easyfpga" fsoc-streq expect-true
plat.device@ s" EP4CE6E22C8" fsoc-streq expect-true

s" ../boards/ep2c5_mini.4th" included
plat.name@ s" ep2c5_mini" fsoc-streq expect-true

cr ." platform_test ok" cr
