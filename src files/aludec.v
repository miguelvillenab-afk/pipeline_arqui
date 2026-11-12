//////////////////////////////////////////////////////////////////////////////////
// aludec: decodificador de la ALU.
//
// ALUControl (4 bits):
//   0000 add   0001 sub   0010 and   0011 or    0100 xor
//   0101 slt   0110 sltu  0111 sll   1000 srl   1001 sra
//
// ALUOp: 00 = suma (lw, sw, jal, jalr, lui), 01 = resta,
//        10 = según funct3 (R-type e I-type ALU).
//////////////////////////////////////////////////////////////////////////////////
module aludec(input  opb5,
              input  [2:0] funct3,
              input  funct7b5,
              input  [1:0] ALUOp,
              output [3:0] ALUControl);

  wire  RtypeSub;
  reg [3:0] ALUControl_reg;

  assign RtypeSub = funct7b5 & opb5;  // TRUE solo para sub (R-type)
  assign ALUControl = ALUControl_reg;

  always @* case(ALUOp)
      2'b00:                ALUControl_reg = 4'b0000; // add
      2'b01:                ALUControl_reg = 4'b0001; // sub
      default: case(funct3) // R-type o I-type ALU
                 3'b000:  if (RtypeSub)
                            ALUControl_reg = 4'b0001; // sub
                          else
                            ALUControl_reg = 4'b0000; // add, addi
                 3'b001:    ALUControl_reg = 4'b0111; // sll, slli
                 3'b010:    ALUControl_reg = 4'b0101; // slt, slti
                 3'b011:    ALUControl_reg = 4'b0110; // sltu, sltiu
                 3'b100:    ALUControl_reg = 4'b0100; // xor, xori
                 // srl/srli vs sra/srai: bit 30 de la instrucción
                 // (funct7[5] en R-type, imm[10] en I-type)
                 3'b101:  if (funct7b5)
                            ALUControl_reg = 4'b1001; // sra, srai
                          else
                            ALUControl_reg = 4'b1000; // srl, srli
                 3'b110:    ALUControl_reg = 4'b0011; // or, ori
                 3'b111:    ALUControl_reg = 4'b0010; // and, andi
                 default:   ALUControl_reg = 4'b0000;
               endcase
    endcase
endmodule
