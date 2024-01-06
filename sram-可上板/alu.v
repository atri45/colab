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
	input wire[31:0] a,b,  //������a,b
	input wire [4:0] sa,
	input wire [4:0] alucontrolE,
	output reg[31:0] result,
	input wire [63:0] hilo_in, //��ȡ��HI��LO�Ĵ�����ֵ
	output reg[63:0] hilo_out, //����д��HI��LO�Ĵ���
	output reg div_stall,   //��������ˮ����ͣ����
	output wire overflow,     //����ж�
	input wire [31:0] cp0_rdata //��ȡ��CP0�Ĵ�����ֵ
	//input wire is_except, //���ڴ����쳣ʱ���Ƴ������ˢ��
	
	
	//output wire div_ready,  //�����Ƿ����
	
	
	// output wire zero
    );

	reg double_sign; //����������˫����λ�������������
	assign overflow = (alucontrolE==`ADD_CONTROL || alucontrolE==`SUB_CONTROL) & (double_sign ^ result[31]); 

	//div
	reg div_start;
	reg div_signed;
	reg [31:0] a_save; //����ʱ������������������ֹ��ΪM�׶ε�ˢ�£��̶�����ǰ��ѡ�����źŸı䣬����alu���뷢���仯��ʹ��������
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
				//�߼�����8��
				`AND_CONTROL   :  result = a & b;  //ָ��AND��ANDI
				`OR_CONTROL    :  result = a | b;  //ָ��OR��ORI
				`XOR_CONTROL   :  result = a ^ b;  //ָ��XOR
				`NOR_CONTROL   :  result = ~(a | b);  //ָ��NOR��XORI
				`LUI_CONTROL   :  result = {b[15:0],16'b0}; //ָ��LUI
				//��λָ��6��
				`SLL_CONTROL   :  result = b << sa;  //ָ��SLL
				`SRL_CONTROL   :  result = b >> sa;  //ָ��SRL
				`SRA_CONTROL   :  result = $signed(b) >>> sa;  //ָ��SRL
				`SLLV_CONTROL  :  result = b << a[4:0];  //ָ��SLLV
				`SRLV_CONTROL  :  result = b >> a[4:0];  //ָ��SRLV
				`SRAV_CONTROL  :  result = $signed(b) >>> a[4:0]; //ָ��SRAV
				//��������ָ��14��
				`ADD_CONTROL   :  {double_sign,result} = {a[31],a} + {b[31],b}; //ָ��ADD��ADDI
				`ADDU_CONTROL  :  result = a + b; //ָ��ADDU��ADDIU
				`SUB_CONTROL   :  {double_sign,result} = {a[31],a} - {b[31],b}; //ָ��SUB
				`SUBU_CONTROL  :  result = a - b; //ָ��SUBU
				`SLT_CONTROL   :  result = $signed(a) < $signed(b) ? 32'b1 : 32'b0;  //ָ��SLT��SLTI
				`SLTU_CONTROL  :  result = a < b ? 32'b1 : 32'b0; //ָ��SLTU��SLTIU
				`MULT_CONTROL  :  hilo_out = $signed(a) * $signed(b); //ָ��MULT 
				`MULTU_CONTROL :  hilo_out = {32'b0, a} * {32'b0, b}; //ָ��MULTU
				`DIV_CONTROL   :  begin //ָ��DIV, ����������״̬���߼�
					if(~div_ready & ~div_start) begin //~div_start : Ϊ�˱�֤�������й����У�����Դ����������ALU����ı�����±���ֵ
						//�����������ֵ������ʱ�򲻶�
						div_start <= 1'b1;
						div_signed <= 1'b1;
						div_stall <= 1'b1;
						a_save <= a; //����ʱ��������������
						b_save <= b;
					end
					else if(div_ready) begin
						div_start <= 1'b0;
						div_signed <= 1'b1;
						div_stall <= 1'b0;
						hilo_out <= div_result;
					end
				end
				`DIVU_CONTROL  :  begin //ָ��DIVU, ����������״̬���߼�
					if(~div_ready & ~div_start) begin //~div_start : Ϊ�˱�֤�������й����У�����Դ����������ALU����ı�����±���ֵ
						//�����������ֵ������ʱ�򲻶�
						div_start <= 1'b1;
						div_signed <= 1'b0;
						div_stall <= 1'b1;
						a_save <= a; ////����ʱ��������������
						b_save <= b;
					end
					else if(div_ready) begin
						div_start <= 1'b0;
						div_signed <= 1'b0;
						div_stall <= 1'b0;
						hilo_out <= div_result;
					end
				end
				//�����ƶ�ָ��4��
				`MFHI_CONTROL  :  result = hilo_in[63:32]; //ָ��MFHI
				`MFLO_CONTROL  :  result = hilo_in[31:0]; //ָ��MFLO
				`MTHI_CONTROL  :  hilo_out = {a,hilo_in[31:0]}; //ָ��MTHI
				`MTLO_CONTROL  :  hilo_out = {hilo_in[63:32],a}; //ָ��MTLO
				//��дCP0
				`MFC0_CONTROL  :  result = cp0_rdata; //ָ��MFC0
				`MTC0_CONTROL  :  result = b;  //ָ��MTC0
				default        :  result = `ZeroWord;
			endcase
		end
    end
	wire annul; //��ֹ�����ź�
	assign annul = ((alucontrolE == `DIV_CONTROL)|(alucontrolE == `DIVU_CONTROL)) & is_except;
	//���������
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
//    reg [31:0] a_save; //����ʱ������������������ֹ��ΪM�׶ε�ˢ�£��̶�����ǰ��ѡ�����źŸı䣬����alu���뷢���仯��ʹ��������
//    reg [31:0] b_save;
    
//    wire [63:0]div_result;
    
//    //wire div_signed, div_cancel, div_valid;
    
//    wire div_ready;
//    wire annul; //��ֹ�����ź�
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
//             //��λָ��
//            `SLL_CONTROL: y<= b << sa;
//            `SRL_CONTROL: y<= b >> sa;
//            `SRA_CONTROL: y<= ( {32{b[31]}} << (6'd32 - {1'b0,sa}) ) | b >> sa;
//            //`SRA_CONTROL: y<= $signed(b) >>> sa;
//            `SLLV_CONTROL: y<= b << a[4:0];
//            `SRLV_CONTROL: y<= b >> a[4:0];
//            `SRAV_CONTROL: y<= ( {32{b[31]}} << (6'd32 - {1'b0,a[4:0]}) ) | b >> a[4:0];
//           //`SRAV_CONTROL: y<= $signed(b) >>> a[4:0];
//           //�����ƶ�ָ��
//            `MFHI_CONTROL: y <= hilo_o[63:32];
//            `MFLO_CONTROL: y <= hilo_o[31:0];
//            `MTHI_CONTROL: hilo_i <= {a, hilo_o[31:0]};
//            `MTLO_CONTROL: hilo_i <= {hilo_o[63:32],a}; 
//            //��������ָ��
//            `ADD_CONTROL:y<=$signed(a) + $signed(b);
//            `ADDU_CONTROL: y <= a+b;
//            `SUB_CONTROL, `SUBU_CONTROL: y <= a + (~b + 1);
//            `SLT_CONTROL: y <= $signed(a) < $signed(b);
//            `SLTU_CONTROL: y <= a < b;
//            `MULTU_CONTROL: hilo_i <= {32'b0, a} * {32'b0, b};
//            `MULT_CONTROL:  hilo_i <= $signed(a) * $signed(b);
//            `DIV_CONTROL: //hilo_i <= div_result;
//            begin //ָ��DIV, ����������״̬���߼�
//                    if(~div_ready & ~div_start) begin //~div_start : Ϊ�˱�֤�������й����У�����Դ����������ALU����ı�����±���ֵ
//                        //�����������ֵ������ʱ�򲻶�
//                        div_start <= 1'b1;
//                        div_signed <= 1'b1;
//                        div_stall <= 1'b1;
//                        a_save <= a; //����ʱ��������������
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
//            begin //ָ��DIVU, ����������״̬���߼�
//                    if(~div_ready & ~div_start) begin //~div_start : Ϊ�˱�֤�������й����У�����Դ����������ALU����ı�����±���ֵ
//                        //�����������ֵ������ʱ�򲻶�
//                        div_start <= 1'b1;
//                        div_signed <= 1'b0;
//                        div_stall <= 1'b1;
//                        a_save <= a; ////����ʱ��������������
//                        b_save <= b;
//                    end
//                    else if(div_ready) begin
//                        div_start <= 1'b0;
//                        div_signed <= 1'b0;
//                        div_stall <= 1'b0;
//                        hilo_i <= div_result;
//                    end
//                end
            
//            //��Ȩָ��
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
//             //??��???
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
