`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// riscvpipeline: procesador RISC-V pipelineado (5 etapas).
//
// Mantiene la misma interfaz externa que riscvsingle para poder intercambiar
// el procesador en top_pipeline.v sin cambiar memorias ni testbench.
//////////////////////////////////////////////////////////////////////////////////

module riscvpipeline(
    input  clk,
    input  reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] DataAdr,
    output [31:0] WriteData,
    input  [31:0] ReadData
    );

    datapath_pipeline dp (
        .clk   (clk),
        .reset (reset),
        .PC    (PC),
        .Instr (Instr),
        .MemWrite  (MemWrite),
        .DataAdr   (DataAdr),
        .WriteData (WriteData),
        .ReadData  (ReadData),

        // Salidas de observabilidad: no se usan en este wrapper.
        .IF_ID_Instr (),
        .IF_ID_PC    (),
        .IF_ID_PC4   (),

        .ID_EX_SrcA       (),
        .ID_EX_WriteData  (),
        .ID_EX_ImmExt     (),
        .ID_EX_PC         (),
        .ID_EX_PC4        (),
        .ID_EX_rs1        (),
        .ID_EX_rs2        (),
        .ID_EX_rd         (),
        .ID_EX_ALUSrc     (),
        .ID_EX_ALUControl (),
        .ID_EX_RegWrite   (),
        .ID_EX_MemWrite   (),
        .ID_EX_ResultSrc  (),
        .ID_EX_Branch     (),
        .ID_EX_Jump       (),
        .ID_EX_ImmSrc     (),

        .EX_MEM_ALUResult (),
        .EX_MEM_Zero      (),
        .EX_MEM_WriteData (),
        .EX_MEM_rd        (),
        .EX_MEM_PC4       (),
        .EX_MEM_PCTarget  (),
        .EX_MEM_MemWrite  (),
        .EX_MEM_RegWrite  (),
        .EX_MEM_ResultSrc (),
        .EX_MEM_Branch    (),
        .EX_MEM_Jump      ()
    );

endmodule
