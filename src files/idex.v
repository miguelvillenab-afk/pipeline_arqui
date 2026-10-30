`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2026 13:29:28
// Design Name: 
// Module Name: idex
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module idex(
    input clk,
    input reset,
    
    input stall_ID_EX, 
    input flush_ID_EX,
    
    input  [31:0] SrcA,
    input  [31:0] WriteData,
    input  [31:0] ImmExt,
    input  [31:0] IF_ID_PC4,
    input  [4:0]  rs1,
    input  [4:0]  rs2,
    input  [4:0]  rd,
    
    input        ALUSrc,
    input  [2:0] ALUControl,
    input        RegWrite,
    input        MemWrite,
    input  [1:0] ResultSrc,
    input        Branch,
    input        Jump,
    input  [1:0] ImmSrc,
    
    output [31:0] ID_EX_SrcA,
    output [31:0] ID_EX_WriteData,
    output [31:0] ID_EX_ImmExt,
    output [31:0] ID_EX_PC4,
    output [4:0]  ID_EX_rs1,
    output [4:0]  ID_EX_rs2,
    output [4:0]  ID_EX_rd,
    
    output        ID_EX_ALUSrc,
    output [2:0]  ID_EX_ALUControl,
    output        ID_EX_RegWrite,
    output        ID_EX_MemWrite,
    output [1:0]  ID_EX_ResultSrc,
    output        ID_EX_Branch,
    output        ID_EX_Jump,
    output [1:0]  ID_EX_ImmSrc
    );
    
    wire[154:0] d_concat;
    
    assign d_concat = {
        SrcA, 
        WriteData, 
        ImmExt, 
        IF_ID_PC4, 
        rs1, 
        rs2, 
        rd,
        ALUSrc, 
        ALUControl, 
        RegWrite, 
        MemWrite, 
        ResultSrc, 
        Branch, 
        Jump, 
        ImmSrc
    };
    
    wire[154:0] q_concat;
    
    flopr #(.WIDTH(155)) reg_idex (
        .clk(clk),
        .reset(reset),
        .d(d_concat),
        .q(q_concat)
    );
    
    assign {ID_EX_SrcA, 
            ID_EX_WriteData, 
            ID_EX_ImmExt, 
            ID_EX_PC4, 
            ID_EX_rs1, 
            ID_EX_rs2, 
            ID_EX_rd,
            ID_EX_ALUSrc, 
            ID_EX_ALUControl, 
            ID_EX_RegWrite, 
            ID_EX_MemWrite, 
            ID_EX_ResultSrc, 
            ID_EX_Branch, 
            ID_EX_Jump, 
            ID_EX_ImmSrc} = q_concat;
endmodule
