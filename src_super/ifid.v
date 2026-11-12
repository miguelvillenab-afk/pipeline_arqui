`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Registro IF/ID (Fetch -> Decode)
//
// - reset: limpia el registro.
// - flush: inserta una burbuja. La instrucción se limpia a NOP
//   (addi x0, x0, 0) y no a 0, porque el opcode 0 cae en el default de
//   maindec y propaga x por las señales de control.
// - stall: mantiene el valor actual (el registro no se actualiza).
//
// Prioridad: reset > flush > stall.
//////////////////////////////////////////////////////////////////////////////////

module ifid(
    input  clk,
    input  reset,
    input  stall,
    input  flush,
    input  [31:0] Instr_in,
    input  [31:0] PC_in,
    input  [31:0] PC4_in,
    output reg [31:0] IF_ID_Instr,
    output reg [31:0] IF_ID_PC,
    output reg [31:0] IF_ID_PC4
    );

    // addi x0, x0, 0
    localparam [31:0] NOP = 32'h0000_0013;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            IF_ID_Instr <= NOP;
            IF_ID_PC    <= 32'b0;
            IF_ID_PC4   <= 32'b0;
        end else if (flush) begin
            IF_ID_Instr <= NOP;
            IF_ID_PC    <= 32'b0;
            IF_ID_PC4   <= 32'b0;
        end else if (!stall) begin
            IF_ID_Instr <= Instr_in;
            IF_ID_PC    <= PC_in;
            IF_ID_PC4   <= PC4_in;
        end
    end

endmodule
