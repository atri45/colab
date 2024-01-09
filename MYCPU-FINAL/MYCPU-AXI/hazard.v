`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/22 10:23:13
// Design Name: 
// Module Name: hazard
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


module hazard(
	//fetch stage
	output wire stallF,flushF,
	input wire i_stall,
	//decode stage
	input wire[4:0] rsD,rtD,
	input wire branchD,
	output wire forwardaD,forwardbD,
	output wire stallD,flushD,
	//execute stage
	input wire[4:0] rsE,rtE,rdE,
	input wire[4:0] writeregE,
	input wire regwriteE,
	input wire memtoregE,
	output reg[1:0] forwardaE,forwardbE,
	input wire hilodstE,hilowriteE,hiloreadE,
	output forwardhiloE,
	input div_stallE,
	output stallE,flushE,
	input cp0readE,
	output forwardcp0E,
	//mem stage
	input wire[4:0] rdM,
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,
    input hilodstM,hilowriteM,
    output stallM,flushM,
    input cp0weM,
    input wire[31:0] excepttypeM, 
	input wire d_stall,
    output flushexceptM,
	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	input hilodstW,hilowriteW,
	output stallW,flushW,
	input cp0weW,

	output longest_stall
    );

	wire lwstallD,branchstallD,flushexcept;

	//forwarding sources to D stage (branch equality)
	assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);
	assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);
	
	//forwarding sources to E stage (ALU)
	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		if(rsE != 0) begin
			/* code */
			if(rsE == writeregM & regwriteM) begin
				/* code */
				forwardaE = 2'b10;
			end else if(rsE == writeregW & regwriteW) begin
				/* code */
				forwardaE = 2'b01;
			end
		end
		if(rtE != 0) begin
			/* code */
			if(rtE == writeregM & regwriteM) begin
				/* code */
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW) begin
				/* code */
				forwardbE = 2'b01;
			end
		end
	end

    assign forwardhiloE = ((hiloreadE != 0) && hilowriteM)? 1'b1:
             1'b0;
             
    assign forwardcp0E = ((cp0readE != 0) && cp0weM && rdM == rdE);

	//stalls
	assign  lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	assign  branchstallD = branchD &
				(regwriteE & 
				(writeregE == rsD | writeregE == rtD) |
				memtoregM &
				(writeregM == rsD | writeregM == rtD));
	
	assign longest_stall = i_stall | d_stall | div_stallE ;

	
	assign  stallD = lwstallD | branchstallD |longest_stall;
	assign  stallF = stallD & ~flushexceptM;
	assign stallE = longest_stall; 
	assign stallM = longest_stall;
    assign stallW = longest_stall & ~flushexceptM;

    assign  flushexceptM = (|excepttypeM);
    assign flushF = flushexceptM;
    assign flushD = flushexceptM;
	assign flushE = (lwstallD & ~longest_stall) | (branchstallD & ~longest_stall) | flushexceptM;
	assign flushM = flushexceptM;
	assign flushW = flushexceptM;

endmodule
