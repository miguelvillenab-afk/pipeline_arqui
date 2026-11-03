module extend(
    input  [31:0] instr,  // ✅ CAMBIO: Recibe 32 bits completos
    input  [1:0]  immsrc,
    output reg [31:0] immext
);

    always @(*) begin
        case(immsrc)
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
                immext = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            // U-type (lui) o J-type (jal)
            2'b11: begin
                immext = {instr[31:12], 12'b0};  // Para LUI
                // Si necesitas JAL completo:
                // immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            default: begin
                immext = 32'b0;
            end
        endcase
    end

endmodule