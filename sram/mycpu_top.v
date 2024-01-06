module mycpu_top(
    input clk,
    input resetn,  //low active
    input wire [5:0] ext_int,
    //cpu inst sram
    output        inst_sram_en   ,
    output [3 :0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    //cpu data sram
    output        data_sram_en   ,
    output [3 :0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,
    //debug 
    output [31:0] debug_wb_pc,     
    output [3 :0] debug_wb_rf_wen,  
    output [4 :0] debug_wb_rf_wnum, 
    output [31:0] debug_wb_rf_wdata
);

// �?个例�?
	wire [31:0] pc;
	wire [31:0] instr;
	wire memwrite;
	wire memread;
	wire [3:0] select;
	wire [31:0] aluout, writedata, readdata;
    wire [31:0] pcW;
    wire regwriteW;
	wire [4:0] writeregW;
	wire [31:0] resultW;
	wire no_dcache;
    mips mips(
        .clk(~clk),
        .rst(~resetn),
        .ext_int(ext_int),
        //instr
        // .inst_en(inst_en),
        .pcF(pc),                    //pcF
        .instrF(instr),              //instrF
        //data
        // .data_en(data_en),
        .memwriteM(memwrite),
        .memreadM(memread),
        .aluoutM(aluout),
        .writedataM(writedata),
        .selectM(select),
        .readdataM(readdata),
        .pcW(pcW),.regwriteW(regwriteW),.writeregW(writeregW),.resultW(resultW)
    );
    mmu mmu(
        .inst_vaddr(pc),
        .inst_paddr(inst_sram_addr),
        .data_vaddr(aluout),
        .data_paddr(data_sram_addr),
        .no_dcache(no_dcache)
    );

    assign inst_sram_en = 1'b1;     //如果有inst_en，就用inst_en
    assign inst_sram_wen = 4'b0;
    assign inst_sram_wdata = 32'b0;
    assign instr = inst_sram_rdata;

    assign data_sram_en = (memread|memwrite);     //?????data_en??????data_en
    assign data_sram_wen = select;
    //assign data_sram_addr = aluout;
    assign data_sram_wdata = writedata;
    assign readdata = data_sram_rdata;
    
    assign debug_wb_pc = pcW;
    assign debug_wb_rf_wen = {4{regwriteW}};
    assign debug_wb_rf_wnum = writeregW; 
    assign debug_wb_rf_wdata = resultW;

    //ascii
    instdec instdec(
        .instr(instr)
    );

endmodule