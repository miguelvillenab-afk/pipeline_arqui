`timescale 1ns / 1ps

module dmem(
    input clk, 
    input we,
    input [31:0] a, 
    input [31:0] wd,
    output [31:0] rd
);
  
    // 64 palabras de 32 bits (256 bytes de memoria)
    reg [31:0] RAM[63:0];
    integer i;

    initial begin
        // Memoria determinista: las palabras no inicializadas valen 0.
        for (i = 0; i < 64; i = i + 1)
            RAM[i] = 32'd0;
        RAM[0] = 32'h0000000A; 
        RAM[2] = 32'h0000001E; 
    end

    // Lectura combinacional: MEM/WB captura el dato en el mismo flanco en que
    // la instruccion esta en MEM, por lo que el dato debe estar estable antes.
    assign rd = RAM[a[31:2]];

    // Escritura sincrona.
    always @(posedge clk) begin
        if (we) begin
            RAM[a[31:2]] <= wd; 
        end
    end

endmodule