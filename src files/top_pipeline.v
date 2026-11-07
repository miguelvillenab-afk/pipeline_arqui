`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// top_pipeline: top del procesador pipelineado.
//
// Misma interfaz que top.v (single-cycle) para poder usar el mismo
// testbench de integración:
//   - top.v          -> riscvsingle + imem + dmem
//   - top_pipeline.v -> riscvpipeline + imem + dmem
//////////////////////////////////////////////////////////////////////////////////

module top_pipeline(
    input  clk,
    input  reset,
    output [31:0] WriteData,
    output [31:0] DataAdr,
    output        MemWrite
    );

    wire [31:0] PC, Instr, ReadData;

    riscvpipeline rvp (
        .clk       (clk),
        .reset     (reset),
        .PC        (PC),
        .Instr     (Instr),
        .MemWrite  (MemWrite),
        .DataAdr   (DataAdr),
        .WriteData (WriteData),
        .ReadData  (ReadData)
    );

    imem imem (
        .a  (PC),
        .rd (Instr)
    );

    dmem dmem (
        .clk (clk),
        .we  (MemWrite),
        .a   (DataAdr),
        .wd  (WriteData),
        .rd  (ReadData)
    );

endmodule
