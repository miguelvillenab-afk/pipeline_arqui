`timescale 1ns / 1ps
module hazard_opt(
    input [4:0]  rs1_A, rs2_A,
    input [4:0]  rs1_B, rs2_B,
    input        issue_B,
    input [4:0]  rs1_EX_A, rs2_EX_A, rd_EX_A,
    input [1:0]  ResultSrc_EX_A,
    input        RegWrite_EX_A,
    input        ALUSrc_EX_A,
    input [4:0]  rs1_EX_B, rs2_EX_B, rd_EX_B,
    input [1:0]  ResultSrc_EX_B,
    input        RegWrite_EX_B,
    input        ALUSrc_EX_B,
    input [4:0]  rd_MEM_A, rd_MEM_B,
    input        RegWrite_MEM_A, RegWrite_MEM_B,
    input [4:0]  rd_WB_A, rd_WB_B,
    input        RegWrite_WB_A, RegWrite_WB_B,
    input        PCSrc_EX_A, PCSrc_EX_B,
    
    // NUEVO: Señales para detectar Mispredict
    input        ID_EX_Branch, ID_EX_Jump, ID_EX_predict_taken,
    input        ID_EX_B_Branch, ID_EX_B_Jump, ID_EX_B_predict_taken,
    
    output reg        stall_IF_ID,
    output reg        flush_IF_ID,
    output reg        flush_ID_EX_A,
    output reg        flush_ID_EX_B,
    output [2:0]      fwdA_A, fwdB_A, fwdC_A,
    output [2:0]      fwdA_B, fwdB_B, fwdC_B
);

    // Prioridad: MEM_A > MEM_B > WB_A > WB_B
    function [2:0] fwd(
        input [4:0] rs,
        input [4:0] rdMA, input wMA,
        input [4:0] rdMB, input wMB,
        input [4:0] rdWA, input wWA,
        input [4:0] rdWB, input wWB
    );
        begin
            if      (wMA && rdMA != 5'd0 && rdMA == rs) fwd = 3'd3;
            else if (wMB && rdMB != 5'd0 && rdMB == rs) fwd = 3'd4;
            else if (wWA && rdWA != 5'd0 && rdWA == rs) fwd = 3'd1;
            else if (wWB && rdWB != 5'd0 && rdWB == rs) fwd = 3'd2;
            else                                        fwd = 3'd0;
        end
    endfunction

    // Forwarding (Igual que en tu E2)
    assign fwdA_A = fwd(rs1_EX_A, rd_MEM_A, RegWrite_MEM_A, rd_MEM_B, RegWrite_MEM_B, rd_WB_A, RegWrite_WB_A, rd_WB_B, RegWrite_WB_B);
    assign fwdB_A = ALUSrc_EX_A ? 3'd0 : fwd(rs2_EX_A, rd_MEM_A, RegWrite_MEM_A, rd_MEM_B, RegWrite_MEM_B, rd_WB_A, RegWrite_WB_A, rd_WB_B, RegWrite_WB_B);
    assign fwdC_A = fwd(rs2_EX_A, rd_MEM_A, RegWrite_MEM_A, rd_MEM_B, RegWrite_MEM_B, rd_WB_A, RegWrite_WB_A, rd_WB_B, RegWrite_WB_B);
    assign fwdA_B = fwd(rs1_EX_B, rd_MEM_A, RegWrite_MEM_A, rd_MEM_B, RegWrite_MEM_B, rd_WB_A, RegWrite_WB_A, rd_WB_B, RegWrite_WB_B);
    assign fwdB_B = ALUSrc_EX_B ? 3'd0 : fwd(rs2_EX_B, rd_MEM_A, RegWrite_MEM_A, rd_MEM_B, RegWrite_MEM_B, rd_WB_A, RegWrite_WB_A, rd_WB_B, RegWrite_WB_B);
    assign fwdC_B = fwd(rs2_EX_B, rd_MEM_A, RegWrite_MEM_A, rd_MEM_B, RegWrite_MEM_B, rd_WB_A, RegWrite_WB_A, rd_WB_B, RegWrite_WB_B);

    // Load-use (Igual que en tu E2)
    wire lw_EX_A = (ResultSrc_EX_A == 2'b01) && RegWrite_EX_A;
    wire lw_EX_B = (ResultSrc_EX_B == 2'b01) && RegWrite_EX_B;
    wire A_usa_EX_A = (rd_EX_A != 5'd0) && ((rd_EX_A == rs1_A) || (rd_EX_A == rs2_A));
    wire A_usa_EX_B = (rd_EX_B != 5'd0) && ((rd_EX_B == rs1_A) || (rd_EX_B == rs2_A));
    wire B_usa_EX_A = issue_B && (rd_EX_A != 5'd0) && ((rd_EX_A == rs1_B) || (rd_EX_A == rs2_B));
    wire B_usa_EX_B = issue_B && (rd_EX_B != 5'd0) && ((rd_EX_B == rs1_B) || (rd_EX_B == rs2_B));
    wire lw_stall = (lw_EX_A && (A_usa_EX_A || B_usa_EX_A)) || (lw_EX_B && (A_usa_EX_B || B_usa_EX_B));

    // NUEVO: Detección de Mispredict (Fallo de Predicción)
    // Si fue branch/jump y el resultado real (PCSrc) es distinto al predicho, es un fallo.
    wire mispred_A = (ID_EX_Branch || ID_EX_Jump) && (PCSrc_EX_A != ID_EX_predict_taken);
    wire mispred_B = (ID_EX_B_Branch || ID_EX_B_Jump) && (PCSrc_EX_B != ID_EX_B_predict_taken);
    wire mispredict = mispred_A || mispred_B;

    always @(*) begin
        stall_IF_ID   = 1'b0;
        flush_IF_ID   = 1'b0;
        flush_ID_EX_A = 1'b0;
        flush_ID_EX_B = 1'b0;

        // Prioridad 1: Fallo de predicción (solo si el predictor se equivocó)
        if (mispredict) begin
            flush_IF_ID   = 1'b1;
            flush_ID_EX_A = 1'b1;
            flush_ID_EX_B = 1'b1;
        end
        // Prioridad 2: load-use
        else if (lw_stall) begin
            stall_IF_ID   = 1'b1;
            flush_ID_EX_A = 1'b1;
            flush_ID_EX_B = 1'b1;
        end
    end
endmodule