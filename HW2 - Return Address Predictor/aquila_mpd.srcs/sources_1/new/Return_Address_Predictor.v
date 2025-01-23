`timescale 1ns / 1ps
`include "aquila_config.vh"

module rap #( parameter ENTRY_NUM = 16384, parameter XLEN = 32 )
(
    // System signals
    input               clk_i,
    input               rst_i,
    input               stall_i,

    // from Program_Counter
    input  [XLEN-1 : 0] pc_i, // Addr of the next instruction to be fetched.
    input               true_ret_misprediction_i,

    // from Decode
    input               is_jal_i,
    input               is_ret_i,
    input  [XLEN-1 : 0] dec_pc_i, // Addr of the instr. just processed by decoder.

    // from Execute
    input               exe_is_ret_i,
    input               branch_taken_i,
    input               branch_misprediction_i,
    input  [XLEN-1 : 0] branch_target_addr_i, // also include jalr(ret)
    input               exe2rap_rap_return_hit,

    // to Program_Counter
    output              return_hit_o,
    // output              branch_decision_o,
    output [XLEN-1 : 0] return_target_addr_o
);
wire push, pop, empty, full, we;
wire [XLEN-1 : 0] ret_inst_tag, branch_target_addr_o;
circular_lifo_buffer#(.ENTRY_NUM(ENTRY_NUM), .XLEN(XLEN))
RAP_CLB(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .push_i(push),
    .pop_i(pop),
    .data_i(dec_pc_i + 4),
    .data_o(return_target_addr_o), // return answer
    .empty_o(empty),
    .full_o(full)
);
localparam NBITS = $clog2(ENTRY_NUM);
wire [NBITS-1 : 0]      read_addr;
wire [NBITS-1 : 0]      write_addr;
wire                    unrecord_ret_pre, unrecord_ret;
assign unrecord_ret_pre = (ret_inst_tag != pc_i); // with is_ret_i
reg unrecord_ret_pre_d, unrecord_ret_pre_dd;
assign unrecord_ret = unrecord_ret_pre_dd & is_ret_i;

reg [31:0] ret_cnt, ret_hit_cnt;

always @ (posedge clk_i)
begin
    if (rst_i) begin
        ret_hit_cnt <= 0;
    end
    else if (!stall_i & is_ret_i & exe2rap_rap_return_hit & !true_ret_misprediction_i) begin
        ret_hit_cnt <= ret_hit_cnt + 1;
    end
end
always @ (posedge clk_i)
begin
    if (rst_i) begin
        ret_cnt <= 0;
    end
    else if (!stall_i & is_ret_i) begin
        ret_cnt <= ret_cnt + 1;
    end
end
always @ (posedge clk_i)
begin
    if (rst_i) begin
        unrecord_ret_pre_d <= 1'b0;
        unrecord_ret_pre_dd <= 1'b0;
    end
    else if (!stall_i) begin
        unrecord_ret_pre_d <= unrecord_ret_pre;
        unrecord_ret_pre_dd <= unrecord_ret_pre_d;
    end
end
assign read_addr = pc_i[NBITS+1 : 2];
assign write_addr = dec_pc_i[NBITS+1 : 2];

assign we = ~stall_i & exe_is_ret_i & (branch_target_addr_i == return_target_addr_o);
distri_ram #(.ENTRY_NUM(ENTRY_NUM), .XLEN(XLEN*2)) // predict the pc of ret of a jal
RAP_BHT(
    .clk_i(clk_i),
    .we_i(we),                  
                                
    .write_addr_i(write_addr),  
    .read_addr_i(read_addr),    

    .data_i({branch_target_addr_i, dec_pc_i}), // jal_pc | ret_pc
    .data_o({branch_target_addr_o, ret_inst_tag}) // if (ret_inst_tag == pc_i) pc_i is a ret
);
assign push = is_jal_i & (~stall_i);
assign pop = (return_hit_o | unrecord_ret | true_ret_misprediction_i) & (~empty) & (~stall_i);
//assign pop = (return_hit_o | unrecord_ret) & (~empty) & (~stall_i);
assign return_hit_o = (ret_inst_tag == pc_i) & (~empty); // current_pc is consider a ret
endmodule
