`timescale 1ns / 1ps

// Mux de 5 entradas para el forwarding dual:
//   s=0 -> d0 (valor propio del registro)
//   s=1 -> d1 (WB vía A)
//   s=2 -> d2 (WB vía B)
//   s=3 -> d3 (EX/MEM vía A)
//   s=4 -> d4 (EX/MEM vía B)

module mux5 #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] d0, d1, d2, d3, d4,
    input  [2:0]       s,
    output [WIDTH-1:0] y
    );

    assign y = (s == 3'd1) ? d1 :
               (s == 3'd2) ? d2 :
               (s == 3'd3) ? d3 :
               (s == 3'd4) ? d4 : d0;

endmodule