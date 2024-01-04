`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 15:12:22
// Design Name: 
// Module Name: datapath
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


module datapath(
	input wire clk,rst,
	//fetch stage
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	//decode stage
	input wire sign_ext,
	input wire pcsrcD,branchD,
	input wire jumpD,
	output wire cmpresultD,
	output wire[5:0] opD,functD,
	output wire[4:0] rtD,
	//execute stage
	input wire memtoregE,jalrE,rawriteE,
	input wire alusrcE,regdstE,
	input wire regwriteE,
	input wire[4:0] alucontrolE,
	output wire flushE,stallE,
	input wire hilodstE,hilowriteE,hiloreadE,
	//mem stage
	input wire memtoregM,
	input wire regwriteM,
	output wire[31:0] aluoutM,writedata_o,
	input wire[31:0] readdataM,
    input hilodstM,hilowriteM,
    output wire stallM,
    output wire[3:0]selectM,
	//writeback stage
	input wire memtoregW,
	input wire regwriteW,
	input wire hilodstW,hilowriteW,
	output wire stallW
    );
	
	//fetch stage
	wire stallF;
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD,pcplus8F;
	//decode stage
	wire [31:0] pcplus4D,pcplus8D, instrD;
	wire forwardaD,forwardbD;
	wire [4:0] rsD,rdD,saD;
	wire flushD,stallD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	//execute stage
	wire [31:0] pcplus8E;
	wire [1:0] forwardaE,forwardbE,forwardhiloE;
	wire [4:0] rsE,rtE,rdE,saE;
	wire [4:0] writeregE,writereg2E;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE, aluout2E;
	wire [63:0] hilo_iE,hilo_o2E;
	wire [31:0] hilo_oE;
	wire div_stallE;
	wire [5:0]opE;
	//mem stage
	wire [4:0] writeregM;
	wire [63:0] hilo_iM;
	wire [31:0] writedataM,readdata_o;
	wire [5:0] opM;
	//writeback stage
	wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW,resultW;
    wire [63:0] hilo_iW, hilo_oW;
    
    
	//hazard detection
	hazard h(
		//fetch stage
		stallF,
		//decode stage
		rsD,rtD,
		branchD,
		forwardaD,forwardbD,
		stallD,
		//execute stage
		rsE,rtE,
		writeregE,
		regwriteE,
		memtoregE,
		forwardaE,forwardbE,
		flushE,
		hilodstE,hilowriteE,hiloreadE,
		forwardhiloE,
		div_stallE,
		stallE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		hilodstM,hilowriteM,
		stallM,
		//write back stage
		writeregW,
		regwriteW,
		hilodstW,hilowriteW,
		stallW
		);

	//next PC logic (operates in fetch an decode)
//	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);
//	mux2 #(32) pcmux(pcnextbrFD,
//		{pcplus4D[31:28],instrD[25:0],2'b00},
//		jumpD,pcnextFD);
	mux4 #(32) pcmux(pcplus4F, pcbranchD, {pcplus4D[31:28],instrD[25:0],2'b00}, srca2D, {jumpD, branchD&cmpresultD}, pcnextFD);

	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);
	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,pcnextFD,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);
	adder pcadd2(pcF, 32'b1000, pcplus8F);
	//decode stage
	flopenr #(32) r1D(clk,rst,~stallD,pcplus4F,pcplus4D);
	flopenr #(32) r2D(clk,rst,~stallD,pcplus8F,pcplus8D);
	flopenrc #(32) r3D(clk,rst,~stallD,flushD,instrF,instrD);
	signext se(sign_ext,instrD[15:0],signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd3(pcplus4D,signimmshD,pcbranchD);
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	compare comp(srca2D,srcb2D,opD,rtD,cmpresultD);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];

	//execute stage
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~stallE,flushE,rdD,rdE);
    flopenrc #(5) r7E(clk,rst,~stallE,flushE,saD,saE);
    flopenrc #(6) r8E(clk,rst,~stallE,flushE,opD,opE);
    flopenrc #(32) r9E(clk,rst,~stallE,flushE,pcplus8D,pcplus8E);

	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux3 #(64) forwardhilomux(hilo_oW,hilo_iW,hilo_iM,forwardhiloE,hilo_o2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	alu alu(clk,rst,flushE,srca2E,srcb3E,saE,alucontrolE,aluoutE,hilo_o2E,hilo_iE,div_stallE);
	mux2 #(5) wrmux1(rtE,rdE,regdstE,writeregE);
	mux2 #(5) wrmux2(writeregE,5'b11111,rawriteE,writereg2E);
	mux2 #(32) aluoutmux(aluoutE,pcplus8E,jalrE,aluout2E);

	//mem stage
	flopenr #(32) r1M(clk,rst,~stallM,srcb2E,writedataM);
	flopenr #(32) r2M(clk,rst,~stallM,aluout2E,aluoutM);
	flopenr #(5) r3M(clk,rst,~stallM,writereg2E,writeregM);
    flopenr #(64) r4M(clk,rst,~stallM,hilo_iE,hilo_iM);
    flopenr #(6) r5M(clk,rst,~stallM,opE,opM);
    data_mem_shell dms(opM,aluoutM[1:0],readdataM,writedataM,readdata_o,writedata_o,selectM);
    
	//writeback stage
	flopenr #(32) r1W(clk,rst,~stallW,aluoutM,aluoutW);
	flopenr #(32) r2W(clk,rst,~stallW,readdata_o,readdataW);
	flopenr #(5) r3W(clk,rst,~stallW,writeregM,writeregW);
	flopenr #(64) r4W(clk,rst,~stallW,hilo_iM,hilo_iW);
	
	hilo_reg hilo(clk,rst,hilowriteW,hilo_iW[63:32],hilo_iW[31:0],hilo_oW[63:32],hilo_oW[31:0]);

	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);
	
endmodule
