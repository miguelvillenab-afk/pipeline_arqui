`timescale 1ns/1ps

module datapath(input  clk, reset,
                input  [1:0]  ResultSrc, 
                input  PCSrc, ALUSrc,
                input  RegWrite,
                input  [1:0]  ImmSrc, 
                input  [2:0]  ALUControl,
                output Zero,
                output [31:0] PC,
                input  [31:0] Instr,
                output [31:0] ALUResult, WriteData, 
                input  [31:0] ReadData,
                output [31:0] IF_ID_Instr,
                output [31:0] IF_ID_PC,
                output [31:0] IF_ID_PC4
                );
  
  localparam WIDTH = 32; // Define a local parameter for bus width

  // para la estapa fecth/id
  wire [31:0] PCNext, PCPlus4, PCTarget; 
  wire [31:0] ImmExt; 
  wire [31:0] id_SrcA, id_WriteData;



  //salidas del reg_idex - etapa execute
  wire[31:0] ex_SrcA, ex_WriteData, ex_ImmExt,ex_PC4;
  wire[4:0] ex_rs1, ex_rs2, ex_rd;
  wire      ex_ALUSrc, ex_RegWrite, ex_MemWrite, ex_Branch, ex_Jump;
  wire[2:0] ex_ALUControl;
  wire[1:0] ex_ResultSrc, ex_ImmSrc;

  //cables internos de la etapa execute
  wire [31:0] ex_SrcB, ex_ALUResult;

  //cables de la etapa WB
  wire [31:0] wb_Result; 

  // next PC logic
  flopr #(WIDTH) pcreg(
    .clk(clk), 
    .reset(reset), 
    .d(PCNext), 
    .q(PC)
  ); 

  adder       pcadd4(
    .a(PC), 
    .b({WIDTH{1'b0}} + 4), // Using WIDTH parameter for constant 4
    .y(PCPlus4)
  ); 

  ifid reg_ifid (
    .clk (clk),
    .reset (reset),
    .stall (1'b0),  //igual q el flush 
    .flush (1'b0), //0 hardcodeado para hacer en una siguiente fase
    .Instr_in (Instr),
    .PC_in (PC),
    .PC4_in (PCPlus4),
    .IF_ID_Instr (IF_ID_Instr),
    .IF_ID_PC (IF_ID_PC),
    .IF_ID_PC4 (IF_ID_PC4)
  );
  
 idex reg_idex(
    
    .clk(clk),
    .reset(reset),
    .stall_ID_EX(1'b0),
    .flush_ID_EX(1'b0),

    //Entradas de la etapa ID
    .SrcA(id_SrcA),
    .WriteData(id_WriteData),
    .ImmExt(ImmExt),
    .IF_ID_PC4(IF_ID_PC4),
    .rs1(IF_ID_Instr[19:15]),
    .rs2(IF_ID_Instr[24:20]),
    .rd(IF_ID_Instr[11:7]),
    .ALUSrc(ALUSrc),
    .ALUControl(ALUControl),
    .RegWrite(RegWrite),
    .MemWrite(1'b0),
    .ResultSrc(ResultSrc),
    .Branch(1'b0),
    .Jump(1'b0),
    .ImmSrc(ImmSrc),

    //Salidas hacia etapa Execute
    .ID_EX_SrcA(ex_SrcA),
    .ID_EX_WriteData(ex_WriteData),
    .ID_EX_ImmExt(ex_ImmExt),
    .ID_EX_PC4(ex_PC4),
    .ID_EX_rs1(ex_rs1),
    .ID_EX_rs2(ex_rs2),
    .ID_EX_rd(ex_rd),
    .ID_EX_ALUSrc(ex_ALUSrc),
    .ID_EX_ALUControl(ex_ALUControl),
    .ID_EX_RegWrite(ex_RegWrite),
    .ID_EX_MemWrite(ex_MemWrite),
    .ID_EX_ResultSrc(ex_ResultSrc),
    .ID_EX_Branch(ex_Branch),
    .ID_EX_Jump(ex_Jump),
    .ID_EX_ImmSrc(ex_ImmSrc)
 );
 
  adder       pcaddbranch(
    .a(IF_ID_PC), 
    .b(ex_ImmExt), 
    .y(PCTarget)
  ); 

  mux2 #(WIDTH)  pcmux(
    .d0(PCPlus4), 
    .d1(PCTarget), 
    .s(PCSrc), 
    .y(PCNext)
  ); 
 
  // register file logic
  regfile     rf(
    .clk(clk), 
    .we3(ex_RegWrite), 
    .a1(IF_ID_Instr[19:15]), 
    .a2(IF_ID_Instr[24:20]), 
    .a3(ex_rd), 
    .wd3(wb_Result), 
    .rd1(id_SrcA), 
    .rd2(id_WriteData)
  ); 

  extend      ext(
    .instr(IF_ID_Instr[31:7]), 
    .immsrc(ImmSrc), 
    .immext(ImmExt)
  ); 

  // ALU logic
  mux2 #(WIDTH)  srcbmux(
    .d0(ex_WriteData), 
    .d1(ex_ImmExt), 
    .s(ex_ALUSrc), 
    .y(ex_SrcB)
  ); 

  alu         alu(
    .a(ex_SrcA), 
    .b(ex_SrcB), 
    .alucontrol(ex_ALUControl), 
    .result(ex_ALUResult), 
    .zero(Zero)
  ); 

  mux3 #(WIDTH)  resultmux(
    .d0(ex_ALUResult), 
    .d1(ReadData), 
    .d2(ex_PC4), 
    .s(ex_ResultSrc), 
    .y(wb_Result)
  ); 
    assign ALUResult = ex_ALUResult;
    assign WriteData = ex_WriteData;
endmodule