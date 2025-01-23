`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/09 14:24:09
// Design Name: 
// Module Name: bram
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


module weights_feeder #(
    parameter XLEN = 32,               
    parameter WEIGHT_SIZE = 30560       
)(
    input                  clk,        
    input                  rst,        

    // MMIO 接口
    (* mark_debug = "true" *)input                  EN,         
    (* mark_debug = "true" *)input  [17:0]          ADDR,       
    (* mark_debug = "true" *)input                  WR,         
    (* mark_debug = "true" *)input  [XLEN-1:0]      DATAI,      
    (* mark_debug = "true" *)output [XLEN-1:0]      DATAO,      
    (* mark_debug = "true" *)output reg             READY       
);


    bram_example weights_bram(
    .clk(clk),
    .rst(rst),
    .addr(ADDR[16:2]),
    .data_in(DATAI),
    .data_out(DATAO),
    .we(EN && WR)
    );

    (* mark_debug = "true" *)wire [16-1:0] bram_addr;
    assign bram_addr = ADDR[17:2]; 

    always @(posedge clk) begin
        if (rst) begin
            READY <= 1'b0;
        end else if (EN) begin
            if (WR) begin
         
                if (bram_addr < WEIGHT_SIZE) begin
                    READY <= 1'b1;
                end else begin
                    READY <= 1'b0; 
                end
            end else begin
               
                if (bram_addr < WEIGHT_SIZE) begin
                    READY <= 1'b1;
                end else begin
                    READY <= 1'b0;
                end
            end
        end else begin
            READY <= 1'b0; 
        end
    end
    
endmodule


