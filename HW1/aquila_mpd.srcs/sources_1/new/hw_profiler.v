`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/02 17:57:04
// Design Name: 
// Module Name: hw_profiler
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


module hw_profiler #(
    parameter XLEN = 32,
    // main()
    parameter [XLEN-1:0] PROGRAM_MAIN_START = 32'h00001088,
    parameter [XLEN-1:0] PROGRAM_MAIN_END = 32'h00002ea0,
    // core_list_find()
    parameter [XLEN-1:0] FUNC1_START = 32'h00001cfc,
    parameter [XLEN-1:0] FUNC1_END = 32'h0001d4c,
    // core_list_reverse()
    parameter [XLEN-1:0] FUNC2_START = 32'h00001d50,
    parameter [XLEN-1:0] FUNC2_END = 32'h00001d70,
    // core_state_transition()
    parameter [XLEN-1:0] FUNC3_START = 32'h000029f4,
    parameter [XLEN-1:0] FUNC3_END = 32'h00002cdc,
    // matrix_mul_matrix_bitextract()
    parameter [XLEN-1:0] FUNC4_START = 32'h00002650,
    parameter [XLEN-1:0] FUNC4_END = 32'h0000270c,
    // crcu8()
    parameter [XLEN-1:0] FUNC5_START = 32'h000019b4,
    parameter [XLEN-1:0] FUNC5_END = 32'h000019f8
)(
    // System signals
    input                 clk_i,
    input                 rst_i,
    
    // Signals from the processor
    input [XLEN-1:0]     decode_pc_i,        // PC from decode stage
    input [XLEN-1:0]     exe_pc_i,           // PC from execute stage
    input                we_i,               // write enable from exe stage
    input                re_i,               // read enable from exe stage
    input                stall_pipeline_i,   // cause by executing instr
    input                stall_data_hazard_i,// cause by decoding instr
    
    // Profile results
    output  [31:0]    total_cycles_o,
    output  [31:0]    func1_cycles_o,
    output  [31:0]    func2_cycles_o,
    output  [31:0]    func3_cycles_o,
    output  [31:0]    func4_cycles_o,
    output  [31:0]    func5_cycles_o,
    output  [31:0]    total_mem_cycles_o
    
);
    (* mark_debug = "true" *)reg [31:0]    total_cycles;
    (* mark_debug = "true" *)reg [31:0]    total_stall_cycles;
    (* mark_debug = "true" *)reg [31:0]    total_mem_cycles;
    (* mark_debug = "true" *)reg [31:0]    total_memstall_cycles;
    
    (* mark_debug = "true" *)reg [31:0]    func1_cycles;
    (* mark_debug = "true" *)reg [31:0]    func1_mem_cycles;
    (* mark_debug = "true" *)reg [31:0]    func1_stall_cycles;
    (* mark_debug = "true" *)reg [31:0]    func1_memstall_cycles;
    
    (* mark_debug = "true" *)reg [31:0]    func2_cycles;
    (* mark_debug = "true" *)reg [31:0]    func2_mem_cycles;
    (* mark_debug = "true" *)reg [31:0]    func2_stall_cycles;
    (* mark_debug = "true" *)reg [31:0]    func2_memstall_cycles;
    
    (* mark_debug = "true" *)reg [31:0]    func3_cycles;
    (* mark_debug = "true" *)reg [31:0]    func3_mem_cycles;
    (* mark_debug = "true" *)reg [31:0]    func3_stall_cycles;
    (* mark_debug = "true" *)reg [31:0]    func3_memstall_cycles;
    
    (* mark_debug = "true" *)reg [31:0]    func4_cycles;
    (* mark_debug = "true" *)reg [31:0]    func4_mem_cycles;
    (* mark_debug = "true" *)reg [31:0]    func4_stall_cycles;
    (* mark_debug = "true" *)reg [31:0]    func4_memstall_cycles;
    
    (* mark_debug = "true" *)reg [31:0]    func5_cycles;
    (* mark_debug = "true" *)reg [31:0]    func5_mem_cycles;
    (* mark_debug = "true" *)reg [31:0]    func5_stall_cycles;
    (* mark_debug = "true" *)reg [31:0]    func5_memstall_cycles;
    
    assign total_cycles_o = total_cycles;
    assign func1_cycles_o = func1_cycles;
    assign func2_cycles_o = func2_cycles;
    assign func3_cycles_o = func3_cycles;
    assign func4_cycles_o = func4_cycles;
    assign func5_cycles_o = func5_cycles;

    reg program_running;
    // crt0(), main(), crt0()
    // because pipline, pc will be PROGRAM_MAIN_END at the beginning, and then go to main()
    // when main() return, pc == PROGRAM_MAIN_END
    always @(posedge clk_i) begin
        if (rst_i || exe_pc_i == PROGRAM_MAIN_END)
            program_running <= 0;
        else if (exe_pc_i == PROGRAM_MAIN_START)
            program_running <= 1;
    end
    // Total cycle counter
    always @(posedge clk_i) begin
        if (rst_i)
            total_cycles <= 32'b0;
        else if (program_running)
            total_cycles <= total_cycles + 1;
    end
    
    // Function 1 profiling
    always @(posedge clk_i) begin
        if (rst_i)
            func1_cycles <= 32'b0;
        else if (FUNC1_START <= exe_pc_i && exe_pc_i <= FUNC1_END)
            func1_cycles <= func1_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func1_mem_cycles <= 32'b0;
        else if (FUNC1_START <= exe_pc_i && exe_pc_i <= FUNC1_END && (we_i || re_i))
            func1_mem_cycles <= func1_mem_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func1_stall_cycles <= 32'b0;
        else if (FUNC1_START <= exe_pc_i && exe_pc_i <= FUNC1_END && stall_pipeline_i)
            func1_stall_cycles <= func1_stall_cycles + 1;
        else if (FUNC1_START <= decode_pc_i && decode_pc_i <= FUNC1_END && stall_data_hazard_i)
            func1_stall_cycles <= func1_stall_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func1_memstall_cycles <= 32'b0;
        else if ((we_i || re_i)) begin
            if (FUNC1_START <= exe_pc_i && exe_pc_i <= FUNC1_END && stall_pipeline_i)
                func1_memstall_cycles <= func1_memstall_cycles + 1;
            else if (FUNC1_START <= decode_pc_i && decode_pc_i <= FUNC1_END && stall_data_hazard_i)
                func1_memstall_cycles <= func1_memstall_cycles + 1;
        end
    end
    
    // Function 2 profiling
    always @(posedge clk_i) begin
        if (rst_i)
            func2_cycles <= 32'b0;
        else if (FUNC2_START <= exe_pc_i && exe_pc_i <= FUNC2_END)
            func2_cycles <= func2_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func2_mem_cycles <= 32'b0;
        else if (FUNC2_START <= exe_pc_i && exe_pc_i <= FUNC2_END && (we_i || re_i))
            func2_mem_cycles <= func2_mem_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func2_stall_cycles <= 32'b0;
        else if (FUNC2_START <= exe_pc_i && exe_pc_i <= FUNC2_END && stall_pipeline_i)
            func2_stall_cycles <= func2_stall_cycles + 1;
        else if (FUNC2_START <= decode_pc_i && decode_pc_i <= FUNC2_END && stall_data_hazard_i)
            func2_stall_cycles <= func2_stall_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func2_memstall_cycles <= 32'b0;
        else if ((we_i || re_i)) begin
            if (FUNC2_START <= exe_pc_i && exe_pc_i <= FUNC2_END && stall_pipeline_i)
                func2_memstall_cycles <= func2_memstall_cycles + 1;
            else if (FUNC2_START <= decode_pc_i && decode_pc_i <= FUNC2_END && stall_data_hazard_i)
                func2_memstall_cycles <= func2_memstall_cycles + 1;
        end
    end
    
    // Function 3 profiling
    always @(posedge clk_i) begin
        if (rst_i)
            func3_cycles <= 32'b0;
        else if (FUNC3_START <= exe_pc_i && exe_pc_i <= FUNC3_END)
            func3_cycles <= func3_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func3_mem_cycles <= 32'b0;
        else if (FUNC3_START <= exe_pc_i && exe_pc_i <= FUNC3_END && (we_i || re_i))
            func3_mem_cycles <= func3_mem_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func3_stall_cycles <= 32'b0;
        else if (FUNC3_START <= exe_pc_i && exe_pc_i <= FUNC3_END && stall_pipeline_i)
            func3_stall_cycles <= func3_stall_cycles + 1;
        else if (FUNC1_START <= decode_pc_i && decode_pc_i <= FUNC3_END && stall_data_hazard_i)
            func3_stall_cycles <= func3_stall_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func3_memstall_cycles <= 32'b0;
        else if ((we_i || re_i)) begin
            if (FUNC3_START <= exe_pc_i && exe_pc_i <= FUNC3_END && stall_pipeline_i)
                func3_memstall_cycles <= func3_memstall_cycles + 1;
            else if (FUNC3_START <= decode_pc_i && decode_pc_i <= FUNC3_END && stall_data_hazard_i)
                func3_memstall_cycles <= func3_memstall_cycles + 1;
        end
    end

    // Function 4 profiling
    always @(posedge clk_i) begin
        if (rst_i)
            func4_cycles <= 32'b0;
        else if (FUNC4_START <= exe_pc_i && exe_pc_i <= FUNC4_END)
            func4_cycles <= func4_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func4_mem_cycles <= 32'b0;
        else if (FUNC4_START <= exe_pc_i && exe_pc_i <= FUNC4_END && (we_i || re_i))
            func4_mem_cycles <= func4_mem_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func4_stall_cycles <= 32'b0;
        else if (FUNC4_START <= exe_pc_i && exe_pc_i <= FUNC4_END && stall_pipeline_i)
            func4_stall_cycles <= func4_stall_cycles + 1;
        else if (FUNC4_START <= decode_pc_i && decode_pc_i <= FUNC4_END && stall_data_hazard_i)
            func4_stall_cycles <= func4_stall_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func4_memstall_cycles <= 32'b0;
        else if ((we_i || re_i)) begin
            if (FUNC4_START <= exe_pc_i && exe_pc_i <= FUNC4_END && stall_pipeline_i)
                func4_memstall_cycles <= func4_memstall_cycles + 1;
            else if (FUNC4_START <= decode_pc_i && decode_pc_i <= FUNC4_END && stall_data_hazard_i)
                func4_memstall_cycles <= func4_memstall_cycles + 1;
        end
    end

    // Function 5 profiling
    always @(posedge clk_i) begin
        if (rst_i)
            func5_cycles <= 32'b0;
        else if (FUNC5_START <= exe_pc_i && exe_pc_i <= FUNC5_END)
            func5_cycles <= func5_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func5_mem_cycles <= 32'b0;
        else if (FUNC5_START <= exe_pc_i && exe_pc_i <= FUNC5_END && (we_i || re_i))
            func5_mem_cycles <= func5_mem_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func5_stall_cycles <= 32'b0;
        else if (FUNC5_START <= exe_pc_i && exe_pc_i <= FUNC5_END && stall_pipeline_i)
            func5_stall_cycles <= func5_stall_cycles + 1;
        else if (FUNC5_START <= decode_pc_i && decode_pc_i <= FUNC5_END && stall_data_hazard_i)
            func5_stall_cycles <= func5_stall_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            func5_memstall_cycles <= 32'b0;
        else if ((we_i || re_i)) begin
            if (FUNC5_START <= exe_pc_i && exe_pc_i <= FUNC5_END && stall_pipeline_i)
                func5_memstall_cycles <= func5_memstall_cycles + 1;
            else if (FUNC5_START <= decode_pc_i && decode_pc_i <= FUNC5_END && stall_data_hazard_i)
                func5_memstall_cycles <= func5_memstall_cycles + 1;
        end
    end
    
    // load/store instr. caculate
    // read/write enable
    assign total_mem_cycles_o = total_mem_cycles;
    
    always @(posedge clk_i) begin
        if (rst_i)
            total_mem_cycles <= 32'b0;
        else if (program_running && (we_i || re_i))
            total_mem_cycles <= total_mem_cycles + 1;
    end
    // stall cycle caculate
    always @(posedge clk_i) begin
        if (rst_i)
            total_stall_cycles <= 32'b0;
        else if (program_running && stall_pipeline_i)
            total_stall_cycles <= total_stall_cycles + 1;
        else if (program_running && stall_data_hazard_i)
            total_stall_cycles <= total_stall_cycles + 1;
    end
    always @(posedge clk_i) begin
        if (rst_i)
            total_memstall_cycles <= 32'b0;
        else if ((we_i || re_i)) begin
            if (program_running && stall_pipeline_i)
                total_memstall_cycles <= total_memstall_cycles + 1;
            else if (program_running && stall_data_hazard_i)
                total_memstall_cycles <= total_memstall_cycles + 1;
        end
    end
    
endmodule
