`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// hazard_unit: forwarding, stall por load-use y flush por saltos.
//
// Forwarding (selección de los mux3 de EX):
//   00 = valor leído en ID (sin forwarding)
//   01 = resultado de WB  (instrucción en MEM/WB)
//   10 = ALUResult de MEM (instrucción en EX/MEM)  -> prioridad sobre WB
//   ForwardA: operando rs1 (SrcA de la ALU, base de jalr, comparador de branch)
//   ForwardB: operando rs2 de la ALU (solo si ALUSrc = 0)
//   ForwardC: dato rs2 sin pasar por ALUSrc (dato de sw y comparador de branch)
//
// Load-use: si hay un lw en EX y la instrucción en ID usa su rd, se congela
// PC e IF/ID y se inserta una burbuja en ID/EX (flush). El lw sigue avanzando.
//
// Salto tomado en EX (branch o jal/jalr): se anulan las dos instrucciones del
// camino incorrecto (IF/ID e ID/EX).
//////////////////////////////////////////////////////////////////////////////////

module hazard_unit (
    // Registros fuente de la instrucción en ID
    input [4:0] rs1_ID, rs2_ID,
    // Instrucción en EX
    input [4:0] rs1_EX, rs2_EX, rd_EX,
    input [1:0] ResultSrc_EX,
    input       RegWrite_EX,
    input       ALUSrc_EX,
    // Instrucción en MEM
    input [4:0] rd_MEM,
    input       RegWrite_MEM,
    // Instrucción en WB
    input [4:0] rd_WB,
    input       RegWrite_WB,
    // Salto tomado en EX
    input       PCSrc_EX,

    output reg       stall_IF_ID,
    output reg       stall_ID_EX,
    output reg       flush_IF_ID,
    output reg       flush_ID_EX,
    output reg [1:0] ForwardA, ForwardB, ForwardC
);

    // Selección de forwarding para un registro fuente en EX.
    // Todas las señales entran como argumentos: si la función leyera señales
    // del módulo directamente, always @(*) no se reevaluaría cuando cambian
    // y la simulación daría un forwarding desactualizado.
    function [1:0] fwd(input [4:0] rs,
                       input [4:0] rdM, input wM,
                       input [4:0] rdW, input wW);
        begin
            if      (wM && (rdM != 5'd0) && (rdM == rs)) fwd = 2'b10;
            else if (wW && (rdW != 5'd0) && (rdW == rs)) fwd = 2'b01;
            else                                          fwd = 2'b00;
        end
    endfunction

    wire [1:0] fwd_rs1 = fwd(rs1_EX, rd_MEM, RegWrite_MEM, rd_WB, RegWrite_WB);
    wire [1:0] fwd_rs2 = fwd(rs2_EX, rd_MEM, RegWrite_MEM, rd_WB, RegWrite_WB);

    wire lw_in_EX = (ResultSrc_EX == 2'b01) && RegWrite_EX;
    wire lw_stall = lw_in_EX && (rd_EX != 5'd0) &&
                    ((rd_EX == rs1_ID) || (rd_EX == rs2_ID));

    always @(*) begin
        stall_IF_ID = 1'b0;
        stall_ID_EX = 1'b0;   // ID/EX nunca se congela: recibe burbujas
        flush_IF_ID = 1'b0;
        flush_ID_EX = 1'b0;

        // Un lw y un salto no pueden estar en EX a la vez, así que estos dos
        // casos son excluyentes.
        if (PCSrc_EX) begin
            flush_IF_ID = 1'b1;
            flush_ID_EX = 1'b1;
        end else if (lw_stall) begin
            stall_IF_ID = 1'b1;
            flush_ID_EX = 1'b1;
        end

        ForwardA = fwd_rs1;
        ForwardB = ALUSrc_EX ? 2'b00 : fwd_rs2;
        ForwardC = fwd_rs2;
    end

endmodule
