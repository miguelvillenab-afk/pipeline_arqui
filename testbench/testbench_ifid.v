`timescale 1ns/1ps

module testbench_ifid;
  reg clk;
  reg reset;
  reg stall;
  reg flush;
  reg [31:0] Instr_in;
  reg [31:0] PC_in;
  reg [31:0] PC4_in;

  wire [31:0] IF_ID_Instr;
  wire [31:0] IF_ID_PC;
  wire [31:0] IF_ID_PC4;

  ifid dut(
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .flush(flush),
    .Instr_in(Instr_in),
    .PC_in(PC_in),
    .PC4_in(PC4_in),
    .IF_ID_Instr(IF_ID_Instr),
    .IF_ID_PC(IF_ID_PC),
    .IF_ID_PC4(IF_ID_PC4)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 0;
    reset = 1;
    stall = 0;
    flush = 0;
    Instr_in = 32'h00000013;
    PC_in    = 32'h00000000;
    PC4_in   = 32'h00000004;

    #20 reset = 0;

    #20;
    Instr_in = 32'h00100093;
    PC_in    = 32'h00000004;
    PC4_in   = 32'h00000008;

    #20 stall = 1;
    Instr_in = 32'h00200093;
    PC_in    = 32'h00000008;
    PC4_in   = 32'h0000000c;

    #20 stall = 0;
    Instr_in = 32'h00300093;
    PC_in    = 32'h0000000c;
    PC4_in   = 32'h00000010;

    #20 flush = 1;
    #20 flush = 0;

    #20 $finish;
  end
endmodule