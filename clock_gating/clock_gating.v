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
//Clock_EN 只在时钟低电平时才切换，确保不出现毛刺
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module clock_delay(
	input rst,
    input clk_in,
    output clk_out
    );

reg carry;
reg [12:0] cnt1;
reg [13:0] cnt2;
reg clk_EN;
reg cnt_EN;


always@(posedge clk_in) begin
	if(rst) begin
		cnt1<=0;
		carry<=0;
	end
	else if(cnt1==13'd50) begin
		cnt1<=0;
		carry<=1;
	end
	else begin
		cnt1<=cnt1+1;
		carry<=0;
	end
end

always@(posedge clk_in) begin
	if(rst) begin
		cnt2<=0;
		cnt_EN<=0;
	end
	else if(cnt2==14'd10) begin
		cnt2<=0;
		cnt_EN<=1;
	end
	else if(carry) begin
	cnt2<=cnt2+1;
	end
	else cnt_EN<=cnt_EN;
end

always@(cnt_EN or clk_in)
	if(!clk_in)  clk_EN=cnt_EN;

assign clk_out=clk_in&clk_EN;
endmodule
