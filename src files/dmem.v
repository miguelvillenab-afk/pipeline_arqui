`timescale 1ns / 1ps

module dmem(
    input clk, 
    input we,
    input [31:0] a, 
    input [31:0] wd,
    output reg [31:0] rd
);
  
    // 64 palabras de 32 bits (256 bytes de memoria)
    reg [31:0] RAM[63:0]; 

    initial begin
        RAM[0] = 32'h0000000A; 
        RAM[2] = 32'h0000001E; 
    end

    always @(posedge clk) begin
        // Lectura y escritura sincronizadas
        rd <= RAM[a[31:2]]; 
        if (we) begin
            RAM[a[31:2]] <= wd; 
        end
    end

endmodule