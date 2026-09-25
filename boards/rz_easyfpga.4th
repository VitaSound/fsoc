\ boards/rz_easyfpga.4th — EP4CE6E22C8 (litex-boards rz_easyfpga)

s" rz_easyfpga" platform-new
s" EP4CE6E22C8" plat-device
s" Cyclone IV E" plat-family

s" clk50" 0 io-begin
  s" 23" pins
  s" LVTTL" iostd
  50000000 plat-clock-hz
io-end

s" user_led" 0 io-begin
  s" 87" pins
io-end

s" user_btn" 0 io-begin
  s" 25" pins
io-end

s" serial" 0 io-begin
  s" tx" s" 114" subsignal
  s" rx" s" 115" subsignal
io-end
