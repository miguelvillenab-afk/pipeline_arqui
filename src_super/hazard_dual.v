`timescale 1ns / 1ps
// Códigos de forwarding:
//   000 = sin forwarding
//   001 = MEM/WB vía A
//   010 = MEM/WB vía B
//   011 = EX/MEM vía A
//   100 = EX/MEM vía B

module hazard_dual(
    // Etapa ID
    input [4:0]  rs1_A, rs2_A,
    input [4:0]  rs1_B, rs2_B,
    input        issue_B,

    // ID/EX A
    input [4:0]  rs1_EX_A, rs2_EX_A, rd_EX_A,
    input [1:0]  ResultSrc_EX_A,
    input        RegWrite_EX_A,
    input        ALUSrc_EX_A,

    // ID/EX B
    input [4:0]  rs1_EX_B, rs2_EX_B, rd_EX_B,
    input [1:0]  ResultSrc_EX_B,
    input        RegWrite_EX_B,
    input        ALUSrc_EX_B,

    // EX/MEM
    input [4:0]  rd_MEM_A, rd_MEM_B,
    input        RegWrite_MEM_A, RegWrite_MEM_B,

    // MEM/WB
    input [4:0]  rd_WB_A, rd_WB_B,
    input        RegWrite_WB_A, RegWrite_WB_B,

    // Branch/jump resuelto en EX
    input        PCSrc_EX_A, PCSrc_EX_B,

    output reg        stall_IF_ID,
    output reg        flush_IF_ID,
    output reg        flush_ID_EX_A,
    output reg        flush_ID_EX_B,
    output reg [2:0]  fwdA_A, fwdB_A, fwdC_A,
    output reg [2:0]  fwdA_B, fwdB_B
    );

    wire lw_EX_A = (ResultSrc_EX_A == 2'b01) && RegWrite_EX_A;
    wire lw_EX_B = (ResultSrc_EX_B == 2'b01) && RegWrite_EX_B;

    wire A_usa_EX_A = (rd_EX_A != 5'd0) &&
                      ((rd_EX_A == rs1_A) || (rd_EX_A == rs2_A));
    wire A_usa_EX_B = (rd_EX_B != 5'd0) &&
                      ((rd_EX_B == rs1_A) || (rd_EX_B == rs2_A));
    wire B_usa_EX_A = issue_B && (rd_EX_A != 5'd0) &&
                      ((rd_EX_A == rs1_B) || (rd_EX_A == rs2_B));
    wire B_usa_EX_B = issue_B && (rd_EX_B != 5'd0) &&
                      ((rd_EX_B == rs1_B) || (rd_EX_B == rs2_B));

    wire lw_stall = (lw_EX_A && (A_usa_EX_A || B_usa_EX_A)) ||
                    (lw_EX_B && (A_usa_EX_B || B_usa_EX_B));

    always @(*) begin
        stall_IF_ID   = 1'b0;
        flush_IF_ID   = 1'b0;
        flush_ID_EX_A = 1'b0;
        flush_ID_EX_B = 1'b0;
        fwdA_A = 3'd0;  fwdB_A = 3'd0;  fwdC_A = 3'd0;
        fwdA_B = 3'd0;  fwdB_B = 3'd0;

        if (lw_stall) begin
            stall_IF_ID   = 1'b1;
            flush_ID_EX_A = 1'b1;
            flush_ID_EX_B = 1'b1;
        end
        else if (PCSrc_EX_A || PCSrc_EX_B) begin
            flush_IF_ID   = 1'b1;
            flush_ID_EX_A = 1'b1;
            flush_ID_EX_B = 1'b1;
        end

        // forwarding A: operando rs1
        if (RegWrite_MEM_A && (rd_MEM_A != 5'd0) && (rd_MEM_A == rs1_EX_A))
            fwdA_A = 3'd3;
        else if (RegWrite_MEM_B && (rd_MEM_B != 5'd0) && (rd_MEM_B == rs1_EX_A))
            fwdA_A = 3'd4;
        else if (RegWrite_WB_A && (rd_WB_A != 5'd0) && (rd_WB_A == rs1_EX_A))
            fwdA_A = 3'd1;
        else if (RegWrite_WB_B && (rd_WB_B != 5'd0) && (rd_WB_B == rs1_EX_A))
            fwdA_A = 3'd2;

        // forwarding A: operando rs2 (solo si ALUSrc = 0)
        if (!ALUSrc_EX_A) begin
            if (RegWrite_MEM_A && (rd_MEM_A != 5'd0) && (rd_MEM_A == rs2_EX_A))
                fwdB_A = 3'd3;
            else if (RegWrite_MEM_B && (rd_MEM_B != 5'd0) && (rd_MEM_B == rs2_EX_A))
                fwdB_A = 3'd4;
            else if (RegWrite_WB_A && (rd_WB_A != 5'd0) && (rd_WB_A == rs2_EX_A))
                fwdB_A = 3'd1;
            else if (RegWrite_WB_B && (rd_WB_B != 5'd0) && (rd_WB_B == rs2_EX_A))
                fwdB_A = 3'd2;
        end

        // forwarding vía A: dato de store (siempre rs2)
        if (RegWrite_MEM_A && (rd_MEM_A != 5'd0) && (rd_MEM_A == rs2_EX_A))
            fwdC_A = 3'd3;
        else if (RegWrite_MEM_B && (rd_MEM_B != 5'd0) && (rd_MEM_B == rs2_EX_A))
            fwdC_A = 3'd4;
        else if (RegWrite_WB_A && (rd_WB_A != 5'd0) && (rd_WB_A == rs2_EX_A))
            fwdC_A = 3'd1;
        else if (RegWrite_WB_B && (rd_WB_B != 5'd0) && (rd_WB_B == rs2_EX_A))
            fwdC_A = 3'd2;

        // forwarding B: operando rs1
        if (RegWrite_MEM_A && (rd_MEM_A != 5'd0) && (rd_MEM_A == rs1_EX_B))
            fwdA_B = 3'd3;
        else if (RegWrite_MEM_B && (rd_MEM_B != 5'd0) && (rd_MEM_B == rs1_EX_B))
            fwdA_B = 3'd4;
        else if (RegWrite_WB_A && (rd_WB_A != 5'd0) && (rd_WB_A == rs1_EX_B))
            fwdA_B = 3'd1;
        else if (RegWrite_WB_B && (rd_WB_B != 5'd0) && (rd_WB_B == rs1_EX_B))
            fwdA_B = 3'd2;

        // forwarding B: operando rs2 (solo si ALUSrc = 0)
        if (!ALUSrc_EX_B) begin
            if (RegWrite_MEM_A && (rd_MEM_A != 5'd0) && (rd_MEM_A == rs2_EX_B))
                fwdB_B = 3'd3;
            else if (RegWrite_MEM_B && (rd_MEM_B != 5'd0) && (rd_MEM_B == rs2_EX_B))
                fwdB_B = 3'd4;
            else if (RegWrite_WB_A && (rd_WB_A != 5'd0) && (rd_WB_A == rs2_EX_B))
                fwdB_B = 3'd1;
            else if (RegWrite_WB_B && (rd_WB_B != 5'd0) && (rd_WB_B == rs2_EX_B))
                fwdB_B = 3'd2;
        end
    end

endmodule