`timescale 1ns/1ns
`define clk_period 20

module DR_LUT_tb();
	 reg clk;
    reg rst_n;
    reg [2:0]baud_set;
    wire[15:0] bps_DR;
	 
	initial begin
	 clk = 1;
	 rst_n = 1'b1;
	 baud_set=3'd4;
	 
	 
	 #(`clk_period*10);
	 baud_set=3'd2;
	 #(`clk_period*10);
	 $stop;	
	 end
	 
	always#(`clk_period/2)clk = ~clk;

	 DR_LUT tb1
	(
	.clk(clk),
	.rst_n(rst_n),
	.baud_set(baud_set),
	.bps_DR(bps_DR)
	);
endmodule