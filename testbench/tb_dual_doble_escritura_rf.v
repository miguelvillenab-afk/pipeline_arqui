`timescale 1ns / 1ps
module tb_dual_doble_escritura_rf;
    reg clk, reset;
    wire [31:0] WriteData, DataAdr;
    wire MemWrite;

    top_dual #(.MEMFILE("dual_doble_escritura_rf.mem")) uut (
        .clk(clk), .reset(reset),
        .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end
    initial begin
        reset = 1; #20; reset = 0;
        #100; $finish;
    end
endmodule