//////////////////////////////////////////////////////////////////////////////////
// maindec: decodificador principal (opcode -> señales de control).
//
// Instrucciones soportadas:
//   lw, sw, R-type, I-type ALU, branches (beq/blt) y jal.
//
// ImmSrc: 00 = I, 01 = S, 10 = B, 11 = J.
// ResultSrc: 00 = ALU, 01 = memoria, 10 = PC+4 (jal).
// Branch = 1 para beq y blt; la condición la evalúa el comparador de EX
// usando funct3.
//////////////////////////////////////////////////////////////////////////////////
module maindec(input  [6:0] op,
               output [1:0] ResultSrc,
               output MemWrite,
               output Branch, ALUSrc,
               output RegWrite, Jump,
               output [1:0] ImmSrc,
               output [1:0] ALUOp);

  reg [10:0] controls;

  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump} = controls;

  always @* case(op)
    // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump
      7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw
      7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw
      7'b0110011: controls = 11'b1_00_0_0_00_0_10_0; // R-type
      7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq, blt
      7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I-type ALU
      7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
      // Opcode no implementado: todo en 0 (se comporta como NOP y no
      // propaga x por las señales de control).
      default:    controls = 11'b0_00_0_0_00_0_00_0;
    endcase
endmodule
