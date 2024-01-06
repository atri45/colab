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
	input   wire clk,rst,
	input wire[5:0]ext_int,
	//fetch stage
	output  wire[31:0] pcF,
	input   wire[31:0] instrF,
	//decode stage
	input   wire sign_ext,
	input   wire pcsrcD,branchD,
	input   wire jumpD,
	output  wire cmpresultD,
	output  wire[31:0] instrD,
	output  wire[5:0] opD,functD,
	output  wire[4:0] rtD,
	input   wire breakD,syscallD,invalidD,eretD,jalrD,rawriteD,
	//execute stage
	input   wire memtoregE,jalrE,rawriteE,
	input   wire alusrcE,regdstE,
	input   wire regwriteE,
	input   wire[4:0] alucontrolE,
	output  wire flushE,stallE,
	input   wire hilodstE,hilowriteE,hiloreadE,
	input   wire cp0readE,
	//mem stage
	input   wire memtoregM,
	input   wire regwriteM,
	output  wire[31:0] aluoutM,writedata_o,
	input   wire[31:0] readdataM,
    input   wire hilodstM,hilowriteM,
    output  wire flushM,stallM,
    output  wire[3:0]selectM,
    input   wire cp0weM,
	//writeback stage
	input   wire memtoregW,
	input   wire regwriteW,
	input   wire hilodstW,hilowriteW,
	output  wire flushW,stallW,
	input   wire cp0weW,
	output  wire[31:0] pcW,     
	output 	wire[4:0] writeregW,
	output 	wire[31:0] resultW 
    );
	
	//fetch stage
	wire stallF,flushF;
	wire instadelF,is_in_delayslotF;
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD,pcplus8F;
	//decode stage
	wire [31:0] pcplus4D,pcplus8D,pcD;
	wire forwardaD,forwardbD;
	wire [4:0] rsD,rdD,saD;
	wire flushD,stallD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	wire instadelD,is_in_delayslotD;
	//execute stage
	wire [31:0] pcplus8E,pcE;
	wire [1:0] forwardaE,forwardbE;
	wire forwardcp0E;
	wire forwardhiloE;
	wire [4:0] rsE,rtE,rdE,saE;
	wire [4:0] writeregE,writereg2E;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE, aluout2E;
	wire [63:0] hilo_iE,hilo_o2E;
	wire [63:0] hilo_oE;
	wire div_stallE;
	wire [5:0]opE;
	wire overflowE;
	wire breakE,syscallE,invalidE,eretE;
	wire instadelE,is_in_delayslotE;
	wire [31:0]cp0dataE,cp0data2E;
	//mem stage
	wire flushM;
	wire [4:0] rdM;
	wire [4:0] writeregM;
	wire [63:0] hilo_iM;
	wire [63:0] hilo_oM;
	wire [31:0] writedataM,readdata_o;
	wire [5:0] opM;
	wire breakM,syscallM,invalidM,eretM,overflowM;
	wire adelM,adesM;
	wire instadelM;
	wire [31:0] bad_addrM;
	wire [31:0] pcM,newpcM;
	wire is_in_delayslotM;
	wire [31:0] excepttypeM,count_oM,compare_oM,status_oM,cause_oM,epc_oM, config_oM,prid_oM,badvaddrM;
	wire flushexceptM;
	//writeback stage
	wire flushW;
	wire [31:0] aluoutW,readdataW;
    
    
	//hazard detection
	hazard h(
		//fetch stage
		stallF,flushF,
		//decode stage
		rsD,rtD,
		branchD,
		forwardaD,forwardbD,
		stallD,flushD,
		//execute stage
		rsE,rtE,rdE,
		writeregE,
		regwriteE,
		memtoregE,
		forwardaE,forwardbE,
		hilodstE,hilowriteE,hiloreadE,
		forwardhiloE,
		div_stallE,
		stallE,flushE,
		cp0readE,
		forwardcp0E,
		//mem stage
		rdM,
		writeregM,
		regwriteM,
		memtoregM,
		hilodstM,hilowriteM,
		stallM,flushM,
		cp0weM,excepttypeM,
		flushexceptM,
		//write back stage
		writeregW,
		regwriteW,
		hilodstW,hilowriteW,
		stallW,flushW,
		cp0weW
		);

	//next PC logic (operates in fetch an decode)
	mux4 #(32) pcmux(pcplus4F, pcbranchD, {pcplus4D[31:28],instrD[25:0],2'b00}, srca2D, {jumpD, branchD&cmpresultD}, pcnextFD);

	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);
	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,flushF,pcnextFD,newpcM,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);
	adder pcadd2(pcF, 32'b1000, pcplus8F);
	assign instadelF = (pcF[1:0] != 2'b00);
	assign is_in_delayslotF = (jumpD|jalrD|rawriteD|branchD);
	//decode stage
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,pcplus8F,pcplus8D);
	flopenrc #(32) r3D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(1) r4D(clk,rst,~stallD,flushD,instadelF,instadelD);
	flopenrc #(1) r5D(clk,rst,~stallD,flushD,is_in_delayslotF,is_in_delayslotD);
	flopenrc #(32) r6D(clk,rst,~stallD,flushD,pcF,pcD);

	signext se(sign_ext,instrD[15:0],signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd3(pcplus4D,signimmshD,pcbranchD);
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	compare comp(srca2D,srcb2D,opD,functD,rtD,cmpresultD);

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
    flopenrc #(5) r10E(clk,rst,~stallE,flushE,{instadelD,syscallD,breakD,eretD,invalidD},{instadelE,syscallE,breakE,eretE,invalidE});
    flopenrc #(1) r11E(clk,rst,~stallE,flushE,is_in_delayslotD,is_in_delayslotE);
    flopenrc #(32) r12E(clk,rst,~stallE,flushE,pcD,pcE);
    
	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(64) forwardhilomux(hilo_oM,hilo_iM,forwardhiloE,hilo_o2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	alu alu(clk,rst,flushE,srca2E,srcb3E,saE,alucontrolE,aluoutE,hilo_o2E,hilo_iE,div_stallE,overflowE,cp0data2E);
	mux2 #(5) wrmux1(rtE,rdE,regdstE,writeregE);
	mux2 #(5) wrmux2(writeregE,5'b11111,rawriteE,writereg2E);
	mux2 #(32) aluoutmux(aluoutE,pcplus8E,jalrE|rawriteE,aluout2E);
    mux2 #(32) forwardcp0mux(cp0dataE,aluoutM,forwardcp0E,cp0data2E);
    
	//mem stage
	flopenrc #(32) r1M(clk,rst,~stallM,flushM,srcb2E,writedataM);
	flopenrc #(32) r2M(clk,rst,~stallM,flushM,aluout2E,aluoutM);
	flopenrc #(5) r3M(clk,rst,~stallM,flushM,writereg2E,writeregM);
    flopenrc #(64) r4M(clk,rst,~stallM,flushM,hilo_iE,hilo_iM);
    flopenrc #(6) r5M(clk,rst,~stallM,flushM,opE,opM);
    flopenrc #(5) r6M(clk,rst,~stallM,flushM,rdE,rdM);
    flopenrc #(6) r7M(clk,rst,~stallM,flushM,{instadelE,syscallE,breakE,eretE,invalidE,overflowE},{instadelM,syscallM,breakM,eretM,invalidM,overflowM});
    flopenrc #(1) r8M(clk,rst,~stallM,flushM,is_in_delayslotE,is_in_delayslotM);
    flopenrc #(32) r9M(clk,rst,~stallM,flushM,pcE,pcM);
    
    //assign bad_addrM = (instadelM)? pcM: (adelM | adesM)? aluoutM: 32'b0;
    assign bad_addrM = (instadelM)? pcM:aluoutM;
    data_mem_shell dms(opM,aluoutM[1:0],readdataM,writedataM,readdata_o,writedata_o,selectM,adelM,adesM);
    hilo_reg hilo(clk,rst,hilowriteM,hilo_iM[63:32],hilo_iM[31:0],hilo_oM[63:32],hilo_oM[31:0]);
    exception exception(rst,ext_int,cp0weM,rdM,aluoutM,adelM,adesM,instadelM,syscallM,breakM,eretM,invalidM,overflowM,status_oM,cause_oM,epc_oM,excepttypeM,newpcM);
    cp0 CP0(clk,rst,cp0weM,rdM,rdE,aluoutM,ext_int,excepttypeM,pcM,is_in_delayslotM,
    bad_addrM,cp0dataE,count_oM,compare_oM,status_oM,cause_oM,epc_oM,config_oM,prid_oM,badvaddrM);
    
	//writeback stage
	flopenrc #(32) r1W(clk,rst,~stallW,flushW,aluoutM,aluoutW);
	flopenrc #(32) r2W(clk,rst,~stallW,flushW,readdata_o,readdataW);
	flopenrc #(5) r3W(clk,rst,~stallW,flushW,writeregM,writeregW);
	flopenrc #(32) r4W(clk,rst,~stallW,flushW,pcM,pcW);
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);
	
endmodule
