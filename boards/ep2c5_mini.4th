\ boards/ep2c5_mini.4th — Cyclone II EP2C5T144C8 (Quartus II 13.0sp1)

s" ep2c5_mini" platform-new
s" EP2C5T144C8" plat-device
s" Cyclone II" plat-family

s" clk50" 0 io-begin
  s" 23" pins
  s" LVTTL" iostd
  50000000 plat-clock-hz
io-end

s" user_led" 0 io-begin
  s" 3" pins
io-end

s" user_btn" 0 io-begin
  s" 144" pins
io-end
