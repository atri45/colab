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
    input wire[31:0] instr,
	input wire[5:0] op,funct,
    input wire[4:0] rt,
	output wire memtoreg,memwrite,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,jalr,
	output wire sign_ext,
	output wire hilodst,hilowrite,hiloread,
	output wire memread,
	output wire rawrite,
	output wire break,syscall,cp0we,cp0read,eret,
	output reg invalid
    );
    
    //基础七个控制信号+1
	reg[7:0] controls;
	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,jalr} = controls;
	always @(*) begin
	invalid = 1'b0;
		case (op)
			`R_TYPE:begin
			    case(funct)
			        `JR: controls <= 8'b00010010;
			        `JALR: controls <= 8'b11010011;
			        `BREAK: controls <= 8'b11010011;
			        `SYSCALL: controls <= 8'b11010011;
                    default: controls <= 8'b11000000;//R-TYRE
                endcase
			end
			`ANDI:controls <= 8'b10100000;// ANDI
			`XORI:controls <= 8'b10100000;// XORI
			`LUI:controls <= 8'b10100000;// LUI
			`ORI:controls <= 8'b10100000;// ORI
            `ADDI:controls <= 8'b10100000;
            `ADDIU:controls <= 8'b10100000;
            `SLTI:controls <= 8'b10100000;
            `SLTIU:controls <= 8'b10100000;
            
			`LB,`LBU,`LH,`LHU,`LW:controls <= 8'b10100100;
            `SB,`SH,`SW:controls <= 8'b00101000; 
            
            `J:controls <= 8'b00000010;
            `JAL:controls <= 8'b10000011;
            `BEQ:controls <= 8'b00010000;
            `BNE:controls <= 8'b00010000;
            `BGTZ:controls <= 8'b00010000;
            `BLEZ:controls <= 8'b00010000;
            `REGIMM_INST:controls <= {rt[4], 6'b0001000, rt[4]};
            
            `SPECIAL3_INST:
                case(instr[25:21])
                    `MFC0:controls <= 8'b10000000;
                    `MTC0,`ERET:controls <= 8'b00000000;
                     
                endcase
            
			default:  begin
			controls <= 8'b00000000;//illegal op	
			invalid = 1; 
			end
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
                    
    assign memread = ((op == `LB)||(op==`LBU)||(op == `LH)||(op==`LHU)||(op == `LW));                 
    
    //写回31号寄存器
    assign rawrite = ((op == `JAL) || 
                     (op == `REGIMM_INST && rt == `BGEZAL) ||
                     (op == `REGIMM_INST && rt == `BLTZAL));
              
    // 自陷指令
    assign break = (op == `R_TYPE && funct == `BREAK); 
    assign syscall = (op == `R_TYPE && funct == `SYSCALL);
              
    // 特权指令
    assign cp0we = (instr[31:21] == 11'b0100_0000_100 && instr[10:0] == 11'b00000000000); //MTC0
    assign cp0read = (instr[31:21] == 11'b01000000000 && instr[10:0] == 11'b00000000000); //MFC0
    assign eret = (instr == 32'b01000010000000000000000000011000); //ERET
endmodule
