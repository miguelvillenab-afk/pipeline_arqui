//////////////////////////////////////////////////////////////////////////////////
// regfile: banco de 32 registros, 2 lecturas combinacionales y 1 escritura.
//
// - x0 vale siempre 0: no se escribe y se lee como 0.
// - Lectura con bypass (write-through): si en el mismo ciclo WB escribe el
//   registro que ID está leyendo, se devuelve el valor nuevo. Sin esto, una
//   instrucción que está 3 posiciones detrás de su productora leería el valor
//   viejo (ya no hay forwarding que la cubra).
//////////////////////////////////////////////////////////////////////////////////
module regfile(input  clk,
               input  reset,
               input  we3,
               input  [4:0] a1, a2, a3,
               input  [31:0] wd3,
               output [31:0] rd1, rd2);

  reg [31:0] rf[0:31];
  integer i;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      for (i = 0; i < 32; i = i + 1)
        rf[i] <= 32'b0;
    end else if (we3 && (a3 != 5'd0)) begin
      rf[a3] <= wd3;
    end
  end

  assign rd1 = (a1 == 5'd0)              ? 32'b0 :
               (we3 && (a3 == a1))       ? wd3   :
                                           rf[a1];
  assign rd2 = (a2 == 5'd0)              ? 32'b0 :
               (we3 && (a3 == a2))       ? wd3   :
                                           rf[a2];
endmodule
