`timescale 1ns / 1ps

module ifid(
    input clk,
    input reset,
    input stall,
    input flush,
    input [31:0] Instr_in,
    input [31:0] PC_in,
    input [31:0] PC4_in,
    output reg [31:0] IF_ID_Instr,
    output reg [31:0] IF_ID_PC,
    output reg [31:0] IF_ID_PC4
    );
    
    always @(posedge clk or posedge reset) begin 
        if (reset) begin
            IF_ID_Instr <= 32'b0;
            IF_ID_PC <= 32'b0;
            IF_ID_PC4 <= 32'b0;
        end else if (flush) begin 
            IF_ID_Instr <= 32'b0;
            IF_ID_PC <= 32'b0;
            IF_ID_PC4 <= 32'b0;
        end else if (!stall) begin 
            IF_ID_Instr <= Instr_in;
            IF_ID_PC <= PC_in;
            IF_ID_PC4 <= PC4_in;
        end
     end     
endmodule
