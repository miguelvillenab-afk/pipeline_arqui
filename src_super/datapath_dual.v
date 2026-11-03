`timescale 1ns / 1ps


module datapath_dual(
    input  clk,
    input  reset,

    // memoria top
    output [31:0] PC,
    input  [31:0] Instr_A,
    input  [31:0] Instr_B,
    output        MemWrite,
    output [31:0] DataAdr,
    output [31:0] WriteData,
    input  [31:0] ReadData,

    // IF/ID A
    output [31:0] IF_ID_Instr,
    output [31:0] IF_ID_PC,
    output [31:0] IF_ID_PC4,

    // IF/ID B 
    output [31:0] IF_ID_Instr_B,
    output [31:0] IF_ID_PC_B,
    output [31:0] IF_ID_PC4_B,
    
    //decode B
    output [4:0]  ID_B_rs1,
    output [4:0]  ID_B_rs2,
    output [4:0]  ID_B_rd,
    output [31:0] ID_B_SrcA,
    output [31:0] ID_B_WriteData,
    output [31:0] ID_B_ImmExt,
    output        ID_B_ALUSrc,
    output [2:0]  ID_B_ALUControl,
    output        ID_B_RegWrite,
    output        ID_B_MemWrite,
    output [1:0]  ID_B_ResultSrc,
    output        ID_B_Branch,
    output        ID_B_Jump,

    //señales ya decodificado 
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

    //resultado de la alu 
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

    output [31:0] MEM_WB_ReadData,
    output [31:0] MEM_WB_ALUResult,
    output [31:0] MEM_WB_PC4,
    output [4:0]  MEM_WB_rd,
    output        MEM_WB_RegWrite,
    output [1:0]  MEM_WB_ResultSrc
    );

    localparam WIDTH = 32;

    // IF
    wire [31:0] PCNext, PCPlus4, PCPlus8;

    wire [31:0] wb_Result;

    wire stall_ifid_hz, stall_idex_hz;
    wire flush_ifid_hz, flush_idex_hz;
    wire [1:0] ForwardA, ForwardB;

    flopenrc #(WIDTH) pcreg (
        .clk   (clk),
        .reset (reset),
        .en    (~stall_ifid_hz),
        .clr   (1'b0),
        .d     (PCNext),
        .q     (PC)
    );

    adder pcadd4 (
        .a (PC),
        .b (32'd4),
        .y (PCPlus4)
    );

    adder pcadd8 (
        .a (PC),
        .b (32'd8),
        .y (PCPlus8)
    );

    // IF/ID
    ifid reg_ifid_a (
        .clk         (clk),
        .reset       (reset),
        .stall       (stall_ifid_hz),
        .flush       (flush_ifid_hz),
        .Instr_in    (Instr_A),
        .PC_in       (PC),
        .PC4_in      (PCPlus4),
        .IF_ID_Instr (IF_ID_Instr),
        .IF_ID_PC    (IF_ID_PC),
        .IF_ID_PC4   (IF_ID_PC4)
    );

    ifid reg_ifid_b (
        .clk         (clk),
        .reset       (reset),
        .stall       (stall_ifid_hz),
        .flush       (flush_ifid_hz),
        .Instr_in    (Instr_B),
        .PC_in       (PCPlus4),
        .PC4_in      (PCPlus8),
        .IF_ID_Instr (IF_ID_Instr_B),
        .IF_ID_PC    (IF_ID_PC_B),
        .IF_ID_PC4   (IF_ID_PC4_B)
    );

    // ID
    wire [31:0] id_SrcA, id_WriteData, ImmExt;

    wire [1:0] dec_ResultSrc, dec_ImmSrc, dec_ALUOp;
    wire       dec_MemWrite, dec_Branch, dec_ALUSrc, dec_RegWrite, dec_Jump;
    wire [2:0] dec_ALUControl;

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
    
    regfile_dual rf (
        .clk    (clk),
        .reset  (reset),

        // Escritura vía A (la única activa en esta sub-etapa)
        .we3_A  (MEM_WB_RegWrite),
        .a3_A   (MEM_WB_rd),
        .wd3_A  (wb_Result),

        // Escritura vía B (deshabilitada todavía)
        .we3_B  (1'b0),
        .a3_B   (5'd0),
        .wd3_B  (32'd0),

        // Lecturas vía A
        .a1_A   (IF_ID_Instr[19:15]),
        .a2_A   (IF_ID_Instr[24:20]),
        .rd1_A  (id_SrcA),
        .rd2_A  (id_WriteData),

        // Lecturas vía B
        .a1_B   (IF_ID_Instr_B[19:15]),
        .a2_B   (IF_ID_Instr_B[24:20]),
        .rd1_B  (ID_B_SrcA),
        .rd2_B  (ID_B_WriteData)
    );

    extend ext (
        .instr  (IF_ID_Instr[31:7]),
        .immsrc (dec_ImmSrc),
        .immext (ImmExt)
    );

    //decode de B: DUAL DECODE
    // Se decodifica la instrucción B en paralelo
    // señales solo se exponen para observación; no llegan a EX.
    wire [1:0] dec_B_ResultSrc, dec_B_ImmSrc, dec_B_ALUOp;
    wire       dec_B_MemWrite, dec_B_Branch, dec_B_ALUSrc, dec_B_RegWrite, dec_B_Jump;
    wire [2:0] dec_B_ALUControl;

    maindec md_b (
        .op        (IF_ID_Instr_B[6:0]),
        .ResultSrc (dec_B_ResultSrc),
        .MemWrite  (dec_B_MemWrite),
        .Branch    (dec_B_Branch),
        .ALUSrc    (dec_B_ALUSrc),
        .RegWrite  (dec_B_RegWrite),
        .Jump      (dec_B_Jump),
        .ImmSrc    (dec_B_ImmSrc),
        .ALUOp     (dec_B_ALUOp)
    );

    aludec ad_b (
        .opb5       (IF_ID_Instr_B[5]),
        .funct3     (IF_ID_Instr_B[14:12]),
        .funct7b5   (IF_ID_Instr_B[30]),
        .ALUOp      (dec_B_ALUOp),
        .ALUControl (dec_B_ALUControl)
    );

    extend ext_b (
        .instr  (IF_ID_Instr_B[31:7]),
        .immsrc (dec_B_ImmSrc),
        .immext (ID_B_ImmExt)
    );

    assign ID_B_rs1        = IF_ID_Instr_B[19:15];
    assign ID_B_rs2        = IF_ID_Instr_B[24:20];
    assign ID_B_rd         = IF_ID_Instr_B[11:7];
    assign ID_B_ALUSrc     = dec_B_ALUSrc;
    assign ID_B_ALUControl = dec_B_ALUControl;
    assign ID_B_RegWrite   = dec_B_RegWrite;
    assign ID_B_MemWrite   = dec_B_MemWrite;
    assign ID_B_ResultSrc  = dec_B_ResultSrc;
    assign ID_B_Branch     = dec_B_Branch;
    assign ID_B_Jump       = dec_B_Jump;

    // ID/EX
    idex reg_idex (
        .clk           (clk),
        .reset         (reset),
        .stall_ID_EX   (stall_idex_hz),
        .flush_ID_EX   (flush_idex_hz),

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

    // EX
    wire [31:0] ex_SrcB, ex_ALUResult, ex_PCTarget;
    wire        ex_Zero, ex_PCSrc;

    wire [31:0] alu_SrcA_fwd, alu_SrcB_fwd;

    mux2 #(WIDTH) srcbmux (
        .d0 (ID_EX_WriteData),
        .d1 (ID_EX_ImmExt),
        .s  (ID_EX_ALUSrc),
        .y  (ex_SrcB)
    );

    mux3 #(WIDTH) mux_forwardA (
        .d0 (ID_EX_SrcA),
        .d1 (wb_Result),
        .d2 (EX_MEM_ALUResult),
        .s  (ForwardA),
        .y  (alu_SrcA_fwd)
    );

    mux3 #(WIDTH) mux_forwardB (
        .d0 (ex_SrcB),
        .d1 (wb_Result),
        .d2 (EX_MEM_ALUResult),
        .s  (ForwardB),
        .y  (alu_SrcB_fwd)
    );

    alu alu (
        .a          (alu_SrcA_fwd),
        .b          (alu_SrcB_fwd),
        .alucontrol (ID_EX_ALUControl),
        .result     (ex_ALUResult),
        .zero       (ex_Zero)
    );

    adder pcaddbranch (
        .a (ID_EX_PC),
        .b (ID_EX_ImmExt),
        .y (ex_PCTarget)
    );

    assign ex_PCSrc = (ID_EX_Branch & ex_Zero) | ID_EX_Jump;

    // Sub-etapa 1: solo se ejecuta A, por eso PCNext = PC+4.
    mux2 #(WIDTH) pcmux (
        .d0 (PCPlus4),
        .d1 (ex_PCTarget),
        .s  (ex_PCSrc),
        .y  (PCNext)
    );

    // EX/MEM
    exmem reg_exmem (
        .clk              (clk),
        .reset            (reset),
        .ALUResult        (ex_ALUResult),
        .Zero             (ex_Zero),
        .WriteData        (ID_EX_WriteData),
        .rd               (ID_EX_rd),
        .PC4              (ID_EX_PC4),
        .PCTarget         (ex_PCTarget),
        .MemWrite         (ID_EX_MemWrite),
        .RegWrite         (ID_EX_RegWrite),
        .ResultSrc        (ID_EX_ResultSrc),
        .Branch           (ID_EX_Branch),
        .Jump             (ID_EX_Jump),
        .EX_MEM_ALUResult (EX_MEM_ALUResult),
        .EX_MEM_Zero      (EX_MEM_Zero),
        .EX_MEM_WriteData (EX_MEM_WriteData),
        .EX_MEM_rd        (EX_MEM_rd),
        .EX_MEM_PC4       (EX_MEM_PC4),
        .EX_MEM_PCTarget  (EX_MEM_PCTarget),
        .EX_MEM_MemWrite  (EX_MEM_MemWrite),
        .EX_MEM_RegWrite  (EX_MEM_RegWrite),
        .EX_MEM_ResultSrc (EX_MEM_ResultSrc),
        .EX_MEM_Branch    (EX_MEM_Branch),
        .EX_MEM_Jump      (EX_MEM_Jump)
    );

    // MEM/WB
    memwb reg_memwb (
        .clk              (clk),
        .reset            (reset),
        .ReadData         (ReadData),
        .ALUResult        (EX_MEM_ALUResult),
        .PC4              (EX_MEM_PC4),
        .rd               (EX_MEM_rd),
        .RegWrite         (EX_MEM_RegWrite),
        .ResultSrc        (EX_MEM_ResultSrc),
        .MEM_WB_ReadData  (MEM_WB_ReadData),
        .MEM_WB_ALUResult (MEM_WB_ALUResult),
        .MEM_WB_PC4       (MEM_WB_PC4),
        .MEM_WB_rd        (MEM_WB_rd),
        .MEM_WB_RegWrite  (MEM_WB_RegWrite),
        .MEM_WB_ResultSrc (MEM_WB_ResultSrc)
    );

    // HAZARD UNIT
    hazard_unit hu (
        .rs1_ID        (IF_ID_Instr[19:15]),
        .rs2_ID        (IF_ID_Instr[24:20]),

        .rs1_EX        (ID_EX_rs1),
        .rs2_EX        (ID_EX_rs2),
        .rd_EX         (ID_EX_rd),
        .ResultSrc_EX  (ID_EX_ResultSrc),
        .RegWrite_EX   (ID_EX_RegWrite),

        .rd_MEM        (EX_MEM_rd),
        .RegWrite_MEM  (EX_MEM_RegWrite),

        .PCSrc_EX      (ex_PCSrc),

        .stall_IF_ID   (stall_ifid_hz),
        .stall_ID_EX   (stall_idex_hz),
        .flush_IF_ID   (flush_ifid_hz),
        .flush_ID_EX   (flush_idex_hz),
        .ForwardA      (ForwardA),
        .ForwardB      (ForwardB)
    );

    // WB
    assign DataAdr   = EX_MEM_ALUResult;
    assign MemWrite  = EX_MEM_MemWrite;
    assign WriteData = EX_MEM_WriteData;

    assign wb_Result = (MEM_WB_ResultSrc == 2'b01) ? MEM_WB_ReadData :
                       (MEM_WB_ResultSrc == 2'b10) ? MEM_WB_PC4 :
                                                     MEM_WB_ALUResult;

endmodule