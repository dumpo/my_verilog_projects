`timescale 1ns/1ps
module DUT1(output out );
	reg clk;
	reg rst_n;
	reg [7:0] in;
	reg load;
	initial begin
		rst_n=0;
		clk=0;
		load=0;
		#50
		rst_n=1;
		in=8'd4;
		load=1;
		#30
		load=0;
		
		#200
		load=1;
		in=8'd127;
		#30
		load=0;

		#200
		load=1;
		in=8'd255;
		#30
		load=0;
		#200
		$stop;
		
	end
	
	always#10
		clk<=~clk;
	parallel_to_serial u1(rst_n,load,clk,in,out);
endmodule