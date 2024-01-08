`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/05 11:02:27
// Design Name: 
// Module Name: exception
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module exception(
	input wire rst,
	input wire[5:0]ext_int,
    input wire adel,ades,
	input wire instadel,syscall,breakM,eret,invalid,overflow,
	input wire[31:0] cp0_statusM,cp0_causeM,cp0_epcM,
	output wire[31:0] excepttypeM,
	output wire[31:0] newpcM,
	output wire isexceptM
    );
assign excepttypeM = (rst)? 32'b0:
                    ((({ext_int,cp0_causeM[9:8]} & cp0_statusM[15:8]) != 8'h00) &&
				 	 (cp0_statusM[1] == 1'b0) && (cp0_statusM[0] == 1'b1))? 32'h00000001: //int
                    (instadel | adel)? 32'h00000004://adel
                    (ades)? 32'h00000005://ades
                    (syscall)? 32'h00000008://syscall
                    (breakM)? 32'h00000009://breakM
                    (eret)? 32'h0000000e://eret
                    (invalid)? 32'h0000000a://ri
                    (overflow)? 32'h0000000c://overflow
                    32'h0;
   
assign isexceptM = |excepttypeM;

assign newpcM = (excepttypeM == 32'h00000001)? 32'hbfc00380:
                (excepttypeM == 32'h00000004)? 32'hbfc00380:
                (excepttypeM == 32'h00000005)? 32'hbfc00380:
                (excepttypeM == 32'h00000008)? 32'hbfc00380:
                (excepttypeM == 32'h00000009)? 32'hbfc00380:
                (excepttypeM == 32'h0000000a)? 32'hbfc00380:
                (excepttypeM == 32'h0000000c)? 32'hbfc00380:
                (excepttypeM == 32'h0000000e)? cp0_epcM:
                32'b0;

endmodule
