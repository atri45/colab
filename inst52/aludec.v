`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:27:24
// Design Name: 
// Module Name: aludec
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
module aludec(
    input wire[5:0] op,
	input wire[5:0] funct,
	output reg[4:0] alucontrol
    );
	always @(*) begin
        case (op)
        // logic function
            `ANDI: alucontrol <= `AND_CONTROL;
            `XORI: alucontrol <= `XOR_CONTROL;
            `LUI: alucontrol <= `LUI_CONTROL;
            `ORI: alucontrol <= `OR_CONTROL;
            `SLTI:alucontrol <=`SLT_CONTROL; 
            `SLTIU:alucontrol <= `SLTU_CONTROL;  
            `ADDI:alucontrol <= `ADD_CONTROL; 
            `ADDIU:alucontrol <= `ADDU_CONTROL;
            `J:alucontrol <= `AND_CONTROL;
            `JAL:alucontrol <= `AND_CONTROL;
            `R_TYPE:
                case(funct)
                    `AND: alucontrol <=`AND_CONTROL;
                    `OR: alucontrol <= `OR_CONTROL;
                    `XOR: alucontrol <= `XOR_CONTROL;
                    `NOR: alucontrol <= `NOR_CONTROL;
                    `SLL:alucontrol <= `SLL_CONTROL;
                    `SRL:alucontrol <= `SRL_CONTROL;
                    `SRA:alucontrol <= `SRA_CONTROL;
                    `SLLV:alucontrol <= `SLLV_CONTROL;
                    `SRLV:alucontrol <= `SRLV_CONTROL;
                    `SRAV:alucontrol <= `SRAV_CONTROL;   
                    `MFHI:alucontrol <= `MFHI_CONTROL;
                    `MFLO:alucontrol <= `MFLO_CONTROL; 
                    `MTHI:alucontrol <= `MTHI_CONTROL; 
                    `MTLO:alucontrol <= `MTLO_CONTROL; 
                    `SLT:alucontrol <= `SLT_CONTROL;
                    `SLTU:alucontrol <=`SLTU_CONTROL; 
                    `ADD:alucontrol <= `ADD_CONTROL;
                    `ADDU:alucontrol <=`ADDU_CONTROL;
                    `SUB:alucontrol <= `SUB_CONTROL;
                    `SUBU:alucontrol <=`SUBU_CONTROL;
                    `MULT:alucontrol <=`MULT_CONTROL;
                    `MULTU:alucontrol <= `MULTU_CONTROL; 
                    `DIV:alucontrol <= `DIV_CONTROL;
                    `DIVU:alucontrol <=`DIVU_CONTROL;
                    `JR:alucontrol <= `AND_CONTROL;
                    `JALR:alucontrol <= `AND_CONTROL;
                endcase
		endcase
	end
endmodule


//module aludec(
//    input wire[5:0] op,
//	input wire[5:0] funct,
//	output reg[2:0] alucontrol
//    );
//	always @(*) begin
//		case (aluop)
//			2'b00: alucontrol <= 3'b010;//add (for lw/sw/addi)
//			2'b01: alucontrol <= 3'b110;//sub (for beq)
//			default : case (funct)
//				6'b100000:alucontrol <= 3'b010; //add
//				6'b100010:alucontrol <= 3'b110; //sub
//				6'b100100:alucontrol <= 3'b000; //and
//				6'b100101:alucontrol <= 3'b001; //or
//				6'b101010:alucontrol <= 3'b111; //slt
//				default:  alucontrol <= 3'b000;
//			endcase
//		endcase
	
//	end
//endmodule
