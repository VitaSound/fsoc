\ boards/colorlight_5a_75e_v7_1.4th — LFE5U-25F-6BG256C
\ Pins from litex-boards colorlight_5a_75e.py revision 7.1.
\ The onboard LED is active-low.

s" colorlight_5a_75e_v7_1" platform-new
s" LFE5U-25F-6BG256C" plat-device
s" ECP5" plat-family
s" CABGA256" plat-package
s" 6" plat-speed
s" 25k" plat-density

s" clk25" 0 io-begin
  s" P6" pins
  s" LVCMOS33" iostd
  25000000 plat-clock-hz
io-end

s" user_led" 0 io-begin
  s" P11" pins
  s" LVCMOS33" iostd
io-end

s" user_btn" 0 io-begin
  s" M13" pins
  s" LVCMOS33" iostd
io-end
