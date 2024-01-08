`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/26 21:25:26
// Design Name: 
// Module Name: pc
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


module pc #(parameter WIDTH = 8)(
input wire clk,rst,en,flush,
input wire[WIDTH-1:0] d,
input wire[WIDTH-1:0] newpc,
output reg[WIDTH-1:0] q
    );

initial begin
    q<=32'hbfc00000;
end

always @(posedge clk) begin
    if(rst)
        q <= 32'hbfc00000;
    else if(flush)
        q <= newpc;
    else if(en)
        q <= d;
    else
        q <= q;
end
endmodule
