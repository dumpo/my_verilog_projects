//������Ƶ
module clock_div1
(
input rst,
input clk,
output reg clk_div
);

	reg clk_n=0;
	reg clk_p=0;
    parameter N=7;
    localparam WIDHT = $clog2(N)+1;
    reg [WIDHT:0] cnt1,cnt2;
    
    always@(posedge clk) begin
        if(rst) begin
            cnt1<=0;
			cnt2<=0;
            clk_p<=0;
			clk_div<=0;
			clk_n<=0;
        end
		else begin
			if(cnt1==N-1)     begin 
			cnt1<=0;
			clk_p<=~clk_p;
			end
			else if(cnt1==(N-1)>>1) begin
				clk_p<=~clk_p;
				cnt1<=cnt1+1;
			end

			else begin
				cnt1<=cnt1+1;
				clk_p<=clk_p;
			end
		end
	end
    
    always@(negedge clk) begin
        if(rst) begin
            cnt1<=0;
			cnt2<=0;
            clk_p<=0;
			clk_div<=0;
			clk_n<=0;
        end
		else begin
			if(cnt2==N-1) begin
			cnt2<=0;
			clk_n<=~clk_n;
			end
			else if(cnt2==(N-1)>>1) begin
            clk_n<=~clk_n;
			cnt2<=cnt2+1;
			end
			
			else begin
            cnt2<=cnt2+1;
            clk_n<=clk_n;
			end
		end
	end
    always@(*) clk_div=clk_n|clk_p;
endmodule



/********************************************
		������ʵ�� 7 ��Ƶ
*********************************************/
module Odd_Divider(
	input clk,
	input rst_n,
	output clk_divider
);
reg [2:0] count_p;	//�����ؼ���
reg [2:0] count_n;	//�½��ؼ���
reg clk_p;				//�����ط�Ƶ
reg clk_n;				//�½��ط�Ƶ
//�����ؼ���
always @ ( posedge clk or negedge rst_n )
begin 
	if( !rst_n ) 
		count_p <= 3'b0;
	else if( count_p == 3'd6 ) 
		count_p <= 3'b0;
	else  
		count_p <= count_p + 1'b1;
end
//�����ط�Ƶ
always  @ ( posedge clk or negedge rst_n )
begin 
	if( !rst_n ) begin 
		clk_p <= 1'b0;
	end 
	else begin 
		if( count_p == 3'd3 || count_p == 3'd6 ) begin 
			clk_p <= ~clk_p;
		end
	end
end 
//�½��ؼ���
always @ ( negedge clk or negedge rst_n )
begin 
	if( !rst_n ) 
		count_n <= 3'b0;
	else if( count_n == 3'd6 ) 
		count_n <= 3'b0;
	else  
		count_n <= count_n + 1'b1;
end
//�½��ط�Ƶ
always  @ ( negedge clk or negedge rst_n )
begin 
	if( !rst_n ) begin 
		clk_n <= 1'b0;
	end 
	else begin 
		if( count_n == 3'd3 || count_n == 3'd6 ) begin 
			clk_n <= ~clk_n;
		end
	end
end 
assign clk_divider = clk_p | clk_n;
endmodule



//ż����Ƶ
module clock_div2
(
input rst,
input clk,
output reg clk_div
);
    parameter N=4;
    localparam WIDHT = $clog2(N);
    reg [WIDHT:0] cnt;
    always@(posedge clk) begin
        if(rst) begin
            cnt<=0;
            clk_div<=0;
        end
        
        else if(cnt==N/2-1) begin
            cnt<=0;
            clk_div<=~clk_div;
        end
            
        else begin
            cnt<=cnt+1;
        	clk_div<=clk_div;
    	end
    end
endmodule