`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/03/2023 07:17:38 PM
// Design Name: 
// Module Name: mult_booth_array_tb
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


module mult_booth_array_tb;
    parameter period = 5; // Clock period
    parameter word_size_a = 8;
    parameter word_size_b = 8;
    
    //---Inputs----
    reg                 clk_i;
    reg                 rst_i;
    reg                 ce_i;
    reg [word_size_a-1:0]   a_i;
    reg [word_size_a-1:0]   b_i;
   
    //---Outputs---
    wire [word_size_a+word_size_b-1:0]  p_o;
    
    //module instantiation
    mult_booth_array UUT(
        .clk_i(clk_i),
	    .rst_i(rst_i),
	 	.ce_i(ce_i),
	    .a_i(a_i),
		.b_i(b_i),
	    .p_o(p_o)
    );

    always #(period) clk_i = !clk_i;

    
    initial begin
    
        clk_i     <= 0;
        #period;
        rst_i   <= 1;
        #(period*4);
        rst_i   <= 0;
        #period;
        ce_i  <= 1;
        a_i   <= 8'h54;
        b_i   <= 8'h12;
        #period;
        // Expected output p_o = 16'h05e8;
        end
endmodule
