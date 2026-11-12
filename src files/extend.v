//////////////////////////////////////////////////////////////////////////////////
// extend: extensión de inmediatos.
//
// ImmSrc: 00 = I, 01 = S, 10 = B, 11 = J (jal) o U (lui).
// maindec asigna ImmSrc = 11 a jal y a lui, así que aquí se distinguen por
// opcode. Por eso el módulo recibe la instrucción completa [31:0].
//////////////////////////////////////////////////////////////////////////////////
module extend(input  [31:0] instr,
              input  [1:0]  immsrc,
              output reg [31:0] immext);

  always @* case(immsrc)
      // I-type (addi, lw, jalr, slli...)
      2'b00:   immext = {{20{instr[31]}}, instr[31:20]};
      // S-type (sw)
      2'b01:   immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      // B-type (branches)
      2'b10:   immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
      // J-type (jal) o U-type (lui)
      2'b11:   if (instr[6:0] == 7'b1101111)
                 immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
               else
                 immext = {instr[31:12], 12'b0};
      default: immext = 32'b0;
    endcase
endmodule
