`timescale 1ns / 1ps

module hazard_unit (
    input [4:0] rs1_ID, rs2_ID,
    input [4:0] rs1_EX, rs2_EX,
    input [4:0] rd_EX, rd_MEM,
    input [1:0] ResultSrc_EX,
    input       RegWrite_EX,
    input       RegWrite_MEM,
    input       RegWrite_WB,
    input [4:0] rd_WB,
    input       ALUSrc_EX,
    input       PCSrc_EX,
    output reg  stall_IF_ID,
    output reg  stall_ID_EX,
    output reg  flush_IF_ID,
    output reg  flush_ID_EX,
    output reg [1:0] ForwardA, ForwardB,
    output reg [1:0] ForwardC
);

    wire lw_in_EX = (ResultSrc_EX == 2'b01) && RegWrite_EX;
    
    wire lw_stall = lw_in_EX && (rd_EX != 5'd0) && 
                    ((rd_EX == rs1_ID) || (rd_EX == rs2_ID));

    always @(*) begin
        stall_IF_ID = 0; 
        stall_ID_EX = 0; 
        flush_IF_ID = 0; 
        flush_ID_EX = 0;
        ForwardA = 2'b00; 
        ForwardB = 2'b00;
        ForwardC = 2'b00;
        
        if (lw_stall) begin
            stall_IF_ID = 1;
            stall_ID_EX = 1;
            flush_ID_EX = 1;
        end
        else if (PCSrc_EX) begin
            flush_IF_ID = 1;
            flush_ID_EX = 1; 
        end
        
        // Forwarding desde EX/MEM
        if (RegWrite_MEM && (rd_MEM != 5'd0) && (rd_MEM == rs1_EX)) 
            ForwardA = 2'b10;
        if (RegWrite_MEM && (rd_MEM != 5'd0) && (rd_MEM == rs2_EX) && !ALUSrc_EX) 
            ForwardB = 2'b10;
        if (RegWrite_MEM && (rd_MEM != 5'd0) && (rd_MEM == rs2_EX)) 
            ForwardC = 2'b10;
        
        // Forwarding desde MEM/WB
        if (RegWrite_WB && (rd_WB != 5'd0) && (rd_WB == rs1_EX) && !(RegWrite_MEM && (rd_MEM == rs1_EX))) 
            ForwardA = 2'b01;
        if (RegWrite_WB && (rd_WB != 5'd0) && (rd_WB == rs2_EX) && !(RegWrite_MEM && (rd_MEM == rs2_EX)) && !ALUSrc_EX) 
            ForwardB = 2'b01;
        if (RegWrite_WB && (rd_WB != 5'd0) && (rd_WB == rs2_EX) && !(RegWrite_MEM && (rd_MEM == rs2_EX))) 
            ForwardC = 2'b01;
    end

endmodule