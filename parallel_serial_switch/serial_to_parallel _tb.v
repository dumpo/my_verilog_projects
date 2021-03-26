`timescale 1ns/1ps
module DUT2(output [7:0] out );
	reg clk;
	reg rst_n;
	reg in;
	initial begin
		rst_n=0;
		clk=0;

		#50
		rst_n=1;
		in=0;

		#20
		in=1;
		
		#20

		in=1;
		#20
in=0;

		#20
in=1;

		#20
in=0;
		#20
in=1;
		#20
in=1;
#200
		$stop;
		
	end
	
	always#10
		clk<=~clk;
	serial_to_parallel u2(rst_n,clk,in,out);
endmodule