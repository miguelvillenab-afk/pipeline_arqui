`timescale 1ns / 1ps
module tb_dual_branch_flush;
    reg clk, reset;
    wire [31:0] PC, WriteData, DataAdr;
    wire MemWrite;

    top_dual #(.MEMFILE("dual_branch_flush.mem")) uut (
        .clk(clk), .reset(reset),
        .PC(PC), .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite)
    );

    // Señales internas para el waveform
    wire [31:0] Instr_A       = uut.rvd.dp.Instr_A;
    wire [31:0] Instr_B       = uut.rvd.dp.Instr_B;
    wire        issue_B_comb  = uut.rvd.dp.issue_B_comb;
    wire        flush_ifid_hz = uut.rvd.dp.flush_ifid_hz;
    wire        flush_idex_a_hz = uut.rvd.dp.flush_idex_a_hz;
    wire        flush_idex_b_hz = uut.rvd.dp.flush_idex_b_hz;
    wire        ex_PCSrc      = uut.rvd.dp.ex_PCSrc;
    wire        ex_PCSrc_B    = uut.rvd.dp.ex_PCSrc_B;
    wire        MEM_WB_RegWrite   = uut.rvd.dp.MEM_WB_RegWrite;
    wire        MEM_WB_B_RegWrite = uut.rvd.dp.MEM_WB_B_RegWrite;

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        reset = 1; #22; reset = 0;
        #400; $finish;
    end
endmodule