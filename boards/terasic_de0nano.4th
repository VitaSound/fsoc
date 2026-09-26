\ boards/terasic_de0nano.4th — EP4CE22F17C6 (litex-boards terasic_de0nano)
\ Serial tx/rx are JP1:10 and JP1:8 in that file, resolved here to B5 and B4.

s" terasic_de0nano" platform-new
s" EP4CE22F17C6" plat-device
s" Cyclone IV E" plat-family

s" clk50" 0 io-begin
  s" R8" pins
  s" LVTTL" iostd
  50000000 plat-clock-hz
io-end

s" user_led" 0 io-begin
  s" A15" pins
  s" LVTTL" iostd
io-end

s" user_led" 1 io-begin
  s" A13" pins
  s" LVTTL" iostd
io-end

s" user_led" 2 io-begin
  s" B13" pins
  s" LVTTL" iostd
io-end

s" user_led" 3 io-begin
  s" A11" pins
  s" LVTTL" iostd
io-end

s" user_led" 4 io-begin
  s" D1" pins
  s" LVTTL" iostd
io-end

s" user_led" 5 io-begin
  s" F3" pins
  s" LVTTL" iostd
io-end

s" user_led" 6 io-begin
  s" B1" pins
  s" LVTTL" iostd
io-end

s" user_led" 7 io-begin
  s" L3" pins
  s" LVTTL" iostd
io-end

s" user_btn" 0 io-begin
  s" J15" pins
io-end

s" user_btn" 1 io-begin
  s" E1" pins
io-end

s" serial" 0 io-begin
  s" tx" s" B5" subsignal
  s" rx" s" B4" subsignal
  s" LVTTL" iostd
io-end
