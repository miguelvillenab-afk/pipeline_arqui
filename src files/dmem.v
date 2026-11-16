//////////////////////////////////////////////////////////////////////////////////
// dmem: memoria de datos (512 palabras = 2 KB, direcciones 0x000-0x7FC),
// lectura combinacional y escritura síncrona.
//
// El programa del profesor usa x1 = 1536 (0x600) como base de datos y escribe
// hasta 1536 + 52, así que esas direcciones caen en las palabras 384-397 sin
// recortar la dirección.
//
// Contenido inicial determinista (igual en las tres arquitecturas): todo en 0
// salvo RAM[0] = 10 y RAM[2] = 30, que usan los programas de prueba 1 a 4.
//////////////////////////////////////////////////////////////////////////////////
module dmem(input  clk, we,
            input  [31:0] a, wd,
            output [31:0] rd);

  reg [31:0] RAM[511:0];
  integer i;

  initial begin
      for (i = 0; i < 512; i = i + 1)
          RAM[i] = 32'b0;
      RAM[0] = 32'h0000_000A;
      RAM[2] = 32'h0000_001E;
  end

  assign rd = RAM[a[10:2]]; // word aligned

  always @(posedge clk) begin
    if (we) RAM[a[10:2]] <= wd;
  end
endmodule
