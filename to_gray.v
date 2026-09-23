module to_gray(output reg [7:0]graycode, input [31:0]rgb);
reg [13:0]pre_result;
always @(*)begin
	pre_result = rgb[23:16]*6'b001001 + rgb[15:8]*6'b010011 + rgb[7:0]*6'b000011;
	if(pre_result[4] == 1'b0) graycode = pre_result[12:5];
	else if(|pre_result[3:0] == 1'b1) graycode = pre_result[12:5] + 8'b0000_0001;
	else begin
		if(pre_result[5] == 1'b0) graycode = pre_result[12:5];
		else graycode = pre_result[12:5] + 8'b0000_0001;
	end
end
endmodule
