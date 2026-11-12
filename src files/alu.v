//////////////////////////////////////////////////////////////////////////////////
// alu: ALU de 32 bits.
//
// alucontrol (4 bits):
//   0000 add   0001 sub   0010 and   0011 or    0100 xor
//   0101 slt   0110 sltu  0111 sll   1000 srl   1001 sra
//
// Los desplazamientos usan b[4:0] (shamt para slli/srli/srai).
//////////////////////////////////////////////////////////////////////////////////
module alu(input  [31:0] a, b,
           input  [3:0]  alucontrol,
           output [31:0] result,
           output zero);

  wire [31:0] sum, diff;
  wire        lt_signed, lt_unsigned;

  reg [31:0] result_reg;
  assign result = result_reg;

  assign sum  = a + b;
  assign diff = a - b;

  assign lt_signed   = ($signed(a) < $signed(b));
  assign lt_unsigned = (a < b);

  always @* case (alucontrol)
      4'b0000: result_reg = sum;                          // add
      4'b0001: result_reg = diff;                         // sub
      4'b0010: result_reg = a & b;                        // and
      4'b0011: result_reg = a | b;                        // or
      4'b0100: result_reg = a ^ b;                        // xor
      4'b0101: result_reg = {31'b0, lt_signed};           // slt
      4'b0110: result_reg = {31'b0, lt_unsigned};         // sltu
      4'b0111: result_reg = a << b[4:0];                  // sll
      4'b1000: result_reg = a >> b[4:0];                  // srl
      4'b1001: result_reg = $signed(a) >>> b[4:0];        // sra
      default: result_reg = 32'b0;
    endcase

  assign zero = (result == 32'b0);

endmodule
