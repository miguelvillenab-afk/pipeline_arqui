`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// flopenrc: flip-flop con reset asíncrono, enable y clear síncronos.
//
// Orden de prioridad:
//   1. reset (asíncrono)  -> q = 0
//   2. clr   (síncrono)   -> q = 0   (burbuja / flush)
//   3. en    (síncrono)   -> q = d
//   4. en = 0             -> q mantiene su valor (stall)
//
// Se usa para el registro ID/EX, que necesita hold (stall) y limpieza
// (flush) además del reset. flopr.v solo tiene reset y no permite ninguna
// de las dos cosas.
//////////////////////////////////////////////////////////////////////////////////

module flopenrc #(parameter WIDTH = 8) (
    input  clk,
    input  reset,
    input  en,
    input  clr,
    input  [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
    );

    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= {WIDTH{1'b0}};
        else if (clr)
            q <= {WIDTH{1'b0}};
        else if (en)
            q <= d;
    end

endmodule
