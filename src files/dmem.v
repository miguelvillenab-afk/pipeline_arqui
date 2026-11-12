//////////////////////////////////////////////////////////////////////////////////
// dmem: memoria de datos (64 palabras), lectura combinacional y escritura
// síncrona.
//
// Contenido inicial determinista (igual que dmem_dual del Dual-Issue, para
// que los mismos programas den los mismos resultados en las tres
// arquitecturas): todo en 0 salvo RAM[0] = 10 y RAM[2] = 30.
// Se indexa con a[7:2] (igual que dmem_dual).
//////////////////////////////////////////////////////////////////////////////////
module dmem(input  clk, we,
            input  [31:0] a, wd,
            output [31:0] rd);

  reg [31:0] RAM[63:0];
  integer i;

  initial begin
      for (i = 0; i < 64; i = i + 1)
          RAM[i] = 32'b0;
      RAM[0] = 32'h0000_000A;
      RAM[2] = 32'h0000_001E;
  end

  assign rd = RAM[a[7:2]]; // word aligned

  always @(posedge clk) begin
    if (we) RAM[a[7:2]] <= wd;
  end
endmodule
