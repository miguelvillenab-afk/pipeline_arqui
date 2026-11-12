`timescale 1ns/1ps
module tb_comparacion_e2;
  reg clk = 0;
  reg reset = 1;
  wire [31:0] PC, WriteData, DataAdr;
  wire MemWrite;
  integer ciclos = 0;
  integer retiradas = 0;
  integer doble_retiro = 0;
  reg fin = 0;
  reg retiro_A, retiro_B, ultima_A, ultima_B;

  top_dual #(.MEMFILE("dual_alu_indep_debug.mem")) uut (
    .clk(clk), .reset(reset), .PC(PC),
    .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite)
  );
  always #5 clk = ~clk;

  localparam [31:0] NOP = 32'h00000013;
  wire [31:0] PCF = PC;
  wire [31:0] InstrF_A = uut.Instr_A;
  wire [31:0] InstrF_B = uut.Instr_B;
  wire [31:0] InstrD_A = uut.rvd.dp.IF_ID_Instr;
  wire [31:0] InstrD_B = uut.rvd.dp.IF_ID_Instr_B;
  wire [31:0] InstrE_A = ((uut.rvd.dp.ID_EX_PC4 >= 4) && (uut.rvd.dp.ID_EX_PC4 <= 48) && uut.rvd.dp.ID_EX_RegWrite)
                           ? uut.imem.RAM[(uut.rvd.dp.ID_EX_PC4 - 4) >> 2] : NOP;
  wire [31:0] InstrE_B = ((uut.rvd.dp.ID_EX_B_PC4 >= 4) && (uut.rvd.dp.ID_EX_B_PC4 <= 48) && uut.rvd.dp.ID_EX_B_RegWrite)
                           ? uut.imem.RAM[(uut.rvd.dp.ID_EX_B_PC4 - 4) >> 2] : NOP;
  wire [31:0] InstrM_A = ((uut.rvd.dp.EX_MEM_PC4 >= 4) && (uut.rvd.dp.EX_MEM_PC4 <= 48) && uut.rvd.dp.EX_MEM_RegWrite)
                           ? uut.imem.RAM[(uut.rvd.dp.EX_MEM_PC4 - 4) >> 2] : NOP;
  wire [31:0] InstrM_B = ((uut.rvd.dp.EX_MEM_B_PC4 >= 4) && (uut.rvd.dp.EX_MEM_B_PC4 <= 48) && uut.rvd.dp.EX_MEM_B_RegWrite)
                           ? uut.imem.RAM[(uut.rvd.dp.EX_MEM_B_PC4 - 4) >> 2] : NOP;
  wire [31:0] InstrW_A = ((uut.rvd.dp.MEM_WB_PC4 >= 4) && (uut.rvd.dp.MEM_WB_PC4 <= 48) && uut.rvd.dp.MEM_WB_RegWrite)
                           ? uut.imem.RAM[(uut.rvd.dp.MEM_WB_PC4 - 4) >> 2] : NOP;
  wire [31:0] InstrW_B = ((uut.rvd.dp.MEM_WB_B_PC4 >= 4) && (uut.rvd.dp.MEM_WB_B_PC4 <= 48) && uut.rvd.dp.MEM_WB_B_RegWrite)
                           ? uut.imem.RAM[(uut.rvd.dp.MEM_WB_B_PC4 - 4) >> 2] : NOP;
  wire issue_B_comb = uut.rvd.dp.issue_B_comb;
  wire issue_B_reg = uut.rvd.dp.IF_ID_IssueB;
  wire RegWriteW_A = uut.rvd.dp.MEM_WB_RegWrite;
  wire RegWriteW_B = uut.rvd.dp.MEM_WB_B_RegWrite;
  wire [4:0] RdW_A = uut.rvd.dp.MEM_WB_rd;
  wire [4:0] RdW_B = uut.rvd.dp.MEM_WB_B_rd;
  wire [31:0] ResultW_A = uut.rvd.dp.wb_Result;
  wire [31:0] ResultW_B = uut.rvd.dp.wb_Result_B;
  wire stall = uut.rvd.dp.stall_ifid_hz;
  wire [31:0] cycle_count = ciclos;
  wire [31:0] retired_count = retiradas;
  wire [31:0] dual_retire_count = doble_retiro;

  initial begin
    $dumpfile("comparacion_e2.vcd");
    $dumpvars(0, tb_comparacion_e2);
  end

  initial begin
    $display("=== MEDICION E2: dual_alu_indep_debug ===");
    #22 reset = 0;
    #300;
    if (!fin) begin
      $display("ERROR: no se detecto la ultima instruccion en WB");
      $finish;
    end
  end

  always @(posedge clk) begin
    if (!reset && !fin) begin
      ciclos = ciclos + 1;
      retiro_A = (uut.rvd.dp.MEM_WB_RegWrite === 1'b1) &&
                 (uut.rvd.dp.MEM_WB_rd != 5'd0);
      retiro_B = (uut.rvd.dp.MEM_WB_B_RegWrite === 1'b1) &&
                 (uut.rvd.dp.MEM_WB_B_rd != 5'd0);
      ultima_A = retiro_A && (uut.rvd.dp.MEM_WB_PC4 == 32'h30) &&
                 (uut.rvd.dp.MEM_WB_rd == 5'd8);
      ultima_B = retiro_B && (uut.rvd.dp.MEM_WB_B_PC4 == 32'h30) &&
                 (uut.rvd.dp.MEM_WB_B_rd == 5'd8);
      if (retiro_A) retiradas = retiradas + 1;
      if (retiro_B) retiradas = retiradas + 1;
      if (retiro_A && retiro_B) doble_retiro = doble_retiro + 1;
      if (ultima_A || ultima_B) begin
        fin = 1;
        #1;
        $display("CICLOS=%0d", ciclos);
        $display("INSTRUCCIONES_RETIRADAS=%0d", retiradas);
        $display("IPC=%0f", (1.0 * retiradas) / ciclos);
        $display("CICLOS_CON_DOBLE_RETIRO=%0d", doble_retiro);
        $display("RESULTADOS x1=%0d x4=%0d x6=%0d x8=%0d",
                uut.rvd.dp.rf.rf[1], uut.rvd.dp.rf.rf[4],
                uut.rvd.dp.rf.rf[6], uut.rvd.dp.rf.rf[8]);
        if (retiradas == 12 &&
            uut.rvd.dp.rf.rf[1] === 32'd12 &&
            uut.rvd.dp.rf.rf[4] === 32'd30 &&
            uut.rvd.dp.rf.rf[6] === 32'd23 &&
            uut.rvd.dp.rf.rf[8] === 32'd34)
          $display("PASS: 12 instrucciones retiradas y resultados correctos");
        else
          $display("REVISAR: conteo o resultados inesperados");
        #10;
        $finish;
      end
    end
  end
endmodule
