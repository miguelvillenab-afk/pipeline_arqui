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
    // decode B
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
    // ID/EX B
    output [31:0] ID_EX_B_SrcA,
    output [31:0] ID_EX_B_WriteData,
    output [31:0] ID_EX_B_ImmExt,
    output [31:0] ID_EX_B_PC,
    output [31:0] ID_EX_B_PC4,
    output [4:0]  ID_EX_B_rs1,
    output [4:0]  ID_EX_B_rs2,
    output [4:0]  ID_EX_B_rd,
    output        ID_EX_B_ALUSrc,
    output [2:0]  ID_EX_B_ALUControl,
    output        ID_EX_B_RegWrite,
    output        ID_EX_B_MemWrite,
    output [1:0]  ID_EX_B_ResultSrc,
    output        ID_EX_B_Branch,
    output        ID_EX_B_Jump,
    output [1:0]  ID_EX_B_ImmSrc,
    // ID/EX A
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
    // EX/MEM A
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
    // MEM/WB A
    output [31:0] MEM_WB_ReadData,
    output [31:0] MEM_WB_ALUResult,
    output [31:0] MEM_WB_PC4,
    output [4:0]  MEM_WB_rd,
    output        MEM_WB_RegWrite,
    output [1:0]  MEM_WB_ResultSrc
);

    localparam WIDTH = 32;
    
    wire [4:0] rs1_A_eff = (IF_ID_Instr[6:0]   == 7'b0110111) ? 5'd0 : IF_ID_Instr[19:15];
    wire [4:0] rs1_B_eff = (IF_ID_Instr_B[6:0] == 7'b0110111) ? 5'd0 : IF_ID_Instr_B[19:15];

    // IF
    wire [31:0] PCNext, PCPlus4, PCPlus8;
    wire [31:0] wb_Result, wb_Result_B;
    wire stall_ifid_hz;
    wire flush_ifid_hz, flush_idex_a_hz, flush_idex_b_hz;
    wire [2:0] fwdA_A, fwdB_A, fwdC_A;
    wire [2:0] fwdA_B, fwdB_B, fwdC_B;
    wire issue_B_comb;
    wire IF_ID_IssueB;
    wire flush_idex_b;
    assign flush_idex_b = flush_idex_b_hz | ~IF_ID_IssueB;

    // Vía B
    wire [31:0] ex_SrcB_B, ex_ALUResult_B, ex_PCTarget_B;
    wire        ex_Zero_B, ex_PCSrc_B;
    wire [31:0] alu_SrcA_fwd_B, alu_SrcB_fwd_B, writeData_fwd_B;
    wire [31:0] EX_MEM_B_ALUResult, EX_MEM_B_WriteData;
    wire [31:0] EX_MEM_B_PC4, EX_MEM_B_PCTarget;
    wire [4:0]  EX_MEM_B_rd;
    wire        EX_MEM_B_Zero, EX_MEM_B_MemWrite, EX_MEM_B_RegWrite;
    wire        EX_MEM_B_Branch, EX_MEM_B_Jump;
    wire [1:0]  EX_MEM_B_ResultSrc;
    wire [31:0] MEM_WB_B_ReadData, MEM_WB_B_ALUResult, MEM_WB_B_PC4;
    wire [4:0]  MEM_WB_B_rd;
    wire        MEM_WB_B_RegWrite;
    wire [1:0]  MEM_WB_B_ResultSrc;

    // E2.4: flush_exmem_b se activa cuando A toma branch (B es más joven)
    wire flush_exmem_b;
    assign flush_exmem_b = 1'b0;  // Temporal: lo activaremos cuando tengamos ex_PCSrc

    // === IF ===
    flopenrc #(WIDTH) pcreg (
        .clk(clk), .reset(reset), .en(~stall_ifid_hz), .clr(1'b0),
        .d(PCNext), .q(PC)
    );
    adder pcadd4 (.a(PC), .b(32'd4), .y(PCPlus4));
    adder pcadd8 (.a(PC), .b(32'd8), .y(PCPlus8));

    // === IF/ID ===
    ifid reg_ifid_a (
        .clk(clk), .reset(reset), .stall(stall_ifid_hz), .flush(flush_ifid_hz),
        .Instr_in(Instr_A), .PC_in(PC), .PC4_in(PCPlus4),
        .IF_ID_Instr(IF_ID_Instr), .IF_ID_PC(IF_ID_PC), .IF_ID_PC4(IF_ID_PC4)
    );
    ifid reg_ifid_b (
        .clk(clk), .reset(reset), .stall(stall_ifid_hz), .flush(flush_ifid_hz),
        .Instr_in(Instr_B), .PC_in(PCPlus4), .PC4_in(PCPlus8),
        .IF_ID_Instr(IF_ID_Instr_B), .IF_ID_PC(IF_ID_PC_B), .IF_ID_PC4(IF_ID_PC4_B)
    );
    flopenrc #(1) reg_issue_b (
        .clk(clk), .reset(reset), .en(~stall_ifid_hz), .clr(flush_ifid_hz),
        .d(issue_B_comb), .q(IF_ID_IssueB)
    );

    // === ID vía A ===
    wire [31:0] id_SrcA, id_WriteData, ImmExt;
    wire [1:0] dec_ResultSrc, dec_ImmSrc, dec_ALUOp;
    wire dec_MemWrite, dec_Branch, dec_ALUSrc, dec_RegWrite, dec_Jump;
    wire [2:0] dec_ALUControl;

    maindec md (
        .op(IF_ID_Instr[6:0]), .ResultSrc(dec_ResultSrc), .MemWrite(dec_MemWrite),
        .Branch(dec_Branch), .ALUSrc(dec_ALUSrc), .RegWrite(dec_RegWrite),
        .Jump(dec_Jump), .ImmSrc(dec_ImmSrc), .ALUOp(dec_ALUOp)
    );
    aludec ad (
        .opb5(IF_ID_Instr[5]), .funct3(IF_ID_Instr[14:12]),
        .funct7b5(IF_ID_Instr[30]), .ALUOp(dec_ALUOp), .ALUControl(dec_ALUControl)
    );

    regfile_dual rf (
        .clk(clk), .reset(reset),
        .we3_A(MEM_WB_RegWrite), .a3_A(MEM_WB_rd), .wd3_A(wb_Result),
        .we3_B(MEM_WB_B_RegWrite), .a3_B(MEM_WB_B_rd), .wd3_B(wb_Result_B),
        .a1_A(rs1_A_eff), .a2_A(IF_ID_Instr[24:20]),
        .rd1_A(id_SrcA), .rd2_A(id_WriteData),
        .a1_B(rs1_B_eff), .a2_B(IF_ID_Instr_B[24:20]),
        .rd1_B(ID_B_SrcA), .rd2_B(ID_B_WriteData)
    );
    extend_dual ext (
        .instr(IF_ID_Instr), .immsrc(dec_ImmSrc), .immext(ImmExt)
    );

    // === ID vía B (Dual Decode) ===
    wire [1:0] dec_B_ResultSrc, dec_B_ImmSrc, dec_B_ALUOp;
    wire dec_B_MemWrite, dec_B_Branch, dec_B_ALUSrc, dec_B_RegWrite, dec_B_Jump;
    wire [2:0] dec_B_ALUControl;

    maindec md_b (
        .op(IF_ID_Instr_B[6:0]), .ResultSrc(dec_B_ResultSrc), .MemWrite(dec_B_MemWrite),
        .Branch(dec_B_Branch), .ALUSrc(dec_B_ALUSrc), .RegWrite(dec_B_RegWrite),
        .Jump(dec_B_Jump), .ImmSrc(dec_B_ImmSrc), .ALUOp(dec_B_ALUOp)
    );
    aludec ad_b (
        .opb5(IF_ID_Instr_B[5]), .funct3(IF_ID_Instr_B[14:12]),
        .funct7b5(IF_ID_Instr_B[30]), .ALUOp(dec_B_ALUOp), .ALUControl(dec_B_ALUControl)
    );
    extend_dual ext_b (
        .instr(IF_ID_Instr_B), .immsrc(dec_B_ImmSrc), .immext(ID_B_ImmExt)
    );

    assign ID_B_rs1 = rs1_B_eff;
    assign ID_B_rs2 = IF_ID_Instr_B[24:20];
    assign ID_B_rd  = IF_ID_Instr_B[11:7];
    assign ID_B_ALUSrc = dec_B_ALUSrc;
    assign ID_B_ALUControl = dec_B_ALUControl;
    assign ID_B_RegWrite = dec_B_RegWrite;
    assign ID_B_MemWrite = dec_B_MemWrite;
    assign ID_B_ResultSrc = dec_B_ResultSrc;
    assign ID_B_Branch = dec_B_Branch;
    assign ID_B_Jump = dec_B_Jump;

    // === ID/EX A ===
    idex reg_idex (
        .clk(clk), .reset(reset), .stall_ID_EX(1'b0), .flush_ID_EX(flush_idex_a_hz),
        .SrcA(id_SrcA), .WriteData(id_WriteData), .ImmExt(ImmExt),
        .IF_ID_PC(IF_ID_PC), .IF_ID_PC4(IF_ID_PC4),
        .rs1(rs1_A_eff), .rs2(IF_ID_Instr[24:20]), .rd(IF_ID_Instr[11:7]),
        .ALUSrc(dec_ALUSrc), .ALUControl(dec_ALUControl), .RegWrite(dec_RegWrite),
        .MemWrite(dec_MemWrite), .ResultSrc(dec_ResultSrc),
        .Branch(dec_Branch), .Jump(dec_Jump), .ImmSrc(dec_ImmSrc),
        .ID_EX_SrcA(ID_EX_SrcA), .ID_EX_WriteData(ID_EX_WriteData),
        .ID_EX_ImmExt(ID_EX_ImmExt), .ID_EX_PC(ID_EX_PC), .ID_EX_PC4(ID_EX_PC4),
        .ID_EX_rs1(ID_EX_rs1), .ID_EX_rs2(ID_EX_rs2), .ID_EX_rd(ID_EX_rd),
        .ID_EX_ALUSrc(ID_EX_ALUSrc), .ID_EX_ALUControl(ID_EX_ALUControl),
        .ID_EX_RegWrite(ID_EX_RegWrite), .ID_EX_MemWrite(ID_EX_MemWrite),
        .ID_EX_ResultSrc(ID_EX_ResultSrc), .ID_EX_Branch(ID_EX_Branch),
        .ID_EX_Jump(ID_EX_Jump), .ID_EX_ImmSrc(ID_EX_ImmSrc)
    );

    // === ID/EX B ===
    idex reg_idex_b (
        .clk(clk), .reset(reset), .stall_ID_EX(1'b0), .flush_ID_EX(flush_idex_b),
        .SrcA(ID_B_SrcA), .WriteData(ID_B_WriteData), .ImmExt(ID_B_ImmExt),
        .IF_ID_PC(IF_ID_PC_B), .IF_ID_PC4(IF_ID_PC4_B),
        .rs1(ID_B_rs1), .rs2(ID_B_rs2), .rd(ID_B_rd),
        .ALUSrc(ID_B_ALUSrc), .ALUControl(ID_B_ALUControl),
        .RegWrite(ID_B_RegWrite), .MemWrite(ID_B_MemWrite),
        .ResultSrc(ID_B_ResultSrc), .Branch(ID_B_Branch), .Jump(ID_B_Jump),
        .ImmSrc(dec_B_ImmSrc),
        .ID_EX_SrcA(ID_EX_B_SrcA), .ID_EX_WriteData(ID_EX_B_WriteData),
        .ID_EX_ImmExt(ID_EX_B_ImmExt), .ID_EX_PC(ID_EX_B_PC), .ID_EX_PC4(ID_EX_B_PC4),
        .ID_EX_rs1(ID_EX_B_rs1), .ID_EX_rs2(ID_EX_B_rs2), .ID_EX_rd(ID_EX_B_rd),
        .ID_EX_ALUSrc(ID_EX_B_ALUSrc), .ID_EX_ALUControl(ID_EX_B_ALUControl),
        .ID_EX_RegWrite(ID_EX_B_RegWrite), .ID_EX_MemWrite(ID_EX_B_MemWrite),
        .ID_EX_ResultSrc(ID_EX_B_ResultSrc), .ID_EX_Branch(ID_EX_B_Branch),
        .ID_EX_Jump(ID_EX_B_Jump), .ID_EX_ImmSrc(ID_EX_B_ImmSrc)
    );

    // === EX vía A ===
    wire [31:0] ex_SrcB, ex_ALUResult, ex_PCTarget;
    wire ex_Zero, ex_PCSrc;
    wire [31:0] alu_SrcA_fwd, alu_SrcB_fwd, writeData_fwd;

    mux2 #(WIDTH) srcbmux (.d0(ID_EX_WriteData), .d1(ID_EX_ImmExt), .s(ID_EX_ALUSrc), .y(ex_SrcB));
    mux5 #(WIDTH) mux_forwardA (.d0(ID_EX_SrcA), .d1(wb_Result), .d2(wb_Result_B),
                                .d3(EX_MEM_ALUResult), .d4(EX_MEM_B_ALUResult),
                                .s(fwdA_A), .y(alu_SrcA_fwd));
    mux5 #(WIDTH) mux_forwardB (.d0(ex_SrcB), .d1(wb_Result), .d2(wb_Result_B),
                                .d3(EX_MEM_ALUResult), .d4(EX_MEM_B_ALUResult),
                                .s(fwdB_A), .y(alu_SrcB_fwd));
    mux5 #(WIDTH) mux_forwardC (.d0(ID_EX_WriteData), .d1(wb_Result), .d2(wb_Result_B),
                                .d3(EX_MEM_ALUResult), .d4(EX_MEM_B_ALUResult),
                                .s(fwdC_A), .y(writeData_fwd));

    alu alu_inst (.a(alu_SrcA_fwd), .b(alu_SrcB_fwd), .alucontrol(ID_EX_ALUControl),
             .result(ex_ALUResult), .zero(ex_Zero));
    adder pcaddbranch (.a(ID_EX_PC), .b(ID_EX_ImmExt), .y(ex_PCTarget));
    assign ex_PCSrc = (ID_EX_Branch & ex_Zero) | ID_EX_Jump;

    // === EX vía B ===
    mux2 #(WIDTH) srcbmux_b (.d0(ID_EX_B_WriteData), .d1(ID_EX_B_ImmExt),
                             .s(ID_EX_B_ALUSrc), .y(ex_SrcB_B));
    mux5 #(WIDTH) mux_forwardA_B (.d0(ID_EX_B_SrcA), .d1(wb_Result), .d2(wb_Result_B),
                                  .d3(EX_MEM_ALUResult), .d4(EX_MEM_B_ALUResult),
                                  .s(fwdA_B), .y(alu_SrcA_fwd_B));
    mux5 #(WIDTH) mux_forwardB_B (.d0(ex_SrcB_B), .d1(wb_Result), .d2(wb_Result_B),
                                  .d3(EX_MEM_ALUResult), .d4(EX_MEM_B_ALUResult),
                                  .s(fwdB_B), .y(alu_SrcB_fwd_B));
    // E2.2: forwarding para dato de store en B
    mux5 #(WIDTH) mux_forwardC_B (.d0(ID_EX_B_WriteData), .d1(wb_Result), .d2(wb_Result_B),
                                  .d3(EX_MEM_ALUResult), .d4(EX_MEM_B_ALUResult),
                                  .s(fwdC_B), .y(writeData_fwd_B));

    alu alu_b (.a(alu_SrcA_fwd_B), .b(alu_SrcB_fwd_B), .alucontrol(ID_EX_B_ALUControl),
               .result(ex_ALUResult_B), .zero(ex_Zero_B));
    adder pcaddbranch_b (.a(ID_EX_B_PC), .b(ID_EX_B_ImmExt), .y(ex_PCTarget_B));
    assign ex_PCSrc_B = (ID_EX_B_Branch & ex_Zero_B) | ID_EX_B_Jump;

    // === E2.3: PC mux de 4 entradas ===
    // Prioridad: ex_PCSrc (A) > ex_PCSrc_B (B) > issue_B_comb
    wire [31:0] pc_sel_ab;
    mux2 #(WIDTH) pcmux_ab (
        .d0(PCPlus4),
        .d1(PCPlus8),
        .s(issue_B_comb),
        .y(pc_sel_ab)
    );
    wire [31:0] pc_sel_target;
    mux2 #(WIDTH) pcmux_target (
        .d0(ex_PCTarget_B),   // si solo B toma branch
        .d1(ex_PCTarget),     // si A toma branch (prioridad máxima)
        .s(ex_PCSrc),
        .y(pc_sel_target)
    );
    wire [31:0] pc_sel_final;
    mux2 #(WIDTH) pcmux_final (
        .d0(pc_sel_ab),           // ningún branch tomado
        .d1(pc_sel_target),       // algún branch tomado
        .s(ex_PCSrc | ex_PCSrc_B),
        .y(pc_sel_final)
    );
    assign PCNext = pc_sel_final;

    // === EX/MEM A ===
    exmem reg_exmem (
        .clk(clk), .reset(reset),
        .ALUResult(ex_ALUResult), .Zero(ex_Zero), .WriteData(writeData_fwd),
        .rd(ID_EX_rd), .PC4(ID_EX_PC4), .PCTarget(ex_PCTarget),
        .MemWrite(ID_EX_MemWrite), .RegWrite(ID_EX_RegWrite),
        .ResultSrc(ID_EX_ResultSrc), .Branch(ID_EX_Branch), .Jump(ID_EX_Jump),
        .EX_MEM_ALUResult(EX_MEM_ALUResult), .EX_MEM_Zero(EX_MEM_Zero),
        .EX_MEM_WriteData(EX_MEM_WriteData), .EX_MEM_rd(EX_MEM_rd),
        .EX_MEM_PC4(EX_MEM_PC4), .EX_MEM_PCTarget(EX_MEM_PCTarget),
        .EX_MEM_MemWrite(EX_MEM_MemWrite), .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .EX_MEM_ResultSrc(EX_MEM_ResultSrc), .EX_MEM_Branch(EX_MEM_Branch),
        .EX_MEM_Jump(EX_MEM_Jump)
    );

    // === EX/MEM B (con flush_exmem_b) ===
    exmem reg_exmem_b (
        .clk(clk), .reset(reset),
        .ALUResult(ex_ALUResult_B), .Zero(ex_Zero_B), .WriteData(writeData_fwd_B),
        .rd(ID_EX_B_rd), .PC4(ID_EX_B_PC4), .PCTarget(ex_PCTarget_B),
        .MemWrite(ID_EX_B_MemWrite & ~flush_exmem_b),
        .RegWrite(ID_EX_B_RegWrite & ~flush_exmem_b),
        .ResultSrc(ID_EX_B_ResultSrc), .Branch(ID_EX_B_Branch), .Jump(ID_EX_B_Jump),
        .EX_MEM_ALUResult(EX_MEM_B_ALUResult), .EX_MEM_Zero(EX_MEM_B_Zero),
        .EX_MEM_WriteData(EX_MEM_B_WriteData), .EX_MEM_rd(EX_MEM_B_rd),
        .EX_MEM_PC4(EX_MEM_B_PC4), .EX_MEM_PCTarget(EX_MEM_B_PCTarget),
        .EX_MEM_MemWrite(EX_MEM_B_MemWrite), .EX_MEM_RegWrite(EX_MEM_B_RegWrite),
        .EX_MEM_ResultSrc(EX_MEM_B_ResultSrc), .EX_MEM_Branch(EX_MEM_B_Branch),
        .EX_MEM_Jump(EX_MEM_B_Jump)
    );

    // === MEM/WB A ===
    memwb reg_memwb (
        .clk(clk), .reset(reset),
        .ReadData(ReadData), .ALUResult(EX_MEM_ALUResult), .PC4(EX_MEM_PC4),
        .rd(EX_MEM_rd), .RegWrite(EX_MEM_RegWrite), .ResultSrc(EX_MEM_ResultSrc),
        .MEM_WB_ReadData(MEM_WB_ReadData), .MEM_WB_ALUResult(MEM_WB_ALUResult),
        .MEM_WB_PC4(MEM_WB_PC4), .MEM_WB_rd(MEM_WB_rd),
        .MEM_WB_RegWrite(MEM_WB_RegWrite), .MEM_WB_ResultSrc(MEM_WB_ResultSrc)
    );

    // === MEM/WB B ===
    memwb reg_memwb_b (
        .clk(clk), .reset(reset),
        .ReadData(ReadData), .ALUResult(EX_MEM_B_ALUResult), .PC4(EX_MEM_B_PC4),
        .rd(EX_MEM_B_rd), .RegWrite(EX_MEM_B_RegWrite), .ResultSrc(EX_MEM_B_ResultSrc),
        .MEM_WB_ReadData(MEM_WB_B_ReadData), .MEM_WB_ALUResult(MEM_WB_B_ALUResult),
        .MEM_WB_PC4(MEM_WB_B_PC4), .MEM_WB_rd(MEM_WB_B_rd),
        .MEM_WB_RegWrite(MEM_WB_B_RegWrite), .MEM_WB_ResultSrc(MEM_WB_B_ResultSrc)
    );

    // === ISSUE UNIT ===
    issue_dual iu (
        .Instr_A(Instr_A), .Instr_B(Instr_B), .issue_B(issue_B_comb)
    );

    // === HAZARD UNIT ===
    hazard_dual hz (
        .rs1_A(rs1_A_eff), .rs2_A(IF_ID_Instr[24:20]),
        .rs1_B(rs1_B_eff), .rs2_B(IF_ID_Instr_B[24:20]),
        .issue_B(IF_ID_IssueB),
        .rs1_EX_A(ID_EX_rs1), .rs2_EX_A(ID_EX_rs2), .rd_EX_A(ID_EX_rd),
        .ResultSrc_EX_A(ID_EX_ResultSrc), .RegWrite_EX_A(ID_EX_RegWrite),
        .ALUSrc_EX_A(ID_EX_ALUSrc),
        .rs1_EX_B(ID_EX_B_rs1), .rs2_EX_B(ID_EX_B_rs2), .rd_EX_B(ID_EX_B_rd),
        .ResultSrc_EX_B(ID_EX_B_ResultSrc), .RegWrite_EX_B(ID_EX_B_RegWrite),
        .ALUSrc_EX_B(ID_EX_B_ALUSrc),
        .rd_MEM_A(EX_MEM_rd), .RegWrite_MEM_A(EX_MEM_RegWrite),
        .rd_MEM_B(EX_MEM_B_rd), .RegWrite_MEM_B(EX_MEM_B_RegWrite),
        .rd_WB_A(MEM_WB_rd), .RegWrite_WB_A(MEM_WB_RegWrite),
        .rd_WB_B(MEM_WB_B_rd), .RegWrite_WB_B(MEM_WB_B_RegWrite),
        .PCSrc_EX_A(ex_PCSrc), .PCSrc_EX_B(ex_PCSrc_B),
        .stall_IF_ID(stall_ifid_hz), .flush_IF_ID(flush_ifid_hz),
        .flush_ID_EX_A(flush_idex_a_hz), .flush_ID_EX_B(flush_idex_b_hz),
        .fwdA_A(fwdA_A), .fwdB_A(fwdB_A), .fwdC_A(fwdC_A),
        .fwdA_B(fwdA_B), .fwdB_B(fwdB_B), .fwdC_B(fwdC_B)
    );

    wire A_is_mem_op = EX_MEM_MemWrite   | (EX_MEM_ResultSrc   == 2'b01);

    assign DataAdr   = A_is_mem_op ? EX_MEM_ALUResult : EX_MEM_B_ALUResult;
    assign WriteData = A_is_mem_op ? EX_MEM_WriteData : EX_MEM_B_WriteData;
    assign MemWrite  = A_is_mem_op ? EX_MEM_MemWrite  : EX_MEM_B_MemWrite;

    // === WB ===
    assign wb_Result = (MEM_WB_ResultSrc == 2'b01) ? MEM_WB_ReadData :
                       (MEM_WB_ResultSrc == 2'b10) ? MEM_WB_PC4 :
                                                     MEM_WB_ALUResult;
    assign wb_Result_B = (MEM_WB_B_ResultSrc == 2'b01) ? MEM_WB_B_ReadData :
                         (MEM_WB_B_ResultSrc == 2'b10) ? MEM_WB_B_PC4 :
                                                         MEM_WB_B_ALUResult;

endmodule