`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// extend_dual: extensión de inmediato para el datapath dual.
//
// Es igual a src files/extend.v, salvo que en ImmSrc = 2'b11 distingue:
//   - opcode 7'b1101111 (jal) -> inmediato J-type
//   - cualquier otro           -> inmediato U-type (lui)
//
// Motivo: maindec asigna ImmSrc = 2'b11 tanto a jal como a lui, pero
// src files/extend.v siempre genera el inmediato de LUI. Con eso, el target
// de jal queda mal. Este módulo corrige el caso sin cambiar el ancho de
// ImmSrc ni tocar los módulos de src files/.
//////////////////////////////////////////////////////////////////////////////////

module extend_dual(
    input  [31:0] instr,
    input  [1:0]  immsrc,
    output reg [31:0] immext
    );

    always @(*) begin
        case (immsrc)
            // I-type (addi, lw, etc.)
            2'b00: begin
                immext = {{20{instr[31]}}, instr[31:20]};
            end
            // S-type (sw)
            2'b01: begin
                immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
            // B-type (beq)
            2'b10: begin
                immext = {{19{instr[31]}}, instr[31], instr[7],
                          instr[30:25], instr[11:8], 1'b0};
            end
            // U-type (lui) o J-type (jal)
            2'b11: begin
                if (instr[6:0] == 7'b1101111)
                    immext = {{12{instr[31]}}, instr[19:12], instr[20],
                              instr[30:21], 1'b0};
                else
                    immext = {instr[31:12], 12'b0};
            end
            default: begin
                immext = 32'b0;
            end
        endcase
    end

endmodule
