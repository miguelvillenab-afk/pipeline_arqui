`timescale 1ns / 1ps
module imem_dual #(
    parameter MEMFILE = "program1.mem"
    )(
    input  [31:0] a0,
    input  [31:0] a1,
    output [31:0] rd0,
    output [31:0] rd1
    );

    reg [31:0] RAM [63:0];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1)
            RAM[i] = 32'h00000013;      // NOP por defecto
        $readmemh(MEMFILE, RAM);
    end

    // [7:2] = 64 palabras; evita índices fuera de rango (X)
    assign rd0 = RAM[a0[7:2]];
    assign rd1 = RAM[a1[7:2]];
endmodule