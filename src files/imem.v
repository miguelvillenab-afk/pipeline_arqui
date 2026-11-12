//////////////////////////////////////////////////////////////////////////////////
// imem: memoria de instrucciones (64 palabras).
//
// - MEMFILE permite cargar otro programa sin renombrar archivos; el valor por
//   defecto mantiene "program1.mem".
// - Las palabras no cargadas valen NOP (addi x0, x0, 0) y cualquier dirección
//   fuera de rango devuelve NOP, para que el pipeline no propague x al pasar
//   el final del programa.
//////////////////////////////////////////////////////////////////////////////////
module imem #(
    parameter MEMFILE = "program1.mem"
    )(
    input  [31:0] a,
    output [31:0] rd);

  reg [31:0] RAM[63:0];
  integer i;

  initial begin
      for (i = 0; i < 64; i = i + 1)
          RAM[i] = 32'h0000_0013;
      $readmemh(MEMFILE, RAM);
  end

  assign rd = (a[31:8] == 24'b0) ? RAM[a[7:2]] : 32'h0000_0013; // word aligned
endmodule
