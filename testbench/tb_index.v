`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench autocontenido del registro ID/EX (antes tb_index.v).
//
// Verifica:
//   1. reset -> todas las salidas en 0
//   2. captura de operandos, PC, PC4, rs1/rs2/rd y todas las señales de control
//   3. stall_ID_EX mantiene el valor anterior
//   4. flush_ID_EX limpia a burbuja (todo 0)
//   5. flush tiene prioridad sobre stall
//////////////////////////////////////////////////////////////////////////////////

module tb_idex;

  reg clk;
  reg reset;
  reg stall_ID_EX;
  reg flush_ID_EX;

  reg [31:0] SrcA;
  reg [31:0] WriteData;
  reg [31:0] ImmExt;
  reg [31:0] IF_ID_PC;
  reg [31:0] IF_ID_PC4;
  reg [4:0]  rs1;
  reg [4:0]  rs2;
  reg [4:0]  rd;

  reg        ALUSrc;
  reg [2:0]  ALUControl;
  reg        RegWrite;
  reg        MemWrite;
  reg [1:0]  ResultSrc;
  reg        Branch;
  reg        Jump;
  reg [1:0]  ImmSrc;

  wire [31:0] ID_EX_SrcA;
  wire [31:0] ID_EX_WriteData;
  wire [31:0] ID_EX_ImmExt;
  wire [31:0] ID_EX_PC;
  wire [31:0] ID_EX_PC4;
  wire [4:0]  ID_EX_rs1;
  wire [4:0]  ID_EX_rs2;
  wire [4:0]  ID_EX_rd;

  wire        ID_EX_ALUSrc;
  wire [2:0]  ID_EX_ALUControl;
  wire        ID_EX_RegWrite;
  wire        ID_EX_MemWrite;
  wire [1:0]  ID_EX_ResultSrc;
  wire        ID_EX_Branch;
  wire        ID_EX_Jump;
  wire [1:0]  ID_EX_ImmSrc;

  integer errors;

  idex dut (
    .clk           (clk),
    .reset         (reset),
    .stall_ID_EX   (stall_ID_EX),
    .flush_ID_EX   (flush_ID_EX),

    .SrcA          (SrcA),
    .WriteData     (WriteData),
    .ImmExt        (ImmExt),
    .IF_ID_PC      (IF_ID_PC),
    .IF_ID_PC4     (IF_ID_PC4),
    .rs1           (rs1),
    .rs2           (rs2),
    .rd            (rd),

    .ALUSrc        (ALUSrc),
    .ALUControl    (ALUControl),
    .RegWrite      (RegWrite),
    .MemWrite      (MemWrite),
    .ResultSrc     (ResultSrc),
    .Branch        (Branch),
    .Jump          (Jump),
    .ImmSrc        (ImmSrc),

    .ID_EX_SrcA       (ID_EX_SrcA),
    .ID_EX_WriteData  (ID_EX_WriteData),
    .ID_EX_ImmExt     (ID_EX_ImmExt),
    .ID_EX_PC         (ID_EX_PC),
    .ID_EX_PC4        (ID_EX_PC4),
    .ID_EX_rs1        (ID_EX_rs1),
    .ID_EX_rs2        (ID_EX_rs2),
    .ID_EX_rd         (ID_EX_rd),
    .ID_EX_ALUSrc     (ID_EX_ALUSrc),
    .ID_EX_ALUControl (ID_EX_ALUControl),
    .ID_EX_RegWrite   (ID_EX_RegWrite),
    .ID_EX_MemWrite   (ID_EX_MemWrite),
    .ID_EX_ResultSrc  (ID_EX_ResultSrc),
    .ID_EX_Branch     (ID_EX_Branch),
    .ID_EX_Jump       (ID_EX_Jump),
    .ID_EX_ImmSrc     (ID_EX_ImmSrc)
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

  task check5(input [4:0] got, input [4:0] exp, input [255:0] label);
    begin
      check32({27'b0, got}, {27'b0, exp}, label);
    end
  endtask

  task check3(input [2:0] got, input [2:0] exp, input [255:0] label);
    begin
      check32({29'b0, got}, {29'b0, exp}, label);
    end
  endtask

  task check2(input [1:0] got, input [1:0] exp, input [255:0] label);
    begin
      check32({30'b0, got}, {30'b0, exp}, label);
    end
  endtask

  task check1(input got, input exp, input [255:0] label);
    begin
      check32({31'b0, got}, {31'b0, exp}, label);
    end
  endtask

  initial begin
    clk          = 0;
    reset        = 1;
    stall_ID_EX  = 0;
    flush_ID_EX  = 0;
    SrcA         = 0;
    WriteData    = 0;
    ImmExt       = 0;
    IF_ID_PC     = 0;
    IF_ID_PC4    = 0;
    rs1          = 0;
    rs2          = 0;
    rd           = 0;
    ALUSrc       = 0;
    ALUControl   = 0;
    RegWrite     = 0;
    MemWrite     = 0;
    ResultSrc    = 0;
    Branch       = 0;
    Jump         = 0;
    ImmSrc       = 0;
    errors       = 0;

    // Reset
    @(posedge clk); #1;
    check32(ID_EX_SrcA,      32'h0, "reset SrcA");
    check32(ID_EX_PC,        32'h0, "reset PC");
    check1 (ID_EX_RegWrite,  1'b0,  "reset RegWrite");
    check1 (ID_EX_MemWrite,  1'b0,  "reset MemWrite");
    check1 (ID_EX_Branch,    1'b0,  "reset Branch");
    check1 (ID_EX_Jump,      1'b0,  "reset Jump");

    // Captura normal
    reset = 0;
    @(negedge clk);
    SrcA       = 32'hAAAA_AAAA;
    WriteData  = 32'h1111_1111;
    ImmExt     = 32'hFFFF_FFF0;
    IF_ID_PC   = 32'h0000_0100;
    IF_ID_PC4  = 32'h0000_0104;
    rs1        = 5'd1;
    rs2        = 5'd2;
    rd         = 5'd3;
    ALUSrc     = 1'b1;
    ALUControl = 3'b010;
    RegWrite   = 1'b1;
    MemWrite   = 1'b1;
    ResultSrc  = 2'b01;
    Branch     = 1'b1;
    Jump       = 1'b1;
    ImmSrc     = 2'b10;

    @(posedge clk); #1;
    check32(ID_EX_SrcA,      32'hAAAA_AAAA, "captura SrcA");
    check32(ID_EX_WriteData, 32'h1111_1111, "captura WriteData");
    check32(ID_EX_ImmExt,    32'hFFFF_FFF0, "captura ImmExt");
    check32(ID_EX_PC,        32'h0000_0100, "captura PC");
    check32(ID_EX_PC4,       32'h0000_0104, "captura PC4");
    check5 (ID_EX_rs1,       5'd1,          "captura rs1");
    check5 (ID_EX_rs2,       5'd2,          "captura rs2");
    check5 (ID_EX_rd,        5'd3,          "captura rd");
    check1 (ID_EX_ALUSrc,    1'b1,          "captura ALUSrc");
    check3 (ID_EX_ALUControl,3'b010,        "captura ALUControl");
    check1 (ID_EX_RegWrite,  1'b1,          "captura RegWrite");
    check1 (ID_EX_MemWrite,  1'b1,          "captura MemWrite");
    check2 (ID_EX_ResultSrc, 2'b01,         "captura ResultSrc");
    check1 (ID_EX_Branch,    1'b1,          "captura Branch");
    check1 (ID_EX_Jump,      1'b1,          "captura Jump");
    check2 (ID_EX_ImmSrc,    2'b10,         "captura ImmSrc");

    // Stall: debe mantener todo
    @(negedge clk);
    stall_ID_EX = 1;
    SrcA       = 32'hBBBB_BBBB;
    WriteData  = 32'h2222_2222;
    ImmExt     = 32'h0000_0008;
    IF_ID_PC   = 32'h0000_0200;
    IF_ID_PC4  = 32'h0000_0204;
    rs1        = 5'd4;
    rs2        = 5'd5;
    rd         = 5'd6;
    ALUSrc     = 1'b0;
    ALUControl = 3'b001;
    RegWrite   = 1'b0;
    MemWrite   = 1'b0;
    ResultSrc  = 2'b10;
    Branch     = 1'b0;
    Jump       = 1'b0;
    ImmSrc     = 2'b01;

    @(posedge clk); #1;
    check32(ID_EX_SrcA,      32'hAAAA_AAAA, "stall mantiene SrcA");
    check32(ID_EX_WriteData, 32'h1111_1111, "stall mantiene WriteData");
    check32(ID_EX_PC,        32'h0000_0100, "stall mantiene PC");
    check5 (ID_EX_rd,        5'd3,          "stall mantiene rd");
    check1 (ID_EX_RegWrite,  1'b1,          "stall mantiene RegWrite");
    check2 (ID_EX_ResultSrc, 2'b01,         "stall mantiene ResultSrc");

    // Flush: burbuja (todo 0)
    @(negedge clk);
    stall_ID_EX = 0;
    flush_ID_EX = 1;
    @(posedge clk); #1;
    check32(ID_EX_SrcA,      32'h0, "flush limpia SrcA");
    check32(ID_EX_WriteData, 32'h0, "flush limpia WriteData");
    check32(ID_EX_PC,        32'h0, "flush limpia PC");
    check5 (ID_EX_rd,        5'd0,  "flush limpia rd");
    check1 (ID_EX_RegWrite,  1'b0,  "flush limpia RegWrite");
    check1 (ID_EX_MemWrite,  1'b0,  "flush limpia MemWrite");
    check1 (ID_EX_Branch,    1'b0,  "flush limpia Branch");
    check1 (ID_EX_Jump,      1'b0,  "flush limpia Jump");

    // Flush + stall: gana flush
    @(negedge clk);
    stall_ID_EX = 1;
    flush_ID_EX = 1;
    SrcA        = 32'hCCCC_CCCC;
    @(posedge clk); #1;
    check32(ID_EX_SrcA, 32'h0, "flush gana sobre stall");

    // Reset final
    @(negedge clk);
    flush_ID_EX = 0;
    stall_ID_EX = 0;
    reset       = 1;
    SrcA        = 32'hDDDD_DDDD;
    @(posedge clk); #1;
    check32(ID_EX_SrcA, 32'h0, "reset final SrcA");

    if (errors == 0)
      $display("TESTBENCH ID/EX: PASS");
    else
      $display("TESTBENCH ID/EX: FAIL (%0d errores)", errors);

    $finish;
  end

endmodule
