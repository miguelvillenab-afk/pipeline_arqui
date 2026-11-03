`timescale 1ns / 1ps

module imem_dual(
    input [31:0] a0,
    input [31:0] a1,
    output [31:0] rd0,
    output [31:0] rd1
    );
    
    reg [31:0] RAM [63:0];
    
    initial begin 
        $readmemh("program1.mem", RAM);
    end
    
    assign rd0 = RAM[a0[31:2]];
    assign rd1 = RAM[a1[31:2]];

endmodule