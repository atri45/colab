`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: controller
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


module controller(
	input wire clk,rst,
	output wire sign_ext,
	
	//decode stage
	input wire[5:0] opD,functD,
	output wire pcsrcD,branchD,equalD,jumpD,
	
	//execute stage
	input wire flushE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire[4:0] alucontrolE,
	output wire hilodstE,hilowriteE,hiloreadE,
//	output wire divE,signed_divE,

	//mem stage
	output wire memtoregM,memwriteM,regwriteM,
	output wire hilodstM,hilowriteM,
	
	//write back stage
	output wire memtoregW,regwriteW,
    output wire hilodstW,hilowriteW
    );
	
	//decode stage
//	wire[1:0] aluopD;
	wire memtoregD,memwriteD,alusrcD,
		regdstD,regwriteD;
	wire[4:0] alucontrolD;
	wire hilodstD,hilowriteD,hiloreadD;
//	wire divD,signed_divD;
	
	//execute stage
	wire memwriteE;

	maindec md(
		opD,functD,
		memtoregD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,
		sign_ext,
		hilodstD,hilowriteD,hiloreadD
//		divD,signed_divD
//		aluopD
		);
	aludec ad(opD,functD,alucontrolD);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	floprc #(14) regE(
		clk,
		rst,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,hilodstD,hilowriteD,hiloreadD,divD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,hilodstE,hilowriteE,hiloreadE,divE}
		);
	flopr #(5) regM(
		clk,rst,
		{memtoregE,memwriteE,regwriteE,hilodstE,hilowriteE},
		{memtoregM,memwriteM,regwriteM,hilodstM,hilowriteM}
		);
	flopr #(4) regW(
		clk,rst,
		{memtoregM,regwriteM,hilodstM,hilowriteM},
		{memtoregW,regwriteW,hilodstW,hilowriteW}
		);
endmodule
