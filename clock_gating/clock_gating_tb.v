`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:29:10 03/02/2021 
// Design Name: 
// Module Name:    clock_delay
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 上电后，延迟1S再允许时钟，保证芯片上电时序正常。
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module clock_delay_tb();
	reg clk_in;
	reg rst;
	wire clk_out;
	

	initial begin 
	clk_in=0;
	rst=1;
	#40
	rst=0;
	#100000
	$finish;
	end
	

always #10 clk_in<=~clk_in;
	clock_delay u1(.clk_in(clk_in),.clk_out(clk_out),.rst(rst));
endmodule
