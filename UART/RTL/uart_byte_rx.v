module uart_byte_rx
(
input clk,
input rst_n,
input [2:0] baud_set,
input rs232_rx,
output reg [7:0] data_byte,
output reg rx_done
);

/***************数据寄存，加两级D触发器消除亚稳态***************/
reg rs232_q1,rs232_q2,rs232_q3,rs232_q4;
always@(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		rs232_q1<=0;
		rs232_q2<=0;
		rs232_q3<=0;
		rs232_q4<=0;
		
	end
	else begin
		rs232_q1<=rs232_rx;
		rs232_q2<=rs232_q1;
		rs232_q3<=rs232_q2;
		rs232_q4<=rs232_q3;
	end
end
assign rs232_negedge=rs232_q3& ~rs232_q2; //数据的下降沿



/*************************采样时钟生成*******************/
	reg [15:0] bps_DR; //时钟分频计数器最大值
	localparam system_clk=50_000_000;
	localparam sample_multiple=16; //采样倍数	
    localparam [15:0] bps_9600=system_clk/9600/sample_multiple-1;
    localparam [15:0] bps_19200=system_clk/19200/sample_multiple-1;
    localparam [15:0] bps_38400=system_clk/38400/sample_multiple-1;
    localparam [15:0] bps_57600=system_clk/57600/sample_multiple-1;
    localparam [15:0] bps_115200=system_clk/115200/sample_multiple-1;
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) bps_DR<=bps_9600;
        else begin
            case(baud_set)
                0:bps_DR<=bps_9600;
                1:bps_DR<=bps_19200;
                2:bps_DR<=bps_38400;
                3:bps_DR<=bps_57600;
                4:bps_DR<=bps_115200;
                default:bps_DR<=bps_9600;
            endcase
        end
    end
	
	reg [15:0] sample_clk_cnt;
	reg sample_clk;
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			sample_clk_cnt<=0;
			sample_clk<=0;
		end
		// else if(!bps_EN) begin
			// sample_clk_cnt<=0;
			// sample_clk<=0;
		// end
		else begin
			if(sample_clk_cnt==bps_DR) begin
				sample_clk_cnt<=0;
				sample_clk<=1;
			end
			else begin
				sample_clk_cnt<=sample_clk_cnt+1;
				sample_clk<=0;
			end
		end	
	end


/*************************采样、判别*******************/	
//接收1字节时采样次数
localparam [7:0] bps_cnt_MAX=sample_multiple*10-1;    
/*1bit的采样次数，只取中间1/3，前后1/3下面*/
localparam [7:0] bps_sample_end=sample_multiple/3*2+1;
localparam [7:0] bps_sample_begin=sample_multiple/3;
//采样误差阈值，允许25%的采样点错误
localparam [7:0] bps_sample_th=	(bps_sample_end-bps_sample_end-1)/4*3;
localparam data_width=$clog2(sample_multiple);
	reg [data_width-1:0] r_data_byte[7:0];
	reg [data_width-1:0]START_BIT;
	reg [data_width-1:0]STOP_BIT;
	reg [7:0] bps_cnt;

	always@(posedge clk or negedge rst_n) begin
		if(~rst_n)
			bps_cnt<=0;
		/*波特率计数器清零条件：接收一byte完成，或起始位有误，重新计数*/
		else if(bps_cnt==bps_cnt_MAX||(bps_cnt==bps_sample_end&&(START_BIT>bps_sample_th)))
			bps_cnt<=0;
		else if(sample_clk)
			bps_cnt<=bps_cnt+1;
		else 
			bps_cnt<=bps_cnt;
	end
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n)
			rx_done<=0;
		else if(bps_cnt==bps_cnt_MAX)
			rx_done<=1;
		else 
			rx_done<=0;
	end



	
	//FSM for byte rx
	localparam bit_start=0,bit0=1,bit1=2,bit2=3,bit3=4,bit4=5,bit5=6,bit6=7,bit7=8,bit_stop=9;
	reg[3:0] cur_bit,next_bit;
	
	always@(clk or negedge rst_n) begin
		if(!rst_n) 
			next_bit<=bit_start;
		else if(bps_cnt) begin
			if(cur_bit==bit_stop)
				next_bit<=bit_start;
			else 
				next_bit<=cur_bit+1;
		end
	end
	
	always@(clk or negedge rst_n) begin
		if(!rst_n) begin
			cur_bit<=bit_start;
			START_BIT <= 0;
			r_data_byte[0] <= 0; r_data_byte[1] <= 0;
			r_data_byte[2] <= 0; r_data_byte[3] <= 0;
			r_data_byte[4] <= 0; r_data_byte[5] <= 0;
			r_data_byte[6] <= 0; r_data_byte[7] <= 0;			
			STOP_BIT = 0;
		end
		else if(bps_cnt) begin
			case(cur_bit)
				bit_start:begin
					if(bps_cnt==0) begin
						START_BIT <= 0;
						r_data_byte[0] <= 0; r_data_byte[1] <= 0;
						r_data_byte[2] <= 0; r_data_byte[3] <= 0;
						r_data_byte[4] <= 0; r_data_byte[5] <= 0;
						r_data_byte[6] <= 0; r_data_byte[7] <= 0;
						STOP_BIT = 0;
					end
					else if(bps_cnt>bps_sample_begin&&bps_cnt<bps_sample_begin)
						START_BIT <= START_BIT + rs232_q4;
				end
				bit0:begin
					if(bps_cnt>bps_sample_begin+sample_multiple*2&&bps_cnt<bps_sample_begin+sample_multiple*2)
						r_data_byte[0] <= r_data_byte[0] + rs232_q4;
				end
				bit1:begin
					if(bps_cnt>bps_sample_begin+sample_multiple*3&&bps_cnt<bps_sample_begin+sample_multiple*3)
						r_data_byte[1] <= r_data_byte[1] + rs232_q4;
				end
				bit2:begin
					if(bps_cnt>bps_sample_begin+sample_multiple*4&&bps_cnt<bps_sample_begin+sample_multiple*4)
						r_data_byte[2] <= r_data_byte[2] + rs232_q4;
				end
				bit3:begin
					if(bps_cnt>bps_sample_begin+sample_multiple*5&&bps_cnt<bps_sample_begin+sample_multiple*5)
						r_data_byte[3] <= r_data_byte[3] + rs232_q4;
				end
				bit4:begin
					if(bps_cnt>bps_sample_begin+sample_multiple*6&&bps_cnt<bps_sample_begin+sample_multiple*6)
						r_data_byte[4] <= r_data_byte[4] + rs232_q4;
				end
				bit5:begin
					if(bps_cnt>bps_sample_begin+sample_multiple*7&&bps_cnt<bps_sample_begin+sample_multiple*7)
						r_data_byte[5] <= r_data_byte[5] + rs232_q4;
				end
				bit6:begin
					if(bps_cnt>bps_sample_begin+sample_multiple*8&&bps_cnt<bps_sample_begin+sample_multiple*8)
						r_data_byte[6] <= r_data_byte[6] + rs232_q4;
				end	
				bit7:begin
					if(bps_cnt>bps_sample_begin+sample_multiple*9&&bps_cnt<bps_sample_begin+sample_multiple*9)
						r_data_byte[7] <= r_data_byte[7] + rs232_q4;
				end
				bit_stop:begin
					if(bps_cnt>bps_sample_begin+sample_multiple*10&&bps_cnt<bps_sample_begin+sample_multiple*10)
						STOP_BIT <= STOP_BIT + rs232_q4;
				end
				default:begin
					START_BIT<=START_BIT;
					STOP_BIT<=STOP_BIT;
					r_data_byte[0] <= r_data_byte[0]; r_data_byte[1] <= r_data_byte[1];
					r_data_byte[2] <= r_data_byte[2]; r_data_byte[3] <= r_data_byte[3];
					r_data_byte[4] <= r_data_byte[4]; r_data_byte[5] <= r_data_byte[5];
					r_data_byte[6] <= r_data_byte[6]; r_data_byte[7] <= r_data_byte[7];
					
				end
			endcase
		end
	end

		

	/*数据状态判定，有效采样数高于阈值判定为有效*/
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
		data_byte <= 8'd0;
		else if(bps_cnt == bps_cnt_MAX)begin
			data_byte[0] <= r_data_byte[0]>bps_sample_th;
			data_byte[1] <= r_data_byte[1]>bps_sample_th;
			data_byte[2] <= r_data_byte[2]>bps_sample_th;
			data_byte[3] <= r_data_byte[3]>bps_sample_th;
			data_byte[4] <= r_data_byte[4]>bps_sample_th;
			data_byte[5] <= r_data_byte[5]>bps_sample_th;
			data_byte[6] <= r_data_byte[6]>bps_sample_th;
			data_byte[7] <= r_data_byte[7]>bps_sample_th;
		end
	end
endmodule