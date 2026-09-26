\ tests/platform_test.4th — boards load by name and leave the stack clean

s" test_common.4th" included
s" load.4th" included

s" vitasound_ep4ce10" board-load
plat.name@ s" vitasound_ep4ce10" expect-str-eq
plat.device@ s" EP4CE10E22C8" expect-str-eq
plat.family@ s" Cyclone IV E" expect-str-eq
plat.ios-len 7 expect=

s" clk50" 0 io-find dup 0<> expect-true io.clock-hz@ 50000000 expect=
plat-clock io.clock-hz@ 50000000 expect=
plat-clock io.name$ @ fsoc-fetch s" clk50" expect-str-eq
s" user_led" 0 io-find dup 0<> expect-true io.clock-hz@ 0 expect=
s" user_led" 0 io-find io.low@ 0= expect-true
s" user_led" 0 io-find 0<> expect-true
s" user_led" 1 io-find 0<> expect-true
s" nosuch" 0 io-find 0= expect-true

s" clk50" 0 request
s" user_led" 0 request
plat.reqs-len 2 expect=
s" user_led" request-all
plat.reqs-len 4 expect=

s" rz_easyfpga" board-load
plat.name@ s" rz_easyfpga" expect-str-eq
plat.device@ s" EP4CE6E22C8" expect-str-eq
plat.family@ s" Cyclone IV E" expect-str-eq
s" clk50" 0 io-find io.clock-hz@ 50000000 expect=

s" ep2c5_mini" board-load
plat.name@ s" ep2c5_mini" expect-str-eq
plat.device@ s" EP2C5T144C8" expect-str-eq
plat.family@ s" Cyclone II" expect-str-eq
s" clk50" 0 io-find io.clock-hz@ 50000000 expect=

s" colorlight_5a_75e_v6_0" board-load
plat.device@ s" LFE5U-25F-6BG256C" expect-str-eq
plat.family@ s" ECP5" expect-str-eq
plat.package@ s" CABGA256" expect-str-eq
plat.speed@ s" 6" expect-str-eq
plat.density@ s" 25k" expect-str-eq
plat-clock io.clock-hz@ 25000000 expect=
plat-clock io.pins$ @ fsoc-fetch s" P6" expect-str-eq
s" user_led" 0 io-find io.pins$ @ fsoc-fetch s" T6" expect-str-eq
s" user_led" 0 io-find io.low@ 0<> expect-true
s" user_btn" 0 io-find io.pins$ @ fsoc-fetch s" R7" expect-str-eq

s" colorlight_5a_75e_v7_1" board-load
plat.device@ s" LFE5U-25F-6BG256C" expect-str-eq
plat.speed@ s" 6" expect-str-eq
plat-clock io.clock-hz@ 25000000 expect=
s" user_led" 0 io-find io.pins$ @ fsoc-fetch s" P11" expect-str-eq
s" user_led" 0 io-find io.low@ 0<> expect-true
s" user_btn" 0 io-find io.pins$ @ fsoc-fetch s" M13" expect-str-eq

s" colorlight_5a_75e_v8_2" board-load
plat.device@ s" LFE5U-25F-7BG256I" expect-str-eq
plat.speed@ s" 7" expect-str-eq
s" user_led" 0 io-find io.pins$ @ fsoc-fetch s" T6" expect-str-eq
s" user_led" 0 io-find io.low@ 0<> expect-true

quartus-reset
s" vitasound_ep4ce10" board-load
s" serial" 0 request
s" serial" 0 s" tx" s" uart_tx" quartus-map-sub
s" serial" 0 s" rx" s" uart_rx" quartus-map-sub
s" soc" quartus-project
s" top" quartus-top
s" top.v" quartus-vfile
s" clk" s" 20" quartus-clock
s" /tmp/fsoc-qsf-test.qsf" quartus-qsf
s" grep -q 'PIN_114 -to uart_tx' /tmp/fsoc-qsf-test.qsf" system
$? 0= expect-true
s" grep -q 'PIN_115 -to uart_rx' /tmp/fsoc-qsf-test.qsf" system
$? 0= expect-true
s" rm -f /tmp/fsoc-qsf-test.qsf" system

s" nosuch" ' board-load catch 0<> expect-true
2drop

expect-stack-clean
cr ." platform_test ok" cr
