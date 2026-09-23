
module case_2(
	output wire [7:0]Result_D_2,
	output wire [13:0]Img_A_2,
	output wire fin_2,
	output wire Img_CEN_2,
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
parameter [3:0]waiting=4'd0, col0=4'd1, col1=4'd2, col2=4'd3, col3=4'd4, calculate=4'd5, round=4'd6, write=4'd7, find_start=4'd8, finish=4'd9; 
reg [3:0]CS;
wire [7:0]graycode[3:0];
reg [31:0]rgb[3:0];
reg pre_fin, pre_CEN;
reg [13:0]pre_A;
reg [35:0]x;//p(x)
reg signed[105:0]pre_D;
wire [35:0]pre_x;//pre_p(x)
wire [7:0]real_x, real_y;//coordinates of the required data in ROM 
wire signed[11:0]a, b, c, d;
wire signed[67:0] x_sq;
wire signed[99:0] x_cu;

to_gray gray0(.graycode(graycode[0]), .rgb(rgb[0]));
to_gray gray1(.graycode(graycode[1]), .rgb(rgb[1]));
to_gray gray2(.graycode(graycode[2]), .rgb(rgb[2]));
to_gray gray3(.graycode(graycode[3]), .rgb(rgb[3]));

assign Result_D_2 = pre_D[104:97];
assign Img_A_2 = pre_A;
assign fin_2 = pre_fin;
assign Img_CEN_2 = pre_CEN;
assign real_x = (current_addr%scaled_w)*(original_w-8'd1)/(scaled_w-8'd1)+x0;
assign real_y = (current_addr/scaled_w)*(original_h-8'd1)/(scaled_h-8'd1)+y0;
assign a = $signed({4'b0, graycode[1]})*$signed(3'd3)+$signed({4'b0, graycode[3]})-$signed({4'b0, graycode[0]})-$signed({4'b0, graycode[2]})*$signed(3'd3);
assign b = ($signed({4'b0, graycode[0]})<<1)+($signed({4'b0, graycode[2]})<<2)-$signed({4'b0, graycode[1]})*$signed(4'd5)-$signed({4'b0, graycode[3]});
assign c = $signed({4'b0, graycode[2]})-$signed({4'b0, graycode[0]});
assign d = $signed({4'b0, graycode[1]})<<1;
assign x_sq = $signed(x)*$signed(x);
assign x_cu = $signed(x)*$signed(x)*$signed(x);
assign pre_x = ({original_w-8'd1, 32'd0}/(scaled_w-8'd1))*(current_addr%scaled_w);

always @(posedge clk)begin
	if(rst)begin
		CS <= find_start;
	end
	else if(enable)begin
		case(CS)
			find_start:begin
				pre_A <= real_y * 8'd128 + {6'd0, real_x};
				x <= {4'd0, pre_x[31:0]};
				if(CS_top==4'd3) CS <= finish;
				else CS <= CS;
			end
			finish:begin
				CS <= waiting;
			end
			waiting:begin//find 0, detect whether next(-1) is bound
				if(real_x==8'd0) pre_A <= pre_A;
				else pre_A <= pre_A - 14'd1;
				CS <= col0;
			end
			col0:begin//find -1
				if(real_x==8'd0) pre_A <= pre_A + 14'd1;
				else pre_A <= pre_A + 14'd2;
				CS <= col1;
			end
			col1:begin//find 1, detect whether next(2) is bound
				if(real_x==8'd126) pre_A <= pre_A;
				else pre_A <= pre_A + 14'd1;
				CS <= col2;
			end
			col2:begin//find 2
				CS <= col3;
			end
			col3:begin
				CS <= calculate;
			end
			calculate:begin
				pre_D <= a*x_cu+b*$signed({x_sq, 32'd0})+c*$signed({$signed(x), 64'd0})+$signed({d, 96'd0});
				CS <= round;
			end
			round:begin
				if(pre_D>$signed({9'd255, 97'd0})) pre_D <= $signed({9'd255, 97'b0});
				else if(pre_D<$signed(0)) pre_D <= 106'd0;
				else begin
					if(pre_D[96]==1'b0) pre_D <= $signed({pre_D[105:97], 97'b0});
					else begin
						/*if(|pre_D[95:0]==1'b1)*/ pre_D <= $signed({$signed(pre_D[105:97])+$signed(9'd1), 97'b0});
						/*else if(pre_D[97]==1'b0) pre_D <= $signed({pre_D[105:97], 97'b0});
						else pre_D <= $signed({$signed(pre_D[105:97])+$signed(9'd1), 97'b0});*/
					end
				end
				CS <= write;
			end
			write:begin
				CS <= find_start;
			end
			default:begin
				CS <= waiting;
			end
		endcase
	end
	else ;
end

always @(*)begin
	if(CS==find_start) pre_fin = 1'b0;
	else if(CS==finish) pre_CEN = 1'b0;
	else if(CS==col0) rgb[1] = Img_Q;
	else if(CS==col1) rgb[0] = Img_Q;
	else if(CS==col2) rgb[2] = Img_Q;
	else if(CS==col3) rgb[3] = Img_Q;
	else if(CS==write)begin
		pre_CEN = 1'b1;
		if(CS_top==4'd3) pre_fin = 1'b1;
		else pre_fin = 1'b0;
	end
	else ;
end

endmodule
