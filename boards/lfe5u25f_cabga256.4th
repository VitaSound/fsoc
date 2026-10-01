\ boards/lfe5u25f_cabga256.4th — package adapter, not a PCB.
\ Balls from prjtrellis database/ECP5/LFE5U-25F/iodb.json, package CABGA256.
\ clk is P6. pad 0..144 are plain PIO, then PCLK balls. VREF is unused.

s" lfe5u25f_cabga256" platform-new
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

s" pad" 0 io-begin
  s" A2" pins
  s" LVCMOS33" iostd
io-end

s" pad" 1 io-begin
  s" A3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 2 io-begin
  s" A4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 3 io-begin
  s" A5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 4 io-begin
  s" A6" pins
  s" LVCMOS33" iostd
io-end

s" pad" 5 io-begin
  s" A9" pins
  s" LVCMOS33" iostd
io-end

s" pad" 6 io-begin
  s" A10" pins
  s" LVCMOS33" iostd
io-end

s" pad" 7 io-begin
  s" A11" pins
  s" LVCMOS33" iostd
io-end

s" pad" 8 io-begin
  s" A12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 9 io-begin
  s" A13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 10 io-begin
  s" A14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 11 io-begin
  s" A15" pins
  s" LVCMOS33" iostd
io-end

s" pad" 12 io-begin
  s" B1" pins
  s" LVCMOS33" iostd
io-end

s" pad" 13 io-begin
  s" B2" pins
  s" LVCMOS33" iostd
io-end

s" pad" 14 io-begin
  s" B3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 15 io-begin
  s" B4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 16 io-begin
  s" B5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 17 io-begin
  s" B6" pins
  s" LVCMOS33" iostd
io-end

s" pad" 18 io-begin
  s" B10" pins
  s" LVCMOS33" iostd
io-end

s" pad" 19 io-begin
  s" B11" pins
  s" LVCMOS33" iostd
io-end

s" pad" 20 io-begin
  s" B12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 21 io-begin
  s" B13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 22 io-begin
  s" B14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 23 io-begin
  s" B16" pins
  s" LVCMOS33" iostd
io-end

s" pad" 24 io-begin
  s" C1" pins
  s" LVCMOS33" iostd
io-end

s" pad" 25 io-begin
  s" C2" pins
  s" LVCMOS33" iostd
io-end

s" pad" 26 io-begin
  s" C3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 27 io-begin
  s" C4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 28 io-begin
  s" C5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 29 io-begin
  s" C6" pins
  s" LVCMOS33" iostd
io-end

s" pad" 30 io-begin
  s" C10" pins
  s" LVCMOS33" iostd
io-end

s" pad" 31 io-begin
  s" C11" pins
  s" LVCMOS33" iostd
io-end

s" pad" 32 io-begin
  s" C12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 33 io-begin
  s" C13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 34 io-begin
  s" C14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 35 io-begin
  s" C15" pins
  s" LVCMOS33" iostd
io-end

s" pad" 36 io-begin
  s" C16" pins
  s" LVCMOS33" iostd
io-end

s" pad" 37 io-begin
  s" D1" pins
  s" LVCMOS33" iostd
io-end

s" pad" 38 io-begin
  s" D3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 39 io-begin
  s" D4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 40 io-begin
  s" D5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 41 io-begin
  s" D6" pins
  s" LVCMOS33" iostd
io-end

s" pad" 42 io-begin
  s" D9" pins
  s" LVCMOS33" iostd
io-end

s" pad" 43 io-begin
  s" D10" pins
  s" LVCMOS33" iostd
io-end

s" pad" 44 io-begin
  s" D11" pins
  s" LVCMOS33" iostd
io-end

s" pad" 45 io-begin
  s" D12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 46 io-begin
  s" D13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 47 io-begin
  s" D14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 48 io-begin
  s" D16" pins
  s" LVCMOS33" iostd
io-end

s" pad" 49 io-begin
  s" E1" pins
  s" LVCMOS33" iostd
io-end

s" pad" 50 io-begin
  s" E2" pins
  s" LVCMOS33" iostd
io-end

s" pad" 51 io-begin
  s" E3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 52 io-begin
  s" E4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 53 io-begin
  s" E5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 54 io-begin
  s" E6" pins
  s" LVCMOS33" iostd
io-end

s" pad" 55 io-begin
  s" E9" pins
  s" LVCMOS33" iostd
io-end

s" pad" 56 io-begin
  s" E10" pins
  s" LVCMOS33" iostd
io-end

s" pad" 57 io-begin
  s" E11" pins
  s" LVCMOS33" iostd
io-end

s" pad" 58 io-begin
  s" E12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 59 io-begin
  s" E13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 60 io-begin
  s" E14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 61 io-begin
  s" E15" pins
  s" LVCMOS33" iostd
io-end

s" pad" 62 io-begin
  s" E16" pins
  s" LVCMOS33" iostd
io-end

s" pad" 63 io-begin
  s" F1" pins
  s" LVCMOS33" iostd
io-end

s" pad" 64 io-begin
  s" F2" pins
  s" LVCMOS33" iostd
io-end

s" pad" 65 io-begin
  s" F3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 66 io-begin
  s" F4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 67 io-begin
  s" F5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 68 io-begin
  s" F12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 69 io-begin
  s" F13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 70 io-begin
  s" F14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 71 io-begin
  s" F15" pins
  s" LVCMOS33" iostd
io-end

s" pad" 72 io-begin
  s" F16" pins
  s" LVCMOS33" iostd
io-end

s" pad" 73 io-begin
  s" G2" pins
  s" LVCMOS33" iostd
io-end

s" pad" 74 io-begin
  s" G4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 75 io-begin
  s" G5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 76 io-begin
  s" G12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 77 io-begin
  s" G13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 78 io-begin
  s" G15" pins
  s" LVCMOS33" iostd
io-end

s" pad" 79 io-begin
  s" H2" pins
  s" LVCMOS33" iostd
io-end

s" pad" 80 io-begin
  s" H3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 81 io-begin
  s" H4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 82 io-begin
  s" H5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 83 io-begin
  s" H12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 84 io-begin
  s" H13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 85 io-begin
  s" H14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 86 io-begin
  s" H15" pins
  s" LVCMOS33" iostd
io-end

s" pad" 87 io-begin
  s" J4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 88 io-begin
  s" J5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 89 io-begin
  s" J12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 90 io-begin
  s" J13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 91 io-begin
  s" K3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 92 io-begin
  s" K5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 93 io-begin
  s" K12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 94 io-begin
  s" K14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 95 io-begin
  s" L3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 96 io-begin
  s" L5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 97 io-begin
  s" L12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 98 io-begin
  s" L14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 99 io-begin
  s" M3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 100 io-begin
  s" M4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 101 io-begin
  s" M5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 102 io-begin
  s" M6" pins
  s" LVCMOS33" iostd
io-end

s" pad" 103 io-begin
  s" M11" pins
  s" LVCMOS33" iostd
io-end

s" pad" 104 io-begin
  s" M12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 105 io-begin
  s" M13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 106 io-begin
  s" M14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 107 io-begin
  s" N1" pins
  s" LVCMOS33" iostd
io-end

s" pad" 108 io-begin
  s" N3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 109 io-begin
  s" N4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 110 io-begin
  s" N5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 111 io-begin
  s" N6" pins
  s" LVCMOS33" iostd
io-end

s" pad" 112 io-begin
  s" N11" pins
  s" LVCMOS33" iostd
io-end

s" pad" 113 io-begin
  s" N12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 114 io-begin
  s" N13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 115 io-begin
  s" N14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 116 io-begin
  s" N16" pins
  s" LVCMOS33" iostd
io-end

s" pad" 117 io-begin
  s" P1" pins
  s" LVCMOS33" iostd
io-end

s" pad" 118 io-begin
  s" P2" pins
  s" LVCMOS33" iostd
io-end

s" pad" 119 io-begin
  s" P3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 120 io-begin
  s" P4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 121 io-begin
  s" P13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 122 io-begin
  s" P14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 123 io-begin
  s" P15" pins
  s" LVCMOS33" iostd
io-end

s" pad" 124 io-begin
  s" P16" pins
  s" LVCMOS33" iostd
io-end

s" pad" 125 io-begin
  s" R2" pins
  s" LVCMOS33" iostd
io-end

s" pad" 126 io-begin
  s" R3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 127 io-begin
  s" R4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 128 io-begin
  s" R5" pins
  s" LVCMOS33" iostd
io-end

s" pad" 129 io-begin
  s" R12" pins
  s" LVCMOS33" iostd
io-end

s" pad" 130 io-begin
  s" R13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 131 io-begin
  s" R14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 132 io-begin
  s" R15" pins
  s" LVCMOS33" iostd
io-end

s" pad" 133 io-begin
  s" T2" pins
  s" LVCMOS33" iostd
io-end

s" pad" 134 io-begin
  s" T3" pins
  s" LVCMOS33" iostd
io-end

s" pad" 135 io-begin
  s" T4" pins
  s" LVCMOS33" iostd
io-end

s" pad" 136 io-begin
  s" T13" pins
  s" LVCMOS33" iostd
io-end

s" pad" 137 io-begin
  s" T14" pins
  s" LVCMOS33" iostd
io-end

s" pad" 138 io-begin
  s" T15" pins
  s" LVCMOS33" iostd
io-end

s" pad" 139 io-begin
  s" A7" pins
  s" LVCMOS33" iostd
io-end

s" pad" 140 io-begin
  s" A8" pins
  s" LVCMOS33" iostd
io-end

s" pad" 141 io-begin
  s" B7" pins
  s" LVCMOS33" iostd
io-end

s" pad" 142 io-begin
  s" B8" pins
  s" LVCMOS33" iostd
io-end

s" pad" 143 io-begin
  s" B9" pins
  s" LVCMOS33" iostd
io-end

s" pad" 144 io-begin
  s" C7" pins
  s" LVCMOS33" iostd
io-end

