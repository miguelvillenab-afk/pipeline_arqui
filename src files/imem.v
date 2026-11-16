//////////////////////////////////////////////////////////////////////////////////
// imem: memoria de instrucciones (256 palabras = 1 KB, direcciones 0x000-0x3FC).
//
// - MEMFILE permite cargar otro programa sin renombrar archivos.
// - Las palabras no cargadas valen NOP (addi x0, x0, 0) y cualquier dirección
//   fuera de rango devuelve NOP, para que el pipeline no propague x al pasar
//   el final del programa.
// - 256 palabras alcanzan para el programa del profesor (90 instrucciones) y
//   dejan espacio para el programa propio.
//////////////////////////////////////////////////////////////////////////////////
module imem #(
    parameter MEMFILE = "prueba_final.mem"
    )(
    input  [31:0] a,
    output [31:0] rd);

  reg [31:0] RAM[255:0];
  integer i;

  initial begin
      for (i = 0; i < 256; i = i + 1)
          RAM[i] = 32'h0000_0013;
      $readmemh(MEMFILE, RAM);
  end

  assign rd = (a[31:10] == 22'b0) ? RAM[a[9:2]] : 32'h0000_0013; // word aligned
endmodule
