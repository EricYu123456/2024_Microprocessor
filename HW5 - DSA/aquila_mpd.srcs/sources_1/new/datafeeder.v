`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/28 13:11:34
// Design Name: 
// Module Name: datafeeder
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

//       [1] 0xC400_0000 - 0xC4FF_FFFF : DSA device

// 0xc400_0000 ~ 0xc400_FFFF A array
// 0xc401_0000 ~ 0xc401_FFFF B array
// 0xc402_0000  number count
// 0xc403_0000 Answer

module datafeeder
#(
   parameter [15: 0] XLEN = 32,
   parameter [31: 0] BUF_LEN = 8 // buffers both a and b
) (
    input clk,   // clock
    input rst,   // reset

    (* mark_debug = "true" *)input EN,
    (* mark_debug = "true" *)input [17 : 0] ADDR,
    (* mark_debug = "true" *)input WR, // 1: write 0:read
    (* mark_debug = "true" *)input [XLEN -1 : 0] DATAI,
    output [XLEN -1 : 0] DATAO,
    output reg READY
    );


    (* mark_debug = "true" *)reg [32 - 1: 0] target_num;
    (* mark_debug = "true" *)reg [32 - 1: 0] answer_store;


    (* mark_debug = "true" *)reg [3: 0] A_state; // 管理緩衝區的數據填充、處理完成後返回初始化的邏輯。
    (* mark_debug = "true" *)reg [3: 0] A_nextstate;
    localparam A_INIT = 0;
    localparam A_FILL = 1;
    localparam A_LOAD = 2;
    
    (* mark_debug = "true" *)reg [3: 0] S_state; // 控制浮點運算單元的工作流程，包括數據讀取、運算、結果保存等。
    (* mark_debug = "true" *)reg [3: 0] S_next_state;
    localparam S_INIT = 0;
    localparam S_COMP = 1;
    localparam S_COMP_WAIT = 2;
    localparam S_COMP_PREP = 3;
    localparam S_DONE = 4;
    
    (* mark_debug = "true" *)reg final_done;

    always @(posedge clk ) begin
        if(rst) A_state <= A_INIT;
        else A_state <= A_nextstate;
    end
    
    (* mark_debug = "true" *)reg load_ab_done;
    
    always @(*) begin
        case (A_state)
            A_INIT: A_nextstate = (EN && (WR) && (ADDR == 18'h2_0000))? A_FILL : A_INIT;
            A_FILL: A_nextstate = (EN && (WR) && (ADDR == (18'h1_0000 + (target_num - 1)*4)))? A_LOAD: A_FILL;
            // A_LOAD: A_nextstate = (EN && (~WR) && (ADDR == 18'h3_0000) && S_state == S_DONE)? A_INIT: A_LOAD;
            A_LOAD: A_nextstate = (final_done && S_state == S_DONE)? A_INIT: A_LOAD;
            default: A_nextstate = A_INIT;
        endcase
    end



    always @(posedge clk ) begin
        if(rst) target_num <= 0;
        else if(EN && (WR) && (ADDR == 18'h2_0000)) target_num <= DATAI;
    end

    (* mark_debug = "true" *)reg [$clog2(BUF_LEN): 0] bufread_addr;    //the address to read RAM to FPU
    (* mark_debug = "true" *)reg [$clog2(BUF_LEN): 0] bufread_upbound; //the upper bound of read (num)
    
    (* mark_debug = "true" *)wire [XLEN-1 :0] buff1data_o;
    (* mark_debug = "true" *)wire [XLEN-1 :0] buff2data_o;
    
    

    wire writetoram_ok = EN && WR && (ADDR[15 :2] >= 0) && (ADDR[15: 2] < BUF_LEN);
    
    distri_ram #(.ENTRY_NUM(BUF_LEN), .XLEN(XLEN))
    buffer_1(
        .clk_i(clk),
        .we_i((ADDR[17:16] == 2'b00) && writetoram_ok), // Enabled when the instruction at Decode.
        .write_addr_i(ADDR[15: 2]),        // Write addr for the instruction at Decode.
        .read_addr_i(bufread_addr),         // Read addr for Fetch.
        .data_i(DATAI), // Valid at the next cycle (instr. at Execute).
        .data_o(buff1data_o)  // Combinational read data (same cycle at Fetch).
    );

    distri_ram #(.ENTRY_NUM(BUF_LEN), .XLEN(XLEN))
    buffer_2(
        .clk_i(clk),
        .we_i((ADDR[17:16] == 2'b01) && writetoram_ok), // Enabled when the instruction at Decode.
        .write_addr_i(ADDR[15: 2]),        // Write addr for the instruction at Decode.
        .read_addr_i(bufread_addr),         // Read addr for Fetch.
        .data_i(DATAI), // Valid at the next cycle (instr. at Execute).
        .data_o(buff2data_o)  // Combinational read data (same cycle at Fetch).
    );
    
//    (* mark_debug = "true" *)wire [31:0] weight_ram_o;
//    weight_ram #(.XLEN(32))
//    weight_ram(
//        .clk_i(clk),
//        .we_i(1'b0),
//        .read_addr1_i(32'h0),
//        .read_addr2_i(bufread_addr),
//        .data_o(weight_ram_o)
//    );
    
    always @(posedge clk) begin
        if(rst) load_ab_done <= 0;
        else if((ADDR[17:16] == 2'b01) && writetoram_ok) load_ab_done <= 1;
        else if(S_state == S_COMP && load_ab_done) load_ab_done <= 0;
    end
    
    always @(posedge clk ) begin
        if(rst) bufread_upbound <= 0;
        // else if(A_state == A_INIT) bufread_upbound <= 0;
        else if(A_state == A_FILL)begin
            if((ADDR[17:16] == 2'b01) && writetoram_ok) bufread_upbound <= ADDR[15: 2]+1;
        end
    end



    (* mark_debug = "true" *)reg s_axis_a_tvalid, s_axis_b_tvalid, s_axis_c_tvalid;
    (* mark_debug = "true" *)wire s_axis_a_tready, s_axis_b_tready, s_axis_c_tready;
    (* mark_debug = "true" *)reg [32 - 1 : 0] s_axis_a_tdata, s_axis_b_tdata, s_axis_c_tdata;

    (* mark_debug = "true" *)wire m_axis_result_tvalid;
    (* mark_debug = "true" *)wire m_axis_result_tready;
    (* mark_debug = "true" *)wire [32-1: 0] m_axis_result_tdata;
    
    

    floating_point_0 your_instance_name (
    .aclk(clk),                                  // input wire aclk
    .s_axis_a_tvalid(s_axis_a_tvalid),            // input wire s_axis_a_tvalid
    .s_axis_a_tready(s_axis_a_tready),            // output wire s_axis_a_tready
    .s_axis_a_tdata(s_axis_a_tdata),              // input wire [31 : 0] s_axis_a_tdata
    
    .s_axis_b_tvalid(s_axis_b_tvalid),            // input wire s_axis_b_tvalid
    .s_axis_b_tready(s_axis_b_tready),            // output wire s_axis_b_tready
    .s_axis_b_tdata(s_axis_b_tdata),              // input wire [31 : 0] s_axis_b_tdata
    
    .s_axis_c_tvalid(s_axis_c_tvalid),            // input wire s_axis_c_tvalid
    .s_axis_c_tready(s_axis_c_tready),            // output wire s_axis_c_tready
    .s_axis_c_tdata(s_axis_c_tdata),              // input wire [31 : 0] s_axis_c_tdata
    
    .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
    .m_axis_result_tready(m_axis_result_tready),  // input wire m_axis_result_tready
    .m_axis_result_tdata(m_axis_result_tdata)     // output wire [31 : 0] m_axis_result_tdata
);   
    
    always @(posedge clk)begin
 
        if (EN && WR)
            READY <= 1;
//        else if(EN && (~WR) && (S_state == S_DONE || S_state == S_INIT))
//            READY <= 1;
        else if(ADDR[17:16] == 2'b11 && final_done)
            READY <= 1;
        else
            READY <= 0;
    end

    always @(posedge clk ) begin
        if(rst) final_done <= 0;
        else if (bufread_addr == target_num - 1 && m_axis_result_tvalid) final_done <= 1; // ans had caculated
        else if (READY && ADDR[17:16] == 2'b11) final_done <= 0; // has sent ans to CPU
    end


    always @(posedge clk ) begin
        if(rst) S_state <= S_INIT;
        else S_state <= S_next_state;
    end
    
    always @(*)begin
        case (S_state)
            S_INIT: S_next_state = (bufread_upbound > 0)? S_COMP: S_INIT;
            S_COMP: S_next_state = (load_ab_done)? S_COMP_WAIT: S_COMP;
            S_COMP_WAIT: S_next_state = (m_axis_result_tvalid && ~writetoram_ok)? S_COMP_PREP: S_COMP_WAIT;
            S_COMP_PREP: S_next_state = (bufread_addr == (target_num -1))? S_DONE:S_COMP;
            S_DONE: S_next_state = (A_state == A_INIT)? S_INIT:S_DONE;
            default: S_next_state = S_INIT;
        endcase
    end

    always @(posedge clk ) begin
        if(rst) bufread_addr <= 0;
        if(S_state == S_DONE) bufread_addr <= 0;
        else if((A_state == A_LOAD || A_state == A_FILL) && (S_state == S_COMP_PREP) && (bufread_addr < (bufread_upbound))) begin 
            bufread_addr <= bufread_addr  + 1;
        end
    end

    always @(posedge clk ) begin
        if(rst)begin
            s_axis_a_tdata <= 0;
            s_axis_b_tdata <= 0;
            s_axis_c_tdata <= 0;
        end
        else if(S_state == S_COMP)begin
            s_axis_a_tdata <= buff1data_o;
            s_axis_b_tdata <= buff2data_o;
            s_axis_c_tdata <= answer_store;
            
        end
    end


    always @(posedge clk ) begin
        if(rst)begin
            s_axis_a_tvalid <= 0;
            s_axis_b_tvalid <= 0;
            s_axis_c_tvalid <= 0;
        end 
        else if(S_state == S_COMP && (bufread_upbound > 0) && load_ab_done)begin
            s_axis_a_tvalid <= 1;
            s_axis_b_tvalid <= 1;
            s_axis_c_tvalid <= 1;
        end else begin
            s_axis_a_tvalid <= 0;
            s_axis_b_tvalid <= 0;
            s_axis_c_tvalid <= 0;
        end
    end

    assign m_axis_result_tready = (S_state == S_COMP_PREP);


    always @(posedge clk)begin
        if(rst) answer_store <= 0;
        if(A_state == A_INIT) answer_store <= 0;
        if(S_state == S_COMP_PREP) answer_store <= m_axis_result_tdata;
        if(ADDR[17:16] == 2'b11 && final_done) answer_store <= m_axis_result_tdata;
    end

    assign DATAO = answer_store;

endmodule
