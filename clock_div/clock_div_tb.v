`timescale 1ns/1ps
module DUT(output clk_out1,output clk_out2,output clk_out3);
reg rst;
reg clk;



initial
begin
	rst<=1;
	clk<=0;
	#15
	rst<=0;
	#1000 $stop;
end
	
always #10 clk<=~clk;

Odd_Divider div3(clk,~rst,clk_out3);
clock_div1 div1(rst,clk,clk_out1);
clock_div2 div2(rst,clk,clk_out2);
endmodule