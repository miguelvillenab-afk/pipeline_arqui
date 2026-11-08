`timescale 1ns / 1ps
module tb_dual_reagrupamiento;
    reg clk, reset;
    wire [31:0] WriteData, DataAdr;
    wire MemWrite;

    top_dual #(.MEMFILE("dual_reagrupamiento.mem")) uut (
        .clk(clk), .reset(reset),
        .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end
    initial begin
        reset = 1; #20; reset = 0;
        #150; $finish;
    end
endmodule