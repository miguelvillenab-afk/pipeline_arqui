`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// datapath_pipeline.v
//
// Datapath del procesador RISC-V de 5 etapas:
//
//   IF -> IF/ID -> ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB
//
// Implementado hasta la Fase 4:
//   - Fase 1: PC, imem (desde top_pipeline), PC+4 y registro IF/ID.
//   - Fase 2: decodificación (maindec + aludec) en ID, regfile, extend y
//             registro ID/EX con stall/flush reales.
//   - Fase 3: ALU, mux ALUSrc, sumador de branch/jal y registro EX/MEM.
//   - Fase 4: registro MEM/WB y writeback real desde MEM_WB_* al regfile.
//
// Todavía NO incluye forwarding ni detección de load-use (Fase 6).
//////////////////////////////////////////////////////////////////////////////////

module datapath_pipeline(
    input  clk,
    input  reset,

    // Interfaz con memorias / top
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] DataAdr,
    output [31:0] WriteData,
    input  [31:0] ReadData,

    // Observabilidad Fase 1
    output [31:0] IF_ID_Instr,
    output [31:0] IF_ID_PC,
    output [31:0] IF_ID_PC4,

    // Observabilidad Fase 2
    output [31:0] ID_EX_SrcA,
    output [31:0] ID_EX_WriteData,
    output [31:0] ID_EX_ImmExt,
    output [31:0] ID_EX_PC,
    output [31:0] ID_EX_PC4,
    output [4:0]  ID_EX_rs1,
    output [4:0]  ID_EX_rs2,
    output [4:0]  ID_EX_rd,
    output        ID_EX_ALUSrc,
    output [2:0]  ID_EX_ALUControl,
    output        ID_EX_RegWrite,
    output        ID_EX_MemWrite,
    output [1:0]  ID_EX_ResultSrc,
    output        ID_EX_Branch,
    output        ID_EX_Jump,
    output [1:0]  ID_EX_ImmSrc,

    // Observabilidad Fase 3
    output [31:0] EX_MEM_ALUResult,
    output        EX_MEM_Zero,
    output [31:0] EX_MEM_WriteData,
    output [4:0]  EX_MEM_rd,
    output [31:0] EX_MEM_PC4,
    output [31:0] EX_MEM_PCTarget,
    output        EX_MEM_MemWrite,
    output        EX_MEM_RegWrite,
    output [1:0]  EX_MEM_ResultSrc,
    output        EX_MEM_Branch,
    output        EX_MEM_Jump,

    // Observabilidad Fase 4
    output [31:0] MEM_WB_ReadData,
    output [31:0] MEM_WB_ALUResult,
    output [31:0] MEM_WB_PC4,
    output [4:0]  MEM_WB_rd,
    output        MEM_WB_RegWrite,
    output [1:0]  MEM_WB_ResultSrc
    );

    localparam WIDTH = 32;

    // ---------------------------------------------------------------- IF
    wire [31:0] PCNext, PCPlus4;

    // Resultado de writeback
    wire [31:0] wb_Result;

    flopr #(WIDTH) pcreg (
        .clk   (clk),
        .reset (reset),
        .d     (PCNext),
        .q     (PC)
    );

    adder pcadd4 (
        .a (PC),
        .b (32'd4),
        .y (PCPlus4)
    );

    // ------------------------------------------------------------- IF/ID
    wire flush_if_id;
    wire flush_id_ex;

    ifid reg_ifid (
        .clk        (clk),
        .reset      (reset),
        .stall      (1'b0),          // Fase 6: unidad de hazards
        .flush      (flush_if_id),
        .Instr_in   (Instr),
        .PC_in      (PC),
        .PC4_in     (PCPlus4),
        .IF_ID_Instr(IF_ID_Instr),
        .IF_ID_PC   (IF_ID_PC),
        .IF_ID_PC4  (IF_ID_PC4)
    );

    // ---------------------------------------------------------------- ID
    wire [31:0] id_SrcA, id_WriteData, ImmExt;

    wire [1:0] dec_ResultSrc, dec_ImmSrc, dec_ALUOp;
    wire       dec_MemWrite, dec_Branch, dec_ALUSrc, dec_RegWrite, dec_Jump;
    wire [2:0] dec_ALUControl;

    // El control se decodifica con la instrucción que está en ID (IF_ID_Instr),
    // NO con la instrucción que está saliendo de imem.
    maindec md (
        .op        (IF_ID_Instr[6:0]),
        .ResultSrc (dec_ResultSrc),
        .MemWrite  (dec_MemWrite),
        .Branch    (dec_Branch),
        .ALUSrc    (dec_ALUSrc),
        .RegWrite  (dec_RegWrite),
        .Jump      (dec_Jump),
        .ImmSrc    (dec_ImmSrc),
        .ALUOp     (dec_ALUOp)
    );

    aludec ad (
        .opb5       (IF_ID_Instr[5]),
        .funct3     (IF_ID_Instr[14:12]),
        .funct7b5   (IF_ID_Instr[30]),
        .ALUOp      (dec_ALUOp),
        .ALUControl (dec_ALUControl)
    );

    // El puerto de escritura usa el resultado y el rd que salen de MEM/WB.
    regfile rf (
        .clk (clk),
        .we3 (MEM_WB_RegWrite),
        .a1  (IF_ID_Instr[19:15]),
        .a2  (IF_ID_Instr[24:20]),
        .a3  (MEM_WB_rd),
        .wd3 (wb_Result),
        .rd1 (id_SrcA),
        .rd2 (id_WriteData)
    );

    extend ext (
        .instr  (IF_ID_Instr[31:7]),
        .immsrc (dec_ImmSrc),
        .immext (ImmExt)
    );

    // ------------------------------------------------------------- ID/EX
    idex reg_idex (
        .clk           (clk),
        .reset         (reset),
        .stall_ID_EX   (1'b0),        // Fase 6: unidad de hazards
        .flush_ID_EX   (flush_id_ex),

        .SrcA          (id_SrcA),
        .WriteData     (id_WriteData),
        .ImmExt        (ImmExt),
        .IF_ID_PC      (IF_ID_PC),
        .IF_ID_PC4     (IF_ID_PC4),
        .rs1           (IF_ID_Instr[19:15]),
        .rs2           (IF_ID_Instr[24:20]),
        .rd            (IF_ID_Instr[11:7]),

        .ALUSrc        (dec_ALUSrc),
        .ALUControl    (dec_ALUControl),
        .RegWrite      (dec_RegWrite),
        .MemWrite      (dec_MemWrite),
        .ResultSrc     (dec_ResultSrc),
        .Branch        (dec_Branch),
        .Jump          (dec_Jump),
        .ImmSrc        (dec_ImmSrc),

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

    // ---------------------------------------------------------------- EX
    wire [31:0] ex_SrcB, ex_ALUResult, ex_PCTarget;
    wire        ex_Zero, ex_PCSrc;

    mux2 #(WIDTH) srcbmux (
        .d0 (ID_EX_WriteData),
        .d1 (ID_EX_ImmExt),
        .s  (ID_EX_ALUSrc),
        .y  (ex_SrcB)
    );

    alu alu (
        .a          (ID_EX_SrcA),
        .b          (ex_SrcB),
        .alucontrol (ID_EX_ALUControl),
        .result     (ex_ALUResult),
        .zero       (ex_Zero)
    );

    // PC de la instrucción en EX + inmediato -> destino de branch/jal.
    adder pcaddbranch (
        .a (ID_EX_PC),
        .b (ID_EX_ImmExt),
        .y (ex_PCTarget)
    );

    assign ex_PCSrc = (ID_EX_Branch & ex_Zero) | ID_EX_Jump;

    mux2 #(WIDTH) pcmux (
        .d0 (PCPlus4),
        .d1 (ex_PCTarget),
        .s  (ex_PCSrc),
        .y  (PCNext)
    );

    // Un branch/jal tomado en EX invalida las dos instrucciones más jóvenes:
    // la que está en IF/ID y la que está entrando a ID/EX.
    assign flush_if_id = ex_PCSrc;
    assign flush_id_ex = ex_PCSrc;

    // ------------------------------------------------------------ EX/MEM
    exmem reg_exmem (
        .clk             (clk),
        .reset           (reset),
        .ALUResult       (ex_ALUResult),
        .Zero            (ex_Zero),
        .WriteData       (ID_EX_WriteData),
        .rd              (ID_EX_rd),
        .PC4             (ID_EX_PC4),
        .PCTarget        (ex_PCTarget),
        .MemWrite        (ID_EX_MemWrite),
        .RegWrite        (ID_EX_RegWrite),
        .ResultSrc       (ID_EX_ResultSrc),
        .Branch          (ID_EX_Branch),
        .Jump            (ID_EX_Jump),
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

    // ------------------------------------------------------------ MEM/WB
    memwb reg_memwb (
        .clk               (clk),
        .reset             (reset),
        .ReadData          (ReadData),
        .ALUResult         (EX_MEM_ALUResult),
        .PC4               (EX_MEM_PC4),
        .rd                (EX_MEM_rd),
        .RegWrite          (EX_MEM_RegWrite),
        .ResultSrc         (EX_MEM_ResultSrc),
        .MEM_WB_ReadData   (MEM_WB_ReadData),
        .MEM_WB_ALUResult  (MEM_WB_ALUResult),
        .MEM_WB_PC4        (MEM_WB_PC4),
        .MEM_WB_rd         (MEM_WB_rd),
        .MEM_WB_RegWrite   (MEM_WB_RegWrite),
        .MEM_WB_ResultSrc  (MEM_WB_ResultSrc)
    );

    // ---------------------------------------------------------------- WB
    assign DataAdr   = EX_MEM_ALUResult;
    assign MemWrite  = EX_MEM_MemWrite;
    assign WriteData = EX_MEM_WriteData;

    assign wb_Result = (MEM_WB_ResultSrc == 2'b01) ? MEM_WB_ReadData :
                       (MEM_WB_ResultSrc == 2'b10) ? MEM_WB_PC4 :
                                                     MEM_WB_ALUResult;

endmodule
