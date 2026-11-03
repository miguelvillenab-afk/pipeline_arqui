`timescale 1ns / 1ps
// igual que el pepilined pero recibe dos instrucciones por ciclo A y B.

module riscv_dual(
    input  clk,
    input  reset,
    output [31:0] PC,
    input  [31:0] Instr_A,
    input  [31:0] Instr_B,
    output        MemWrite,
    output [31:0] DataAdr,
    output [31:0] WriteData,
    input  [31:0] ReadData
    );

    datapath_dual dp (
        .clk   (clk),
        .reset (reset),
        .PC    (PC),
        .Instr_A (Instr_A),
        .Instr_B (Instr_B),
        .MemWrite  (MemWrite),
        .DataAdr   (DataAdr),
        .WriteData (WriteData),
        .ReadData  (ReadData),

        .IF_ID_Instr   (),
        .IF_ID_PC      (),
        .IF_ID_PC4     (),
        .IF_ID_Instr_B (),
        .IF_ID_PC_B    (),
        .IF_ID_PC4_B   (),
        //Decode
        .ID_B_rs1        (),
        .ID_B_rs2        (),
        .ID_B_rd         (),
        .ID_B_SrcA       (),
        .ID_B_WriteData  (),
        .ID_B_ImmExt     (),
        .ID_B_ALUSrc     (),
        .ID_B_ALUControl (),
        .ID_B_RegWrite   (),
        .ID_B_MemWrite   (),
        .ID_B_ResultSrc  (),
        .ID_B_Branch     (),
        .ID_B_Jump       (),
        

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
        .EX_MEM_Jump      (),

        .MEM_WB_ReadData  (),
        .MEM_WB_ALUResult (),
        .MEM_WB_PC4       (),
        .MEM_WB_rd        (),
        .MEM_WB_RegWrite  (),
        .MEM_WB_ResultSrc ()
    );

endmodule