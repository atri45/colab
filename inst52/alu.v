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
    input clk,rst,flushE,
	input wire[31:0] a,b,
	input wire[4:0] sa,
	input wire[4:0] alucontrol,
	output reg[31:0] y,
	input[63:0] hilo_o,
	output reg[63:0] hilo_i,
	output wire div_stall
//	output reg overflow,
//	output wire zero
    );
    wire div_valid, div_signed, div_cancel;
    wire [63:0]div_result;
    wire div_ready;
    assign div_cancel = 0;
    assign div_signed = (alucontrol == `DIV_CONTROL);
    assign div_valid = ((alucontrol == `DIV_CONTROL)||(alucontrol == `DIVU_CONTROL));
    div DIV(~clk,rst,flushE,a,b,div_valid,div_signed,div_stall,div_result);

	always @(*) begin
        case (alucontrol)
            `AND_CONTROL: y <= a & b;
            `OR_CONTROL: y <= a | b;
            `XOR_CONTROL: y <= a ^ b;
            `NOR_CONTROL: y <= ~ (a | b);
            `LUI_CONTROL: y <= {b[15:0], 16'b0};
             //移位指令
            `SLL_CONTROL: y<= b << sa;
            `SRL_CONTROL: y<= b >> sa;
            `SRA_CONTROL: y<= ( {32{b[31]}} << (6'd32 - {1'b0,sa}) ) | b >> sa;
            //`SRA_CONTROL: y<= $signed(b) >>> sa;
            `SLLV_CONTROL: y<= b << a[4:0];
            `SRLV_CONTROL: y<= b >> a[4:0];
            `SRAV_CONTROL: y<= ( {32{b[31]}} << (6'd32 - {1'b0,a[4:0]}) ) | b >> a[4:0];
           //`SRAV_CONTROL: y<= $signed(b) >>> a[4:0];
           //数据移动指令
            `MFHI_CONTROL: y <= hilo_o[63:32];
            `MFLO_CONTROL: y <= hilo_o[31:0];
            `MTHI_CONTROL: hilo_i <= {a, hilo_o[31:0]};
            `MTLO_CONTROL: hilo_i <= {hilo_o[63:32],a}; 
            //算术运算指令
            `ADD_CONTROL:y<=$signed(a) + $signed(b);
            `ADDU_CONTROL: y <= a+b;
            `SUB_CONTROL, `SUBU_CONTROL: y <= a + (~b + 1);
            `SLT_CONTROL: y <= $signed(a) < $signed(b);
            `SLTU_CONTROL: y <= a < b;
            `MULTU_CONTROL: hilo_i <= {32'b0, a} * {32'b0, b};
            `MULT_CONTROL:  hilo_i <= $signed(a) * $signed(b);
            `DIV_CONTROL: hilo_i <= div_result;
            `DIVU_CONTROL: hilo_i <= div_result;
        endcase
    end
    
    
//	wire[31:0] s,bout;
//	assign bout = op[2] ? ~b : b;
//	assign s = a + bout + op[2];
//	always @(*) begin
//		case (op[1:0])
//			2'b00: y <= a & bout;
//			2'b01: y <= a | bout;
//			2'b10: y <= s;
//			2'b11: y <= s[31];
//			default : y <= 32'b0;
//		endcase	
//	end
//	assign zero = (y == 32'b0);

//	always @(*) begin
//		case (op[2:1])
//			2'b01:overflow <= a[31] & b[31] & ~s[31] |
//							~a[31] & ~b[31] & s[31];
//			2'b11:overflow <= ~a[31] & b[31] & s[31] |
//							a[31] & ~b[31] & ~s[31];
//			default : overflow <= 1'b0;
//		endcase	
//	end
endmodule
