`timescale 1ns/1ns
`define clk_period 20

module uart_byte_tx_tb;

	reg Clk;
	reg Rst_n;
	reg [7:0]data_byte;
	reg send_en;
	reg [2:0]baud_set;
	
	wire Rs232_Tx;
	wire Tx_Done;
	wire uart_state;
	
	uart_byte_tx uart_byte_tx1(
		.clk(Clk),
		.rst_n(Rst_n),
		.data(data_byte),
		.send_en(send_en),
		.baud_set(baud_set),
		
		.t_data(Rs232_Tx),
		.tx_done(Tx_Done),
		.uart_state(uart_state)
	);
	
	initial Clk = 1;
	always#(`clk_period/2)Clk = ~Clk;
	
	initial begin
	   $dumpfile("Counter.vcd");
       $dumpvars(0, uart_byte_tx_tb);
	
		Rst_n = 1'b0;
		data_byte = 8'd0;
		send_en = 1'd0;
		baud_set = 3'd4;
		#(`clk_period*20 + 1 )
		Rst_n = 1'b1;
		#(`clk_period*50);
		data_byte = 8'haa;
		send_en = 1'd1;
		#`clk_period;
		send_en = 1'd0;
		
		@(posedge Tx_Done)
		
		#(`clk_period*5000);
		data_byte = 8'h55;
		send_en = 1'd1;
		#`clk_period;
		send_en = 1'd0;
		@(posedge Tx_Done)
		#(`clk_period*5000);
		$finish;	
	end

endmodule



