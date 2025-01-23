`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/02 15:43:28
// Design Name: 
// Module Name: datafeeder1
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


module datafeeder1
#( parameter [15: 0] XLEN = 32
)(
    input clk,
    input rst,

    input EN,
    input  [17 : 0] ADDR,
    input WR, // 1: write 0:read
    input  [XLEN -1 : 0] DATAI,
    output [XLEN -1 : 0] DATAO,
    output reg READY
    );
    
    reg [31:0] target_idx; // fully_connected_layer_forward_propagation(): int i = 0; i < total_size; i++
    always @(posedge clk) begin
        if(rst) target_idx <= 0;
        else if(EN && (WR) && (ADDR == 18'h3_0000)) target_idx <= DATAI; // S_INIT -> S_COMP
    end
    
    reg [13:0] weight_ram_addr2;
//    always @(posedge clk) begin
//        if(rst) weight_ram_addr2 <= 0;
//        else if(EN && (WR) && (ADDR[17:16] == 2'b01)) weight_ram_addr2 <= ADDR[15: 2]; // S_COMP -> S_COMP_WAIT
//    end

    wire [5*32-1:0] weight_ram_o1;
    wire [31:0] weight_ram_o;
    assign weight_ram_o = weight_ram_o1[31:0];
    weight_ram #(.XLEN(32))
    weight_ram(
        .clk_i(clk),
        .we_i(1'b0),
        .read_addr1_i(target_idx),
        .read_addr2_i(weight_ram_addr2),
        .data_o(weight_ram_o1)
    );
    
    
    reg s_axis_a_tvalid, s_axis_b_tvalid, s_axis_c_tvalid;
    wire s_axis_a_tready, s_axis_b_tready, s_axis_c_tready;
    reg [32 - 1 : 0] s_axis_a_tdata, s_axis_b_tdata, s_axis_c_tdata;

    wire m_axis_result_tvalid;
    wire m_axis_result_tready;
    wire [32-1: 0] m_axis_result_tdata;
    
    reg [32-1 : 0] answer_store;
    
    floating_point_1 func1_FPU (
    .aclk(clk),                                   // input wire aclk
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
    
    
    reg [3: 0] S_state; 
    reg [3: 0] S_next_state;
    localparam S_INIT = 0;
    localparam S_COMP = 1;
    localparam S_COMP_WAIT = 2;
    localparam S_DONE = 3;
    
    always @(posedge clk) begin
        if(rst) S_state <= S_INIT;
        else S_state <= S_next_state;
    end
    
    always @(*)begin
        case (S_state)
            S_INIT: S_next_state = (EN && WR && (ADDR == 18'h3_0000))? S_COMP: S_INIT; // sent ready
            S_COMP: S_next_state = (WR && (ADDR[17:16] == 2'b10))? S_COMP_WAIT : (((!WR) && (ADDR == 18'h3_0004))? S_DONE : S_COMP); // sent ready
            S_COMP_WAIT: S_next_state = (m_axis_result_tvalid)? ((weight_ram_addr2 == 512)? S_DONE : S_COMP) : S_COMP_WAIT; // a*b+c done
            S_DONE: S_next_state = ((!WR) && (ADDR == 18'h3_0004))? S_INIT : S_DONE; // all done
            default: S_next_state = S_INIT;
        endcase
    end
    assign m_axis_result_tready = (S_state == S_COMP_WAIT && (S_next_state == S_COMP || S_next_state == S_DONE));
    
    always @(posedge clk) begin
        if(rst || (S_state == S_DONE && S_next_state == S_INIT)) weight_ram_addr2 <= 0;
        else if(S_state == S_COMP && S_next_state == S_COMP_WAIT) weight_ram_addr2 <= weight_ram_addr2 + 1; // S_COMP -> S_COMP_WAIT
    end
    
    always @(posedge clk)begin
 
        if (EN && WR && (ADDR == 18'h3_0000)) // received idx
            READY <= 1;
        else if(S_state == S_COMP && S_next_state == S_COMP_WAIT) // received data
            READY <= 1;
        else if(S_state == S_COMP_WAIT && S_next_state == S_DONE)
            READY <= 1;
        else if(S_state == S_DONE && S_next_state == S_INIT) // CPU seek answer
            READY <= 1;
        else
            READY <= 0;
    end
    always @(posedge clk) begin
        if(rst || (S_state == S_INIT && S_next_state == S_COMP))begin
            answer_store <= 0;
        end
        else if(S_state == S_COMP_WAIT && m_axis_result_tvalid)begin
            answer_store <= m_axis_result_tdata;
        end
    end
    always @(posedge clk) begin
        if(rst)begin
            s_axis_a_tdata <= 0;
            s_axis_b_tdata <= 0;
            s_axis_c_tdata <= 0;
        end
        else if(S_state == S_COMP && S_next_state == S_COMP_WAIT)begin
            s_axis_a_tdata <= weight_ram_o;
            s_axis_b_tdata <= DATAI;
            s_axis_c_tdata <= answer_store;
            
        end
    end
    
    always @(posedge clk) begin
        if(rst)begin
            s_axis_a_tvalid <= 0;
            s_axis_b_tvalid <= 0;
            s_axis_c_tvalid <= 0;
        end 
        else if(S_state == S_COMP && S_next_state == S_COMP_WAIT)begin
            s_axis_a_tvalid <= 1;
            s_axis_b_tvalid <= 1;
            s_axis_c_tvalid <= 1;
        end else begin
            s_axis_a_tvalid <= 0;
            s_axis_b_tvalid <= 0;
            s_axis_c_tvalid <= 0;
        end
    end
    
    reg [32-1:0] ans;
    assign DATAO = answer_store;
    always @(posedge clk) begin
        if(rst)begin
            ans <= 0;
        end 
        else if(S_state == S_DONE && S_next_state == S_INIT)begin
            ans <= answer_store;
        end
    end
    
    
    
    
    
endmodule
