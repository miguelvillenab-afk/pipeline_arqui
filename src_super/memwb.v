`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Registro MEM/WB (Memory -> Writeback)
//
// Captura el dato leído de dmem, el resultado de la ALU, PC+4, el registro
// destino y las señales de control que necesita Writeback.
//
// No tiene stall/flush según el contrato: las instrucciones que llegan a MEM
// deben completar su recorrido. Las burbujas se insertan antes, limpiando
// ID/EX (RegWrite=0, MemWrite=0, etc.).
//////////////////////////////////////////////////////////////////////////////////

module memwb(
    input  clk,
    input  reset,

    // Entradas desde la etapa MEM
    input  [31:0] ReadData,
    input  [31:0] ALUResult,
    input  [31:0] PC4,
    input  [4:0]  rd,
    input         RegWrite,
    input  [1:0]  ResultSrc,

    // Salidas hacia la etapa WB
    output reg [31:0] MEM_WB_ReadData,
    output reg [31:0] MEM_WB_ALUResult,
    output reg [31:0] MEM_WB_PC4,
    output reg [4:0]  MEM_WB_rd,
    output reg        MEM_WB_RegWrite,
    output reg [1:0]  MEM_WB_ResultSrc
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            MEM_WB_ReadData  <= 32'b0;
            MEM_WB_ALUResult <= 32'b0;
            MEM_WB_PC4       <= 32'b0;
            MEM_WB_rd        <= 5'b0;
            MEM_WB_RegWrite  <= 1'b0;
            MEM_WB_ResultSrc <= 2'b0;
        end else begin
            MEM_WB_ReadData  <= ReadData;
            MEM_WB_ALUResult <= ALUResult;
            MEM_WB_PC4       <= PC4;
            MEM_WB_rd        <= rd;
            MEM_WB_RegWrite  <= RegWrite;
            MEM_WB_ResultSrc <= ResultSrc;
        end
    end

endmodule
