
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
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

module alu(
	input wire clk,rst,isexceptM,flushE,
	input wire[31:0] a,b,
	input wire [4:0] sa,
	input wire [4:0] alucontrol,
	output reg [31:0] aluout,
	input wire [63:0] hilo_o,
	output reg[63:0] hilo_i, 
	output reg div_stall,  
	output wire overflow, 
	input wire [31:0] cp0data
    );

	reg double_sign; 
	assign overflow = (alucontrol==`ADD_CONTROL || alucontrol==`SUB_CONTROL) & (double_sign ^ aluout[31]); 

	reg div_start;
	reg div_signed;
	reg [31:0] a_save; 
	reg [31:0] b_save;
	wire [63:0] div_result;
	wire div_cancel; 
	assign div_cancel = ((alucontrol == `DIV_CONTROL)|(alucontrol == `DIVU_CONTROL)) & isexceptM;
	div div(clk,rst,div_signed,a_save,b_save,div_start,div_cancel,div_result,div_ready);
	
	always @(*) begin
		double_sign = 0;
		hilo_i = 64'b0;
		if(rst | isexceptM) begin
			div_stall = 1'b0;
			div_start = 1'b0;
		end
		else begin
        	case(alucontrol)
				//逻辑运算
				`AND_CONTROL   :  aluout = a & b;  //指令AND、ANDI
				`OR_CONTROL    :  aluout = a | b;  //指令OR、ORI
				`XOR_CONTROL   :  aluout = a ^ b;  //指令XOR
				`NOR_CONTROL   :  aluout = ~(a | b);  //指令NOR、XORI
				`LUI_CONTROL   :  aluout = {b[15:0],16'b0}; //指令LUI
				//移位指令
				`SLL_CONTROL   :  aluout = b << sa;  //指令SLL
				`SRL_CONTROL   :  aluout = b >> sa;  //指令SRL
				`SRA_CONTROL   :  aluout = $signed(b) >>> sa;  //指令SRA
				`SLLV_CONTROL  :  aluout = b << a[4:0];  //指令SLLV
				`SRLV_CONTROL  :  aluout = b >> a[4:0];  //指令SRLV
				`SRAV_CONTROL  :  aluout = $signed(b) >>> a[4:0]; //指令SRAV
				//算数运算
				`ADD_CONTROL   :  {double_sign,aluout} = {a[31],a} + {b[31],b}; //指令ADD、ADDI
				`ADDU_CONTROL  :  aluout = a + b; //指令ADDU、ADDIU
				`SUB_CONTROL   :  {double_sign,aluout} = {a[31],a} - {b[31],b}; //指令SUB
				`SUBU_CONTROL  :  aluout = a - b; //指令SUBU
				`SLT_CONTROL   :  aluout = $signed(a) < $signed(b) ? 32'b1 : 32'b0;  //指令SLT、SLTI
				`SLTU_CONTROL  :  aluout = a < b ? 32'b1 : 32'b0; //指令SLTU、SLTIU
				`MULT_CONTROL  :  hilo_i = $signed(a) * $signed(b); //指令MULT 
				`MULTU_CONTROL :  hilo_i = {32'b0, a} * {32'b0, b}; //指令MULTU
				`DIV_CONTROL   :  begin //指令DIV
					if(~div_ready & ~div_start) begin 
						div_start <= 1'b1;
						div_signed <= 1'b1;
						div_stall <= 1'b1;
						a_save <= a; 
						b_save <= b;
					end
					else if(div_ready) begin
						div_start <= 1'b0;
						div_signed <= 1'b1;
						div_stall <= 1'b0;
						hilo_i <= div_result;
					end
				end
				`DIVU_CONTROL  :  begin 
					if(~div_ready & ~div_start) begin 
						div_start <= 1'b1;
						div_signed <= 1'b0;
						div_stall <= 1'b1;
						a_save <= a; 
						b_save <= b;
					end
					else if(div_ready) begin
						div_start <= 1'b0;
						div_signed <= 1'b0;
						div_stall <= 1'b0;
						hilo_i <= div_result;
					end
				end
				//数据移动指令
				`MFHI_CONTROL  :  aluout = hilo_o[63:32]; //指令MFHI
				`MFLO_CONTROL  :  aluout = hilo_o[31:0]; //指令MFLO
				`MTHI_CONTROL  :  hilo_i = {a,hilo_o[31:0]}; //指令MTHI
				`MTLO_CONTROL  :  hilo_i = {hilo_o[63:32],a}; //指令MTLO
				//读写CP0
				`MFC0_CONTROL  :  aluout = cp0data; //指令MFC0
				`MTC0_CONTROL  :  aluout = b;  //指令MTC0
				default        :  aluout = `ZeroWord;
			endcase
		end
    end
endmodule