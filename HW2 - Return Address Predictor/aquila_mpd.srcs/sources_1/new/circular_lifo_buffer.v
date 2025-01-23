`timescale 1ns / 1ps

module circular_lifo_buffer
#(parameter ENTRY_NUM = 32,
  parameter XLEN = 32,
  parameter AWDTH = $clog2(ENTRY_NUM))
(
    input                clk_i,
    input                rst_i,
    input                push_i,
    input                pop_i,
    input  [XLEN-1 : 0]  data_i,
    output [XLEN-1 : 0]  data_o,
    output               empty_o,
    output               full_o
);

    // Internal storage and pointer
    reg [XLEN-1 : 0] RAM[ENTRY_NUM-1 : 0]; // buffer
    reg [AWDTH-1 : 0] top_ptr;             // top pointer
    integer count;                         // data counter
    
    // combinational circuit
    assign data_o = RAM[top_ptr];
    assign empty_o = (count == 0);
    assign full_o = (count == ENTRY_NUM);
    
    // Initialize RAM and control signals
    integer i;
    initial begin
        for (i = 0; i < ENTRY_NUM; i = i + 1)
            RAM[i] <= 0;
        top_ptr <= 0;
        count <= 0;
        //empty_o <= 1;
        //full_o <= 0;
    end

    // Push and pop operations
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            // Reset logic
            top_ptr <= 0;
            count <= 0;
            //empty_o <= 1;
            //full_o <= 0;
        end else begin
            // Push operation
            if (push_i && !full_o) begin
                RAM[(top_ptr + 1) % ENTRY_NUM] <= data_i;
                top_ptr <= (top_ptr + 1) % ENTRY_NUM;
                count <= count + 1;
            end else if (push_i && full_o) begin
                RAM[(top_ptr + 1) % ENTRY_NUM] <= data_i;
                top_ptr <= (top_ptr + 1) % ENTRY_NUM;
            end

            // Pop operation
            if (pop_i && !empty_o) begin
                top_ptr <= (top_ptr - 1 + ENTRY_NUM) % ENTRY_NUM;
                // data_o <= RAM[top_ptr];
                count <= count - 1;
            end

            // Update empty and full status
            //empty_o <= (count == 0);
            //full_o <= (count == ENTRY_NUM);
        end
    end
endmodule
