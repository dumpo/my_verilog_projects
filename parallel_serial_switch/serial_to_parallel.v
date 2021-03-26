module serial_to_parallel #(parameter WEIDTH=8)
(
	input rst_n,
	input clk,
	input data_in,
	output reg [WEIDTH-1:0] data_out,
	output done
);


reg [2:0] cnt;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		data_out<=8'b0;
		end
	else begin
		data_out<={data_out[WEIDTH-2:0],data_in};
	end
end


endmodule