`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:28:56 12/05/2017 
// Design Name: 
// Module Name:    ipsend 
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
/****************************************/
//      GMII UDP数据包发送模块　　　　　　　//
/****************************************/

module ipsend(
				  input              clk,                   //GMII发送的时钟信号
				  output reg         txen,                  //GMII数据使能信号
				  output reg         txer,                  //GMII发送错误信号
				  output reg [7:0]   dataout,               //GMII发送数据
				  input      [31:0]  crc,                   //CRC32校验码
				  input      [31:0]  datain,                //RAM中的数据	 
				  output reg         crcen,                 //CRC32 校验使能
				  output reg         crcre,                 //CRC32 校验清除

				  output reg [3:0]   tx_state,              //发送状态机    
					
				  input  [13:0] Data_Length,
				  output reg [12:0]   ram_rd_addr,            //ram读地址
				  input ipsend_en
				  
	  );

wire [15:0] Data_Length_16bit;
assign Data_Length_16bit = {1'b0,Data_Length,1'b0};//一共需要发送的字节数,等于脉冲采样点数*2，尾部补1个零，相当于乘以2。

parameter bag_length=16'd128;
parameter bag_width=7;
//parameter bag_width=$clog2(bag_length);

wire [6:0] tx_bag_total;
reg [6:0] send_bag_counter;
wire [15:0] tx_lastbag_length;
wire bag_add;
assign tx_lastbag_length=(Data_Length_16bit[bag_width-1:0])?{8'd0,Data_Length_16bit[bag_width-1:0]}:16'd128; //这样能够适应采样点数16000，即2MHz采样率&8ms脉宽OK
assign bag_add=(Data_Length_16bit[bag_width-1:0])?1'b1:1'b0;
assign tx_bag_total=Data_Length_16bit[14:bag_width]+bag_add;

				

reg [15:0]  tx_total_length;//发送包的长度
reg [15:0]  tx_data_length;        //发送的数据包的长度
reg [15:0]  tx_counter_length;//发送包的长度

reg [31:0]  datain_reg;
reg [7:0] waitcounter;

reg [31:0] ip_header [6:0];                  //数据段为1K

reg [7:0] preamble [7:0];                    //preamble
reg [7:0] mac_addr [13:0];                   //mac address
reg [4:0] i,j;

reg [31:0] check_buffer;
reg [31:0] time_counter;
reg [15:0] tx_data_counter;
reg [31:0] ipbag_counter;

reg [31:0] udpbag_counter;


parameter idle=4'b0000,start=4'b0001,make=4'b0010,send55=4'b0011,sendmac=4'b0100,sendheader=4'b0101,sendcounter=4'b0110,
          senddata=4'b0111,sendcrc=4'b1000,sendcircle=4'b1001,sendwait=4'b1010;



initial
  begin
	 tx_state<=idle;
	 //定义IP 包头
	 preamble[0]<=8'h55;                 //7个前导码55,一个帧开始符d5
	 preamble[1]<=8'h55;
	 preamble[2]<=8'h55;
	 preamble[3]<=8'h55;
	 preamble[4]<=8'h55;
	 preamble[5]<=8'h55;
	 preamble[6]<=8'h55;
	 preamble[7]<=8'hD5;
	 mac_addr[0]<=8'hFF;                 //目的MAC地址 ff-ff-ff-ff-ff-ff, 全ff为广播包
	 mac_addr[1]<=8'hFF;
	 mac_addr[2]<=8'hFF;
	 mac_addr[3]<=8'hFF;
	 mac_addr[4]<=8'hFF;
	 mac_addr[5]<=8'hFF;
	 mac_addr[6]<=8'h00;                 //默认的开发板源MAC地址 00-0A-35-01-FE-C0, 用户也可以修改
	 mac_addr[7]<=8'h0A;
	 mac_addr[8]<=8'h35;
	 mac_addr[9]<=8'h01;
	 mac_addr[10]<=8'hFE;
	 mac_addr[11]<=8'hC0;
	 mac_addr[12]<=8'h08;                //0800: IP包类型
	 mac_addr[13]<=8'h00;
	 i<=0;
 end


//UDP数据发送程序	 
always@(negedge clk)
begin		
		case(tx_state)
		  idle:begin
				 txer<=1'b0;
				 txen<=1'b0;
				 crcen<=1'b0;
				 crcre<=1;
				 j<=0;
				 dataout<=0;
				 ram_rd_addr<=0;
				 tx_data_counter<=0;
				 send_bag_counter<=0;
				 waitcounter <=8'd0;
//				 datain_reg <=0;
/*             if (time_counter==32'h04000000) begin     //等待延迟, 每隔一段时间发送一个数据包，值越小，包发送之间的间隔越小
				     tx_state<=start;  
                 time_counter<=0;
             end
             else
                 time_counter<=time_counter+1'b1;
				
*/	

				if(ipsend_en) 	begin tx_state<=sendcircle;end 	
			end
			sendcircle:begin
				if(send_bag_counter==tx_bag_total) 
					begin 
						tx_state<=idle;					
						ipbag_counter<=ipbag_counter+1'b1;
					end
				else if(send_bag_counter==tx_bag_total-1'b1)
						begin
							tx_data_length <= tx_lastbag_length;
							tx_total_length <= tx_lastbag_length + 16'd44;
							tx_counter_length <= tx_lastbag_length + 16'd24;
							tx_state<=start;
							send_bag_counter<=send_bag_counter+1'b1;
							tx_data_counter<=0;
							txer<=1'b0;
				         txen<=1'b0;
				         crcen<=1'b0;
				         crcre<=1;
				         j<=0;
				         dataout<=0;
						end
				else
					begin
						tx_data_length <= bag_length;
						tx_total_length <= bag_length + 16'd44;
						tx_counter_length <= bag_length + 16'd24;
						tx_state<=start;
						send_bag_counter<=send_bag_counter+1'b1;
						tx_data_counter<=0;
						txer<=1'b0;
			         txen<=1'b0;
				      crcen<=1'b0;
				      crcre<=1;
				      j<=0;
			     	   dataout<=0;
					end					
				end						
		   start:begin        //IP header
					ip_header[0]<={16'h4500,tx_total_length};        //版本号：4； 包头长度：20；IP包总长
//					ip_header[1][31:16]<=ip_header[1][31:16]+1'b1;   //包序列号
					ip_header[1][31:16]<=16'h4000;   //包序列号					
					ip_header[1][15:0]<=16'h4000;                    //Fragment offset
				   ip_header[2]<=32'h80110000;                      //mema[2][15:0] 协议：17(UDP)
				   ip_header[3]<=32'hc0a80002;                      //192.168.0.2源地址
				   ip_header[4]<=32'hc0a80003;                      //192.168.0.3目的地址广播地址
					ip_header[5]<=32'h1f901f90;                      //2个字节的源端口号和2个字节的目的端口号
				   ip_header[6]<={tx_counter_length,16'h0000};         //2个字节的数据长度和2个字节的校验和（无）
	   			tx_state<=make;
					udpbag_counter<=udpbag_counter+1'b1;
         end	
         make:begin            //生成包头的校验和
			    if(i==0) begin
					  check_buffer<=ip_header[0][15:0]+ip_header[0][31:16]+ip_header[1][15:0]+ip_header[1][31:16]+ip_header[2][15:0]+
					               ip_header[2][31:16]+ip_header[3][15:0]+ip_header[3][31:16]+ip_header[4][15:0]+ip_header[4][31:16];
                 i<=i+1'b1;
				   end
             else if(i==1) begin
					   check_buffer[15:0]<=check_buffer[31:16]+check_buffer[15:0];
					   i<=i+1'b1;
				 end
			    else	begin
				      ip_header[2][15:0]<=~check_buffer[15:0];                 //header checksum
					   i<=0;
					   tx_state<=send55;
					end
		   end
			send55: begin                    //发送8个IP前导码:7个55, 1个d5                    
 				 txen<=1'b1;                             //GMII数据发送有效
				 crcre<=1'b1;                            //reset crc  
				 if(i==7) begin
               dataout[7:0]<=preamble[i][7:0];
					i<=0;
				   tx_state<=sendmac;
				 end
				 else begin                        
				    dataout[7:0]<=preamble[i][7:0];
				    i<=i+1;
				 end
			end	
			sendmac: begin                           //发送目标MAC address和源MAC address和IP包类型  
			 	 crcen<=1'b1;                            //crc校验使能，crc32数据校验从目标MAC开始		
				 crcre<=1'b0;                            			
             if(i==13) begin
               dataout[7:0]<=mac_addr[i][7:0];
					i<=0;
				   tx_state<=sendheader;
				 end
				 else begin                        
				    dataout[7:0]<=mac_addr[i][7:0];
				    i<=i+1'b1;
				 end
			end
			sendheader: begin                        //发送7个32bit的IP 包头	
			   if(j==6) begin                        //发送ip_header[6]                   
					  if(i==0) begin
						 dataout[7:0]<=ip_header[j][31:24];
						 i<=i+1'b1;
					  end
					  else if(i==1) begin
						 dataout[7:0]<=ip_header[j][23:16];
						 i<=i+1'b1;
					  end
					  else if(i==2) begin
						 dataout[7:0]<=ip_header[j][15:8];
						 i<=i+1'b1;
					  end
					  else if(i==3) begin
						 dataout[7:0]<=ip_header[j][7:0];
						 i<=0;
						 j<=0;
						 tx_state<=sendcounter;			 
					  end
					  else
						 txer<=1'b1;
				end		 
				else begin                                   //发送ip_header[0]~ip_header[5]   
					  if(i==0) begin
						 dataout[7:0]<=ip_header[j][31:24];
						 i<=i+1'b1;
					  end
					  else if(i==1) begin
						 dataout[7:0]<=ip_header[j][23:16];
						 i<=i+1'b1;
					  end
					  else if(i==2) begin
						 dataout[7:0]<=ip_header[j][15:8];
						 i<=i+1'b1;
					  end
					  else if(i==3) begin
						 dataout[7:0]<=ip_header[j][7:0];
						 i<=0;
						 j<=j+1'b1;
					  end					
					  else
						 txer<=1'b1;
				end
			 end
			 sendcounter:begin		 
			 	datain_reg<=datain;                   //准备需要发送的数据
//				datain_reg<=datain_reg+1'b1;
				if(i==0) begin 
				dataout[7:0]<=8'hF5;//F5
				i<=i+1'b1;
				end
				else if(i==1) begin 
				dataout[7:0]<=8'hCF;//CF
				i<=i+1'b1;
				end
				else if(i==2) begin 
				dataout[7:0]<=8'hFC;//FC
				i<=i+1'b1;
				end
				else if(i==3) begin 
				dataout[7:0]<=8'h5F;//5F
				i<=i+1'b1;
				end	
				else if(i==4) begin 
//				dataout[7:0]<=8'h20;//验证AD9508写入操作
				dataout[7:0]<=udpbag_counter[31:24];
				i<=i+1'b1;
				end
				else if(i==5) begin 
//				dataout[7:0]<=8'h00;
				dataout[7:0]<=udpbag_counter[23:16];
				i<=i+1'b1;
				end	
				else if(i==6) begin
//				dataout[7:0]<=8'h21;				
				dataout[7:0]<=udpbag_counter[15:8];
				i<=i+1'b1;
				end					
				else if(i==7) begin
//				dataout[7:0]<=8'h31;
				dataout[7:0]<=udpbag_counter[7:0];
				i<=i+1'b1;
				end								
				if(i==8) begin 
//				dataout[7:0]<=8'h03;//验证HMC703写入操作
				dataout[7:0]<=ipbag_counter[31:24];
				i<=i+1'b1;
				end
				else if(i==9) begin
//				dataout[7:0]<=8'h00;				
				dataout[7:0]<=ipbag_counter[23:16];
				i<=i+1'b1;
				end
				else if(i==10) begin
//				dataout[7:0]<=8'h00;				
				dataout[7:0]<=ipbag_counter[15:8];
				i<=i+1'b1;
				end
				else if(i==11) begin
//				dataout[7:0]<=8'h2C;				
				dataout[7:0]<=ipbag_counter[7:0];
				i<=i+1'b1;
				end	
				else if(i==12) begin
//				dataout[7:0]<=8'h30;//验证HMC960写入操作					
				dataout[7:0]<={1'b0,tx_bag_total};
				i<=i+1'b1;
				end
				else if(i==13) begin
//				dataout[7:0]<=8'h00;					
				dataout[7:0]<={1'b0,send_bag_counter};
				i<=i+1'b1;
				end	
				else if(i==14) begin 
//				dataout[7:0]<=8'h00;	
				dataout[7:0]<=tx_data_length[15:8];
				i<=i+1'b1;
				end					
				else if(i==15) begin
//				dataout[7:0]<=8'h2C;	
				dataout[7:0]<=tx_data_length[7:0];
				i<=0;
				tx_state<=senddata;
				end				
			 end			 
			 senddata:begin                                      //发送UDP数据包
			   if(tx_data_counter==tx_data_length-1) begin       //判断是否是发送最后的数据(真正的数据包长度是tx_data_length-8）
				   tx_state<=sendcrc;	                          //发送最后一个字节,状态转到sendcrc
					if(i==0) begin    
					  dataout[7:0]<=datain_reg[15:8];
					  i<=0;
					end
					else if(i==1) begin
					  dataout[7:0]<=datain_reg[7:0];
					  i<=0;
					end
					else if(i==2) begin
					  dataout[7:0]<=datain_reg[31:24];
					  i<=0;
					end
					else if(i==3) begin
			        dataout[7:0]<=datain_reg[23:16];
					  datain_reg<=datain;                       //提前准备数据
//				     datain_reg<=datain_reg+1'b1;
					  i<=0;
					end
            end
            else begin                                     //发送其它的数据包(第一个字节到倒数第二个字节）
               tx_data_counter<=tx_data_counter+1'b1;			
					if(i==0) begin    
					  dataout[7:0]<=datain_reg[15:8];	       //发送高8位(31：24）数据
					  i<=i+1'b1;
					  ram_rd_addr<=ram_rd_addr+1'b1;           //RAM地址加1, 提前让RAM输出数据	
					end
					else if(i==1) begin
					  dataout[7:0]<=datain_reg[7:0];         //发送次高8位(23：16）数据
					  i<=i+1'b1;
					end
					else if(i==2) begin
					  dataout[7:0]<=datain_reg[31:24];          //发送次低8位(15：8）数据
					  i<=i+1'b1;
					end
					else if(i==3) begin
			        dataout[7:0]<=datain_reg[23:16];           //发送低8位(7：0）数据
					  datain_reg<=datain;                      //准备数据		
//			        datain_reg<=datain_reg+1'b1;			  
					  i<=0; 				  
					end
				end
			end	
			sendcrc: begin                              //发送32位的crc校验
				crcen<=1'b0;
				if(i==0)	begin
					  dataout[7:0] <= {~crc[24], ~crc[25], ~crc[26], ~crc[27], ~crc[28], ~crc[29], ~crc[30], ~crc[31]};
					  i<=i+1'b1;
					end
				else begin
				  if(i==1) begin
					   dataout[7:0]<={~crc[16], ~crc[17], ~crc[18], ~crc[19], ~crc[20], ~crc[21], ~crc[22], ~crc[23]};
						i<=i+1'b1;
				  end
				  else if(i==2) begin
					   dataout[7:0]<={~crc[8], ~crc[9], ~crc[10], ~crc[11], ~crc[12], ~crc[13], ~crc[14], ~crc[15]};
						i<=i+1'b1;
				  end
				  else if(i==3) begin
					   dataout[7:0]<={~crc[0], ~crc[1], ~crc[2], ~crc[3], ~crc[4], ~crc[5], ~crc[6], ~crc[7]};
						i<=0;
						tx_state<=sendwait;
				  end
				  else begin
                  txer<=1'b1;
				  end
				end
			end
			sendwait:begin
				if(waitcounter==8'd127) begin tx_state<=sendcircle; waitcounter <=8'd0;end
				else
					begin 
						waitcounter<=waitcounter+1'b1;
						txer<=1'b0;
						txen<=1'b0;
						crcen<=1'b0;
						crcre<=1;
					   dataout<=0;
					end
			end
			
			default:tx_state<=idle;		
       endcase	  
 end
endmodule



