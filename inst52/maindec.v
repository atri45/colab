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
	input wire[5:0] op,funct,
    input wire[4:0] rt,
	output wire memtoreg,memwrite,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,jalr,
	output wire sign_ext,
	output wire hilodst,hilowrite,hiloread,
	output wire memread,
	output wire rawrite
//	output wire[1:0] aluop
    );
    
    //»ù´¡Æß¸ö¿ØÖÆÐÅºÅ+1
	reg[7:0] controls;
	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,jalr} = controls;
	always @(*) begin
		case (op)
			`R_TYPE:begin
			    case(funct)
			        `JR: controls <= 8'b00010010;
			        `JALR: controls <= 8'b11010011;
                    default: controls <= 8'b11000000;//R-TYRE
                endcase
			end
			//6'b100011:controls <= 8'b10100100;//LW
			//6'b101011:controls <= 8'b00101000;//SW
			//6'b000100:controls <= 8'b00010000;//BEQ
			//6'b000010:controls <= 8'b00000010;//J
			//6'b001000:controls <= 7'b1010000;//ADDI
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
			default:  controls <= 8'b00000000;//illegal op	
		endcase
	end
	
	//andi,xori,lui,oriÔËËãÎªÎÞ·ûºÅÀ©Õ¹
	assign sign_ext = | (op[5:2] ^ 4'b0011); 

	//hilo¼Ä´æÆ÷
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
    
    //Ð´»Ø31ºÅ¼Ä´æÆ÷
    assign rawrite = ((op == `JAL) || 
                     (op == `REGIMM_INST && rt == `BGEZAL) ||
                     (op == `REGIMM_INST && rt == `BLTZAL));
              
//    //³ý·¨
//    assign div = ((op == `R_TYPE && funct == `DIV) || (op == `R_TYPE && funct == `DIVU));    
               
endmodule
