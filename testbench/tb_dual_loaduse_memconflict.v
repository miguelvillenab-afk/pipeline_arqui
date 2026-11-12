`timescale 1ns / 1ps
module tb_dual_loaduse_memconflict;
    reg clk, reset;
    wire [31:0] PC, WriteData, DataAdr;
    wire MemWrite;

    top_dual #(.MEMFILE("dual_loaduse_memconflict.mem")) uut (
        .clk(clk), .reset(reset),
        .PC(PC), .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite)
    );

    // Señales internas para el waveform
    wire [31:0] Instr_A      = uut.rvd.dp.Instr_A;
    wire [31:0] Instr_B      = uut.rvd.dp.Instr_B;
    wire        issue_B_comb = uut.rvd.dp.issue_B_comb;
    wire        stall_ifid   = uut.rvd.dp.stall_ifid_hz;
    wire        flush_idex_a = uut.rvd.dp.flush_idex_a_hz;

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        reset = 1; #22; reset = 0;
        #400; $finish;
    end
endmodule