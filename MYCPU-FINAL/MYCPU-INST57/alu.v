
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
				//�߼�����
				`AND_CONTROL   :  aluout = a & b;  //ָ��AND��ANDI
				`OR_CONTROL    :  aluout = a | b;  //ָ��OR��ORI
				`XOR_CONTROL   :  aluout = a ^ b;  //ָ��XOR
				`NOR_CONTROL   :  aluout = ~(a | b);  //ָ��NOR��XORI
				`LUI_CONTROL   :  aluout = {b[15:0],16'b0}; //ָ��LUI
				//��λָ��
				`SLL_CONTROL   :  aluout = b << sa;  //ָ��SLL
				`SRL_CONTROL   :  aluout = b >> sa;  //ָ��SRL
				`SRA_CONTROL   :  aluout = $signed(b) >>> sa;  //ָ��SRA
				`SLLV_CONTROL  :  aluout = b << a[4:0];  //ָ��SLLV
				`SRLV_CONTROL  :  aluout = b >> a[4:0];  //ָ��SRLV
				`SRAV_CONTROL  :  aluout = $signed(b) >>> a[4:0]; //ָ��SRAV
				//��������
				`ADD_CONTROL   :  {double_sign,aluout} = {a[31],a} + {b[31],b}; //ָ��ADD��ADDI
				`ADDU_CONTROL  :  aluout = a + b; //ָ��ADDU��ADDIU
				`SUB_CONTROL   :  {double_sign,aluout} = {a[31],a} - {b[31],b}; //ָ��SUB
				`SUBU_CONTROL  :  aluout = a - b; //ָ��SUBU
				`SLT_CONTROL   :  aluout = $signed(a) < $signed(b) ? 32'b1 : 32'b0;  //ָ��SLT��SLTI
				`SLTU_CONTROL  :  aluout = a < b ? 32'b1 : 32'b0; //ָ��SLTU��SLTIU
				`MULT_CONTROL  :  hilo_i = $signed(a) * $signed(b); //ָ��MULT 
				`MULTU_CONTROL :  hilo_i = {32'b0, a} * {32'b0, b}; //ָ��MULTU
				`DIV_CONTROL   :  begin //ָ��DIV
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
				//�����ƶ�ָ��
				`MFHI_CONTROL  :  aluout = hilo_o[63:32]; //ָ��MFHI
				`MFLO_CONTROL  :  aluout = hilo_o[31:0]; //ָ��MFLO
				`MTHI_CONTROL  :  hilo_i = {a,hilo_o[31:0]}; //ָ��MTHI
				`MTLO_CONTROL  :  hilo_i = {hilo_o[63:32],a}; //ָ��MTLO
				//��дCP0
				`MFC0_CONTROL  :  aluout = cp0data; //ָ��MFC0
				`MTC0_CONTROL  :  aluout = b;  //ָ��MTC0
				default        :  aluout = `ZeroWord;
			endcase
		end
    end
endmodule