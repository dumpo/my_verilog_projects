/**********************************************
UART TX moudle
by linhuifu 2020.20.11
**********************************************/
//`default_nettype none
module uart_byte_tx
	(
	input clk,
	input rst_n,
	input [7:0]data,
	input [2:0]baud_set,
	input send_en,
	output  t_data,
	output  tx_done,
	output  uart_state
	);
	
	wire bps_clk;	//波特率时钟
	wire [15:0]bps_DR;//分频计数最大值
	wire [3:0] bps_cnt_q;
	wire [7:0] r_data;
	
	
	DR_LUT d1
	(
	.clk(clk),
	.rst_n(rst_n),
	.baud_set(baud_set),
	.bps_DR(bps_DR)
	);
	
	div_cnt d2
	(
	.clk(clk),
	.rst_n(rst_n),
	.en_cnt(uart_state),
	.bps_DR(bps_DR),
	.bps_clk(bps_clk)
	);
	
	bps_cnt d3
	(
	.clk(clk),
	.rst_n(rst_n),
	 .send_en(send_en),
	.bps_clk(bps_clk),
	.bps_cnt_q(bps_cnt_q),
	.tx_done(tx_done),
	.uart_state(uart_state)
	);
	
	data_reg d4
	(
    data,
    send_en,
    clk,
    rst_n,
    r_data
	);
	
	rs232_tx d5
	(
    clk,
    rst_n,
    r_data,
    bps_cnt_q,
    t_data
	);
	
	
	
endmodule


//波特率时钟分频系数计算
module DR_LUT
    (
    input clk,
    input rst_n,
    input [2:0]baud_set,
    output reg[15:0] bps_DR
    );

    localparam system_clk_period=20;
    localparam [15:0] bps_DR_9600=104167/system_clk_period-1;
    localparam [15:0] bps_DR_19200=52083/system_clk_period-1;
    localparam [15:0] bps_DR_38400=26041/system_clk_period-1;
    localparam [15:0] bps_DR_57600=17361/system_clk_period-1;
    localparam [15:0] bps_DR_115200=8680/system_clk_period-1;


    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) bps_DR<=bps_DR_9600;
        else begin
            case(baud_set)
                0:bps_DR<=bps_DR_9600;
                1:bps_DR<=bps_DR_19200;
                2:bps_DR<=bps_DR_38400;
                3:bps_DR<=bps_DR_57600;
                4:bps_DR<=bps_DR_115200;
                default:bps_DR<=bps_DR_9600;
            endcase
        end
    end
endmodule

//计数器生成波特率时钟（脉冲）
module div_cnt
    (
    input [15:0]bps_DR,
    input en_cnt,    //仅在发送时计数
    input clk,
    input rst_n,
    output reg bps_clk
    );
   reg [15:0]  d_cnt;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
           d_cnt<=0;
            bps_clk<=0;
        end
        else if(en_cnt) begin
            if(d_cnt==bps_DR) begin 
                d_cnt<=0;
                bps_clk<=1;
			end
            else begin
                d_cnt<=d_cnt+1;
                bps_clk<=0;
			end
        end
        else begin 
            d_cnt<=0;
	    bps_clk<=0;
		end
    end
endmodule

module bps_cnt
    (
    input clk,
    input bps_clk,
    input rst_n,
    input send_en,
    output reg [3:0] bps_cnt_q,
    output  reg tx_done,
    output  reg uart_state
    );
    
	//assign uart_state = rst_n&send_en;
	//assign tx_done = (bps_cnt_q==11);
	
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
           bps_cnt_q<=0;
        end
        else if(bps_cnt_q==11) begin
            bps_cnt_q<=0;

        end
        else if(bps_clk)
            bps_cnt_q<=bps_cnt_q+1;
        else
			bps_cnt_q<=bps_cnt_q;
    end
	 
	 
	 always @(posedge clk or negedge rst_n) begin
		if(!rst_n) 
			uart_state<=0;
		else if(send_en)
			uart_state<=1;
		else 
			uart_state<=uart_state;
	 end
	 
	 always @(posedge clk or negedge rst_n) begin
		if(!rst_n) 
			tx_done<=0;
		else if(bps_cnt_q==11)
			tx_done<=1;
		else 
			tx_done<=0;
	 end
			
endmodule

//根据bps_cnt计数选择发送数据的位
//rs232时序无数据为高电平，开始为为低电平，停止位为高电平
module rs232_tx
(
    input clk,
    input rst_n,
    input [7:0] r_data,
    input [3:0] bps_cnt_q,
    output reg t_data
);
    localparam START_BIT=1'b0;
    localparam STOP_BIT=1'b0;
   always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        t_data<=1'b1;
    else begin
        case(bps_cnt_q)
        0:t_data<=1;
        1:t_data<=START_BIT;
        2:t_data<=r_data[0];
        3:t_data<=r_data[1];
        4:t_data<=r_data[2];
        5:t_data<=r_data[3];
        6:t_data<=r_data[4];
        7:t_data<=r_data[5];
        8:t_data<=r_data[6];
        9:t_data<=r_data[7];
        10:t_data<=STOP_BIT;
        default:t_data<=1;
	endcase
    end
   end
endmodule
//发送时对数据寄存
module data_reg
(
    input [7:0] data,
    input send_en,
    input clk,
    input rst_n,
    output reg[7:0]  r_data
);
   always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        r_data<=0;
    else if(send_en)
        r_data<=data;
    else
        r_data<=r_data;
    end
endmodule