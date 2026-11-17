`timescale 1ns / 1ps
// imem_dual: memoria de instrucciones de 256 palabras con dos puertos de
// lectura (PC y PC+4). Mismo tamaño que imem del pipeline, para que el
// programa del profesor (90 instrucciones) entre completo.
module imem_dual #(
    parameter MEMFILE = "prueba_final.mem"
    )(
    input  [31:0] a0,
    input  [31:0] a1,
    output [31:0] rd0,
    output [31:0] rd1
    );

    reg [31:0] RAM [255:0];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            RAM[i] = 32'h00000013;      // NOP por defecto
        $readmemh(MEMFILE, RAM);
    end

    // [9:2] = 256 palabras (1 KB), igual que imem del pipeline
    assign rd0 = RAM[a0[9:2]];
    assign rd1 = RAM[a1[9:2]];
endmodule