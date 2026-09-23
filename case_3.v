

module case_3(
	output wire [7:0]Result_D_3,
	output wire [13:0]Img_A_3,
	output wire fin_3,
	output wire Img_CEN_3,
	input [15:0]current_addr,
	input [31:0]Img_Q,
	input clk,
	input rst,
	input enable,
    input [7:0] x0,
    input [7:0] y0,
    input [7:0] original_w,
    input [7:0] original_h,
    input [7:0] scaled_w,
    input [7:0] scaled_h,
	input [3:0] CS_top
);
parameter [3:0]waiting_1=4'd0, waiting_2=4'd1, calculate=4'd2, write=4'd7, find_start=4'd8, finish=4'd9; 
reg [3:0]CS;
wire [7:0]graycode;
reg [31:0]rgb;
reg pre_fin, pre_CEN;
reg [13:0]pre_A;
reg [7:0]pre_D;
wire [7:0]real_x, real_y;//coordinates of the required data in ROM 

to_gray gray(.graycode(graycode), .rgb(rgb));

assign Result_D_3 = pre_D;
assign Img_A_3 = pre_A;
assign fin_3 = pre_fin;
assign Img_CEN_3 = pre_CEN;
assign real_x = (current_addr%scaled_w)*(original_w-8'd1)/(scaled_w-8'd1)+x0;
assign real_y = (current_addr/scaled_w)*(original_h-8'd1)/(scaled_h-8'd1)+y0;


always @(posedge clk)begin
	if(rst)begin
		CS <= find_start;
	end
	else if(enable)begin
		case(CS)
			find_start:begin
				pre_A <= real_y * 8'd128 + {6'd0, real_x};
				if(CS_top==4'd4) CS <= finish;
				else CS <= CS;
			end
			finish:begin
				CS <= waiting_1;
			end
			waiting_1:begin
				CS <= waiting_2;
			end
			waiting_2:begin
				CS <= calculate;
			end
			calculate:begin
				pre_D <= graycode;
				CS <= write;
			end
			write:begin
				CS <= find_start;
			end
			default:begin
				CS <= waiting_1;
			end
		endcase
	end
	else ;
end

always @(*)begin
	if(CS==find_start) pre_fin = 1'b0;
	else if(CS==finish) pre_CEN = 1'b0;
	else if(CS==waiting_2) rgb = Img_Q;
	else if(CS==write)begin
		pre_CEN = 1'b1;
		if(CS_top==4'd4) pre_fin = 1'b1;
		else pre_fin = 1'b0;
	end
	else ;
end

endmodule
