//////////////////////////////////////////////////////////////////////////////////
// alu: ALU de 32 bits.
//
// alucontrol (3 bits):
//   000 add   001 sub   010 and   011 or   100 xor   101 slt
//////////////////////////////////////////////////////////////////////////////////
module alu(input  [31:0] a, b,
           input  [2:0]  alucontrol,
           output [31:0] result,
           output zero);

  wire [31:0] sum, diff;
  wire        lt_signed;

  reg [31:0] result_reg;
  assign result = result_reg;

  assign sum  = a + b;
  assign diff = a - b;

  assign lt_signed = ($signed(a) < $signed(b));

  always @* case (alucontrol)
      3'b000:  result_reg = sum;                 // add
      3'b001:  result_reg = diff;                // sub
      3'b010:  result_reg = a & b;               // and
      3'b011:  result_reg = a | b;               // or
      3'b100:  result_reg = a ^ b;               // xor
      3'b101:  result_reg = {31'b0, lt_signed};  // slt
      default: result_reg = 32'b0;
    endcase

  assign zero = (result == 32'b0);

endmodule
