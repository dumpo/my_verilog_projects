module parallel_to_serial
(
rst_n,load,clk,in,out
);


parameter WEIDTH=8;
input [WEIDTH-1:0] in;
input rst_n;
input load;
input clk;
output reg out;
reg [2:0] cnt;
reg [WEIDTH-1:0] in_reg;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		in_reg<=8'b0;
		out<=0;
		end
	else if(load) in_reg<=in;
	else begin
		case(cnt)
			0:out<=in_reg[0];
			1:out<=in_reg[1];
			2:out<=in_reg[2];
			3:out<=in_reg[3];
			4:out<=in_reg[4];
			5:out<=in_reg[5];
			6:out<=in_reg[6];
			7:out<=in_reg[7];
			default:out<=out;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 
		cnt<=0;
	else if(cnt==WEIDTH-1)
		cnt<=0;
	else
		cnt<=cnt+1;
	
end

endmodule