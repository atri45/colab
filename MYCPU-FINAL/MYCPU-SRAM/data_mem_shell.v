`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/01/03 10:48:31
// Design Name:
// Module Name: data_mem_shell
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

module data_mem_shell(
    input wire[5:0] op,
    input wire[1:0] aluout,
    input wire[31:0] readdata_i,
    input wire[31:0] writedata_i,
    output wire[31:0] readdata_o,
    output wire[31:0] writedata_o,
    output wire[3:0] select,
    output wire adel,
    output wire ades
    );
    
    
    assign select = ((op == `LW || op == `LB || op == `LBU || op == `LH || op == `LHU)? 4'b0000:
              (op == `SW && aluout == 2'b00)? 4'b1111:
              (op == `SH && aluout == 2'b10)? 4'b1100:
              (op == `SH && aluout == 2'b00)? 4'b0011:

              (op == `SB && aluout == 2'b11)? 4'b1000:
              (op == `SB && aluout == 2'b10)? 4'b0100:
              (op == `SB && aluout == 2'b01)? 4'b0010:
              (op == `SB && aluout == 2'b00)? 4'b0001:
              4'b0000);
    
    
    assign writedata_o = ((op == `SW)? writedata_i:
        (op == `SH)? {writedata_i[15:0],writedata_i[15:0]}:
        (op == `SB)? {writedata_i[7:0],writedata_i[7:0],writedata_i[7:0],writedata_i[7:0]}:
        32'b0);
        
    assign readdata_o = (
    (op == `LW && aluout == 2'b00)? readdata_i:
    (op == `LH && aluout == 2'b00)? {{16{readdata_i[15]}},readdata_i[15:0]}:
    (op == `LH && aluout == 2'b10)? {{16{readdata_i[31]}},readdata_i[31:16]}:
    (op == `LHU && aluout == 2'b00)? {16'b0,readdata_i[15:0]}:
    (op == `LHU && aluout == 2'b10)? {16'b0,readdata_i[31:16]}:
    (op == `LB && aluout == 2'b00)? {{24{readdata_i[7]}},readdata_i[7:0]}:
    (op == `LB && aluout == 2'b01)? {{24{readdata_i[15]}},readdata_i[15:8]}:
    (op == `LB && aluout == 2'b10)? {{24{readdata_i[23]}},readdata_i[23:16]}:
    (op == `LB && aluout == 2'b11)? {{24{readdata_i[31]}},readdata_i[31:24]}:
    (op == `LBU && aluout == 2'b00)? {24'b0,readdata_i[7:0]}:
    (op == `LBU && aluout == 2'b01)? {24'b0,readdata_i[15:8]}:
    (op == `LBU && aluout == 2'b10)? {24'b0,readdata_i[23:16]}:
    (op == `LBU && aluout == 2'b11)? {24'b0,readdata_i[31:24]}:
    32'b0);
    
    assign adel = ((op == `LH || op == `LHU) && aluout[0]) || (op == `LW && aluout != 2'b00);
    assign ades = (op == `SH & aluout[0]) | (op == `SW & aluout != 2'b00);
        
        
        
endmodule