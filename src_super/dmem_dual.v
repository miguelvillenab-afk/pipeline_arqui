`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// dmem_dual: memoria de datos de un solo puerto para el datapath dual.
//
// Diferencias con src files/dmem.v:
//   - La lectura es combinacional: assign rd = RAM[a[31:2]].
//   - La escritura sigue siendo síncrona.
//
// Motivo del cambio:
//   En el pipeline, MEM/WB captura ReadData en el mismo flanco en que dmem
//   actualiza su registro de lectura. Con lectura registrada, MEM/WB guardaba
//   el dato de la dirección anterior. Con lectura combinacional, el dato está
//   estable durante todo el ciclo de MEM y MEM/WB captura el correcto.
//
// Se mantienen los mismos valores iniciales que src files/dmem.v para no
// alterar la regresión de program1.mem.
//////////////////////////////////////////////////////////////////////////////////

module dmem_dual(
    input  clk,
    input  we,
    input  [31:0] a,
    input  [31:0] wd,
    output [31:0] rd
    );

    // 64 palabras de 32 bits (256 bytes)
    reg [31:0] RAM[63:0];

    initial begin
        RAM[0] = 32'h0000000A;
        RAM[2] = 32'h0000001E;
    end

    // Lectura combinacional: MEM/WB captura el dato en el flanco correcto.
    assign rd = RAM[a[31:2]];

    // Escritura síncrona.
    always @(posedge clk) begin
        if (we)
            RAM[a[31:2]] <= wd;
    end

endmodule
