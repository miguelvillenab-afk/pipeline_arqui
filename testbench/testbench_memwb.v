`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench de la Fase 4: registro MEM/WB + writeback real.
//
// Verifica:
//   1. reset del registro MEM/WB
//   2. captura de ReadData, ALUResult, PC4, rd y controles
//   3. selección del resultmux: ALU vs ReadData vs PC4
//   4. escritura en el regfile solo cuando MEM_WB_RegWrite = 1
//   5. que un rd con RegWrite=0 no modifique el registro
//////////////////////////////////////////////////////////////////////////////////

module testbench_memwb;

  reg clk;
  reg reset;

  reg [31:0] ReadData;
  reg [31:0] ALUResult;
  reg [31:0] PC4;
  reg [4:0]  rd;
  reg        RegWrite;
  reg [1:0]  ResultSrc;

  wire [31:0] MEM_WB_ReadData;
  wire [31:0] MEM_WB_ALUResult;
  wire [31:0] MEM_WB_PC4;
  wire [4:0]  MEM_WB_rd;
  wire        MEM_WB_RegWrite;
  wire [1:0]  MEM_WB_ResultSrc;

  wire [31:0] wb_Result;

  reg  [4:0]  a1;
  wire [31:0] rd1;

  integer errors;

  memwb dut (
    .clk              (clk),
    .reset            (reset),
    .ReadData         (ReadData),
    .ALUResult        (ALUResult),
    .PC4              (PC4),
    .rd               (rd),
    .RegWrite         (RegWrite),
    .ResultSrc        (ResultSrc),
    .MEM_WB_ReadData  (MEM_WB_ReadData),
    .MEM_WB_ALUResult (MEM_WB_ALUResult),
    .MEM_WB_PC4       (MEM_WB_PC4),
    .MEM_WB_rd        (MEM_WB_rd),
    .MEM_WB_RegWrite  (MEM_WB_RegWrite),
    .MEM_WB_ResultSrc (MEM_WB_ResultSrc)
  );

  mux3 #(32) resultmux (
    .d0 (MEM_WB_ALUResult),
    .d1 (MEM_WB_ReadData),
    .d2 (MEM_WB_PC4),
    .s  (MEM_WB_ResultSrc),
    .y  (wb_Result)
  );

  regfile rf (
    .clk (clk),
    .we3 (MEM_WB_RegWrite),
    .a1  (a1),
    .a2  (5'd0),
    .a3  (MEM_WB_rd),
    .wd3 (wb_Result),
    .rd1 (rd1),
    .rd2 ()
  );

  always #5 clk = ~clk;

  task check32(input [31:0] got, input [31:0] exp, input [511:0] label);
    begin
      if (got !== exp) begin
        $display("FAIL %0s: got %h, expected %h", label, got, exp);
        errors = errors + 1;
      end else begin
        $display("PASS %0s", label);
      end
    end
  endtask

  task check5(input [4:0] got, input [4:0] exp, input [511:0] label);
    begin
      check32({27'b0, got}, {27'b0, exp}, label);
    end
  endtask

  task check2(input [1:0] got, input [1:0] exp, input [511:0] label);
    begin
      check32({30'b0, got}, {30'b0, exp}, label);
    end
  endtask

  task check1(input got, input exp, input [511:0] label);
    begin
      check32({31'b0, got}, {31'b0, exp}, label);
    end
  endtask

  initial begin
    clk        = 0;
    reset      = 1;
    ReadData   = 0;
    ALUResult  = 0;
    PC4        = 0;
    rd         = 0;
    RegWrite   = 0;
    ResultSrc  = 0;
    a1         = 0;
    errors     = 0;

    // Reset
    @(posedge clk); #1;
    check32(MEM_WB_ReadData,  32'h0, "reset ReadData");
    check32(MEM_WB_ALUResult, 32'h0, "reset ALUResult");
    check32(MEM_WB_PC4,       32'h0, "reset PC4");
    check5 (MEM_WB_rd,        5'd0,  "reset rd");
    check1 (MEM_WB_RegWrite,  1'b0,  "reset RegWrite");
    check2 (MEM_WB_ResultSrc, 2'b00, "reset ResultSrc");

    // Caso lw: ResultSrc=01 -> wb_Result = ReadData
    reset = 0;
    @(negedge clk);
    ReadData  = 32'hAABB_CCDD;
    ALUResult = 32'h0000_0100;
    PC4       = 32'h0000_0104;
    rd        = 5'd5;
    RegWrite  = 1'b1;
    ResultSrc = 2'b01;

    @(posedge clk); #1;
    check32(MEM_WB_ReadData,  32'hAABB_CCDD, "captura ReadData (lw)");
    check32(MEM_WB_ALUResult, 32'h0000_0100, "captura ALUResult (lw)");
    check32(MEM_WB_PC4,       32'h0000_0104, "captura PC4 (lw)");
    check5 (MEM_WB_rd,        5'd5,          "captura rd (lw)");
    check1 (MEM_WB_RegWrite,  1'b1,          "captura RegWrite (lw)");
    check2 (MEM_WB_ResultSrc, 2'b01,         "captura ResultSrc (lw)");
    check32(wb_Result,        32'hAABB_CCDD, "mux WB selecciona ReadData");

    // El writeback de x5 ocurre en el siguiente posedge.
    // Se prepara el caso ALU y se lee x5.
    @(negedge clk);
    a1        = 5'd5;
    ReadData  = 32'h0000_00EE;
    ALUResult = 32'h0000_0055;
    PC4       = 32'h0000_0204;
    rd        = 5'd6;
    RegWrite  = 1'b1;
    ResultSrc = 2'b00;

    @(posedge clk); #1;
    check32(rd1, 32'hAABB_CCDD, "regfile x5 = ReadData (lw)");
    check32(MEM_WB_ALUResult, 32'h0000_0055, "captura ALUResult");
    check32(wb_Result,        32'h0000_0055, "mux WB selecciona ALU");

    // Caso jal: ResultSrc=10 -> wb_Result = PC4
    @(negedge clk);
    a1        = 5'd6;
    ReadData  = 32'h0000_00EE;
    ALUResult = 32'h0000_0066;
    PC4       = 32'h0000_0304;
    rd        = 5'd7;
    RegWrite  = 1'b1;
    ResultSrc = 2'b10;

    @(posedge clk); #1;
    check32(rd1, 32'h0000_0055, "regfile x6 = ALUResult");
    check32(MEM_WB_PC4, 32'h0000_0304, "captura PC4 (jal)");
    check2 (MEM_WB_ResultSrc, 2'b10, "captura ResultSrc (jal)");
    check32(wb_Result, 32'h0000_0304, "mux WB selecciona PC4");

    // Escribir x8 con un valor conocido
    @(negedge clk);
    a1        = 5'd7;
    ReadData  = 32'h0;
    ALUResult = 32'h0000_1234;
    PC4       = 32'h0000_0404;
    rd        = 5'd8;
    RegWrite  = 1'b1;
    ResultSrc = 2'b00;

    @(posedge clk); #1;
    check32(rd1, 32'h0000_0304, "regfile x7 = PC4 (jal)");

    // Burbuja sobre x8 con RegWrite=0: x8 no debe cambiar
    @(negedge clk);
    a1        = 5'd8;
    ReadData  = 32'h0;
    ALUResult = 32'h0000_BAD0;
    PC4       = 32'h0000_0504;
    rd        = 5'd8;
    RegWrite  = 1'b0;
    ResultSrc = 2'b00;

    @(posedge clk); #1;
    check32(rd1, 32'h0000_1234, "regfile x8 escrito una vez");
    check1 (MEM_WB_RegWrite, 1'b0, "burbuja: RegWrite=0");
    check32(wb_Result, 32'h0000_BAD0, "burbuja: wb_Result existe pero we3=0");

    // Otro ciclo con RegWrite=0: x8 permanece igual
    @(negedge clk);
    ALUResult = 32'h0000_DEAD;
    @(posedge clk); #1;
    check32(rd1, 32'h0000_1234, "regfile x8 no cambia con RegWrite=0");

    // Reset final
    @(negedge clk);
    reset = 1;
    @(posedge clk); #1;
    check32(MEM_WB_ReadData,  32'h0, "reset final ReadData");
    check32(MEM_WB_ALUResult, 32'h0, "reset final ALUResult");
    check1 (MEM_WB_RegWrite,  1'b0,  "reset final RegWrite");

    if (errors == 0)
      $display("TESTBENCH MEM/WB: PASS");
    else
      $display("TESTBENCH MEM/WB: FAIL (%0d errores)", errors);

    $finish;
  end

endmodule
