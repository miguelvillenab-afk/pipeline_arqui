`timescale 1ns/1ps
module tb_comparacion_e1;
  reg clk = 0;
  reg reset = 1;
  wire [31:0] WriteData, DataAdr;
  wire MemWrite;
  integer ciclos = 0;
  integer retiradas = 0;
  reg fin = 0;
  reg retiro, ultima;
  top_pipeline uut (.clk(clk), .reset(reset), .WriteData(WriteData),
                    .DataAdr(DataAdr), .MemWrite(MemWrite));
  always #5 clk = ~clk;
  localparam [31:0] NOP = 32'h00000013;
  wire [31:0] InstrF = uut.Instr;
  wire [31:0] InstrD = uut.rvp.dp.IF_ID_Instr;
  wire [31:0] PCF = uut.PC;
  wire [31:0] PCD = uut.rvp.dp.IF_ID_PC;
  wire [31:0] PCE = uut.rvp.dp.ID_EX_PC;
  wire [31:0] PCM = uut.rvp.dp.EX_MEM_PC4 - 32'd4;
  wire [31:0] PCW = uut.rvp.dp.MEM_WB_PC4 - 32'd4;
  wire [31:0] InstrE = ((uut.rvp.dp.ID_EX_PC4 >= 4) && (uut.rvp.dp.ID_EX_PC4 <= 48))
                         ? uut.imem.RAM[(uut.rvp.dp.ID_EX_PC4 - 4) >> 2] : NOP;
  wire [31:0] InstrM = ((uut.rvp.dp.EX_MEM_PC4 >= 4) && (uut.rvp.dp.EX_MEM_PC4 <= 48))
                         ? uut.imem.RAM[(uut.rvp.dp.EX_MEM_PC4 - 4) >> 2] : NOP;
  wire [31:0] InstrW = ((uut.rvp.dp.MEM_WB_PC4 >= 4) && (uut.rvp.dp.MEM_WB_PC4 <= 48))
                         ? uut.imem.RAM[(uut.rvp.dp.MEM_WB_PC4 - 4) >> 2] : NOP;
  wire RegWriteW = uut.rvp.dp.MEM_WB_RegWrite;
  wire [4:0] RdW = uut.rvp.dp.MEM_WB_rd;
  wire [31:0] ResultW = uut.rvp.dp.wb_Result;
  wire stall = uut.rvp.dp.stall_ifid_hz;
  wire [31:0] cycle_count = ciclos;
  wire [31:0] retired_count = retiradas;

  initial begin
    $dumpfile("comparacion_e1.vcd");
    $dumpvars(0, tb_comparacion_e1);
  end

  initial begin
    $display("=== MEDICION E1: dual_alu_indep_debug ===");
    #22 reset = 0;
    #400;
    if (!fin) begin
      $display("ERROR: no se detecto la ultima instruccion en WB");
      $finish;
    end
  end
  always @(posedge clk) begin
    if (!reset && !fin) begin
      ciclos = ciclos + 1;
      retiro = (uut.rvp.dp.MEM_WB_RegWrite === 1'b1) &&
               (uut.rvp.dp.MEM_WB_rd != 5'd0);
      ultima = retiro && (uut.rvp.dp.MEM_WB_PC4 == 32'h30) &&
               (uut.rvp.dp.MEM_WB_rd == 5'd8);
      if (retiro) retiradas = retiradas + 1;
      if (ultima) begin
        fin = 1;
        #1;
        $display("CICLOS=%0d", ciclos);
        $display("INSTRUCCIONES_RETIRADAS=%0d", retiradas);
        $display("IPC=%0f", (1.0 * retiradas) / ciclos);
        $display("RESULTADOS x1=%0d x4=%0d x6=%0d x8=%0d",
                  uut.rvp.dp.rf.rf[1], uut.rvp.dp.rf.rf[4],
                  uut.rvp.dp.rf.rf[6], uut.rvp.dp.rf.rf[8]);
        if (retiradas == 12 &&
            uut.rvp.dp.rf.rf[1] === 32'd12 &&
            uut.rvp.dp.rf.rf[4] === 32'd30 &&
            uut.rvp.dp.rf.rf[6] === 32'd23 &&
            uut.rvp.dp.rf.rf[8] === 32'd34)
          $display("PASS: 12 instrucciones retiradas y resultados correctos");
        else
          $display("REVISAR: conteo o resultados inesperados");
        #10;
        $finish;
      end
    end
  end
endmodule
