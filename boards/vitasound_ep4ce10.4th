\ boards/vitasound_ep4ce10.4th — EP4CE10E22C8, pins from VitaPolySimple.qsf

s" vitasound_ep4ce10" platform-new
s" EP4CE10E22C8" plat-device

s" clk50" 0 io-begin
  s" 23" pins
  s" LVTTL" iostd
io-end

s" user_led" 0 io-begin
  s" 86" pins
  s" LVTTL" iostd
io-end

s" user_led" 1 io-begin
  s" 85" pins
  s" LVTTL" iostd
io-end

s" user_btn" 0 io-begin
  s" 25" pins
io-end

s" user_btn" 1 io-begin
  s" 24" pins
io-end

s" serial" 0 io-begin
  s" tx" s" 114" subsignal
  s" rx" s" 115" subsignal
  s" LVTTL" iostd
io-end

s" midi" 0 io-begin
  s" rx" s" 105" subsignal
io-end
