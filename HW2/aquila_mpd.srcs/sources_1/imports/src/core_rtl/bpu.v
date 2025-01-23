`timescale 1ns / 1ps

`include "aquila_config.vh"

module bpu #( parameter ENTRY_NUM = 64, parameter XLEN = 32 )
(
    // System signals
    input               clk_i,
    input               rst_i,
    input               stall_i,

    // from Program_Counter
    input  [XLEN-1 : 0] pc_i, // Addr of the next instruction to be fetched.

    // from Decode
    input               is_jal_i,
    input               is_cond_branch_i,
    input  [XLEN-1 : 0] dec_pc_i, // Addr of the instr. just processed by decoder.

    // from Execute
    input               exe_is_branch_i,
    input               branch_taken_i,
    input               branch_misprediction_i,
    input  [XLEN-1 : 0] branch_target_addr_i,

    // to Program_Counter
    output              branch_hit_o,
    output              branch_decision_o,
    output [XLEN-1 : 0] branch_target_addr_o
);

localparam NBITS = $clog2(ENTRY_NUM);

wire [NBITS-1 : 0]      read_addr;
wire [NBITS-1 : 0]      write_addr;
wire [XLEN-1 : 0]       branch_inst_tag;
wire                    we;
reg                     BHT_hit_ff, BHT_hit;

// two-bit saturating counter
reg  [1 : 0]            branch_likelihood[ENTRY_NUM-1 : 0];

// HW2_part1: miss rate
reg  [31 : 0]           jal_cnt;
reg  [31 : 0]           jal_hit_cnt;
reg  [31 : 0]           branch_cnt;
reg  [31 : 0]           branch_hit_cnt;
always @(posedge clk_i)begin
    if(rst_i)begin
        jal_cnt <= 0;
        jal_hit_cnt <= 0;
        branch_cnt <= 0;
        branch_hit_cnt <= 0;
    end else if(~stall_i & is_jal_i & ~BHT_hit)begin
        jal_cnt <= jal_cnt + 1;
    end else if(~stall_i & is_jal_i & BHT_hit)begin
        jal_cnt <= jal_cnt + 1;
        jal_hit_cnt <= jal_hit_cnt + 1;
    end else if(~stall_i & is_cond_branch_i & ~BHT_hit)begin
        branch_cnt <= branch_cnt + 1;
    end else if(~stall_i & is_cond_branch_i & BHT_hit)begin
        branch_cnt <= branch_cnt + 1;
        branch_hit_cnt <= branch_hit_cnt + 1;
    end
    
end

// "we" is enabled to add a new entry to the BHT table when
// the decoded branch instruction is not in the BHT.
// CY Hsiang 0220_2020: added "~stall_i" to "we ="
assign we = ~stall_i & (is_cond_branch_i | is_jal_i) & !BHT_hit;

assign read_addr = pc_i[NBITS+2 : 2];
assign write_addr = dec_pc_i[NBITS+2 : 2];

integer idx;

always @(posedge clk_i)
begin
    if (rst_i)
    begin
        for (idx = 0; idx < ENTRY_NUM; idx = idx + 1)
            branch_likelihood[idx] <= 2'b0;
    end
    else if (stall_i)
    begin
        for (idx = 0; idx < ENTRY_NUM; idx = idx + 1)
            branch_likelihood[idx] <= branch_likelihood[idx];
    end
    else
    begin
        if (we) // Execute the branch instruction for the first time.
        begin
            branch_likelihood[write_addr] <= {branch_taken_i, branch_taken_i};
        end
        else if (exe_is_branch_i)
        begin
            case (branch_likelihood[write_addr])
                2'b00:  // strongly not taken
                    if (branch_taken_i)
                        branch_likelihood[write_addr] <= 2'b01;
                    else
                        branch_likelihood[write_addr] <= 2'b00;
                2'b01:  // weakly not taken
                    if (branch_taken_i)
                        branch_likelihood[write_addr] <= 2'b11;
                    else
                        branch_likelihood[write_addr] <= 2'b00;
                2'b10:  // weakly taken
                    if (branch_taken_i)
                        branch_likelihood[write_addr] <= 2'b11;
                    else
                        branch_likelihood[write_addr] <= 2'b00;
                2'b11:  // strongly taken
                    if (branch_taken_i)
                        branch_likelihood[write_addr] <= 2'b11;
                    else
                        branch_likelihood[write_addr] <= 2'b10;
            endcase
        end
    end
end

// ===========================================================================
//  Branch History Table (BHT). Here, we use a direct-mapping cache table to
//  store branch history. Each entry of the table contains two fields:
//  the branch_target_addr and the PC of the branch instruction (as the tag).
//
distri_ram #(.ENTRY_NUM(ENTRY_NUM), .XLEN(XLEN*2))
BPU_BHT(
    .clk_i(clk_i),
    .we_i(we),                  // Write-enabled when the instruction at the Decode
                                //   is a branch and has never been executed before.
    .write_addr_i(write_addr),  // Direct-mapping index for the branch at Decode.
    .read_addr_i(read_addr),    // Direct-mapping Index for the next PC to be fetched.

    .data_i({branch_target_addr_i, dec_pc_i}), // Input is not used when 'we' is 0.
    .data_o({branch_target_addr_o, branch_inst_tag})
);

// Delay the BHT hit flag at the Fetch stage for two clock cycles (plus stalls)
// such that it can be reused at the Execute stage for BHT update operation.
always @ (posedge clk_i)
begin
    if (rst_i) begin
        BHT_hit_ff <= 1'b0;
        BHT_hit <= 1'b0;
    end
    else if (!stall_i) begin
        BHT_hit_ff <= branch_hit_o;
        BHT_hit <= BHT_hit_ff;
    end
end

// ===========================================================================
//  Outputs signals
//
assign branch_hit_o = (branch_inst_tag == pc_i);
assign branch_decision_o = branch_likelihood[read_addr][1];

endmodule
