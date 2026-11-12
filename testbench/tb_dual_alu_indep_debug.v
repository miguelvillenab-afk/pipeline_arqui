`timescale 1ns / 1ps
module tb_dual_alu_indep_debug;
    reg clk, reset;
    wire [31:0] PC, WriteData, DataAdr;
    wire MemWrite;

    top_dual #(.MEMFILE("dual_alu_indep_debug.mem")) uut (
        .clk(clk), .reset(reset),
        .PC(PC), .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        reset = 1; #22; reset = 0;
        #400; $finish;
    end
endmodule