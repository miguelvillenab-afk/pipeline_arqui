`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Registro EX/MEM (Execute -> Memory)
//
// Captura el resultado de la ALU, la bandera Zero, el dato de store, el
// registro destino, PC+4, la dirección de branch/jal y las señales de
// control que necesitan las etapas MEM y WB.
//
// No tiene stall/flush según el contrato: la instrucción que está en EX
// (por ejemplo un lw) debe continuar hacia MEM. Los stalls de load-use se
// resuelven congelando IF/ID y limpiando ID/EX (burbuja), no EX/MEM.
//////////////////////////////////////////////////////////////////////////////////

module exmem(
    input  clk,
    input  reset,

    // Entradas desde la etapa EX
    input  [31:0] ALUResult,
    input         Zero,
    input  [31:0] WriteData,
    input  [4:0]  rd,
    input  [31:0] PC4,
    input  [31:0] PCTarget,
    input         MemWrite,
    input         RegWrite,
    input  [1:0]  ResultSrc,
    input         Branch,
    input         Jump,

    // Salidas hacia la etapa MEM
    output reg [31:0] EX_MEM_ALUResult,
    output reg        EX_MEM_Zero,
    output reg [31:0] EX_MEM_WriteData,
    output reg [4:0]  EX_MEM_rd,
    output reg [31:0] EX_MEM_PC4,
    output reg [31:0] EX_MEM_PCTarget,
    output reg        EX_MEM_MemWrite,
    output reg        EX_MEM_RegWrite,
    output reg [1:0]  EX_MEM_ResultSrc,
    output reg        EX_MEM_Branch,
    output reg        EX_MEM_Jump
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            EX_MEM_ALUResult <= 32'b0;
            EX_MEM_Zero      <= 1'b0;
            EX_MEM_WriteData <= 32'b0;
            EX_MEM_rd        <= 5'b0;
            EX_MEM_PC4       <= 32'b0;
            EX_MEM_PCTarget  <= 32'b0;
            EX_MEM_MemWrite  <= 1'b0;
            EX_MEM_RegWrite  <= 1'b0;
            EX_MEM_ResultSrc <= 2'b0;
            EX_MEM_Branch    <= 1'b0;
            EX_MEM_Jump      <= 1'b0;
        end else begin
            EX_MEM_ALUResult <= ALUResult;
            EX_MEM_Zero      <= Zero;
            EX_MEM_WriteData <= WriteData;
            EX_MEM_rd        <= rd;
            EX_MEM_PC4       <= PC4;
            EX_MEM_PCTarget  <= PCTarget;
            EX_MEM_MemWrite  <= MemWrite;
            EX_MEM_RegWrite  <= RegWrite;
            EX_MEM_ResultSrc <= ResultSrc;
            EX_MEM_Branch    <= Branch;
            EX_MEM_Jump      <= Jump;
        end
    end

endmodule
