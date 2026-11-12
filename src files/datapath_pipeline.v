`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// datapath_pipeline.v
//
// Datapath del procesador RISC-V de 5 etapas (Single-Issue):
//
//   IF -> IF/ID -> ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB
//
// Incluye:
//   - Forwarding desde MEM y WB a los dos operandos de la ALU (ForwardA/B) y
//     al dato de store / segundo operando del comparador (ForwardC).
//   - Stall por load-use (congela PC e IF/ID, burbuja en ID/EX).
//   - Saltos resueltos en EX: al tomarse, se anulan IF/ID e ID/EX.
//   - Branches beq/bne/blt/bge/bltu/bgeu (comparador en EX según funct3).
//   - jal (destino PC + imm) y jalr (destino (rs1 + imm) & ~1); ambos
//     escriben PC+4 en rd.
//   - lui: rs1 se fuerza a x0 para que la ALU calcule 0 + imm.
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

    // Observabilidad IF/ID
    output [31:0] IF_ID_Instr,
    output [31:0] IF_ID_PC,
    output [31:0] IF_ID_PC4,

    // Observabilidad ID/EX
    output [31:0] ID_EX_SrcA,
    output [31:0] ID_EX_WriteData,
    output [31:0] ID_EX_ImmExt,
    output [31:0] ID_EX_PC,
    output [31:0] ID_EX_PC4,
    output [4:0]  ID_EX_rs1,
    output [4:0]  ID_EX_rs2,
    output [4:0]  ID_EX_rd,
    output        ID_EX_ALUSrc,
    output [3:0]  ID_EX_ALUControl,
    output        ID_EX_RegWrite,
    output        ID_EX_MemWrite,
    output [1:0]  ID_EX_ResultSrc,
    output        ID_EX_Branch,
    output        ID_EX_Jump,
    output [1:0]  ID_EX_ImmSrc,

    // Observabilidad EX/MEM
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

    // Observabilidad MEM/WB
    output [31:0] MEM_WB_ReadData,
    output [31:0] MEM_WB_ALUResult,
    output [31:0] MEM_WB_PC4,
    output [4:0]  MEM_WB_rd,
    output        MEM_WB_RegWrite,
    output [1:0]  MEM_WB_ResultSrc
    );

    localparam WIDTH = 32;

    // Señales de la unidad de hazards
    wire stall_ifid_hz, stall_idex_hz;
    wire flush_ifid_hz, flush_idex_hz;
    wire [1:0] ForwardA, ForwardB, ForwardC;

    // Resultado de writeback
    wire [31:0] wb_Result;

    // ---------------------------------------------------------------- IF
    wire [31:0] PCNext, PCPlus4;

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

    // ------------------------------------------------------------- IF/ID
    ifid reg_ifid (
        .clk        (clk),
        .reset      (reset),
        .stall      (stall_ifid_hz),
        .flush      (flush_ifid_hz),
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
    wire       dec_JumpReg;
    wire [3:0] dec_ALUControl;

    // lui no usa rs1: se fuerza a x0 para que la ALU calcule 0 + imm y para
    // que no se dispare forwarding ni stall por un registro que no se lee.
    wire [4:0] id_rs1 = (IF_ID_Instr[6:0] == 7'b0110111) ? 5'd0 : IF_ID_Instr[19:15];
    wire [4:0] id_rs2 = IF_ID_Instr[24:20];

    maindec md (
        .op        (IF_ID_Instr[6:0]),
        .ResultSrc (dec_ResultSrc),
        .MemWrite  (dec_MemWrite),
        .Branch    (dec_Branch),
        .ALUSrc    (dec_ALUSrc),
        .RegWrite  (dec_RegWrite),
        .Jump      (dec_Jump),
        .JumpReg   (dec_JumpReg),
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
        .clk   (clk),
        .reset (reset),
        .we3   (MEM_WB_RegWrite),
        .a1    (id_rs1),
        .a2    (id_rs2),
        .a3    (MEM_WB_rd),
        .wd3   (wb_Result),
        .rd1   (id_SrcA),
        .rd2   (id_WriteData)
    );

    extend ext (
        .instr  (IF_ID_Instr),
        .immsrc (dec_ImmSrc),
        .immext (ImmExt)
    );

    // ------------------------------------------------------------- ID/EX
    wire [2:0] ID_EX_Funct3;
    wire       ID_EX_JumpReg;

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
        .rs1           (id_rs1),
        .rs2           (id_rs2),
        .rd            (IF_ID_Instr[11:7]),

        .ALUSrc        (dec_ALUSrc),
        .ALUControl    (dec_ALUControl),
        .RegWrite      (dec_RegWrite),
        .MemWrite      (dec_MemWrite),
        .ResultSrc     (dec_ResultSrc),
        .Branch        (dec_Branch),
        .Jump          (dec_Jump),
        .ImmSrc        (dec_ImmSrc),
        .Funct3        (IF_ID_Instr[14:12]),
        .JumpReg       (dec_JumpReg),

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
        .ID_EX_ImmSrc     (ID_EX_ImmSrc),
        .ID_EX_Funct3     (ID_EX_Funct3),
        .ID_EX_JumpReg    (ID_EX_JumpReg)
    );

    // ---------------------------------------------------------------- EX
    wire [31:0] ex_SrcB, ex_ALUResult, ex_PCTarget;
    wire [31:0] ex_PCTargetBr, ex_PCTargetJr;
    wire        ex_Zero, ex_PCSrc;
    wire [31:0] alu_SrcA_fwd, alu_SrcB_fwd, writeData_fwd;

    mux2 #(WIDTH) srcbmux (
        .d0 (ID_EX_WriteData),
        .d1 (ID_EX_ImmExt),
        .s  (ID_EX_ALUSrc),
        .y  (ex_SrcB)
    );

    // Forwarding del operando A (rs1)
    mux3 #(WIDTH) mux_forwardA (
        .d0 (ID_EX_SrcA),           // 00: valor leído en ID
        .d1 (wb_Result),            // 01: desde WB
        .d2 (EX_MEM_ALUResult),     // 10: desde MEM
        .s  (ForwardA),
        .y  (alu_SrcA_fwd)
    );

    // Forwarding del operando B de la ALU (rs2 o inmediato)
    mux3 #(WIDTH) mux_forwardB (
        .d0 (ex_SrcB),
        .d1 (wb_Result),
        .d2 (EX_MEM_ALUResult),
        .s  (ForwardB),
        .y  (alu_SrcB_fwd)
    );

    // Forwarding de rs2 sin inmediato: dato de sw y comparador de branches
    mux3 #(WIDTH) mux_forwardC (
        .d0 (ID_EX_WriteData),
        .d1 (wb_Result),
        .d2 (EX_MEM_ALUResult),
        .s  (ForwardC),
        .y  (writeData_fwd)
    );

    alu alu (
        .a          (alu_SrcA_fwd),
        .b          (alu_SrcB_fwd),
        .alucontrol (ID_EX_ALUControl),
        .result     (ex_ALUResult),
        .zero       (ex_Zero)
    );

    // Comparador de branches (usa los operandos ya con forwarding)
    reg ex_BranchTaken;
    always @(*) begin
        case (ID_EX_Funct3)
            3'b000:  ex_BranchTaken = (alu_SrcA_fwd == writeData_fwd);                   // beq
            3'b001:  ex_BranchTaken = (alu_SrcA_fwd != writeData_fwd);                   // bne
            3'b100:  ex_BranchTaken = ($signed(alu_SrcA_fwd) <  $signed(writeData_fwd)); // blt
            3'b101:  ex_BranchTaken = ($signed(alu_SrcA_fwd) >= $signed(writeData_fwd)); // bge
            3'b110:  ex_BranchTaken = (alu_SrcA_fwd <  writeData_fwd);                   // bltu
            3'b111:  ex_BranchTaken = (alu_SrcA_fwd >= writeData_fwd);                   // bgeu
            default: ex_BranchTaken = 1'b0;
        endcase
    end

    // Destino de branch/jal: PC de la instrucción en EX + inmediato.
    adder pcaddbranch (
        .a (ID_EX_PC),
        .b (ID_EX_ImmExt),
        .y (ex_PCTargetBr)
    );

    // Destino de jalr: la ALU calcula rs1 + imm; se limpia el bit 0.
    assign ex_PCTargetJr = {ex_ALUResult[31:1], 1'b0};

    mux2 #(WIDTH) pctargetmux (
        .d0 (ex_PCTargetBr),
        .d1 (ex_PCTargetJr),
        .s  (ID_EX_JumpReg),
        .y  (ex_PCTarget)
    );

    assign ex_PCSrc = (ID_EX_Branch & ex_BranchTaken) | ID_EX_Jump;

    mux2 #(WIDTH) pcmux (
        .d0 (PCPlus4),
        .d1 (ex_PCTarget),
        .s  (ex_PCSrc),
        .y  (PCNext)
    );

    // ------------------------------------------------------------ EX/MEM
    exmem reg_exmem (
        .clk             (clk),
        .reset           (reset),
        .ALUResult       (ex_ALUResult),
        .Zero            (ex_Zero),
        .WriteData       (writeData_fwd),
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

    // ---------------------------------------------------------- HAZARDS
    hazard_unit hu (
        .rs1_ID       (id_rs1),
        .rs2_ID       (id_rs2),
        .rs1_EX       (ID_EX_rs1),
        .rs2_EX       (ID_EX_rs2),
        .rd_EX        (ID_EX_rd),
        .ResultSrc_EX (ID_EX_ResultSrc),
        .RegWrite_EX  (ID_EX_RegWrite),
        .ALUSrc_EX    (ID_EX_ALUSrc),
        .rd_MEM       (EX_MEM_rd),
        .RegWrite_MEM (EX_MEM_RegWrite),
        .rd_WB        (MEM_WB_rd),
        .RegWrite_WB  (MEM_WB_RegWrite),
        .PCSrc_EX     (ex_PCSrc),
        .stall_IF_ID  (stall_ifid_hz),
        .stall_ID_EX  (stall_idex_hz),
        .flush_IF_ID  (flush_ifid_hz),
        .flush_ID_EX  (flush_idex_hz),
        .ForwardA     (ForwardA),
        .ForwardB     (ForwardB),
        .ForwardC     (ForwardC)
    );

    // --------------------------------------------------------- MEM y WB
    assign DataAdr   = EX_MEM_ALUResult;
    assign MemWrite  = EX_MEM_MemWrite;
    assign WriteData = EX_MEM_WriteData;

    assign wb_Result = (MEM_WB_ResultSrc == 2'b01) ? MEM_WB_ReadData :
                       (MEM_WB_ResultSrc == 2'b10) ? MEM_WB_PC4 :
                                                     MEM_WB_ALUResult;

endmodule
