\ boards/colorlight_5a_75e_v8_2.4th — LFE5U-25F-7BG256I
\ Pins from litex-boards colorlight_5a_75e.py revision 8.2.
\ The onboard LED is active-low.

s" colorlight_5a_75e_v8_2" platform-new
s" LFE5U-25F-7BG256I" plat-device
s" ECP5" plat-family
s" CABGA256" plat-package
s" 7" plat-speed
s" 25k" plat-density

s" clk25" 0 io-begin
  s" P6" pins
  s" LVCMOS33" iostd
  25000000 plat-clock-hz
io-end

s" user_led" 0 io-begin
  s" T6" pins
  s" LVCMOS33" iostd
  active-low
io-end

s" user_btn" 0 io-begin
  s" R7" pins
  s" LVCMOS33" iostd
io-end
