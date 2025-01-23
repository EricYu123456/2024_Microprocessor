`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/17 20:58:06
// Design Name: 
// Module Name: random_2bit
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


module random_2bit (
    input  wire clk,      // Clock signal
    input  wire rst,      // Reset signal
    output reg  [1:0] rnd // 2-bit random number
);

    // Internal LFSR register (minimum 3 bits for randomness)
    reg [2:0] lfsr;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr <= 3'b101; // Initial seed value
        end else begin
            // LFSR with polynomial x^3 + x + 1
            lfsr <= {lfsr[1:0], lfsr[2] ^ lfsr[0]};
        end
    end

    // Assign the lowest 2 bits of LFSR as the random number
    always @(posedge clk) begin
        rnd <= lfsr[1:0];
    end

endmodule
