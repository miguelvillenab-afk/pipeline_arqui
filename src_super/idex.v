`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Registro ID/EX (Decode -> Execute)
//
// Captura todos los operandos y señales de control decodificadas para la
// instrucción que está en Decode. Soporta:
//   - stall_ID_EX = 1 -> mantiene el valor actual (burbuja por hazard).
//   - flush_ID_EX = 1 -> limpia todas las señales a 0 (burbuja segura:
//     RegWrite=0, MemWrite=0, Branch=0, Jump=0).
//
// Prioridad: reset > flush > stall > captura.
//
// Se añadió IF_ID_PC / ID_EX_PC respecto al contrato original porque el
// sumador de branch/jal necesita el PC de la instrucción que está en EX:
//   PCTarget = ID_EX_PC + ID_EX_ImmExt
// Sin ese dato, el diseño anterior mezclaba IF_ID_PC con ex_ImmExt, que
// pertenecen a instrucciones distintas.
//////////////////////////////////////////////////////////////////////////////////

module idex(
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
    output [1:0]  ID_EX_ImmSrc
    );

    // 5 campos de 32 bits + 3 de 5 bits + 12 bits de control = 187 bits
    localparam ID_EX_WIDTH = 32*5 + 5*3 + 12;

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
        ImmSrc
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
        ID_EX_ImmSrc
    } = q_concat;

endmodule
