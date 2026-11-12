//////////////////////////////////////////////////////////////////////////////////
// maindec: decodificador principal (opcode -> señales de control).
//
// Instrucciones soportadas:
//   lw, sw, R-type, I-type ALU, branches (beq/bne/blt/bge/bltu/bgeu),
//   jal, jalr, lui.
//
// ImmSrc: 00 = I, 01 = S, 10 = B, 11 = J o U (extend los distingue por opcode).
// ResultSrc: 00 = ALU, 01 = memoria, 10 = PC+4 (jal/jalr).
// JumpReg = 1 solo para jalr: el destino es (rs1 + imm) & ~1 en lugar de PC + imm.
// Branch = 1 para todos los branches; la condición la evalúa el comparador de
// EX usando funct3.
//////////////////////////////////////////////////////////////////////////////////
module maindec(input  [6:0] op,
               output [1:0] ResultSrc,
               output MemWrite,
               output Branch, ALUSrc,
               output RegWrite, Jump,
               output JumpReg,
               output [1:0] ImmSrc,
               output [1:0] ALUOp);

  reg [11:0] controls;

  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump, JumpReg} = controls;

  always @* case(op)
    // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump_JumpReg
      7'b0000011: controls = 12'b1_00_1_0_01_0_00_0_0; // lw
      7'b0100011: controls = 12'b0_01_1_1_00_0_00_0_0; // sw
      7'b0110011: controls = 12'b1_00_0_0_00_0_10_0_0; // R-type
      7'b1100011: controls = 12'b0_10_0_0_00_1_01_0_0; // branches
      7'b0010011: controls = 12'b1_00_1_0_00_0_10_0_0; // I-type ALU
      7'b1101111: controls = 12'b1_11_0_0_10_0_00_1_0; // jal
      7'b1100111: controls = 12'b1_00_1_0_10_0_00_1_1; // jalr
      7'b0110111: controls = 12'b1_11_1_0_00_0_00_0_0; // lui (rs1 se fuerza a x0)
      // Opcode no implementado: todo en 0 (se comporta como NOP y no
      // propaga x por las señales de control).
      default:    controls = 12'b0_00_0_0_00_0_00_0_0;
    endcase
endmodule
