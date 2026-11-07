`timescale 1ns / 1ps

// imem_dual: memoria de instrucciones de dos puertos de lectura.
//
// MEMFILE permite cargar distintos programas de prueba sin renombrar archivos.
// El valor por defecto mantiene el comportamiento anterior (program1.mem).
module imem_dual #(
    parameter MEMFILE = "program1.mem"
    )(
    input [31:0] a0,
    input [31:0] a1,
    output [31:0] rd0,
    output [31:0] rd1
    );

    reg [31:0] RAM [63:0];

    initial begin
        $readmemh(MEMFILE, RAM);
    end

    assign rd0 = RAM[a0[31:2]];
    assign rd1 = RAM[a1[31:2]];

endmodule
