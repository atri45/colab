module mips_core_with_sram_like(
    input clk,
    input resetn,  //low active
    input wire [5:0] ext_int,
    //instr
    output wire inst_req,
    output wire inst_wr,
    output wire [1:0] inst_size,
    output wire [31:0] inst_addr,
    output wire [31:0] inst_wdata,
    input wire inst_addr_ok,
    input wire inst_data_ok,
    input wire [31:0] inst_rdata,

    //data
    output wire data_req,
    output wire data_wr,
    output wire [1:0] data_size,
    output wire [31:0] data_addr,
    output wire [31:0] data_wdata,
    input wire data_addr_ok,
    input wire data_data_ok,
    input wire [31:0] data_rdata,
    //debug 
    output [31:0] debug_wb_pc,     
    output [3 :0] debug_wb_rf_wen,  
    output [4 :0] debug_wb_rf_wnum, 
    output [31:0] debug_wb_rf_wdata
);

    wire inst_sram_en           ;
    wire [31:0] inst_sram_addr  ;
    wire [31:0] inst_sram_rdata ;
    wire i_stall          ;

    wire data_sram_en           ;
    wire [31:0] data_sram_addr  ;
    wire [31:0] data_sram_rdata ;
    wire [3:0] data_sram_wen    ;
    wire [31:0] data_sram_wdata ;
    wire d_stall          ;
    
    wire longest_stall;
    
// ä¸?ä¸ªä¾‹å­?

	wire [31:0] instr;
    wire [31:0] pcW;
    wire regwriteW;
    wire stallW;
	wire [4:0] writeregW;
	wire [31:0] resultW;
    mips mips(
        .clk(clk),
        .rst(resetn),
        .ext_int(ext_int),
        .pcF(inst_sram_addr),                    //pcF
        .instr_enF(inst_sram_en),
        .instrF(inst_sram_rdata),              //instrF
        .i_stall(i_stall),
        .mem_enM(data_sram_en),
        .aluoutM(data_sram_addr),
        .writedataM(data_sram_wdata),
        .selectM(data_sram_wen),
        .readdataM(data_sram_rdata),
        .d_stall(d_stall),
        
         .longest_stall(longest_stall),
        
        
        .pcW(pcW),.regwriteW(regwriteW),.writeregW(writeregW),.resultW(resultW),.stallW(stallW)
    );

    wire regwrite_for_debugW = stallW ? 0 : regwriteW;
    assign debug_wb_pc = pcW;
    assign debug_wb_rf_wen = {4{regwrite_for_debugW}};
    assign debug_wb_rf_wnum = writeregW; 
    assign debug_wb_rf_wdata = resultW;

    //ascii
    instdec instdec(
        .instr(inst_sram_rdata)
    );
    
    //inst sram to sram-like
    i_sram_to_sram_like i_sram_to_sram_like(
        .clk(clk), .rst(resetn),
        //sram
        .inst_sram_en(inst_sram_en),
        .inst_sram_addr(inst_sram_addr),
        .inst_sram_rdata(inst_sram_rdata),
        .i_stall(i_stall),
        //sram like
        .inst_req(inst_req), 
        .inst_wr(inst_wr),
        .inst_size(inst_size),
        .inst_addr(inst_addr),   
        .inst_wdata(inst_wdata),
        .inst_addr_ok(inst_addr_ok),
        .inst_data_ok(inst_data_ok),
        .inst_rdata(inst_rdata),

        .longest_stall(longest_stall)
    );

    //data sram to sram-like
    d_sram_to_sram_like d_sram_to_sram_like(
        .clk(clk), .rst(resetn),
        //sram
        .data_sram_en(data_sram_en),
        .data_sram_addr(data_sram_addr),
        .data_sram_rdata(data_sram_rdata),
        .data_sram_wen(data_sram_wen),
        .data_sram_wdata(data_sram_wdata),
        .d_stall(d_stall),
        //sram like
        .data_req(data_req),    
        .data_wr(data_wr),
        .data_size(data_size),
        .data_addr(data_addr),   
        .data_wdata(data_wdata),
        .data_addr_ok(data_addr_ok),
        .data_data_ok(data_data_ok),
        .data_rdata(data_rdata),

        .longest_stall(longest_stall)
    );

endmodule