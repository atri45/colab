module d_cache (
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
    parameter  INDEX_WIDTH  = 10, OFFSET_WIDTH = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    
    reg                 cache_valid0 [CACHE_DEEPTH - 1 : 0];
    reg                 cache_valid1 [CACHE_DEEPTH - 1 : 0];
    reg                 cache_valid2 [CACHE_DEEPTH - 1 : 0];
    reg                 cache_valid3 [CACHE_DEEPTH - 1 : 0];

    reg [TAG_WIDTH-1:0] cache_tag0   [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag1   [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag2   [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag3   [CACHE_DEEPTH - 1 : 0];

    reg [31:0]          cache_block0 [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block1 [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block2 [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block3 [CACHE_DEEPTH - 1 : 0];

    reg                 cache_dirty0 [CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty1 [CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty2 [CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty3 [CACHE_DEEPTH - 1 : 0];

    reg[3: 0]           cache_age0   [CACHE_DEEPTH - 1 : 0];
    reg[3: 0]           cache_age1   [CACHE_DEEPTH - 1 : 0];
    reg[3: 0]           cache_age2   [CACHE_DEEPTH - 1 : 0];
    reg[3: 0]           cache_age3   [CACHE_DEEPTH - 1 : 0];
    //save the max age number
    reg[1: 0]           max_age_num  [CACHE_DEEPTH - 1 : 0];

    wire [OFFSET_WIDTH-1:0] offset;
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;

    assign offset = cpu_data_addr[OFFSET_WIDTH - 1 : 0];
    assign index = cpu_data_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_data_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];

    wire c_valid;
    wire [TAG_WIDTH-1:0] c_tag;
    wire [31:0] c_block;
    wire c_dirty;
    wire hit;
    wire[1:0] hit_num;

    assign hit  =    (cache_valid0[index] && tag == cache_tag0[index])||
                     (cache_valid1[index] && tag == cache_tag1[index])||
                     (cache_valid2[index] && tag == cache_tag2[index])||
                     (cache_valid3[index] && tag == cache_tag3[index]);

    assign hit_num = (cache_valid0[index] && tag == cache_tag0[index]) ? 0:
                     (cache_valid1[index] && tag == cache_tag1[index]) ? 1:
                     (cache_valid2[index] && tag == cache_tag2[index]) ? 2:
                     (cache_valid3[index] && tag == cache_tag3[index]) ? 3:0;

    assign c_dirty = hit && hit_num==0 ? cache_dirty0[index] : 
                     hit && hit_num==1 ? cache_dirty1[index] : 
                     hit && hit_num==2 ? cache_dirty2[index] :
                     hit && hit_num==3 ? cache_dirty3[index] : 0;

    assign c_block = hit && hit_num==0 ? cache_block0[index] : 
                     hit && hit_num==1 ? cache_block1[index] : 
                     hit && hit_num==2 ? cache_block2[index] :
                     hit && hit_num==3 ? cache_block3[index] : 0;

    assign c_tag   = (max_age_num[index]==0) ? cache_tag0[index] : (max_age_num[index]==1) ? cache_tag1[index] : 
                     (max_age_num[index]==2) ? cache_tag2[index] : (max_age_num[index]==3) ? cache_tag3[index] : 0;

    assign c_valid = hit;

    wire miss;
    assign miss = ~hit;

    wire read, write;
    assign write = cpu_data_wr;
    assign read = ~write;

    //FSM
    parameter IDLE = 2'b00, RM = 2'b01, WM = 2'b11;
    reg [1:0] state;
    wire   dram_wr_val,dram_rd_val;
    wire   dram_wr_req,dram_rd_req;
    assign dram_wr_val = dram_wr_req ? cache_data_data_ok : 0;
    assign dram_rd_val = dram_rd_req ? cache_data_data_ok : 0;
    
    assign  dram_wr_req = ( state == WM );
    assign  dram_rd_req = ( state == RM ); 

    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:   if( miss & c_dirty & cpu_data_req)
                            state   <=  WM;
                        else if( miss & cpu_data_req & read )
                            state   <=  RM;
                        else
                            state   <=  IDLE;
                WM:     if( dram_wr_val & dram_wr_req & write & cpu_data_req )
                            state   <=  IDLE;
                        else if( dram_wr_val & dram_wr_req )
                            state   <=  RM;
                        else
                            state   <=  WM;
                RM:     if ( dram_rd_val & dram_rd_req)
                            state   <=  IDLE;
                        else
                            state   <=  RM;
                default:    state   <=  IDLE;
            endcase
        end
    end

    //output to mips core
    assign cpu_data_rdata   = hit ? c_block : cache_data_rdata;
    assign cpu_data_addr_ok = hit & cpu_data_req;
    assign cpu_data_data_ok = hit & cpu_data_req;

    wire [31:0] dram_wr_addr,dram_rd_addr;
    assign  dram_wr_addr              =   {c_tag,index,2'b00};
    assign  dram_rd_addr              =   cpu_data_addr;

    //output to axi interface
    assign cache_data_req   = dram_rd_req | dram_wr_req;
    assign cache_data_wr    = dram_wr_req;
    assign cache_data_size  = 2'b10;
    assign cache_data_addr  = dram_wr_req ? dram_wr_addr : dram_rd_req ? dram_rd_addr : 32'b0;
    assign cache_data_wdata = c_block;

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

    assign write_mask = cpu_data_size==2'b00 ?
                            (cpu_data_addr[1] ? (cpu_data_addr[0] ? 4'b1000 : 4'b0100):
                                                (cpu_data_addr[0] ? 4'b0010 : 4'b0001)) :
                            (cpu_data_size==2'b01 ? (cpu_data_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111);

    assign write_cache_data = c_block & ~{{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}} | 
                              cpu_data_wdata & {{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}};

    integer t;
    always @(posedge clk) begin
        if(rst) begin
            // cache_valid0 <= '{default:'0};
            // cache_dirty0 <= '{default:'0};
            // cache_valid1 <= '{default:'0};
            // cache_dirty1 <= '{default:'0};
            // cache_valid2 <= '{default:'0};
            // cache_dirty2 <= '{default:'0};
            // cache_valid3 <= '{default:'0};
            // cache_dirty3 <= '{default:'0};
            // cache_age0   <= '{default:'0};
            // cache_age1   <= '{default:'0};
            // cache_age2   <= '{default:'0};
            // cache_age3   <= '{default:'0};
            // max_age_num  =  '{default:2'b0};
            // for(t=0; t<CACHE_DEEPTH; t=t+1) begin
            //     cache_valid0[t] <= 0;
            //     cache_dirty0[t] <= 0;
            //     cache_valid1[t] <= 0;
            //     cache_dirty1[t] <= 0;
            //     cache_valid2[t] <= 0;
            //     cache_dirty2[t] <= 0;
            //     cache_valid3[t] <= 0;
            //     cache_dirty3[t] <= 0;
            //     cache_age0[t]   <= 1;
            //     cache_age1[t]   <= 1;
            //     cache_age2[t]   <= 1;
            //     cache_age3[t]   <= 1;
            //     max_age_num[t]  =  2'b0;
            // end
        end
        else begin
            if(dram_wr_val)begin // read miss and cache_line dirty, finish write memory
                case(max_age_num[index_save])
                    2'd0 : cache_dirty0[index_save] <= 1'b0;
                    2'd1 : cache_dirty1[index_save] <= 1'b0;
                    2'd2 : cache_dirty2[index_save] <= 1'b0;
                    2'd3 : cache_dirty3[index_save] <= 1'b0;
                endcase
            end
            else if(write & cpu_data_req & hit)begin
                case(hit_num)
                    2'd0: begin
                        cache_block0[index] <= write_cache_data;
                        cache_dirty0[index] <= 1'b1;
                    end
                    2'd1: begin
                        cache_block1[index] <= write_cache_data;
                        cache_dirty1[index] <= 1'b1;
                    end
                    2'd2: begin
                        cache_block2[index] <= write_cache_data;
                        cache_dirty2[index] <= 1'b1;
                    end
                    2'd3: begin
                        cache_block3[index] <= write_cache_data;
                        cache_dirty3[index] <= 1'b1;
                    end
                endcase
            end
            else if(write & cpu_data_req & 
            (~cache_dirty0[index] | ~cache_dirty1[index] | ~cache_dirty2[index] | ~cache_dirty3[index]))begin // just write into cache_line if it is clean
                if (~cache_dirty0[index]) begin
                    cache_valid0[index] <= 1'b1;
                    cache_tag0  [index] <= tag_save;
                    cache_block0[index] <= write_cache_data;
                    cache_dirty0[index] <= 1'b1;
                end
                else if (~cache_dirty1[index]) begin
                    cache_valid1[index] <= 1'b1;
                    cache_tag1  [index] <= tag_save;
                    cache_block1[index] <= write_cache_data;
                    cache_dirty1[index] <= 1'b1;
                end
                else if (~cache_dirty2[index]) begin
                    cache_valid2[index] <= 1'b1;
                    cache_tag2  [index] <= tag_save;
                    cache_block2[index] <= write_cache_data;
                    cache_dirty2[index] <= 1'b1;
                end
                else begin
                    cache_valid3[index] <= 1'b1;
                    cache_tag3  [index] <= tag_save;
                    cache_block3[index] <= write_cache_data;
                    cache_dirty3[index] <= 1'b1;
                end
            end
            else if(dram_rd_val)begin //the cache_line is must be clean if reading memory happened
                case(max_age_num[index])
                    2'd0: begin
                        cache_valid0[index_save] <= 1'b1;
                        cache_tag0 [index_save] <= tag_save;
                        cache_block0[index_save] <= cache_data_rdata;
                    end
                    2'd1: begin
                        cache_valid1[index_save] <= 1'b1;
                        cache_tag1 [index_save] <= tag_save;
                        cache_block1[index_save] <= cache_data_rdata;
                    end
                    2'd2: begin
                        cache_valid2[index_save] <= 1'b1;
                        cache_tag2 [index_save] <= tag_save;
                        cache_block2[index_save] <= cache_data_rdata;
                    end
                    2'd3: begin
                        cache_valid3[index_save] <= 1'b1;
                        cache_tag3 [index_save] <= tag_save;
                        cache_block3[index_save] <= cache_data_rdata;
                    end
                endcase
            end
            if((0!=hit_num?cache_age0[index]+1:0)>=(1!=hit_num?cache_age1[index]+1:0)&&
            (0!=hit_num?cache_age0[index]+1:0)>=(2!=hit_num?cache_age2[index]+1:0)&&
            (0!=hit_num?cache_age0[index]+1:0)>=(3!=hit_num?cache_age3[index]+1:0)) begin
                max_age_num[index] <= 0;
            end else if((1!=hit_num?cache_age1[index]+1:0)>=(0!=hit_num?cache_age0[index]+1:0)&&
                        (1!=hit_num?cache_age1[index]+1:0)>=(2!=hit_num?cache_age2[index]+1:0)&&
                        (1!=hit_num?cache_age1[index]+1:0)>=(3!=hit_num?cache_age3[index]+1:0)) begin
                max_age_num[index] <= 1;
            end else if((2!=hit_num?cache_age2[index]+1:0)>=(0!=hit_num?cache_age0[index]+1:0)&&
                        (2!=hit_num?cache_age2[index]+1:0)>=(1!=hit_num?cache_age1[index]+1:0)&&
                        (2!=hit_num?cache_age2[index]+1:0)>=(3!=hit_num?cache_age3[index]+1:0)) begin
                max_age_num[index] <= 2;
            end else if((3!=hit_num?cache_age3[index]+1:0)>=(0!=hit_num?cache_age0[index]+1:0)&&
                        (3!=hit_num?cache_age3[index]+1:0)>=(1!=hit_num?cache_age1[index]+1:0)&&
                        (3!=hit_num?cache_age3[index]+1:0)>=(2!=hit_num?cache_age2[index]+1:0)) begin
                max_age_num[index] <= 3;
            end
            cache_age0[index] <= hit_num==0 ? 0 : cache_age0[index] + 1;
            cache_age1[index] <= hit_num==1 ? 0 : cache_age1[index] + 1;
            cache_age2[index] <= hit_num==2 ? 0 : cache_age2[index] + 1;
            cache_age3[index] <= hit_num==3 ? 0 : cache_age3[index] + 1;
        end
    end
endmodule