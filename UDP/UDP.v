`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:28:11 12/05/2017 
// Design Name: 
// Module Name:    UDP 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    udp数据通信模块
//////////////////////////////////////////////////////////////////////////////////

module UDP(
			input wire           reset_n,
			
			input	 wire           e_rxc,
			output wire	          e_txen,
			output wire	[7:0]     e_txd,                              
			output wire		       e_txer,		
		
			input  wire [31:0]    ram_rd_data,                         //ram读出的数据
		   output      [3:0]     tx_state,                            //UDP数据发送状态机

			input [13:0] Data_Length,
		   output wire [12:0]     ram_rd_addr,                         //ram数据读地址
			input ipsend_en
);


wire	[31:0] crcnext;
wire	[31:0] crc32;
wire	crcreset;
wire	crcen;


//IP frame发送
ipsend ipsend_inst(
	.clk(e_rxc),
	.txen(e_txen),
	.txer(e_txer),
	.dataout(e_txd),
	.crc(crc32),
	.datain(ram_rd_data),
	.crcen(crcen),
	.crcre(crcreset),
	.tx_state(tx_state),
//	.tx_data_length(tx_data_length),
//	.tx_total_length(tx_total_length),
	.Data_Length (Data_Length),
	.ram_rd_addr(ram_rd_addr),
	.ipsend_en       (ipsend_en)
	);
	
//crc32校验
crc	crc_inst(
	.Clk(e_rxc),
	.Reset(crcreset),
	.Enable(crcen),
	.Data_in(e_txd),
	.Crc(crc32),
	.CrcNext(crcnext));
	
endmodule

