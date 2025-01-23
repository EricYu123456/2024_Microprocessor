`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/05 16:20:57
// Design Name: 
// Module Name: datafeeder2
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


module datafeeder2
#( parameter [15: 0] XLEN = 32
)(
    input clk,
    input rst,
    input EN,
    input  [18 : 0] ADDR,
    input WR, // 1: write 0:read
    input  [XLEN -1 : 0] DATAI,
    output [XLEN -1 : 0] DATAO,
    output reg READY
);
    
    reg [31:0] in_size, w_st, ppi_st, const1, ret_mode, ans_store; // MMIO reg
    assign DATAO = ans_store;
    always @(posedge clk) begin
        if(rst) in_size <= 0;
        else if(EN && (WR) && (ADDR == 19'h4_0000)) in_size <= DATAI;
    end
    always @(posedge clk) begin
        if(rst) w_st <= 0;
        else if(EN && (WR) && (ADDR == 19'h4_0004)) w_st <= DATAI;
    end
    always @(posedge clk) begin
        if(rst) ppi_st <= 0;
        else if(EN && (WR) && (ADDR == 19'h4_0008)) ppi_st <= DATAI;
    end
    always @(posedge clk) begin
        if(rst) const1 <= 0;
        else if(EN && (WR) && (ADDR == 19'h4_000c)) const1 <= DATAI;
    end
    always @(posedge clk) begin
        if(rst) ret_mode <= 0;
        else if(EN && (WR) && (ADDR == 19'h4_0010)) ret_mode <= DATAI;
    end
    reg load_weight_finish, mul_all_done, add_all_done;
    reg [31: 0] time_cnt; 
    
    reg [3: 0] S_state; 
    reg [3: 0] S_next_state;
    localparam S_INIT = 0;
    localparam S_LOAD_IN = 1;
    localparam S_LOAD_FINFSH = 2;
    localparam S_LOAD_WEIGHT = 3;
    localparam S_LOAD_ppist = 4;
    localparam S_LOAD_const1 = 5;
    localparam S_COMP_mul = 6;
    localparam S_COMP_mul_WAIT = 7;
    localparam S_COMP_add = 8;
    localparam S_COMP_add_WAIT = 9;
    localparam S_send_ans = 10;
    localparam S_DONE_PRE = 11;
    localparam S_DONE = 12;
    always @(posedge clk) begin
        if(rst) S_state <= S_INIT;
        else S_state <= S_next_state;
    end
    always @(*) begin
        case (S_state)
            S_INIT: S_next_state = (EN && (WR) && (ADDR == 19'h7_0000))? S_LOAD_WEIGHT : S_INIT; // load w_st
            S_LOAD_WEIGHT: S_next_state = (EN && (WR) && (ADDR == (19'h7_0000 + (25 - 1)*4)))? S_LOAD_IN: S_LOAD_WEIGHT; // load 25 weight
            
            S_LOAD_IN: S_next_state = (EN && (WR) && (ADDR == (19'h5_0000 + (25 - 1)*4)))? S_COMP_mul: S_LOAD_IN;
//            S_LOAD_ppist: S_next_state = (EN && (WR) && (ADDR == 19'h4_0008))? S_LOAD_const1 : S_LOAD_ppist;
//            S_LOAD_const1: S_next_state = (EN && (WR) && (ADDR == 19'h4_000c))? S_COMP_mul : S_LOAD_const1;
            S_COMP_mul: S_next_state = S_COMP_mul_WAIT;
            S_COMP_mul_WAIT: S_next_state = (mul_all_done)? S_send_ans : S_COMP_mul_WAIT;
//            S_COMP_add: S_next_state = S_COMP_add_WAIT;
//            S_COMP_add_WAIT: S_next_state = (add_all_done)? S_DONE_PRE : S_COMP_add_WAIT;
            S_send_ans: S_next_state = ((!WR) && (ADDR == 19'h4_0014))? S_DONE_PRE : S_send_ans;
            S_DONE_PRE: S_next_state = ((WR) && (ADDR == 19'h4_0010))? S_DONE : S_DONE_PRE; // load ret_mode
            S_DONE: S_next_state = (ret_mode == 0)? S_INIT : S_LOAD_IN;
            default: S_next_state = S_INIT;
        endcase
    end
    always @(posedge clk) begin
        if(S_state != S_INIT) time_cnt <= time_cnt + 1;
        else time_cnt <= 0;
    end
//    module weight_ram
//#(parameter XLEN = 32, parameter BURST_LEN = 5) // 25 elements
//(
//    input                clk_i,
//    input                we_i,
//    input  [XLEN-1 : 0]  read_addr1_i, // 0~9
//    input  [14-1 : 0]    read_addr2_i, // 0~511
//    output [BURST_LEN*XLEN-1 : 0] data_o // Output 25 elements
//);
    reg [5:0] w_st_d;
//    wire [5*32-1 : 0] weight_ram_o;
    //reg [31:0] weights [0:24];
//    weight_ram #(.XLEN(32))
//    weight_ram(
//        .clk_i(clk),
//        .we_i(1'b0),
//        .read_addr1_i(32'b0),
//        .read_addr2_i(w_st + w_st_d),
//        .data_o(weight_ram_o)
//    );
    always @(posedge clk) begin
        if(rst)begin
            w_st_d <= 0;
        end else if(S_state == S_LOAD_WEIGHT)begin
            w_st_d <= w_st_d + 5;
        end else if (w_st_d >= 25)begin
            w_st_d <= 0;
        end
    end
//    always @(posedge clk) begin
//        if(S_state == S_LOAD_WEIGHT && w_st_d <= 25)begin
//            weights[(w_st_d-5<0)?0:w_st_d-5] <= weight_ram_o[32-1:0];
//            weights[(w_st_d-4<0)?0:w_st_d-4] <= weight_ram_o[2*32-1:32];
//            weights[(w_st_d-3<0)?0:w_st_d-3] <= weight_ram_o[3*32-1:2*32];
//            weights[(w_st_d-2<0)?0:w_st_d-2] <= weight_ram_o[4*32-1:3*32];
//            weights[(w_st_d-1<0)?0:w_st_d-1] <= weight_ram_o[5*32-1:4*32];
//        end
//    end
    always @(posedge clk) begin
        if(w_st_d >= 25)begin
            load_weight_finish <= 1;
        end else if (load_weight_finish)begin
            load_weight_finish <= 0;
        end
    end
    reg [31:0] weights [0:24];
    always @(posedge clk) begin
        if((S_state == S_LOAD_WEIGHT || S_state == S_INIT)&& EN && WR && (ADDR[18:16] == 3'h7)) weights[ADDR[15:2]] <= DATAI;
    end
    reg  [31:0] in [0:24];
    always @(posedge clk) begin
        if(S_state == S_LOAD_IN && EN && WR && (ADDR[18:16] == 3'h5)) in[ADDR[15:2]] <= DATAI;
    end
    
    always @(posedge clk) begin
        if(S_state == S_LOAD_IN) READY <= 1;
        else if(EN && (WR) && (ADDR >= 19'h4_0000 && ADDR <= 19'h4_0010)) READY <= 1;
        else if(EN && (WR) && (ADDR[18:16] == 3'h5)) READY <= 1;
        else if(EN && (WR) && (ADDR[18:16] == 3'h7)) READY <= 1;
        else if(EN && (!WR) && (ADDR == 19'h4_0014) && S_state == S_send_ans) READY <= 1;
        else if((!WR) && (ADDR == 19'h4_0014) && S_state == S_send_ans)READY <= 1;
        else if((WR) && (ADDR == 19'h4_0010) && S_state == S_DONE_PRE)READY <= 1;
        else READY <= 0;
    end
    reg FP1_a_tvalid, FP1_b_tvalid;
    wire FP1_a_tready, FP1_b_tready, FP1_result_tvalid, FP1_result_tready;
    reg [32 - 1 : 0] FP1_a_tdata, FP1_b_tdata;
    wire [32-1: 0] FP1_result_tdata;
    floating_point_0 FPU1 (
    .aclk(clk),                                // input wire aclk
    .s_axis_a_tvalid(FP1_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP1_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP1_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP1_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP1_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP1_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP1_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP1_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP1_a_tvalid <= 1;
            FP1_b_tvalid <= 1;
            FP1_a_tdata <= weights[0];
//            FP1_b_tdata <= in[ppi_st];
            FP1_b_tdata <= in[0];
        end 
        else begin
            FP1_a_tvalid <= 0;
            FP1_b_tvalid <= 0;
            FP1_a_tdata <= 0;
            FP1_b_tdata <= 0;
        end
    end
    
    
    reg FP2_a_tvalid, FP2_b_tvalid;
    wire FP2_a_tready, FP2_b_tready, FP2_result_tvalid, FP2_result_tready;
    reg [32 - 1 : 0] FP2_a_tdata, FP2_b_tdata;
    wire [32-1: 0] FP2_result_tdata;
    floating_point_0 FPU2 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP2_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP2_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP2_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP2_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP2_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP2_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP2_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP2_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP2_a_tvalid <= 1;
            FP2_b_tvalid <= 1;
            FP2_a_tdata <= weights[1];
//            FP2_b_tdata <= in[ppi_st+1];
            FP2_b_tdata <= in[1];
        end
        else begin
            FP2_a_tvalid <= 0;
            FP2_b_tvalid <= 0;
            FP2_a_tdata <= 0;
            FP2_b_tdata <= 0;
        end
    end
    
    
    reg FP3_a_tvalid, FP3_b_tvalid;
    wire FP3_a_tready, FP3_b_tready, FP3_result_tvalid, FP3_result_tready;
    reg [32 - 1 : 0] FP3_a_tdata, FP3_b_tdata;
    wire [32-1: 0] FP3_result_tdata;
    floating_point_0 FPU3 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP3_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP3_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP3_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP3_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP3_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP3_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP3_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP3_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP3_a_tvalid <= 1;
            FP3_b_tvalid <= 1;
            FP3_a_tdata <= weights[2];
//            FP3_b_tdata <= in[ppi_st+2];
            FP3_b_tdata <= in[2];
        end
        else begin
            FP3_a_tvalid <= 0;
            FP3_b_tvalid <= 0;
            FP3_a_tdata <= 0;
            FP3_b_tdata <= 0;
        end
    end
    
    
    reg FP4_a_tvalid, FP4_b_tvalid;
    wire FP4_a_tready, FP4_b_tready, FP4_result_tvalid, FP4_result_tready;
    reg [32 - 1 : 0] FP4_a_tdata, FP4_b_tdata;
    wire [32-1: 0] FP4_result_tdata;
    floating_point_0 FPU4 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP4_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP4_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP4_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP4_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP4_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP4_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP4_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP4_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP4_a_tvalid <= 1;
            FP4_b_tvalid <= 1;
            FP4_a_tdata <= weights[3];
//            FP4_b_tdata <= in[ppi_st+3];
            FP4_b_tdata <= in[3];
        end
        else begin
            FP4_a_tvalid <= 0;
            FP4_b_tvalid <= 0;
            FP4_a_tdata <= 0;
            FP4_b_tdata <= 0;
        end
    end
    
    
    reg FP5_a_tvalid, FP5_b_tvalid;
    wire FP5_a_tready, FP5_b_tready, FP5_result_tvalid, FP5_result_tready;
    reg [32 - 1 : 0] FP5_a_tdata, FP5_b_tdata;
    wire [32-1: 0] FP5_result_tdata;
    floating_point_0 FPU5 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP5_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP5_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP5_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP5_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP5_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP5_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP5_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP5_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP5_a_tvalid <= 1;
            FP5_b_tvalid <= 1;
            FP5_a_tdata <= weights[4];
//            FP5_b_tdata <= in[ppi_st+4];
            FP5_b_tdata <= in[4];
        end
        else begin
            FP5_a_tvalid <= 0;
            FP5_b_tvalid <= 0;
            FP5_a_tdata <= 0;
            FP5_b_tdata <= 0;
        end
    end
    
    
    reg FP6_a_tvalid, FP6_b_tvalid;
    wire FP6_a_tready, FP6_b_tready, FP6_result_tvalid, FP6_result_tready;
    reg [32 - 1 : 0] FP6_a_tdata, FP6_b_tdata;
    wire [32-1: 0] FP6_result_tdata;
    floating_point_0 FPU6 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP6_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP6_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP6_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP6_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP6_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP6_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP6_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP6_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP6_a_tvalid <= 1;
            FP6_b_tvalid <= 1;
            FP6_a_tdata <= weights[5];
//            FP6_b_tdata <= in[ppi_st+5+const1];
            FP6_b_tdata <= in[5];
        end
        else begin
            FP6_a_tvalid <= 0;
            FP6_b_tvalid <= 0;
            FP6_a_tdata <= 0;
            FP6_b_tdata <= 0;
        end
    end
    
    
    reg FP7_a_tvalid, FP7_b_tvalid;
    wire FP7_a_tready, FP7_b_tready, FP7_result_tvalid, FP7_result_tready;
    reg [32 - 1 : 0] FP7_a_tdata, FP7_b_tdata;
    wire [32-1: 0] FP7_result_tdata;
    floating_point_0 FPU7 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP7_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP7_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP7_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP7_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP7_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP7_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP7_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP7_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP7_a_tvalid <= 1;
            FP7_b_tvalid <= 1;
            FP7_a_tdata <= weights[6];
//            FP7_b_tdata <= in[ppi_st+6+const1];
            FP7_b_tdata <= in[6];
        end
        else begin
            FP7_a_tvalid <= 0;
            FP7_b_tvalid <= 0;
            FP7_a_tdata <= 0;
            FP7_b_tdata <= 0;
        end
    end
    
    
    reg FP8_a_tvalid, FP8_b_tvalid;
    wire FP8_a_tready, FP8_b_tready, FP8_result_tvalid, FP8_result_tready;
    reg [32 - 1 : 0] FP8_a_tdata, FP8_b_tdata;
    wire [32-1: 0] FP8_result_tdata;
    floating_point_0 FPU8 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP8_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP8_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP8_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP8_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP8_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP8_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP8_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP8_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP8_a_tvalid <= 1;
            FP8_b_tvalid <= 1;
            FP8_a_tdata <= weights[7];
//            FP8_b_tdata <= in[ppi_st+7+const1];
            FP8_b_tdata <= in[7];
        end
        else begin
            FP8_a_tvalid <= 0;
            FP8_b_tvalid <= 0;
            FP8_a_tdata <= 0;
            FP8_b_tdata <= 0;
        end
    end
    
    
    reg FP9_a_tvalid, FP9_b_tvalid;
    wire FP9_a_tready, FP9_b_tready, FP9_result_tvalid, FP9_result_tready;
    reg [32 - 1 : 0] FP9_a_tdata, FP9_b_tdata;
    wire [32-1: 0] FP9_result_tdata;
    floating_point_0 FPU9 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP9_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP9_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP9_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP9_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP9_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP9_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP9_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP9_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP9_a_tvalid <= 1;
            FP9_b_tvalid <= 1;
            FP9_a_tdata <= weights[8];
//            FP9_b_tdata <= in[ppi_st+8+const1];
            FP9_b_tdata <= in[8];
        end
        else begin
            FP9_a_tvalid <= 0;
            FP9_b_tvalid <= 0;
            FP9_a_tdata <= 0;
            FP9_b_tdata <= 0;
        end
    end
    reg FP10_a_tvalid, FP10_b_tvalid;
    wire FP10_a_tready, FP10_b_tready, FP10_result_tvalid, FP10_result_tready;
    reg [32 - 1 : 0] FP10_a_tdata, FP10_b_tdata;
    wire [32-1: 0] FP10_result_tdata;
    floating_point_0 FPU10 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP10_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP10_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP10_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP10_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP10_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP10_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP10_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP10_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP10_a_tvalid <= 1;
            FP10_b_tvalid <= 1;
            FP10_a_tdata <= weights[9];
//            FP10_b_tdata <= in[ppi_st+9+const1];
            FP10_b_tdata <= in[9];
        end
        else begin
            FP10_a_tvalid <= 0;
            FP10_b_tvalid <= 0;
            FP10_a_tdata <= 0;
            FP10_b_tdata <= 0;
        end
    end
    
    
    reg FP11_a_tvalid, FP11_b_tvalid;
    wire FP11_a_tready, FP11_b_tready, FP11_result_tvalid, FP11_result_tready;
    reg [32 - 1 : 0] FP11_a_tdata, FP11_b_tdata;
    wire [32-1: 0] FP11_result_tdata;
    floating_point_0 FPU11 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP11_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP11_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP11_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP11_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP11_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP11_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP11_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP11_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP11_a_tvalid <= 1;
            FP11_b_tvalid <= 1;
            FP11_a_tdata <= weights[10];
//            FP11_b_tdata <= in[ppi_st+10+const1*2];
            FP11_b_tdata <= in[10];
        end
        else begin
            FP11_a_tvalid <= 0;
            FP11_b_tvalid <= 0;
            FP11_a_tdata <= 0;
            FP11_b_tdata <= 0;
        end
    end

    reg FP12_a_tvalid, FP12_b_tvalid;
    wire FP12_a_tready, FP12_b_tready, FP12_result_tvalid, FP12_result_tready;
    reg [32 - 1 : 0] FP12_a_tdata, FP12_b_tdata;
    wire [32-1: 0] FP12_result_tdata;
    floating_point_0 FPU12 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP12_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP12_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP12_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP12_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP12_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP12_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP12_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP12_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP12_a_tvalid <= 1;
            FP12_b_tvalid <= 1;
            FP12_a_tdata <= weights[11];
//            FP12_b_tdata <= in[ppi_st+11+const1*2];
            FP12_b_tdata <= in[11];
        end
        else begin
            FP12_a_tvalid <= 0;
            FP12_b_tvalid <= 0;
            FP12_a_tdata <= 0;
            FP12_b_tdata <= 0;
        end
    end

    reg FP13_a_tvalid, FP13_b_tvalid;
    wire FP13_a_tready, FP13_b_tready, FP13_result_tvalid, FP13_result_tready;
    reg [32 - 1 : 0] FP13_a_tdata, FP13_b_tdata;
    wire [32-1: 0] FP13_result_tdata;
    floating_point_0 FPU13 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP13_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP13_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP13_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP13_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP13_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP13_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP13_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP13_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP13_a_tvalid <= 1;
            FP13_b_tvalid <= 1;
            FP13_a_tdata <= weights[12];
//            FP13_b_tdata <= in[ppi_st+12+const1*2];
            FP13_b_tdata <= in[12];
        end
        else begin
            FP13_a_tvalid <= 0;
            FP13_b_tvalid <= 0;
            FP13_a_tdata <= 0;
            FP13_b_tdata <= 0;
        end
    end

    reg FP14_a_tvalid, FP14_b_tvalid;
    wire FP14_a_tready, FP14_b_tready, FP14_result_tvalid, FP14_result_tready;
    reg [32 - 1 : 0] FP14_a_tdata, FP14_b_tdata;
    wire [32-1: 0] FP14_result_tdata;
    floating_point_0 FPU14 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP14_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP14_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP14_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP14_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP14_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP14_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP14_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP14_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP14_a_tvalid <= 1;
            FP14_b_tvalid <= 1;
            FP14_a_tdata <= weights[13];
//            FP14_b_tdata <= in[ppi_st+13+const1*2];
            FP14_b_tdata <= in[13];
        end
        else begin
            FP14_a_tvalid <= 0;
            FP14_b_tvalid <= 0;
            FP14_a_tdata <= 0;
            FP14_b_tdata <= 0;
        end
    end


    reg FP15_a_tvalid, FP15_b_tvalid;
    wire FP15_a_tready, FP15_b_tready, FP15_result_tvalid, FP15_result_tready;
    reg [32 - 1 : 0] FP15_a_tdata, FP15_b_tdata;
    wire [32-1: 0] FP15_result_tdata;
    floating_point_0 FPU15 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP15_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP15_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP15_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP15_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP15_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP15_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP15_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP15_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP15_a_tvalid <= 1;
            FP15_b_tvalid <= 1;
            FP15_a_tdata <= weights[14];
//            FP15_b_tdata <= in[ppi_st+14+const1*2];
            FP15_b_tdata <= in[14];
        end
        else begin
            FP15_a_tvalid <= 0;
            FP15_b_tvalid <= 0;
            FP15_a_tdata <= 0;
            FP15_b_tdata <= 0;
        end
    end


    reg FP16_a_tvalid, FP16_b_tvalid;
    wire FP16_a_tready, FP16_b_tready, FP16_result_tvalid, FP16_result_tready;
    reg [32 - 1 : 0] FP16_a_tdata, FP16_b_tdata;
    wire [32-1: 0] FP16_result_tdata;
    floating_point_0 FPU16 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP16_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP16_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP16_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP16_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP16_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP16_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP16_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP16_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP16_a_tvalid <= 1;
            FP16_b_tvalid <= 1;
            FP16_a_tdata <= weights[15];
//            FP16_b_tdata <= in[ppi_st+15+const1*3];
            FP16_b_tdata <= in[15];
        end
        else begin
            FP16_a_tvalid <= 0;
            FP16_b_tvalid <= 0;
            FP16_a_tdata <= 0;
            FP16_b_tdata <= 0;
        end
    end
    
    reg FP17_a_tvalid, FP17_b_tvalid;
    wire FP17_a_tready, FP17_b_tready, FP17_result_tvalid, FP17_result_tready;
    reg [32 - 1 : 0] FP17_a_tdata, FP17_b_tdata;
    wire [32-1: 0] FP17_result_tdata;
    floating_point_0 FPU17 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP17_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP17_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP17_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP17_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP17_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP17_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP17_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP17_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP17_a_tvalid <= 1;
            FP17_b_tvalid <= 1;
            FP17_a_tdata <= weights[16];
//            FP17_b_tdata <= in[ppi_st+16+const1*3];
            FP17_b_tdata <= in[16];
        end
        else begin
            FP17_a_tvalid <= 0;
            FP17_b_tvalid <= 0;
            FP17_a_tdata <= 0;
            FP17_b_tdata <= 0;
        end
    end
    
    reg FP18_a_tvalid, FP18_b_tvalid;
    wire FP18_a_tready, FP18_b_tready, FP18_result_tvalid, FP18_result_tready;
    reg [32 - 1 : 0] FP18_a_tdata, FP18_b_tdata;
    wire [32-1: 0] FP18_result_tdata;
    floating_point_0 FPU18 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP18_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP18_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP18_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP18_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP18_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP18_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP18_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP18_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP18_a_tvalid <= 1;
            FP18_b_tvalid <= 1;
            FP18_a_tdata <= weights[17];
//            FP18_b_tdata <= in[ppi_st+17+const1*3];
            FP18_b_tdata <= in[17];
        end
        else begin
            FP18_a_tvalid <= 0;
            FP18_b_tvalid <= 0;
            FP18_a_tdata <= 0;
            FP18_b_tdata <= 0;
        end
    end
    reg FP19_a_tvalid, FP19_b_tvalid;
    wire FP19_a_tready, FP19_b_tready, FP19_result_tvalid, FP19_result_tready;
    reg [32 - 1 : 0] FP19_a_tdata, FP19_b_tdata;
    wire [32-1: 0] FP19_result_tdata;
    floating_point_0 FPU19 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP19_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP19_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP19_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP19_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP19_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP19_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP19_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP19_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP19_a_tvalid <= 1;
            FP19_b_tvalid <= 1;
            FP19_a_tdata <= weights[18];
//            FP19_b_tdata <= in[ppi_st+18+const1*3];
            FP19_b_tdata <= in[18];
        end
        else begin
            FP19_a_tvalid <= 0;
            FP19_b_tvalid <= 0;
            FP19_a_tdata <= 0;
            FP19_b_tdata <= 0;
        end
    end
    
    reg FP20_a_tvalid, FP20_b_tvalid;
    wire FP20_a_tready, FP20_b_tready, FP20_result_tvalid, FP20_result_tready;
    reg [32 - 1 : 0] FP20_a_tdata, FP20_b_tdata;
    wire [32-1: 0] FP20_result_tdata;
    floating_point_0 FPU20 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP20_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP20_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP20_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP20_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP20_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP20_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP20_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP20_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP20_a_tvalid <= 1;
            FP20_b_tvalid <= 1;
            FP20_a_tdata <= weights[19];
//            FP20_b_tdata <= in[ppi_st+19+const1*3];
            FP20_b_tdata <= in[19];
        end
        else begin
            FP20_a_tvalid <= 0;
            FP20_b_tvalid <= 0;
            FP20_a_tdata <= 0;
            FP20_b_tdata <= 0;
        end
    end
    
    reg FP21_a_tvalid, FP21_b_tvalid;
    wire FP21_a_tready, FP21_b_tready, FP21_result_tvalid, FP21_result_tready;
    reg [32 - 1 : 0] FP21_a_tdata, FP21_b_tdata;
    wire [32-1: 0] FP21_result_tdata;
    floating_point_0 FPU21 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP21_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP21_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP21_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP21_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP21_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP21_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP21_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP21_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP21_a_tvalid <= 1;
            FP21_b_tvalid <= 1;
            FP21_a_tdata <= weights[20];
//            FP21_b_tdata <= in[ppi_st+20+const1*4];
            FP21_b_tdata <= in[20];
        end
        else begin
            FP21_a_tvalid <= 0;
            FP21_b_tvalid <= 0;
            FP21_a_tdata <= 0;
            FP21_b_tdata <= 0;
        end
    end

    reg FP22_a_tvalid, FP22_b_tvalid;
    wire FP22_a_tready, FP22_b_tready, FP22_result_tvalid, FP22_result_tready;
    reg [32 - 1 : 0] FP22_a_tdata, FP22_b_tdata;
    wire [32-1: 0] FP22_result_tdata;
    floating_point_0 FPU22 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP22_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP22_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP22_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP22_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP22_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP22_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP22_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP22_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP22_a_tvalid <= 1;
            FP22_b_tvalid <= 1;
            FP22_a_tdata <= weights[21];
//            FP22_b_tdata <= in[ppi_st+21+const1*4];
            FP22_b_tdata <= in[21];
        end
        else begin
            FP22_a_tvalid <= 0;
            FP22_b_tvalid <= 0;
            FP22_a_tdata <= 0;
            FP22_b_tdata <= 0;
        end
    end

    reg FP23_a_tvalid, FP23_b_tvalid;
    wire FP23_a_tready, FP23_b_tready, FP23_result_tvalid, FP23_result_tready;
    reg [32 - 1 : 0] FP23_a_tdata, FP23_b_tdata;
    wire [32-1: 0] FP23_result_tdata;
    floating_point_0 FPU23 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP23_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP23_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP23_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP23_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP23_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP23_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP23_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP23_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP23_a_tvalid <= 1;
            FP23_b_tvalid <= 1;
            FP23_a_tdata <= weights[22];
//            FP23_b_tdata <= in[ppi_st+22+const1*4];
            FP23_b_tdata <= in[22];
        end
        else begin
            FP23_a_tvalid <= 0;
            FP23_b_tvalid <= 0;
            FP23_a_tdata <= 0;
            FP23_b_tdata <= 0;
        end
    end

    reg FP24_a_tvalid, FP24_b_tvalid;
    wire FP24_a_tready, FP24_b_tready, FP24_result_tvalid, FP24_result_tready;
    reg [32 - 1 : 0] FP24_a_tdata, FP24_b_tdata;
    wire [32-1: 0] FP24_result_tdata;
    floating_point_0 FPU24 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP24_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP24_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP24_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP24_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP24_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP24_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP24_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP24_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP24_a_tvalid <= 1;
            FP24_b_tvalid <= 1;
            FP24_a_tdata <= weights[23];
//            FP24_b_tdata <= in[ppi_st+23+const1*4];
            FP24_b_tdata <= in[23];
        end
        else begin
            FP24_a_tvalid <= 0;
            FP24_b_tvalid <= 0;
            FP24_a_tdata <= 0;
            FP24_b_tdata <= 0;
        end
    end

    reg FP25_a_tvalid, FP25_b_tvalid;
    wire FP25_a_tready, FP25_b_tready, FP25_result_tvalid, FP25_result_tready;
    reg [32 - 1 : 0] FP25_a_tdata, FP25_b_tdata;
    wire [32-1: 0] FP25_result_tdata;
    floating_point_0 FPU25 (
    .aclk(clk),                                   // input wire aclk
    .s_axis_a_tvalid(FP25_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(FP25_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP25_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP25_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(FP25_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP25_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .m_axis_result_tvalid(FP25_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(FP25_result_tready),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FP25_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    assign FP25_result_tready = (S_state == S_send_ans);
    always @(posedge clk) begin
        if(S_state == S_COMP_mul)begin 
            FP25_a_tvalid <= 1;
            FP25_b_tvalid <= 1;
            FP25_a_tdata <= weights[24];
//            FP25_b_tdata <= in[ppi_st+24+const1*4];
            FP25_b_tdata <= in[24];
        end
        else begin
            FP25_a_tvalid <= 0;
            FP25_b_tvalid <= 0;
            FP25_a_tdata <= 0;
            FP25_b_tdata <= 0;
        end
    end
    // add FPU ========================================================================
    wire FPU_add_a1_result_tvalid;
    wire [31:0] FPU_add_a1_result_tdata;
    floating_point_add FPU_add_a1 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FP1_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP1_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP2_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP2_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_a1_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_a1_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_a2_result_tvalid;
    wire [31:0] FPU_add_a2_result_tdata;
    floating_point_add FPU_add_a2 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FP3_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP3_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP4_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP4_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_a2_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_a2_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_a3_result_tvalid;
    wire [31:0] FPU_add_a3_result_tdata;
    floating_point_add FPU_add_a3 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FP5_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP5_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP6_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP6_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_a3_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_a3_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_a4_result_tvalid;
    wire [31:0] FPU_add_a4_result_tdata;
    floating_point_add FPU_add_a4 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FP7_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP7_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP8_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP8_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_a4_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_a4_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_a5_result_tvalid;
    wire [31:0] FPU_add_a5_result_tdata;
    floating_point_add FPU_add_a5 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FP9_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP9_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP10_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP10_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_a5_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_a5_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_a6_result_tvalid;
    wire [31:0] FPU_add_a6_result_tdata;
    floating_point_add FPU_add_a6 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FP11_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP11_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP12_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP12_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_a6_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_a6_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_a7_result_tvalid;
    wire [31:0] FPU_add_a7_result_tdata;
    floating_point_add FPU_add_a7 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FP13_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP13_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP14_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP14_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_a7_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_a7_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_a8_result_tvalid;
    wire [31:0] FPU_add_a8_result_tdata;
    floating_point_add FPU_add_a8 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FP15_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP15_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP16_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP16_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_a8_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_a8_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_a9_result_tvalid;
    wire [31:0] FPU_add_a9_result_tdata;
    floating_point_add FPU_add_a9 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FP17_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP17_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP18_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP18_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_a9_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_a9_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_a10_result_tvalid;
    wire [31:0] FPU_add_a10_result_tdata;
    floating_point_add FPU_add_a10 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FP19_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP19_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP20_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP20_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_a10_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_a10_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_a11_result_tvalid;
    wire [31:0] FPU_add_a11_result_tdata;
    floating_point_add FPU_add_a11 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FP21_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP21_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP22_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP22_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_a11_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_a11_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_a12_result_tvalid;
    wire [31:0] FPU_add_a12_result_tdata;
    floating_point_add FPU_add_a12 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FP23_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FP23_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FP24_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP24_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_a12_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_a12_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    // 2nd level ===============================================================================
    wire FPU_add_b1_result_tvalid;
    wire [31:0] FPU_add_b1_result_tdata;
    floating_point_add FPU_add_b1 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FPU_add_a1_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FPU_add_a1_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FPU_add_a2_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FPU_add_a2_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_b1_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_b1_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_b2_result_tvalid;
    wire [31:0] FPU_add_b2_result_tdata;
    floating_point_add FPU_add_b2 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FPU_add_a3_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FPU_add_a3_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FPU_add_a4_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FPU_add_a4_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_b2_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_b2_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_b3_result_tvalid;
    wire [31:0] FPU_add_b3_result_tdata;
    floating_point_add FPU_add_b3 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FPU_add_a5_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FPU_add_a5_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FPU_add_a6_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FPU_add_a6_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_b3_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_b3_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_b4_result_tvalid;
    wire [31:0] FPU_add_b4_result_tdata;
    floating_point_add FPU_add_b4 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FPU_add_a7_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FPU_add_a7_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FPU_add_a8_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FPU_add_a8_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_b4_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_b4_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_b5_result_tvalid;
    wire [31:0] FPU_add_b5_result_tdata;
    floating_point_add FPU_add_b5 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FPU_add_a9_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FPU_add_a9_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FPU_add_a10_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FPU_add_a10_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_b5_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_b5_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_b6_result_tvalid;
    wire [31:0] FPU_add_b6_result_tdata;
    floating_point_add FPU_add_b6 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FPU_add_a11_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FPU_add_a11_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FPU_add_a12_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FPU_add_a12_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_b6_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_b6_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    // 3rd level ==============================================================================================
    wire FPU_add_c1_result_tvalid;
    wire [31:0] FPU_add_c1_result_tdata;
    floating_point_add FPU_add_c1 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FPU_add_b1_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FPU_add_b1_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FPU_add_b2_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FPU_add_b2_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_c1_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_c1_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_c2_result_tvalid;
    wire [31:0] FPU_add_c2_result_tdata;
    floating_point_add FPU_add_c2 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FPU_add_b3_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FPU_add_b3_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FPU_add_b4_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FPU_add_b4_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_c2_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_c2_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_c3_result_tvalid;
    wire [31:0] FPU_add_c3_result_tdata;
    floating_point_add FPU_add_c3 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FPU_add_b5_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FPU_add_b5_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FPU_add_b6_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FPU_add_b6_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_c3_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_c3_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    
    // 4th level ==================================================================================================================
    wire FPU_add_d1_result_tvalid;
    wire [31:0] FPU_add_d1_result_tdata;
    floating_point_add FPU_add_d1 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FPU_add_c1_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FPU_add_c1_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FPU_add_c2_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FPU_add_c2_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_d1_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_d1_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    wire FPU_add_d2_result_tvalid;
    wire [31:0] FPU_add_d2_result_tdata;
    floating_point_add FPU_add_d2 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FPU_add_c3_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FPU_add_c3_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FPU_add_c3_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FP25_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_d2_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_d2_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    // 5th level  ==================================================================================================================
    wire FPU_add_e1_result_tvalid;
    wire [31:0] FPU_add_e1_result_tdata;
    floating_point_add FPU_add_e1 (
    .aclk(clk),                                      // input wire aclk
    .s_axis_a_tvalid(FPU_add_d1_result_tvalid),             // input wire s_axis_a_tvalid
    .s_axis_a_tready(),            // output wire s_axis_a_tready
    .s_axis_a_tdata(FPU_add_d1_result_tdata),               // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(FPU_add_d2_result_tvalid),             // input wire s_axis_b_tvalid
    .s_axis_b_tready(),            // output wire s_axis_b_tready
    .s_axis_b_tdata(FPU_add_d2_result_tdata),               // input wire [31 : 0] s_axis_b_tdata

    .m_axis_result_tvalid(FPU_add_e1_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(1'b1),  // input wire m_axis_result_tready
    .m_axis_result_tdata(FPU_add_e1_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
    );
    always @(posedge clk) begin
        if(FPU_add_e1_result_tvalid) mul_all_done <= 1;
        else mul_all_done <= 0;
    end
    always @(posedge clk) begin
        if(rst) ans_store <= 0;
        else if(FPU_add_e1_result_tvalid) ans_store <= FPU_add_e1_result_tdata;
        
    end
endmodule
