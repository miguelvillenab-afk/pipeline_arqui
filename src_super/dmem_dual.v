`timescale 1ns / 1ps
module dmem_dual(
    input  clk,
    input  we,
    input  [31:0] a,
    input  [31:0] wd,
    output [31:0] rd
    );

    reg [31:0] RAM [63:0];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1)
            RAM[i] = 32'b0;
        RAM[0] = 32'h0000000A;
        RAM[2] = 32'h0000001E;
    end

    assign rd = RAM[a[7:2]];

    always @(posedge clk)
        if (we) RAM[a[7:2]] <= wd;
endmodule