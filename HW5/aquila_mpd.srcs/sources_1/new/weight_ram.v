`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/01 16:14:48
// Design Name: 
// Module Name: weight_ram
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


//module weight_ram
//#(parameter XLEN = 32)
//(
//    input                clk_i,
//    input                we_i,
//    input  [XLEN-1 : 0]  read_addr1_i, // 0~9
//    input  [14-1 : 0]    read_addr2_i, // 0~511
//    output [XLEN-1 : 0]  data_o
//);

//reg [32-1 : 0] RAM[0:5119];

//assign data_o = RAM[read_addr1_i*512 + read_addr2_i];

//initial begin
//    $readmemh("C://Users//eric7//Desktop//NYCU//3rd_1//Microprocessor_Systems//HW5//output.txt", RAM);
//end

//endmodule


module weight_ram
#(parameter XLEN = 32, parameter BURST_LEN = 1) // 25 elements
(
    input                clk_i,
    input                we_i,
    input  [XLEN-1 : 0]  read_addr1_i, // 0~9
    input  [14-1 : 0]    read_addr2_i, // 0~511
    output [BURST_LEN*XLEN-1 : 0] data_o // Output 25 elements
);

(* ram_style = "block" *) reg [32-1 : 0] RAM[0:5119];
reg [BURST_LEN*XLEN-1 : 0] burst_data;

assign data_o = burst_data;

initial begin
    $readmemh("C://Users//eric7//Desktop//NYCU//3rd_1//Microprocessor_Systems//HW5//output1.txt", RAM);
end

integer i;
always @(posedge clk_i) begin
    if (we_i) begin
        // Handle write enable logic if needed
    end else begin
        // Generate 25 elements starting from the calculated base address

        for (i = 0; i < BURST_LEN; i = i + 1) begin
            burst_data[i*XLEN +: XLEN] <= RAM[read_addr1_i * 512 + read_addr2_i + i];
        end
    end
end

endmodule
