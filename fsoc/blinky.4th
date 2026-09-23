\ fsoc/blinky.4th — blinky Verilog + sim scripts

variable b-dir-a
variable b-dir-u

: blinky-verilog ( - c-addr u )
    s\" module blinky (\n    input  wire clk50,\n    output wire user_led\n);\n    reg [25:0] counter;\n    always @(posedge clk50) begin\n        counter <= counter + 1'b1;\n    end\n    assign user_led = counter[25];\nendmodule\n" ;

: blinky-join ( c-addr-name u - c-addr u )
    b-dir-a @ b-dir-u @ 2swap fsoc-append ;

: blinky-emit-dir ( c-addr-dir u - )
    b-dir-u ! b-dir-a !
    s" /blinky.v" blinky-join blinky-verilog fsoc-write-file
    s" /tb.v" blinky-join icarus-write-tb
    s" /sim.sh" blinky-join icarus-write-sim-sh
    s" /lint.sh" blinky-join verilator-write-sh ;
