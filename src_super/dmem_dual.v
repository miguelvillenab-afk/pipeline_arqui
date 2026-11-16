`timescale 1ns / 1ps
// dmem_dual: memoria de datos de 512 palabras (2 KB), igual que dmem del
// pipeline. Las direcciones 1536-1588 del programa del profesor caen en las
// palabras 384-397 sin recortar la dirección.
module dmem_dual(
    input  clk,
    input  we,
    input  [31:0] a,
    input  [31:0] wd,
    output [31:0] rd
    );

    reg [31:0] RAM [511:0];
    integer i;

    initial begin
        for (i = 0; i < 512; i = i + 1)
            RAM[i] = 32'b0;
        RAM[0] = 32'h0000000A;
        RAM[2] = 32'h0000001E;
    end

    assign rd = RAM[a[10:2]];

    always @(posedge clk)
        if (we) RAM[a[10:2]] <= wd;
endmodule