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
	input  wire clk,rst,
	input wire[5:0]ext_int,
	
	output wire[31:0] pcF,
	output wire instr_enF,
	input  wire[31:0] instrF,
	input wire i_stall,

    output mem_enM,
	output wire[31:0] aluoutM,writedataM,
	output wire[3:0] selectM,
	input  wire[31:0] readdataM,
	input wire d_stall,
	output wire longest_stall,
	
	output wire[31:0] pcW,
	output wire regwriteW, 
	output wire stallW,
	output wire[4:0] writeregW,
	output wire[31:0] resultW
    );
    
    wire sign_ext;
    
	//decode stage
	wire [31:0] instrD;
	wire [5:0] opD,functD;
	wire [4:0] rtD;
	wire pcsrcD,cmpresultD,branchD,jumpD,jalrD,rawriteD;
	wire breakMD,syscallD,invalidD,eretD;
	
	//execute stage
	wire regdstE,alusrcE,memtoregE,regwriteE,flushE,stallE,jalrE,rawriteE;
	wire [4:0] alucontrolE;
	wire hilodstE,hilowriteE,hiloreadE;
	wire cp0readE;
	
	//mem stage
	wire stallM,flushM;
	wire memtoregM,regwriteM;
	wire hilodstM,hilowriteM;
	wire cp0weM;
	wire isexceptM;
	
	wire memwriteM;
	wire memreadM;
	
	//write back stage
	wire flushW;
	wire memtoregW;
	wire hilodstW,hilowriteW;
    wire cp0weW;
    
    
    
    assign instr_enF = ~isexceptM;
    
	controller c(
		clk,rst,
		sign_ext,
		//decode stage
		instrD,
		opD,functD,rtD,
		pcsrcD,branchD,cmpresultD,jumpD,jalrD,rawriteD,
		breakMD,syscallD,invalidD,eretD,

		//execute stage
		flushE,stallE,
		memtoregE,alusrcE,jalrE,rawriteE,
		regdstE,regwriteE,	
		alucontrolE,
        hilodstE,hilowriteE,hiloreadE,
        cp0readE,
        
		//mem stage
		flushM,stallM,
		memtoregM,memwriteM,regwriteM,
		hilodstM,hilowriteM,
		memreadM,
		cp0weM,
		
		//write back stage
		flushW,stallW,
		memtoregW,regwriteW,
		hilodstW,hilowriteW,
		cp0weW
		);
	datapath dp(
		clk,rst,
		ext_int,
		//fetch stage
		i_stall,
		pcF,
		instrF,
		//decode stage
		sign_ext,
		pcsrcD,branchD,
		jumpD,
		cmpresultD,
		instrD,
		opD,functD,rtD,
		breakMD,syscallD,invalidD,eretD,
		jalrD,rawriteD,
		//execute stage
		memtoregE,jalrE,rawriteE,
		alusrcE,regdstE,
		regwriteE,
		alucontrolE,
		flushE,stallE,
		hilodstE,hilowriteE,hiloreadE,
		cp0readE,
		//mem stage
		memreadM,
		memwriteM,
		memtoregM,
		regwriteM,
		aluoutM,writedataM,
		readdataM,
		hilodstM,hilowriteM,
		flushM,stallM,
		selectM,
		cp0weM,
		isexceptM,
		d_stall,
		mem_enM,
		//writeback stage
		memtoregW,
		regwriteW,
		hilodstW,hilowriteW,
		flushW,stallW,
		cp0weW,
		pcW,writeregW,resultW,
		longest_stall
	    );
	
endmodule
