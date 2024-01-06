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
	input wire clk,rst,is_except,flushE,
	input wire[31:0] a,b,  //操作数a,b
	input wire [4:0] sa,
	input wire [4:0] alucontrolE,
	output reg[31:0] result,
	input wire [63:0] hilo_in, //读取的HI、LO寄存器的值
	output reg[63:0] hilo_out, //用于写入HI、LO寄存器
	output reg div_stall,   //除法的流水线暂停控制
	output wire overflow,     //溢出判断
	input wire [31:0] cp0_rdata //读取的CP0寄存器的值
	//input wire is_except, //用于触发异常时控制除法相关刷新
	
	
	//output wire div_ready,  //除法是否完成
	
	
	// output wire zero
    );

	reg double_sign; //凑运算结果的双符号位，处理整型溢出
	assign overflow = (alucontrolE==`ADD_CONTROL || alucontrolE==`SUB_CONTROL) & (double_sign ^ result[31]); 

	//div
	reg div_start;
	reg div_signed;
	reg [31:0] a_save; //除法时保存两个操作数，防止因为M阶段的刷新，继而数据前推选择器信号改变，导致alu输入发生变化，使除法出错
	reg [31:0] b_save;
	wire [63:0] div_result;
	
	always @(*) begin
		double_sign = 0;
		hilo_out = 64'b0;
		if(rst | is_except) begin
			div_stall = 1'b0;
			div_start = 1'b0;
		end
		else begin
        	case(alucontrolE)
				//逻辑运算8条
				`AND_CONTROL   :  result = a & b;  //指令AND、ANDI
				`OR_CONTROL    :  result = a | b;  //指令OR、ORI
				`XOR_CONTROL   :  result = a ^ b;  //指令XOR
				`NOR_CONTROL   :  result = ~(a | b);  //指令NOR、XORI
				`LUI_CONTROL   :  result = {b[15:0],16'b0}; //指令LUI
				//移位指令6条
				`SLL_CONTROL   :  result = b << sa;  //指令SLL
				`SRL_CONTROL   :  result = b >> sa;  //指令SRL
				`SRA_CONTROL   :  result = $signed(b) >>> sa;  //指令SRL
				`SLLV_CONTROL  :  result = b << a[4:0];  //指令SLLV
				`SRLV_CONTROL  :  result = b >> a[4:0];  //指令SRLV
				`SRAV_CONTROL  :  result = $signed(b) >>> a[4:0]; //指令SRAV
				//算数运算指令14条
				`ADD_CONTROL   :  {double_sign,result} = {a[31],a} + {b[31],b}; //指令ADD、ADDI
				`ADDU_CONTROL  :  result = a + b; //指令ADDU、ADDIU
				`SUB_CONTROL   :  {double_sign,result} = {a[31],a} - {b[31],b}; //指令SUB
				`SUBU_CONTROL  :  result = a - b; //指令SUBU
				`SLT_CONTROL   :  result = $signed(a) < $signed(b) ? 32'b1 : 32'b0;  //指令SLT、SLTI
				`SLTU_CONTROL  :  result = a < b ? 32'b1 : 32'b0; //指令SLTU、SLTIU
				`MULT_CONTROL  :  hilo_out = $signed(a) * $signed(b); //指令MULT 
				`MULTU_CONTROL :  hilo_out = {32'b0, a} * {32'b0, b}; //指令MULTU
				`DIV_CONTROL   :  begin //指令DIV, 除法器控制状态机逻辑
					if(~div_ready & ~div_start) begin //~div_start : 为了保证除法进行过程中，除法源操作数不因ALU输入改变而重新被赋值
						//必须非阻塞赋值，否则时序不对
						div_start <= 1'b1;
						div_signed <= 1'b1;
						div_stall <= 1'b1;
						a_save <= a; //除法时保存两个操作数
						b_save <= b;
					end
					else if(div_ready) begin
						div_start <= 1'b0;
						div_signed <= 1'b1;
						div_stall <= 1'b0;
						hilo_out <= div_result;
					end
				end
				`DIVU_CONTROL  :  begin //指令DIVU, 除法器控制状态机逻辑
					if(~div_ready & ~div_start) begin //~div_start : 为了保证除法进行过程中，除法源操作数不因ALU输入改变而重新被赋值
						//必须非阻塞赋值，否则时序不对
						div_start <= 1'b1;
						div_signed <= 1'b0;
						div_stall <= 1'b1;
						a_save <= a; ////除法时保存两个操作数
						b_save <= b;
					end
					else if(div_ready) begin
						div_start <= 1'b0;
						div_signed <= 1'b0;
						div_stall <= 1'b0;
						hilo_out <= div_result;
					end
				end
				//数据移动指令4条
				`MFHI_CONTROL  :  result = hilo_in[63:32]; //指令MFHI
				`MFLO_CONTROL  :  result = hilo_in[31:0]; //指令MFLO
				`MTHI_CONTROL  :  hilo_out = {a,hilo_in[31:0]}; //指令MTHI
				`MTLO_CONTROL  :  hilo_out = {hilo_in[63:32],a}; //指令MTLO
				//读写CP0
				`MFC0_CONTROL  :  result = cp0_rdata; //指令MFC0
				`MTC0_CONTROL  :  result = b;  //指令MTC0
				default        :  result = `ZeroWord;
			endcase
		end
    end
	wire annul; //终止除法信号
	assign annul = ((alucontrolE == `DIV_CONTROL)|(alucontrolE == `DIVU_CONTROL)) & is_except;
	//接入除法器
	div div(clk,rst,div_signed,a_save,b_save,div_start,annul,div_result,div_ready);
endmodule

//module alu(
//    input clk,rst,flushE,isexceptM,
//    input wire[31:0] a,b,
//    input wire[4:0] sa,
//    input wire[4:0] alucontrol,
//    output reg[31:0] y,
//    input[63:0] hilo_o,
//    output reg[63:0] hilo_i,
//    output reg div_stall,
//    output wire overflow,
//    input wire[31:0] cp0data
////    output wire zero
//    );
//    reg div_start;
//    reg div_signed;
//    reg [31:0] a_save; //除法时保存两个操作数，防止因为M阶段的刷新，继而数据前推选择器信号改变，导致alu输入发生变化，使除法出错
//    reg [31:0] b_save;
    
//    wire [63:0]div_result;
    
//    //wire div_signed, div_cancel, div_valid;
    
//    wire div_ready;
//    wire annul; //终止除法信号
//    assign annul = 1'b0;
//    //reg start_i = 0, signed_div_i=0;
//    wire addoverflow, suboverflow;
    
//    div div(clk,rst,div_signed,a_save,b_save,div_start,annul,div_result,div_ready);
//    //assign div_cancel = 0;
//    //assign div_signed = (alucontrol == `DIV_CONTROL);
//    //assign div_valid = ~div_ready & ((alucontrol == `DIV_CONTROL)|(alucontrol == `DIVU_CONTROL));
//    //div DIV(~clk,rst,signed_div_i,a,b,start_i,div_cancel,div_result,div_ready);
//    //assign div_stall = start_i;
//    assign addoverflow = (a[31] && b[31] && !y[31]) || (!a[31 ]&& !b[31] && y[31]);
//    assign suboverflow = (a[31] && !b[31] && !y[31]) || (!a[31] && b[31] && y[31]);
//    assign overflow = ((alucontrol == `ADD_CONTROL) && addoverflow) || ((alucontrol == `SUB_CONTROL) && suboverflow);
////    always@(posedge div_valid or posedge div_ready or posedge div_signed)begin
////        if(div_valid)
////            start_i = 1'b1;
////        if(div_signed)
////            signed_div_i = 1'b1;
////        if(div_ready)begin
////            start_i = 1'b0;
////            signed_div_i = 1'b0;
////        end
////    end
    
//    always @(*) begin
//        hilo_i = 64'b0;
//        if(rst) begin
//            div_stall = 1'b0;
//            div_start = 1'b0;
//        end
//        case (alucontrol)
//            `AND_CONTROL: y <= a & b;
//            `OR_CONTROL: y <= a | b;
//            `XOR_CONTROL: y <= a ^ b;
//            `NOR_CONTROL: y <= ~ (a | b);
//            `LUI_CONTROL: y <= {b[15:0], 16'b0};
//             //移位指令
//            `SLL_CONTROL: y<= b << sa;
//            `SRL_CONTROL: y<= b >> sa;
//            `SRA_CONTROL: y<= ( {32{b[31]}} << (6'd32 - {1'b0,sa}) ) | b >> sa;
//            //`SRA_CONTROL: y<= $signed(b) >>> sa;
//            `SLLV_CONTROL: y<= b << a[4:0];
//            `SRLV_CONTROL: y<= b >> a[4:0];
//            `SRAV_CONTROL: y<= ( {32{b[31]}} << (6'd32 - {1'b0,a[4:0]}) ) | b >> a[4:0];
//           //`SRAV_CONTROL: y<= $signed(b) >>> a[4:0];
//           //数据移动指令
//            `MFHI_CONTROL: y <= hilo_o[63:32];
//            `MFLO_CONTROL: y <= hilo_o[31:0];
//            `MTHI_CONTROL: hilo_i <= {a, hilo_o[31:0]};
//            `MTLO_CONTROL: hilo_i <= {hilo_o[63:32],a}; 
//            //算术运算指令
//            `ADD_CONTROL:y<=$signed(a) + $signed(b);
//            `ADDU_CONTROL: y <= a+b;
//            `SUB_CONTROL, `SUBU_CONTROL: y <= a + (~b + 1);
//            `SLT_CONTROL: y <= $signed(a) < $signed(b);
//            `SLTU_CONTROL: y <= a < b;
//            `MULTU_CONTROL: hilo_i <= {32'b0, a} * {32'b0, b};
//            `MULT_CONTROL:  hilo_i <= $signed(a) * $signed(b);
//            `DIV_CONTROL: //hilo_i <= div_result;
//            begin //指令DIV, 除法器控制状态机逻辑
//                    if(~div_ready & ~div_start) begin //~div_start : 为了保证除法进行过程中，除法源操作数不因ALU输入改变而重新被赋值
//                        //必须非阻塞赋值，否则时序不对
//                        div_start <= 1'b1;
//                        div_signed <= 1'b1;
//                        div_stall <= 1'b1;
//                        a_save <= a; //除法时保存两个操作数
//                        b_save <= b;
//                    end
//                    else if(div_ready) begin
//                        div_start <= 1'b0;
//                        div_signed <= 1'b1;
//                        div_stall <= 1'b0;
//                        hilo_i <= div_result;
//                    end
//                end
                
//            `DIVU_CONTROL: //hilo_i <= div_result;
//            begin //指令DIVU, 除法器控制状态机逻辑
//                    if(~div_ready & ~div_start) begin //~div_start : 为了保证除法进行过程中，除法源操作数不因ALU输入改变而重新被赋值
//                        //必须非阻塞赋值，否则时序不对
//                        div_start <= 1'b1;
//                        div_signed <= 1'b0;
//                        div_stall <= 1'b1;
//                        a_save <= a; ////除法时保存两个操作数
//                        b_save <= b;
//                    end
//                    else if(div_ready) begin
//                        div_start <= 1'b0;
//                        div_signed <= 1'b0;
//                        div_stall <= 1'b0;
//                        hilo_i <= div_result;
//                    end
//                end
            
//            //特权指令
//            `MTC0_CONTROL: y <= b;
//            `MFC0_CONTROL: y <= cp0data;
//        endcase
//    end

//endmodule



//module alu(
//    input clk,rst,flushE,isexceptM,
//	input wire[31:0] a,b,
//	input wire[4:0] sa,
//	input wire[4:0] alucontrol,
//	output reg[31:0] y,
//	input[63:0] hilo_o,
//	output reg[63:0] hilo_i,
//	output wire div_stall,
//	output wire overflow,
//	input wire[31:0] cp0data
////	output wire zero
//    );
//    wire div_signed, div_cancel, div_valid;
//    wire [63:0]div_result;
//    wire div_ready;
//    reg start_i = 0 , signed_div_i = 0;
//    reg [31:0]a_save, b_save;
//    wire addoverflow, suboverflow;
//    assign div_cancel = ((alucontrol == `DIV_CONTROL)|(alucontrol == `DIVU_CONTROL)) & isexceptM;
//    assign div_signed = (alucontrol == `DIV_CONTROL);
//    assign div_valid = ~div_ready & ((alucontrol == `DIV_CONTROL)|(alucontrol == `DIVU_CONTROL));
//    div DIV(~clk,rst,div_signed,a_save,b_save,start_i,div_cancel,div_result,div_ready);
//    assign div_stall = start_i;
//    assign addoverflow = (a[31] && b[31] && !y[31]) || (!a[31 ]&& !b[31] && y[31]);
//    assign suboverflow = (a[31] && !b[31] && !y[31]) || (!a[31] && b[31] && y[31]);
//    assign overflow = ((alucontrol == `ADD_CONTROL) && addoverflow) || ((alucontrol == `SUB_CONTROL) && suboverflow);
//    always@(posedge div_valid or posedge div_ready or posedge isexceptM)begin
//        if(div_valid) begin
//			if(~isexceptM) begin
//            	start_i <= 1'b1;
//				//div_stall <= 1'b1;
//			end
//			else begin
//				if(isexceptM) begin
//            		start_i <= 1'b0;
//					//div_stall <= 1'b0;
//				end
//			end
//		end
////        if(div_signed)
////            signed_div_i <= 1'b1;
//        else begin
//            if(div_ready)begin
//                start_i <= 1'b0;
//                //signed_div_i <= 1'b0;
//				//div_stall <= 1'b0;
//            end
//        end
//    end
//	always @(*) begin
		
//        case (alucontrol)
//            `AND_CONTROL: y <= a & b;
//            `OR_CONTROL: y <= a | b;
//            `XOR_CONTROL: y <= a ^ b;
//            `NOR_CONTROL: y <= ~ (a | b);
//            `LUI_CONTROL: y <= {b[15:0], 16'b0};
//             //??λ???
//            `SLL_CONTROL: y<= b << sa;
//            `SRL_CONTROL: y<= b >> sa;
//            `SRA_CONTROL: y<= ( {32{b[31]}} << (6'd32 - {1'b0,sa}) ) | b >> sa;
//            //`SRA_CONTROL: y<= $signed(b) >>> sa;
//            `SLLV_CONTROL: y<= b << a[4:0];
//            `SRLV_CONTROL: y<= b >> a[4:0];
//            `SRAV_CONTROL: y<= ( {32{b[31]}} << (6'd32 - {1'b0,a[4:0]}) ) | b >> a[4:0];
//           //`SRAV_CONTROL: y<= $signed(b) >>> a[4:0];
//           //??????????
//            `MFHI_CONTROL: y <= hilo_o[63:32];
//            `MFLO_CONTROL: y <= hilo_o[31:0];
//            `MTHI_CONTROL: hilo_i <= {a, hilo_o[31:0]};
//            `MTLO_CONTROL: hilo_i <= {hilo_o[63:32],a}; 
//            //???????????
//            `ADD_CONTROL:y<=$signed(a) + $signed(b);
//            `ADDU_CONTROL: y <= a+b;
//            `SUB_CONTROL, `SUBU_CONTROL: y <= a + (~b + 1);
//            `SLT_CONTROL: y <= $signed(a) < $signed(b);
//            `SLTU_CONTROL: y <= a < b;
//            `MULTU_CONTROL: hilo_i <= {32'b0, a} * {32'b0, b};
//            `MULT_CONTROL:  hilo_i <= $signed(a) * $signed(b);
//            `DIV_CONTROL: begin
//                if(~div_ready & ~start_i)begin
                    
//                    //start_i <= 1'b1;
//                    //signed_div_i <= 1'b1;
//                    //div_stall <= 1'b1;
//                    a_save <= a;
//                    b_save <= b;
//                end
//                else if(div_ready)
//                    //start_i <= 1'b0;
//                    //div_stall <= 1'b0;
//                    hilo_i <= div_result;
//            end
//            `DIVU_CONTROL: begin
//                if(~div_ready & ~start_i)begin
//                    //start_i <= 1'b1;
//                    //signed_div_i <= 1'b1;
//                    //div_stall <= 1'b1;
//                    a_save <= a;
//                    b_save <= b;
//                end
//                else if(div_ready)
//                    //start_i <= 1'b0;
//                    //div_stall <= 1'b0;
//                    hilo_i <= div_result;
//            end
//            `MTC0_CONTROL: y <= b;
//            `MFC0_CONTROL: y <= cp0data;
//        endcase
//    end

//endmodule
