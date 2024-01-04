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
	input wire[4:0] rtD,
	output wire pcsrcD,branchD,cmpresultD,jumpD,

	//execute stage
	input wire flushE, stallE,
	output wire memtoregE,alusrcE,jalrE,rawriteE,
	output wire regdstE,regwriteE,
	output wire[4:0] alucontrolE,
	output wire hilodstE,hilowriteE,hiloreadE,
//	output wire divE,signed_divE,

	//mem stage
	input wire stallM,
	output wire memtoregM,memwriteM,regwriteM,
	output wire hilodstM,hilowriteM,
	output wire memreadM,
	
	//write back stage
	input wire stallW,
	output wire memtoregW,regwriteW,
    output wire hilodstW,hilowriteW
    );
	
	//decode stage
//	wire[1:0] aluopD;
	wire memtoregD,memwriteD,alusrcD,regdstD,regwriteD,jalrD,rawriteD;
	wire[4:0] alucontrolD;
	wire hilodstD,hilowriteD,hiloreadD;
	wire memreadD;
//	wire divD,signed_divD;
	
	//execute stage
	wire memwriteE;
	wire memreadE;

	maindec md(
		opD,functD,rtD,
		memtoregD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,jalrD,
		sign_ext,
		hilodstD,hilowriteD,hiloreadD,
		memreadD,
		rawriteD
//		divD,signed_divD
//		aluopD
		);
	aludec ad(opD,functD,alucontrolD);

	assign pcsrcD = branchD & cmpresultD;

	//pipeline registers
	flopenrc #(16) regE(
		clk,rst,~stallE,flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,hilodstD,hilowriteD,hiloreadD,memreadD,jalrD,rawriteD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,hilodstE,hilowriteE,hiloreadE,memreadE,jalrE,rawriteE}
		);
	flopenr #(6) regM(
		clk,rst,~stallM,
		{memtoregE,memwriteE,regwriteE,hilodstE,hilowriteE,memreadE},
		{memtoregM,memwriteM,regwriteM,hilodstM,hilowriteM,memreadM}
		);
	flopenr #(4) regW(
		clk,rst,~stallW,
		{memtoregM,regwriteM,hilodstM,hilowriteM},
		{memtoregW,regwriteW,hilodstW,hilowriteW}
		);
endmodule
