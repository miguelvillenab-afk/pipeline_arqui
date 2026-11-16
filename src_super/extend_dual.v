//////////////////////////////////////////////////////////////////////////////////
// extend_dual: extensión de inmediatos (igual que extend del pipeline).
//
// ImmSrc: 00 = I, 01 = S, 10 = B, 11 = J (jal).
//////////////////////////////////////////////////////////////////////////////////
module extend_dual(input  [31:0] instr,
              input  [1:0]  immsrc,
              output reg [31:0] immext);

  always @* case(immsrc)
      // I-type (addi, lw, xori...)
      2'b00:   immext = {{20{instr[31]}}, instr[31:20]};
      // S-type (sw)
      2'b01:   immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      // B-type (beq, blt)
      2'b10:   immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
      // J-type (jal)
      2'b11:   immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
      default: immext = 32'b0;
    endcase
endmodule
