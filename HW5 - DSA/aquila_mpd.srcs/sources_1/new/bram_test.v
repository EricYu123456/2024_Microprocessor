`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/09 16:34:25
// Design Name: 
// Module Name: bram_test
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


module bram_example (
    input clk,
    input rst,
    input [14:0] addr,
    input [31:0] data_in,
    output reg [31:0] data_out,
    input we
);
    (* ram_style = "block" *) reg [31:0] ram [0:30720-1];

    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= data_in;
        end else begin
            data_out <= ram[addr];
        end
    end
endmodule

