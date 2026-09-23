`include "case_1.v"
`include "case_2.v"
`include "case_3.v"
`include "to_gray.v"
`include "general.v"


module bicubic (
    output wire Img_CEN,
    output wire [13:0] Img_A,//sent request address to ROM
    output wire Result_CEN,
    output wire Result_WEN,
    output wire [7:0]Result_D,//output result data
    output wire [15:0] Result_A,//output result addr
	output  done,
    input clk,
    input rst,
    input enable,
    input [7:0] x0,
    input [7:0] y0,
    input [7:0] original_w,
    input [7:0] original_h,
    input [7:0] scaled_w,
    input [7:0] scaled_h,
	input [31:0] Img_Q,//requested data sent back from ROM
	input [7:0]Result_Q 
);



parameter [3:0] hold=4'd0, set_case=4'd1, case_1=4'd2, case_2=4'd3, case_3=4'd4, general=4'd5, write=4'd6;
reg[3:0] CS;

reg r_Img_CEN;	
reg [13:0]r_Img_A;
reg [7:0]r_Result_D;
reg r_Result_CEN;
reg r_Result_WEN;
reg[15:0] r_Result_A;

assign Img_CEN=r_Img_CEN;
assign Img_A=r_Img_A;
assign Result_D=r_Result_D;
assign Result_CEN=r_Result_CEN;
assign Result_WEN=r_Result_WEN;
assign Result_A=r_Result_A;

reg [15:0]sc_addr;
reg[7:0]sc_x;
reg[7:0]sc_y;

wire fin_1;
wire fin_2;
wire fin_3;
wire fin_g;

wire Img_CEN_1;
wire Img_CEN_2;
wire Img_CEN_3;
wire Img_CEN_g;
wire [13:0]Img_A_1;
wire [13:0]Img_A_2;
wire [13:0]Img_A_3;
wire [13:0]Img_A_g;
wire [7:0]Result_D_1;
wire [7:0]Result_D_2;
wire [7:0]Result_D_3;
wire [7:0]Result_D_g;

reg pre_done;
assign done=pre_done;




case_1 Case_1(
	//inputs
	.clk(clk),
	.rst(rst),
	.enable(enable),
	.current_addr(sc_addr),
	.Img_Q(Img_Q),
	.x0(x0),
	.y0(y0),
	.original_w(original_w),
	.original_h(original_h),
	.scaled_w(scaled_w),
	.scaled_h(scaled_h),
	.CS_top(CS),
	//outputs
	.fin_1(fin_1),
	.Img_CEN_1(Img_CEN_1),
	.Img_A_1(Img_A_1),
	.Result_D_1(Result_D_1)
	
);
case_2 Case_2(
	//inputs
	.clk(clk),
	.rst(rst),
	.enable(enable),
	.current_addr(sc_addr),
	.Img_Q(Img_Q),
	.x0(x0),
	.y0(y0),
	.original_w(original_w),
	.original_h(original_h),
	.scaled_w(scaled_w),
	.scaled_h(scaled_h),
	.CS_top(CS),
	//outputs
	.fin_2(fin_2),
	.Img_CEN_2(Img_CEN_2),
	.Img_A_2(Img_A_2),
	.Result_D_2(Result_D_2)
	
);
case_3 Case_3(
	//inputs
	.clk(clk),
	.rst(rst),
	.enable(enable),
	.current_addr(sc_addr),
	.Img_Q(Img_Q),
	.x0(x0),
	.y0(y0),
	.original_w(original_w),
	.original_h(original_h),
	.scaled_w(scaled_w),
	.scaled_h(scaled_h),
	.CS_top(CS),
	//outputs
	.fin_3(fin_3),
	.Img_CEN_3(Img_CEN_3),
	.Img_A_3(Img_A_3),
	.Result_D_3(Result_D_3)
);

general General(
	//inputs
	.clk(clk),
	.rst(rst),
	.enable(enable),
	.sc_addr(sc_addr),
	.Img_Q(Img_Q),
	.x0(x0),
	.y0(y0),
	.original_w(original_w),
	.original_h(original_h),
	.scaled_w(scaled_w),
	.scaled_h(scaled_h),
	.CS_top(CS),
	//outputs
	.fin_g(fin_g),
	.Img_CEN_g(Img_CEN_g),
	.Img_A_g(Img_A_g),
	.Result_D_g(Result_D_g)
);

wire [15:0]bound_x, bound_y;
assign bound_y = ({8'd0, sc_y}*(original_h-8'd1))%(scaled_h-8'd1);
assign bound_x = ({8'd0, sc_x}*(original_w-8'd1))%(scaled_w-8'd1);
always@(posedge clk)begin
	if(rst&&!enable)begin
		//assign rst value 
		sc_addr<=16'd0;
		CS<=hold;
		
		

	end//if
	else if(!rst&&enable)begin
		case (CS)
			hold:begin

				
				CS<=set_case;
			end//hold
			set_case:begin
				
				if (bound_y==16'd0 && bound_x==16'd0)
					CS<=case_3;
				else if (bound_y==16'd0)
					CS<=case_2;
				else if (bound_x==16'd0)
					CS<=case_1;
				else 
					CS<=general;	
			end//set_case
			case_1:begin

				if(fin_1)
					CS<=write;
				else
					CS<=case_1;

			end//case_1
			case_2:begin

				if(fin_2)
					CS<=write;
				else
					CS<=case_2;

			end
			case_3:begin

				if(fin_3)
					CS<=write;
				else
					CS<=case_3;

			end//case_3
			general:begin

				if(fin_g)
					CS<=write;
				else
					CS<=general;

			end//general
			write:begin

				sc_addr<=sc_addr+16'd1;			
				CS<=hold;
			end//write
			default:begin
				;
			end
		endcase
	end //else if

end //always




always@(*)begin
r_Result_A=sc_addr;
sc_x=sc_addr%scaled_w;
sc_y=sc_addr/scaled_w;
	
	
	if(rst&&!enable)begin
		r_Img_CEN=1'b1;
		r_Img_A=14'b0;
		r_Result_D=8'd0;
		//r_Result_A=16'd0;
		r_Result_CEN=1'b1;
		r_Result_WEN=1'b1;
		sc_x=8'd0;
		sc_y=8'd0;

	end//if
	else if(!rst&&enable)begin
		case (CS)
			hold:begin
				if(sc_addr==scaled_w*scaled_h)
					pre_done=1'b1;
				else
					pre_done=1'b0;
				r_Img_CEN=1'b0;
				r_Result_CEN=1'b1;
				r_Result_WEN=1'b1;

			end//hold
			set_case:begin
				r_Img_CEN=1'b0;
				r_Result_CEN=1'b1;
				r_Result_WEN=1'b1;
				pre_done=1'b0;

			end//set_case
			case_1:begin
				r_Img_CEN=Img_CEN_1;
				r_Img_A=Img_A_1;
				r_Result_D=Result_D_1;
				r_Result_CEN=1'b1;
				r_Result_WEN=1'b1;
				pre_done=1'b0;

			end//case_1
			case_2:begin
				r_Img_CEN=Img_CEN_2;
				r_Img_A=Img_A_2;
				r_Result_D=Result_D_2;
				r_Result_CEN=1'b1;
				r_Result_WEN=1'b1;
				pre_done=1'b0;
				

			end
			case_3:begin
				r_Img_CEN=Img_CEN_3;
				r_Img_A=Img_A_3;
				r_Result_D=Result_D_3;
				r_Result_CEN=1'b1;
				r_Result_WEN=1'b1;
				pre_done=1'b0;

			end//case_3
			general:begin
				r_Img_CEN=Img_CEN_g;
				r_Img_A=Img_A_g;
				r_Result_D=Result_D_g;
				r_Result_CEN=1'b1;
				r_Result_WEN=1'b1;
				pre_done=1'b0;


			end//general
			write:begin
				r_Img_CEN=1'b1;
				r_Result_CEN=1'b0;
				r_Result_WEN=1'b0;

			end//write
			default:begin
				;

			end
		endcase
	end //else if

	
end//always





endmodule
