`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// PC -> a0 de imem_dual -> Instr_A
// PC+4 -> a1 de imem_dual -> Instr_B

module top_dual(
    input  clk,
    input  reset,
    output [31:0] WriteData,
    output [31:0] DataAdr,
    output        MemWrite
    );

    wire [31:0] PC, Instr_A, Instr_B, PCPlus4, ReadData;

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

    imem_dual imem (
        .a0  (PC),
        .a1  (PCPlus4),
        .rd0 (Instr_A),
        .rd1 (Instr_B)
    );

    dmem dmem (
        .clk (clk),
        .we  (MemWrite),
        .a   (DataAdr),
        .wd  (WriteData),
        .rd  (ReadData)
    );

endmodule