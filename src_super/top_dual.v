`timescale 1ns / 1ps
module top_dual #(
    parameter MEMFILE = "program1.mem"
    )(
    input  clk,
    input  reset,
    output [31:0] PC,
    output        MemWrite,
    output [31:0] DataAdr,
    output [31:0] WriteData
);

    // Señales internas
    wire [31:0] Instr_A, Instr_B, PCPlus4;
    wire [31:0] ReadData;  

    riscv_dual rvd (
        .clk       (clk),
        .reset     (reset),
        .PC        (PC),
        .Instr_A   (Instr_A),
        .Instr_B   (Instr_B), 
        .MemWrite  (MemWrite),
        .DataAdr   (DataAdr),
        .WriteData (WriteData),
        .ReadData  (ReadData) 
    );

    adder pcadd4 (
        .a (PC),
        .b (32'd4),
        .y (PCPlus4)
    );

    imem_dual #(.MEMFILE(MEMFILE)) imem (
        .a0  (PC),
        .a1  (PCPlus4),
        .rd0 (Instr_A),
        .rd1 (Instr_B)
    );

    dmem_dual dmem (
        .clk (clk),
        .we  (MemWrite),
        .a   (DataAdr),
        .wd  (WriteData),
        .rd  (ReadData)
    );

endmodule