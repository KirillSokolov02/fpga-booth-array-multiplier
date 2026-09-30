`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04/27/2021 07:25:48 PM
// Design Name:
// Module Name: apb_wrapper_rsa
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


module apb_wrapper_booth#(
    parameter BUS_WIDTH = 32,
    parameter ADDR_OFFSET= 'h00000000

)

(
    input clk,
    input rst,
    // Interface to APB bridge
    input S_PSEL,
    input S_PENABLE,
    input [31:0] S_PADDR,
    input S_PWRITE,
    input [31:0] S_PWDATA,
    output reg  S_PREADY,
    output reg  S_PSLVERR,
    output reg [31:0] S_PRDATA
    );


    wire apb_write;
    wire apb_read;
    wire [3:0] addr_index;
    wire [15:0] p_o;

    reg [15:0] p_o_reg;
    reg ce_i;
    reg [7:0] a_i;
    reg [7:0] b_i;
    reg reset;


    assign apb_write = S_PSEL & S_PENABLE & S_PWRITE;
    assign apb_read = S_PSEL & ~S_PWRITE;
    assign addr_index = S_PADDR[3:0]; //hmmm

mult_booth_array #(.word_size_a(8), .word_size_b(8)) mult_booth (.clk_i(clk), .rst_i(reset), .ce_i(ce_i), .a_i(a_i), .b_i(b_i), .p_o(p_o));

    always @( posedge clk )
	begin
	  if ( !rst )
	    begin
	      p_o_reg <= 0;
	    end
	  else
	    begin
	      p_o_reg <= {16'h0, p_o};
	    end
	end


    always@(posedge clk)
    begin
        if (!rst) begin
            S_PREADY  <= 1;
            S_PSLVERR <= 0;
            S_PRDATA  <= 0;
            a_i    <= 0;
            b_i     <= 0;
            ce_i     <= 0;
            reset     <= 1;
        end
        else begin
        reset     <= 0;
        S_PREADY  <= 1;
        S_PSLVERR <= 0;

            if (apb_write) begin
            case (addr_index)
                4'h00: a_i    <= {24'h0, S_PWDATA[7:0]};
                4'h04: b_i <= {24'h0, S_PWDATA[7:0]};
                4'h08: ce_i <= S_PWDATA[0:0];
            endcase
            end
            else if (apb_read) begin
            case (addr_index)
                4'h00: S_PRDATA <= {24'h0, a_i};
                4'h04: S_PRDATA <= {24'h0, b_i};
                4'h08: S_PRDATA <= {31'h0, ce_i};
                4'h0C: S_PRDATA <= p_o_reg;
            endcase
            end else
                S_PRDATA  <= 0;
        end
    end
endmodule
