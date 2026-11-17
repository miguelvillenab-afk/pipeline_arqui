`timescale 1ns / 1ps
module idex_opt(
    input  clk,
    input  reset,
    input  stall_ID_EX,
    input  flush_ID_EX,

    // Entradas de la etapa ID
    input  [31:0] SrcA,
    input  [31:0] WriteData,
    input  [31:0] ImmExt,
    input  [31:0] IF_ID_PC,
    input  [31:0] IF_ID_PC4,
    input  [4:0]  rs1,
    input  [4:0]  rs2,
    input  [4:0]  rd,

    input         ALUSrc,
    input  [2:0]  ALUControl,
    input         RegWrite,
    input         MemWrite,
    input  [1:0]  ResultSrc,
    input         Branch,
    input         Jump,
    input  [1:0]  ImmSrc,
    
    // NUEVO: Predicción y Target temprano
    input  [31:0] ID_PCTarget,
    input         ID_predict_taken,

    // Salidas hacia la etapa EX
    output [31:0] ID_EX_SrcA,
    output [31:0] ID_EX_WriteData,
    output [31:0] ID_EX_ImmExt,
    output [31:0] ID_EX_PC,
    output [31:0] ID_EX_PC4,
    output [4:0]  ID_EX_rs1,
    output [4:0]  ID_EX_rs2,
    output [4:0]  ID_EX_rd,

    output        ID_EX_ALUSrc,
    output [2:0]  ID_EX_ALUControl,
    output        ID_EX_RegWrite,
    output        ID_EX_MemWrite,
    output [1:0]  ID_EX_ResultSrc,
    output        ID_EX_Branch,
    output        ID_EX_Jump,
    output [1:0]  ID_EX_ImmSrc,
    
    // NUEVO: Salidas de predicción
    output [31:0] ID_EX_PCTarget,
    output        ID_EX_predict_taken
    );

    // 6 de 32 bits + 3 de 5 bits + 13 de control = 220 bits
    localparam ID_EX_WIDTH = 32*6 + 5*3 + 13;

    wire [ID_EX_WIDTH-1:0] d_concat;
    wire [ID_EX_WIDTH-1:0] q_concat;

    assign d_concat = {
        SrcA,
        WriteData,
        ImmExt,
        IF_ID_PC,
        IF_ID_PC4,
        rs1,
        rs2,
        rd,
        ALUSrc,
        ALUControl,
        RegWrite,
        MemWrite,
        ResultSrc,
        Branch,
        Jump,
        ImmSrc,
        ID_PCTarget,       // 32 bits
        ID_predict_taken   // 1 bit
    };

    flopenrc #(.WIDTH(ID_EX_WIDTH)) reg_idex (
        .clk   (clk),
        .reset (reset),
        .en    (~stall_ID_EX),
        .clr   (flush_ID_EX),
        .d     (d_concat),
        .q     (q_concat)
    );

    assign {
        ID_EX_SrcA,
        ID_EX_WriteData,
        ID_EX_ImmExt,
        ID_EX_PC,
        ID_EX_PC4,
        ID_EX_rs1,
        ID_EX_rs2,
        ID_EX_rd,
        ID_EX_ALUSrc,
        ID_EX_ALUControl,
        ID_EX_RegWrite,
        ID_EX_MemWrite,
        ID_EX_ResultSrc,
        ID_EX_Branch,
        ID_EX_Jump,
        ID_EX_ImmSrc,
        ID_EX_PCTarget,
        ID_EX_predict_taken
    } = q_concat;

endmodule