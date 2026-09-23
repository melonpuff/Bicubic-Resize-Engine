

module general(
	//inputs
	input clk,
	input rst,
	input enable,
	input[15:0]sc_addr,
	input[31:0]Img_Q,
	input[7:0] x0,
	input[7:0] y0,
	input[7:0] original_w,
	input[7:0] original_h,
	input[7:0] scaled_w,
    input[7:0] scaled_h,
	input [3:0] CS_top,
	//outputs
	output fin_g,
	output Img_CEN_g,
	output [13:0]Img_A_g,
	output [7:0]Result_D_g
);


parameter [3:0] hold=4'd0, col_0=4'd1, col_1=4'd2, col_2=4'd3, col_3=4'd4, caculate_0=4'd5, caculate_1=4'd6, round=4'd7,round_write=4'd8, write=4'd9;
reg [3:0] CS;

reg r_fin_g;
reg r_Img_CEN_g;
reg [13:0]r_Img_A_g;
reg [7:0]r_Result_D_g;

assign fin_g=r_fin_g;
assign Img_CEN_g=r_Img_CEN_g;
assign Img_A_g=r_Img_A_g;
assign Result_D_g=r_Result_D_g;


//start with x0, y0
reg [7:0] ori_x;
reg [7:0] ori_y;

reg [7:0]sc_x;
reg [7:0]sc_y;

reg [31:0]rgb[3:0];
wire [7:0]graycode[3:0];

reg [2:0]count;

reg signed [11:0]a;
reg signed [11:0]b;
reg signed [11:0]c;
reg signed [11:0]d;
wire [35:0]x;
reg [35:0]pre_x;
reg signed [99:0]x3;
reg signed [67:0]x2;
reg signed [105:0]pre_result;
reg signed [105:0]row_result[3:0];
reg signed [105:0]col_result;
assign x = {4'd0, pre_x[31:0]};

to_gray To_gray_0(
	.rgb(rgb[0]),
	.graycode(graycode[0])
);
to_gray To_gray_1(
	.rgb(rgb[1]),
	.graycode(graycode[1])
);
to_gray To_gray_2(
	.rgb(rgb[2]),
	.graycode(graycode[2])
);
to_gray To_gray_3(
	.rgb(rgb[3]),
	.graycode(graycode[3])
);


always@(posedge clk)begin
	if(rst||!enable||(CS_top!=4'd5))begin
		//assign rst value 
		
		
	CS<=hold;
	end//if
	else if(!rst&&enable&&(CS_top==4'd5))begin
		case(CS)
			hold:begin
				count<=3'd0;
			
		
				CS<=col_0;
			end//hold
			col_0:begin


				CS<=col_1;
			end//col_0
			col_1:begin

				CS<=col_2;
			end//col_1
			col_2:begin

				CS<=col_3;
			end//col_2
			col_3:begin

				CS<=caculate_0;
			end//col_3
			caculate_0:begin
				if(count<3'd4)begin//calculation for rows
					a<=12'd3*$signed({4'b0,graycode[1]})+$signed({4'b0,graycode[3]})-$signed({4'b0,graycode[0]})-12'd3*$signed({4'b0,graycode[2]});
					b<=12'd2*$signed({4'b0,graycode[0]})+12'd4*$signed({4'b0,graycode[2]})-12'd5*$signed({4'b0,graycode[1]})-$signed({4'b0,graycode[3]});
					c<=$signed({4'b0,graycode[2]})-$signed({4'b0,graycode[0]});
					d<=12'd2*$signed({4'b0,graycode[1]});
				end
				else if(count==3'd4)begin//calculation for col
					a<=$signed(12'd3)*$signed({4'b0,row_result[1][104:97]})+$signed({4'b0,row_result[3][104:97]})-$signed({4'b0,row_result[0][104:97]})-$signed(12'd3)*$signed({4'b0,row_result[2][104:97]});
					b<=$signed(12'd2)*$signed({4'b0,row_result[0][104:97]})+$signed(12'd4)*$signed({4'b0,row_result[2][104:97]})-$signed(12'd5)*$signed({4'b0,row_result[1][104:97]})-$signed({4'b0,row_result[3][104:97]});
					c<=$signed({4'b0,row_result[2][104:97]})-$signed({4'b0,row_result[0][104:97]});
					d<=$signed(12'd2)*$signed({4'b0,row_result[1][104:97]});
				end
			
			CS<=caculate_1;
			end//caculate_0
			caculate_1:begin
				pre_result<=a*x3+b*$signed({x2,32'd0})+c*$signed({$signed(x),64'd0})+$signed({d,96'd0});
			
				CS<=round;
			end//caculate_1

			round:begin
				if(pre_result>$signed({9'd255,97'd0}))//>255 case
					pre_result<=$signed({9'd255,97'd0});
				else if(pre_result<$signed(0))//<0 case
					pre_result<=106'd0;
				else begin//rounding
					if(pre_result[96]==1'b0)
						pre_result<=$signed({pre_result[105:97],97'b0});
					else begin
						/*if(|pre_result[95:0]==1'b1)*/
							pre_result<=$signed({$signed(pre_result[105:97])+$signed(9'd1),97'b0});
						/*else if (pre_result[97]==1'b0)
							pre_result<=$signed({pre_result[105:97],97'b0});
						else
							pre_result<=$signed({$signed(pre_result[105:97])+$signed(9'd1),97'b0});*/
					end
				end

			
			CS<=round_write;	
			end//round
			round_write:begin
				if(count<3'd3)begin
					CS<=col_0;
					count<=count+3'd1;
				end
				else if(count==3'd3)begin
					CS<=caculate_0;
					count<=count+3'd1;
				end
				else
					CS<=write;
			end//round_write
			write:begin
				CS<=hold;
			end//write
			default:CS<=hold;

		endcase
	end//else if	
end//always

always@(*)begin
	sc_x=sc_addr%scaled_w;
	sc_y=sc_addr/scaled_w;

	ori_x=x0+(sc_addr%scaled_w)*(original_w-8'd1)/(scaled_w-8'd1);	
	ori_y=y0+(sc_addr/scaled_w)*(original_h-8'd1)/(scaled_h-8'd1);

	if(count==3'd4)//x for col calculate
		//pre_x=(sc_y)*({original_h-8'd1, 16'd0}/(scaled_h-8'd1));
		pre_x = ({original_h-8'd1, 32'd0}/(scaled_h-8'd1))*(sc_addr/scaled_w);
	else//x for row calculate
		//pre_x=(sc_x)*({original_w-8'd1, 16'd0}/(scaled_w-8'd1));
		pre_x = ({original_w-8'd1, 32'd0}/(scaled_w-8'd1))*(sc_addr%scaled_w);
		
	x3=$signed(x)*$signed(x)*$signed(x);
	x2=$signed(x)*$signed(x);
	

	if(rst||!enable||(CS_top!=4'd5))begin
	//assign rst value 
		
		

	end//if
	else if(!rst&&enable&&(CS_top==4'd5))begin
		case(CS)
			hold:begin
				r_Img_CEN_g=1'b1;
				r_fin_g=1'b0;
			end//hold
			col_0:begin//ori_x-1
				r_Img_CEN_g=1'b0;
				r_fin_g=1'b0;
				if(count==3'd0)begin
					//bound case upper left
					if((ori_x==8'd0)&&(ori_y==8'd0))
						r_Img_A_g=14'd0;
					//bound case left
					else if (ori_x==8'd0)  
						r_Img_A_g=(ori_y-8'd1)*8'd128+(ori_x-8'd1)+8'd1;
					//bound case upper
					else if(ori_y==8'd0)
						r_Img_A_g=ori_y*8'd128+(ori_x-8'd1);
					else 
						r_Img_A_g=(ori_y-8'd1)*8'd128+(ori_x-8'd1);
										
				end//if(count==0)
				else if(count==3'd1)begin
					//bound case left
					if(ori_x==8'd0)
						r_Img_A_g=(ori_y)*8'd128+(ori_x-8'd1)+8'd1;
					else
						r_Img_A_g=(ori_y)*8'd128+(ori_x-8'd1);

				end//if(count==1)
				else if(count==3'd2)begin
					//bound case left
					if(ori_x==8'd0)
						r_Img_A_g=(ori_y+8'd1)*8'd128+(ori_x-8'd1)+8'd1;
					else
						r_Img_A_g=(ori_y+8'd1)*8'd128+(ori_x-8'd1);

				end//if(count==2)
				else begin
					//bound case down left
					if((ori_x==8'd0)&&(ori_y+8'd1==8'd127))
						r_Img_A_g=8'd128*8'd127;
					//bound case left
					else if(ori_x==8'd0)
						r_Img_A_g=(ori_y+8'd2)*8'd128+(ori_x-8'd1)+8'd1;
					//bound case down
					else if(ori_y+8'd1==8'd127)
						r_Img_A_g=(ori_y+8'd1)*8'd128+ori_x-8'd1;
					else 
						r_Img_A_g=(ori_y+8'd2)*8'd128+(ori_x-8'd1);
				end//(count==3)

			end//col_0
			col_1:begin//ori_x
				r_Img_CEN_g=1'b0;
				r_fin_g=1'b0;
				if(count==3'd0)begin
					//bound case upper
					if(ori_y==8'd0)
						r_Img_A_g=ori_y*8'd128+ori_x;
					else
						r_Img_A_g=(ori_y-8'd1)*8'd128+ori_x;
							
				end//if(count==0)
				else if(count==3'd1)begin
					r_Img_A_g=(ori_y)*8'd128+ori_x;
				end//if(count==1)
				else if(count==3'd2)begin
					r_Img_A_g=(ori_y+8'd1)*8'd128+ori_x;
				end//if(count==2)
				else begin
					//bound down case
					if(ori_y+8'd1==8'd127)
						r_Img_A_g=(ori_y+8'd1)*8'd128+ori_x;
					else 
						r_Img_A_g=(ori_y+8'd2)*8'd128+ori_x;
				end//(count==3)
				rgb[0]=Img_Q;
			end//col_1
			col_2:begin//ori_x+1
				r_Img_CEN_g=1'b0;
				r_fin_g=1'b0;
				if(count==3'd0)begin
					//bound upper case
					if(ori_y==8'd0)
						r_Img_A_g=(ori_y)*8'd128+ori_x+8'd1;
					else
						r_Img_A_g=(ori_y-8'd1)*8'd128+ori_x+8'd1;
					
				end//if(count==0)
				else if(count==3'd1)begin
					r_Img_A_g=(ori_y)*8'd128+ori_x+8'd1;
					
				end//if(count==1)
				else if(count==3'd2)begin
					r_Img_A_g=(ori_y+8'd1)*8'd128+ori_x+8'd1;

				end//if(count==2)
				else begin
					//bound down case
					if(ori_y+8'd1==8'd127)
						r_Img_A_g=(ori_y+8'd1)*8'd128+ori_x+8'd1;
					else
						r_Img_A_g=(ori_y+8'd2)*8'd128+ori_x+8'd1;
				end//(count==3)
				rgb[1]=Img_Q;
			end//col_2
			col_3:begin////ori_x+2
				r_Img_CEN_g=1'b0;
				r_fin_g=1'b0;
				if(count==3'd0)begin
					//bound upper right case
					if((ori_x+8'd1==8'd127)&&(ori_y==8'd0))
						r_Img_A_g=8'd127;
					//bound right case
					else if(ori_x+8'd1==8'd127)
						r_Img_A_g=(ori_y-8'd1)*8'd128+ori_x+8'd1;
					//bound upper case
					else if(ori_y==8'd0)
						r_Img_A_g=(ori_y)*8'd128+ori_x+8'd2;
					else
						r_Img_A_g=(ori_y-8'd1)*8'd128+ori_x+8'd2;
				
				end//if(count==0)
				else if(count==3'd1)begin
					//bound right case
					if(ori_x+8'd1==8'd127)
						r_Img_A_g=(ori_y)*8'd128+ori_x+8'd1;
					else
						r_Img_A_g=(ori_y)*8'd128+ori_x+8'd2;
		
				end//if(count==1)
				else if(count==3'd2)begin
					//bound right case
					if(ori_x+8'd1==8'd127)
						r_Img_A_g=(ori_y+8'd1)*8'd128+ori_x+8'd1;
					else
						r_Img_A_g=(ori_y+8'd1)*8'd128+ori_x+8'd2;

				end//if(count==2)
				else begin
					//bound down right case
					if((ori_x+8'd1==8'd127)&&(ori_y+8'd1==8'd127))
						r_Img_A_g=8'd128*8'd128-8'd1;
					//bound right case
					else if (ori_x+8'd1==8'd127)
						r_Img_A_g=(ori_y+8'd2)*8'd128+ori_x+8'd1;
					//bound down case
					else if (ori_y+8'd1==8'd127)
						r_Img_A_g=(ori_y+8'd1)*8'd128+ori_x+8'd2;
					else
						r_Img_A_g=(ori_y+8'd2)*8'd128+ori_x+8'd2;
				end//(count==3)
				rgb[2]=Img_Q;
			end//col_3
			caculate_0:begin
				r_Img_CEN_g=1'b0;
				r_fin_g=1'b0;
				rgb[3]=Img_Q;
			end//caculate_0
			caculate_1:begin
				r_Img_CEN_g=1'b1;
				r_fin_g=1'b0;
			end//caculate_1
			round:begin
				r_Img_CEN_g=1'b1;
				r_fin_g=1'b0;
			end//round
			round_write:begin
				r_Img_CEN_g=1'b1;
				r_fin_g=1'b0;
				if(count==3'd0)
					row_result[0]=pre_result;
				else if (count==3'd1)
					row_result[1]=pre_result;
				else if (count==3'd2)
					row_result[2]=pre_result;
				else if (count==3'd3)
					row_result[3]=pre_result;
				else if (count==3'd4)
					col_result=pre_result;

			end//round_write
			write:begin
				r_Img_CEN_g=1'b1;
				r_Result_D_g=col_result[104:97];
				if(CS_top==4'd5)
					r_fin_g=1'b1;
				else 
					r_fin_g=1'b0;
					
			end//write
			default:
				;

		endcase
	end//else if
end


endmodule









































