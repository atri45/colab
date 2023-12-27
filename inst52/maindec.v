`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: maindec
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

module maindec(
	input wire[5:0] op,
    input wire[5:0] funct,
	output wire memtoreg,memwrite,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,
	output wire sign_ext,
	output wire hilodst,hilowrite,hiloread
//	output wire[1:0] aluop
    );
    
    //基础七个控制信号
	reg[6:0] controls;
	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump} = controls;
	always @(*) begin
		case (op)
			6'b000000:controls <= 7'b1100000;//R-TYRE
			6'b100011:controls <= 7'b1010010;//LW
			6'b101011:controls <= 7'b0010100;//SW
			6'b000100:controls <= 7'b0001000;//BEQ
			6'b000010:controls <= 7'b0000001;//J
			//6'b001000:controls <= 7'b1010000;//ADDI
			`ANDI:controls <= 7'b1010000;// ANDI
			`XORI:controls <= 7'b1010000;// XORI
			`LUI:controls <= 7'b1010000;// LUI
			`ORI:controls <= 7'b1010000;// ORI
            `ADDI:controls <= 7'b1010000;
            `ADDIU:controls <= 7'b1010000;
            `SLTI:controls <= 7'b1010000;
            `SLTIU:controls <= 7'b1010000;  
			default:  controls <= 7'b0000000;//illegal op	
		endcase
	end
	
	//andi,xori,lui,ori运算为无符号扩展
	assign sign_ext = | (op[5:2] ^ 4'b0011); 
	
	//hilo寄存器
    assign hilodst = ((op == `R_TYPE && funct == `MTHI) || 
                   (op == `R_TYPE && funct == `MFHI));      
    assign hilowrite = ((op == `R_TYPE && funct == `MTHI) ||
                     (op == `R_TYPE && funct == `MTLO) ||
                     (op == `R_TYPE && funct == `MULT) ||
                     (op == `R_TYPE && funct == `MULTU) ||
                     (op == `R_TYPE && funct == `DIV) ||
                     (op == `R_TYPE && funct == `DIVU));                
    assign hiloread = ((op == `R_TYPE && funct == `MFHI) ||
                    (op == `R_TYPE && funct == `MFLO));        
              
//    //除法
//    assign div = ((op == `R_TYPE && funct == `DIV) || (op == `R_TYPE && funct == `DIVU));    
               
endmodule
