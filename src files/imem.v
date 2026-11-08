// MEMFILE permite cargar distintos programas sin renombrar archivos.
// El default coincide con el .mem incluido en proyecto_final.xpr.
module imem #(
    parameter MEMFILE = "program1.mem"
    )(
    input  [31:0] a,
    output [31:0] rd);

  reg [31:0] RAM[63:0];
  integer i;

  initial begin
      // Las palabras no cargadas quedan como NOP (addi x0,x0,0) para que,
      // al terminar el programa, PC no caiga en instrucciones en x.
      for (i = 0; i < 64; i = i + 1)
          RAM[i] = 32'h0000_0013;
      $readmemh(MEMFILE, RAM);
  end

  // Fuera del rango cargado se devuelve NOP: el pipeline puede seguir
  // avanzando despues del final del programa sin propagar x.
  assign rd = (a[31:2] < 7'd64) ? RAM[a[31:2]] : 32'h0000_0013;
endmodule