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
	input wire[31:0]instrD,
	input wire[5:0] opD,functD,
	input wire[4:0] rtD,
	output wire pcsrcD,branchD,cmpresultD,jumpD,jalrD,rawriteD,
    output wire breakD,syscallD,invalidD,
	//execute stage
	input wire flushE, stallE,
	output wire memtoregE,alusrcE,jalrE,rawriteE,
	output wire regdstE,regwriteE,
	output wire[4:0] alucontrolE,
	output wire hilodstE,hilowriteE,hiloreadE,
	output wire cp0readE,
//	output wire divE,signed_divE,

	//mem stage
	input wire stallM,
	output wire memtoregM,memwriteM,regwriteM,
	output wire hilodstM,hilowriteM,
	output wire memreadM,
	output wire cp0weM,
	//write back stage
	input wire stallW,
	output wire memtoregW,regwriteW,
    output wire hilodstW,hilowriteW,
    output wire cp0weW
    );
	
	//decode stage
//	wire[1:0] aluopD;
	wire memtoregD,memwriteD,alusrcD,regdstD,regwriteD;
	wire[4:0] alucontrolD;
	wire hilodstD,hilowriteD,hiloreadD;
	wire memreadD;
	wire cp0weD,cp0readD,eretD;
//	wire divD,signed_divD;
	
	//execute stage
	wire memwriteE;
	wire memreadE;

	maindec md(
	    instrD,
		opD,functD,rtD,
		memtoregD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,jalrD,
		sign_ext,
		hilodstD,hilowriteD,hiloreadD,
		memreadD,
		rawriteD,
        breakD,syscallD,
        cp0weD,cp0readD,eretD,invalidD
		);
	aludec ad(instrD,opD,functD,alucontrolD);

	assign pcsrcD = branchD & cmpresultD;

	//pipeline registers
	flopenrc #(19) regE(
		clk,rst,~stallE,flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,hilodstD,hilowriteD,hiloreadD,memreadD,jalrD,rawriteD,cp0weD,cp0readD,eretD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,hilodstE,hilowriteE,hiloreadE,memreadE,jalrE,rawriteE,cp0weE,cp0readE,eretE}
		);
	flopenr #(7) regM(
		clk,rst,~stallM,
		{memtoregE,memwriteE,regwriteE,hilodstE,hilowriteE,memreadE,cp0weE},
		{memtoregM,memwriteM,regwriteM,hilodstM,hilowriteM,memreadM,cp0weM}
		);
	flopenr #(5) regW(
		clk,rst,~stallW,
		{memtoregM,regwriteM,hilodstM,hilowriteM,cp0weM},
		{memtoregW,regwriteW,hilodstW,hilowriteW,cp0weW}
		);
endmodule
