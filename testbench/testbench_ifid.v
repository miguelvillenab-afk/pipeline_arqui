`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench autocontenido del registro IF/ID.
//
// Verifica:
//   1. reset -> NOP / PC=0 / PC4=0
//   2. captura normal de Instr, PC y PC4
//   3. stall mantiene el valor anterior
//   4. flush inserta NOP
//   5. flush tiene prioridad sobre stall
//////////////////////////////////////////////////////////////////////////////////

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

  localparam [31:0] NOP = 32'h0000_0013;

  integer errors;

  ifid dut(
    .clk        (clk),
    .reset      (reset),
    .stall      (stall),
    .flush      (flush),
    .Instr_in   (Instr_in),
    .PC_in      (PC_in),
    .PC4_in     (PC4_in),
    .IF_ID_Instr(IF_ID_Instr),
    .IF_ID_PC   (IF_ID_PC),
    .IF_ID_PC4  (IF_ID_PC4)
  );

  always #5 clk = ~clk;

  task check32(input [31:0] got, input [31:0] exp, input [255:0] label);
    begin
      if (got !== exp) begin
        $display("FAIL %0s: got %h, expected %h", label, got, exp);
        errors = errors + 1;
      end else begin
        $display("PASS %0s", label);
      end
    end
  endtask

  initial begin
    clk      = 0;
    reset    = 1;
    stall    = 0;
    flush    = 0;
    Instr_in = NOP;
    PC_in    = 32'h0000_0000;
    PC4_in   = 32'h0000_0004;
    errors   = 0;

    // Reset
    @(posedge clk); #1;
    check32(IF_ID_Instr, NOP,        "reset Instr = NOP");
    check32(IF_ID_PC,    32'h0,      "reset PC = 0");
    check32(IF_ID_PC4,   32'h0,      "reset PC4 = 0");

    // Captura normal
    reset = 0;
    @(negedge clk);
    Instr_in = 32'h0010_0093; // addi x1, x0, 1
    PC_in    = 32'h0000_0004;
    PC4_in   = 32'h0000_0008;
    @(posedge clk); #1;
    check32(IF_ID_Instr, 32'h0010_0093, "captura Instr");
    check32(IF_ID_PC,    32'h0000_0004, "captura PC");
    check32(IF_ID_PC4,   32'h0000_0008, "captura PC4");

    // Stall: los valores deben mantenerse
    @(negedge clk);
    stall    = 1;
    Instr_in = 32'h0020_0093; // addi x1, x0, 2
    PC_in    = 32'h0000_0008;
    PC4_in   = 32'h0000_000c;
    @(posedge clk); #1;
    check32(IF_ID_Instr, 32'h0010_0093, "stall mantiene Instr");
    check32(IF_ID_PC,    32'h0000_0004, "stall mantiene PC");
    check32(IF_ID_PC4,   32'h0000_0008, "stall mantiene PC4");

    // Flush: burbuja NOP
    @(negedge clk);
    stall = 0;
    flush = 1;
    @(posedge clk); #1;
    check32(IF_ID_Instr, NOP,   "flush inserta NOP");
    check32(IF_ID_PC,    32'h0, "flush limpia PC");
    check32(IF_ID_PC4,   32'h0, "flush limpia PC4");

    // Flush + stall: gana flush
    @(negedge clk);
    flush    = 1;
    stall    = 1;
    Instr_in = 32'h0030_0093;
    PC_in    = 32'h0000_000c;
    PC4_in   = 32'h0000_0010;
    @(posedge clk); #1;
    check32(IF_ID_Instr, NOP,   "flush gana sobre stall (Instr)");
    check32(IF_ID_PC,    32'h0, "flush gana sobre stall (PC)");

    // Reset final
    @(negedge clk);
    flush = 0;
    stall = 0;
    reset = 1;
    @(posedge clk); #1;
    check32(IF_ID_Instr, NOP,   "reset final Instr");
    check32(IF_ID_PC,    32'h0, "reset final PC");

    if (errors == 0)
      $display("TESTBENCH IF/ID: PASS");
    else
      $display("TESTBENCH IF/ID: FAIL (%0d errores)", errors);

    $finish;
  end

endmodule
