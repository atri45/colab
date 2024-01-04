`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
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


module mips(
	input wire clk,rst,
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	output wire memwriteM,
	output wire[31:0] aluoutM,writedataM,
	input wire[31:0] readdataM
    );
    
    wire sign_ext;
    
	//decode stage
	wire [5:0] opD,functD;
	wire [4:0] rtD;
	wire pcsrcD,cmpresultD,branchD,jumpD;
	
	//execute stage
	wire regdstE,alusrcE,memtoregE,regwriteE,flushE,stallE,jalrE,rawriteE;
	wire [4:0] alucontrolE;
	wire hilodstE,hilowriteE,hiloreadE;
//	wire divE,signed_divE;
	
	//mem stage
	wire stallM;
	wire memtoregM,regwriteM;
	wire hilodstM,hilowriteM;
	
	//write back stage
	wire stallW;
	wire memtoregW,regwriteW;
	wire hilodstW,hilowriteW;

	controller c(
		clk,rst,
		sign_ext,
		//decode stage
		opD,functD,rtD,
		pcsrcD,branchD,cmpresultD,jumpD,

		//execute stage
		flushE,stallE,
		memtoregE,alusrcE,jalrE,rawriteE,
		regdstE,regwriteE,	
		alucontrolE,
        hilodstE,hilowriteE,hiloreadE,
        
		//mem stage
		stallM,
		memtoregM,memwriteM,regwriteM,
		hilodstM,hilowriteM,
		
		//write back stage
		stallW,
		memtoregW,regwriteW,
		hilodstW,hilowriteW
		);
	datapath dp(
		clk,rst,
		//fetch stage
		pcF,
		instrF,
		//decode stage
		sign_ext,
		pcsrcD,branchD,
		jumpD,
		cmpresultD,
		opD,functD,rtD,
		//execute stage
		memtoregE,jalrE,rawriteE,
		alusrcE,regdstE,
		regwriteE,
		alucontrolE,
		flushE,stallE,
		hilodstE,hilowriteE,hiloreadE,
		//mem stage
		memtoregM,
		regwriteM,
		aluoutM,writedataM,
		readdataM,
		hilodstM,hilowriteM,
		stallM,
		//writeback stage
		memtoregW,
		regwriteW,
		hilodstW,hilowriteW,
		stallW
	    );
	
endmodule
