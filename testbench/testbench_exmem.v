`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench de la etapa EX + registro EX/MEM (Fase 3).
//
// Verifica:
//   1. reset del registro EX/MEM
//   2. ALU add -> EX_MEM_ALUResult correcto y EX_MEM_Zero = 0
//   3. ALU sub con resultado 0 -> EX_MEM_Zero = 1
//   4. captura de WriteData, rd, PC4, PCTarget y controles MEM/WB
//   5. cálculo de PCTarget para branch/jal: ID_EX_PC + ImmExt
//////////////////////////////////////////////////////////////////////////////////

module testbench_exmem;

  reg clk;
  reg reset;

  reg [31:0] SrcA;
  reg [31:0] WriteData;
  reg [31:0] ImmExt;
  reg [31:0] PC;
  reg [31:0] PC4;
  reg [4:0]  rd;

  reg        ALUSrc;
  reg [2:0]  ALUControl;
  reg        RegWrite;
  reg        MemWrite;
  reg [1:0]  ResultSrc;
  reg        Branch;
  reg        Jump;

  wire [31:0] SrcB;
  wire [31:0] ALUResult;
  wire [31:0] PCTarget;
  wire        Zero;

  wire [31:0] EX_MEM_ALUResult;
  wire        EX_MEM_Zero;
  wire [31:0] EX_MEM_WriteData;
  wire [4:0]  EX_MEM_rd;
  wire [31:0] EX_MEM_PC4;
  wire [31:0] EX_MEM_PCTarget;
  wire        EX_MEM_MemWrite;
  wire        EX_MEM_RegWrite;
  wire [1:0]  EX_MEM_ResultSrc;
  wire        EX_MEM_Branch;
  wire        EX_MEM_Jump;

  integer errors;

  mux2 #(32) srcbmux (
    .d0 (WriteData),
    .d1 (ImmExt),
    .s  (ALUSrc),
    .y  (SrcB)
  );

  alu alu (
    .a          (SrcA),
    .b          (SrcB),
    .alucontrol (ALUControl),
    .result     (ALUResult),
    .zero       (Zero)
  );

  adder pcaddbranch (
    .a (PC),
    .b (ImmExt),
    .y (PCTarget)
  );

  exmem dut (
    .clk             (clk),
    .reset           (reset),
    .ALUResult       (ALUResult),
    .Zero            (Zero),
    .WriteData       (WriteData),
    .rd              (rd),
    .PC4             (PC4),
    .PCTarget        (PCTarget),
    .MemWrite        (MemWrite),
    .RegWrite        (RegWrite),
    .ResultSrc       (ResultSrc),
    .Branch          (Branch),
    .Jump            (Jump),
    .EX_MEM_ALUResult(EX_MEM_ALUResult),
    .EX_MEM_Zero     (EX_MEM_Zero),
    .EX_MEM_WriteData(EX_MEM_WriteData),
    .EX_MEM_rd       (EX_MEM_rd),
    .EX_MEM_PC4      (EX_MEM_PC4),
    .EX_MEM_PCTarget (EX_MEM_PCTarget),
    .EX_MEM_MemWrite (EX_MEM_MemWrite),
    .EX_MEM_RegWrite (EX_MEM_RegWrite),
    .EX_MEM_ResultSrc(EX_MEM_ResultSrc),
    .EX_MEM_Branch   (EX_MEM_Branch),
    .EX_MEM_Jump     (EX_MEM_Jump)
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
    clk        = 0;
    reset      = 1;
    SrcA       = 0;
    WriteData  = 0;
    ImmExt     = 0;
    PC         = 0;
    PC4        = 0;
    rd         = 0;
    ALUSrc     = 0;
    ALUControl = 0;
    RegWrite   = 0;
    MemWrite   = 0;
    ResultSrc  = 0;
    Branch     = 0;
    Jump       = 0;
    errors     = 0;

    // Reset
    @(posedge clk); #1;
    check32(EX_MEM_ALUResult, 32'h0, "reset ALUResult");
    check1 (EX_MEM_Zero,      1'b0,  "reset Zero");
    check1 (EX_MEM_RegWrite,  1'b0,  "reset RegWrite");
    check1 (EX_MEM_MemWrite,  1'b0,  "reset MemWrite");

    // addi x3, x0, 5  -> ALU add 10 + 5 = 15
    reset = 0;
    @(negedge clk);
    SrcA       = 32'd10;
    WriteData  = 32'd20;
    ImmExt     = 32'd5;
    PC         = 32'h0000_0100;
    PC4        = 32'h0000_0104;
    rd         = 5'd3;
    ALUSrc     = 1'b1;
    ALUControl = 3'b000; // add
    RegWrite   = 1'b1;
    MemWrite   = 1'b0;
    ResultSrc  = 2'b00;
    Branch     = 1'b0;
    Jump       = 1'b0;

    @(posedge clk); #1;
    check32(EX_MEM_ALUResult, 32'd15,        "ALU add: 10 + 5 = 15");
    check1 (EX_MEM_Zero,      1'b0,          "ALU add: Zero = 0");
    check32(EX_MEM_WriteData, 32'd20,        "captura WriteData");
    check5 (EX_MEM_rd,        5'd3,          "captura rd");
    check32(EX_MEM_PC4,       32'h0000_0104, "captura PC4");
    check32(EX_MEM_PCTarget,  32'h0000_0105, "PCTarget = PC + ImmExt");
    check1 (EX_MEM_RegWrite,  1'b1,          "captura RegWrite");
    check1 (EX_MEM_MemWrite,  1'b0,          "captura MemWrite");
    check2 (EX_MEM_ResultSrc, 2'b00,         "captura ResultSrc");

    // sub x7, x7, x7 -> 7 - 7 = 0, Zero = 1
    @(negedge clk);
    SrcA       = 32'd7;
    WriteData  = 32'd7;
    ImmExt     = 32'd0;
    PC         = 32'h0000_0200;
    PC4        = 32'h0000_0204;
    rd         = 5'd7;
    ALUSrc     = 1'b0;
    ALUControl = 3'b001; // sub
    RegWrite   = 1'b0;
    MemWrite   = 1'b1;
    ResultSrc  = 2'b00;
    Branch     = 1'b1;
    Jump       = 1'b0;

    @(posedge clk); #1;
    check32(EX_MEM_ALUResult, 32'd0,        "ALU sub: 7 - 7 = 0");
    check1 (EX_MEM_Zero,      1'b1,          "ALU sub: Zero = 1");
    check32(EX_MEM_PCTarget,  32'h0000_0200, "PCTarget branch");
    check1 (EX_MEM_MemWrite,  1'b1,          "captura MemWrite=1");
    check1 (EX_MEM_Branch,    1'b1,          "captura Branch=1");
    check1 (EX_MEM_RegWrite,  1'b0,          "captura RegWrite=0");

    // jal x1, +8 -> PC destino = PC + 8
    @(negedge clk);
    SrcA       = 32'd0;
    WriteData  = 32'd0;
    ImmExt     = 32'd8;
    PC         = 32'h0000_0300;
    PC4        = 32'h0000_0304;
    rd         = 5'd1;
    ALUSrc     = 1'b1;
    ALUControl = 3'b000;
    RegWrite   = 1'b1;
    MemWrite   = 1'b0;
    ResultSrc  = 2'b10;
    Branch     = 1'b0;
    Jump       = 1'b1;

    @(posedge clk); #1;
    check32(EX_MEM_PCTarget,  32'h0000_0308, "PCTarget jal = PC + 8");
    check1 (EX_MEM_Jump,      1'b1,          "captura Jump=1");
    check2 (EX_MEM_ResultSrc, 2'b10,         "captura ResultSrc jal");

    // Reset final
    @(negedge clk);
    reset = 1;
    @(posedge clk); #1;
    check32(EX_MEM_ALUResult, 32'h0, "reset final ALUResult");
    check1 (EX_MEM_Zero,      1'b0,  "reset final Zero");

    if (errors == 0)
      $display("TESTBENCH EX/MEM: PASS");
    else
      $display("TESTBENCH EX/MEM: FAIL (%0d errores)", errors);

    $finish;
  end

endmodule
