\ fsoc/toolchains/icarus.4th — blinky sim files

: icarus-write-tb ( c-addr-path u - )
    s\" `timescale 1ns / 1ps\nmodule tb;\n  reg clk50;\n  wire user_led;\n  blinky dut(.clk50(clk50), .user_led(user_led));\n  initial clk50 = 0;\n  always #10 clk50 = ~clk50;\n  initial begin\n    $dumpfile(\"out.vcd\");\n    $dumpvars(0, tb);\n    #200;\n    $display(\"blinky sim ok led=%b\", user_led);\n    $finish;\n  end\nendmodule\n" fsoc-write-file ;

: icarus-write-sim-sh ( c-addr-path u - )
    s\" #!/bin/sh\nset -e\niverilog -o tb blinky.v tb.v\nvvp tb\n" fsoc-write-file ;

: verilator-write-sh ( c-addr-path u - )
    s\" #!/bin/sh\nset -e\nverilator --lint-only blinky.v\n" fsoc-write-file ;
