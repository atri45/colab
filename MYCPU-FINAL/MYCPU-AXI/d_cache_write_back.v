module d_cache_write_back (
    input wire clk, rst,
    //mips core
    input         cpu_data_req     ,
    input         cpu_data_wr      ,
    input  [1 :0] cpu_data_size    ,
    input  [31:0] cpu_data_addr    ,
    input  [31:0] cpu_data_wdata   ,
    output [31:0] cpu_data_rdata   ,
    output        cpu_data_addr_ok ,
    output        cpu_data_data_ok ,

    //axi interface
    output         cache_data_req     ,
    output         cache_data_wr      ,
    output  [1 :0] cache_data_size    ,
    output  [31:0] cache_data_addr    ,
    output  [31:0] cache_data_wdata   ,
    input   [31:0] cache_data_rdata   ,
    input          cache_data_addr_ok ,
    input          cache_data_data_ok 
);
    //Cache配置
    parameter  INDEX_WIDTH  = 10, OFFSET_WIDTH = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    
    //Cache存储单元
    reg                 cache_valid [CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag   [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block [CACHE_DEEPTH - 1 : 0];

    //访问地址分解
    wire [OFFSET_WIDTH-1:0] offset;
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    
    assign offset = cpu_data_addr[OFFSET_WIDTH - 1 : 0];
    assign index = cpu_data_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_data_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];

    //访问Cache line
    wire c_valid;
    wire c_dirty;
    wire [TAG_WIDTH-1:0] c_tag;
    wire [31:0] c_block;

    assign c_valid = cache_valid[index];
    assign c_dirty = cache_dirty[index];
    assign c_tag   = cache_tag  [index];
    assign c_block = cache_block[index];

    //判断是否命中
    wire hit, miss;
    assign hit = c_valid & (c_tag == tag);  //cache line的valid位为1，且tag与地�?中tag相等
    assign miss = ~hit;

    //读或�?
    wire read, write;
    assign write = cpu_data_wr;
    assign read = ~write;

    //clean / dirty
    wire clean, dirty;
    assign dirty = c_valid & c_dirty;   //valid后再讨论是否dirty
    assign clean = ~dirty;

    //FSM
    parameter IDLE = 2'b00, RM = 2'b01, WRM = 2'b10;    //WM: 写回内存；WRM: 先写回内存，再读内存
    reg [1:0] state;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:   state <= cpu_data_req & read & miss & clean ? RM :
                                 cpu_data_req & read & miss & dirty ? WRM :
                                 cpu_data_req & write & miss & clean ? RM :
                                 cpu_data_req & write & miss & dirty ? WRM : IDLE;
                RM:     state <= cache_data_data_ok ? IDLE : RM;
                WRM:    state <= cache_data_data_ok ? RM : WRM;
            endcase
        end
    end

    wire read_req, write_req;
    reg addr_rcv;
    wire read_finish, write_finish;
    always @(posedge clk) begin
        addr_rcv <= rst ? 1'b0 :
                    cache_data_req & cache_data_addr_ok ? 1'b1 :
                    cache_data_data_ok ? 1'b0 : addr_rcv;
    end

    assign read_req = state == RM;
    assign write_req = state == WRM;
    assign read_finish = read_req & cache_data_data_ok;
    assign write_finish = write_req & cache_data_data_ok;

    //output to mips core
    assign cpu_data_rdata   = hit ? c_block : cache_data_rdata;
    assign cpu_data_addr_ok = cpu_data_req & (hit) | (state==RM) & cache_data_addr_ok;
    assign cpu_data_data_ok = cpu_data_req & (hit) | (state==RM) & cache_data_data_ok;

    //output to axi interface
    assign cache_data_req   = (state!=IDLE) & ~addr_rcv;
    assign cache_data_wr    = write_req ? 1'b1 : 1'b0;
    assign cache_data_size  = (write_req | write) ? 2'b10 : cpu_data_size;  //写内存size均为2
    assign cache_data_addr  = write_req ? {c_tag, index, 2'b00} : cpu_data_addr;
    assign cache_data_wdata = c_block; //写内存一定是替换脏块

    //写入Cache
    //保存地址中的tag, index，防止addr发生改变
    reg [TAG_WIDTH-1:0] tag_save;
    reg [INDEX_WIDTH-1:0] index_save;
    always @(posedge clk) begin
        tag_save   <= rst ? 0 :
                      cpu_data_req ? tag : tag_save;
        index_save <= rst ? 0 :
                      cpu_data_req ? index : index_save;
    end

    wire [31:0] write_cache_data;
    wire [3:0] write_mask;

    //根据地址低两位和size，生成写掩码（针对sb，sh等不是写完整�?个字的指令）�?4位对�?1个字�?4字节）中每个字的写使�?
    assign write_mask = cpu_data_size==2'b00 ?
                            (cpu_data_addr[1] ? (cpu_data_addr[0] ? 4'b1000 : 4'b0100):
                                                (cpu_data_addr[0] ? 4'b0010 : 4'b0001)) :
                            (cpu_data_size==2'b01 ? (cpu_data_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111);

    //掩码的使用：位为1的代表需要更新的�?
    //位拓展：{8{1'b1}} -> 8'b11111111
    //new_data = old_data & ~mask | write_data & mask
    assign write_cache_data = hit ? (cache_block[index] & ~{{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}} | 
                              cpu_data_wdata & {{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}}) : 
                              (cache_data_rdata & ~{{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}} | 
                              cpu_data_wdata & {{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}});

    integer t;
    always @(posedge clk) begin
        if(rst) begin
            //cache_valid <= '{default: '0};
             for(t=0; t<CACHE_DEEPTH; t=t+1) begin   //�տ�ʼ��Cache��Ϊ��Ч
                 cache_valid[t] <= 0;
             end
        end
        else begin
            if(read_finish & read) begin //读缺失，访存结束�?
                cache_valid[index_save] <= 1'b1;
                cache_dirty[index_save] <= 1'b0;
                cache_tag  [index_save] <= tag_save;
                cache_block[index_save] <= cache_data_rdata;
            end
            else if(read_finish & write & ~hit) begin //写缺失，访存结束�?
                cache_valid[index_save] <= 1'b1;
                cache_dirty[index_save] <= 1'b1;
                cache_tag  [index_save] <= tag_save;
                cache_block[index_save] <= write_cache_data;
            end
            else if(cpu_data_req & write & hit) begin //写命中直接写Cache
                cache_valid[index] <= 1'b1;
                cache_dirty[index] <= 1'b1;
                cache_tag  [index] <= tag;
                cache_block[index] <= write_cache_data;
            end
        end
    end
endmodule