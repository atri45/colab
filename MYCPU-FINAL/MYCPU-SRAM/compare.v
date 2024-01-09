`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/23 22:57:01
// Design Name: 
// Module Name: eqcmp
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
`include "defines2.vh"

module compare(
	input wire [31:0] a,b,
	input wire [5:0] op,funct,
	input wire [4:0] rt,
	output wire y
    );
    
	assign y = ((op == `BEQ) && (a == b)) ||
	           ((op == `BNE) && (a != b)) ||
	           ((op == `BGTZ) && (a[31] == 0) && (a != 32'b0))   ||
	           ((op == `BLEZ) && ((a[31] == 1) || (a == 32'b0))) ||
	           ((op == `REGIMM_INST) && rt[0] && (a[31] == 0))   ||
	           ((op == `REGIMM_INST) && ~rt[0]&& (a[31] == 1))   ||
	           ((op == `R_TYPE) && (funct == `JR || funct == `JALR));

endmodule
