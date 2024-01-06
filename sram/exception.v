`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/05 11:02:27
// Design Name: 
// Module Name: exception
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
module exception(
	input wire rst,
	input wire[5:0]ext_int,

    input wire cp0weW,
    input wire [4:0]waddrW,
    input wire[31:0] wdataW,

    input wire adel,ades,
	input wire instadel,syscall,break,eret,invalid,overflow,
	input wire[31:0] cp0_statusM,cp0_causeM,cp0_epcM,
	output wire[31:0] excepttypeM,
	output wire[31:0] newpcM
	//output reg isexceptM
    );
    wire [31:0] cp0_status,cp0_cause,cp0_epc;

//    assign cp0_status = (cp0weW & (waddrW == `CP0_REG_STATUS))? wdataW:
//                        cp0_statusM;
//    assign cp0_cause = (cp0weW & (waddrW == `CP0_REG_CAUSE))? wdataW:
//                        cp0_causeM;
//    assign cp0_epc = (cp0weW & (waddrW == `CP0_REG_EPC))? wdataW:
//                        cp0_epcM;
                        
assign excepttypeM = (rst)? 32'b0:
                    ((({ext_int,cp0_causeM[9:8]} & cp0_statusM[15:8]) != 8'h00) &&
				 	 (cp0_statusM[1] == 1'b0) && (cp0_statusM[0] == 1'b1))? 32'h00000001: //int
                    (instadel | adel)? 32'h00000004://adel
                    (ades)? 32'h00000005://ades
                    (syscall)? 32'h00000008://syscall
                    (break)? 32'h00000009://break
                    (eret)? 32'h0000000e://eret
                    (invalid)? 32'h0000000a://ri
                    (overflow)? 32'h0000000c://overflow
                    32'h0;
   
//    always @(*) begin
//        if(rst)begin
//            excepttypeM <= 32'b0;
//        end else begin
//            if((cp0_status[15:8] & {6'b000000,cp0_cause[9:8]}) != 8'h00 &
//                    (cp0_status[1] == 1'b0) & cp0_status[0] == 1'b1)begin 
//                //软硬件中断
//               excepttypeM <= 32'h00000001; 
//            end else if(instadel | adel)begin 
//                // 取指非对齐或Load非对齐
//                excepttypeM <= 32'h00000004; 
//            end else if(ades)begin 
//                // Store非对齐
//                excepttypeM <= 32'h00000005;  
//            end else if(syscall)begin 
//                // SYSCALL
//                excepttypeM <= 32'h00000008; 
//            end else if(break)begin 
//                // BREAK
//                excepttypeM <= 32'h00000009;
//            end else if(invalid)begin 
//                // 保留指令（未实现指令）
//                excepttypeM <= 32'h0000000a;
//            end else if(overflow)begin 
//                // 整型溢出
//                excepttypeM <= 32'h0000000c;
//            end
//             else if(eret)begin 
//                // ERET
//                excepttypeM <= 32'h0000000e;
//            end else begin
//                excepttypeM <= 32'b0;
//             end
//        end
//    end                 







assign newpcM = (excepttypeM == 32'h00000001)? 32'hbfc00380:
                (excepttypeM == 32'h00000004)? 32'hbfc00380:
                (excepttypeM == 32'h00000005)? 32'hbfc00380:
                (excepttypeM == 32'h00000008)? 32'hbfc00380:
                (excepttypeM == 32'h00000009)? 32'hbfc00380:
                (excepttypeM == 32'h0000000a)? 32'hbfc00380:
                (excepttypeM == 32'h0000000c)? 32'hbfc00380:
                (excepttypeM == 32'h0000000e)? cp0_epcM:
                32'b0;

endmodule
