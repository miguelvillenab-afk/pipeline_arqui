`timescale 1ns / 1ps

module tb_idex_simple();

    reg clk;
    reg reset;
    reg [31:0] SrcA;
    reg [31:0] WriteData;

    wire [31:0] ID_EX_SrcA;
    wire [31:0] ID_EX_WriteData;

    idex dut (
        .clk(clk),
        .reset(reset),
        .SrcA(SrcA),
        .WriteData(WriteData),
        .stall_ID_EX(1'b0),
        .flush_ID_EX(1'b0),
        .ImmExt(32'b0),
        .IF_ID_PC4(32'b0),
        .rs1(5'b0), 
        .rs2(5'b0), 
        .rd(5'b0),
        .ALUSrc(1'b0), 
        .ALUControl(3'b0), 
        .RegWrite(1'b0), 
        .MemWrite(1'b0),
        .ResultSrc(2'b0), 
        .Branch(1'b0), 
        .Jump(1'b0), 
        .ImmSrc(2'b0),
        .ID_EX_SrcA(ID_EX_SrcA),
        .ID_EX_WriteData(ID_EX_WriteData),
        .ID_EX_ImmExt(), 
        .ID_EX_PC4(),
        .ID_EX_rs1(),
        .ID_EX_rs2(),
        .ID_EX_rd(),
        .ID_EX_ALUSrc(),
        .ID_EX_ALUControl(),
        .ID_EX_RegWrite(),
        .ID_EX_MemWrite(),
        .ID_EX_ResultSrc(),
        .ID_EX_Branch(),
        .ID_EX_Jump(),
        .ID_EX_ImmSrc()
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        SrcA = 32'h00000000;
        WriteData = 32'h00000000;

        #15; 
        reset = 0; 
        
        SrcA = 32'hAAAAAAAA; 
        WriteData = 32'h11111111;
        #10; 
        
        SrcA = 32'hBBBBBBBB; 
        WriteData = 32'h22222222;
        #10; 
        
        SrcA = 32'hCCCCCCCC; 
        WriteData = 32'h33333333;
        #10; 
        
        SrcA = 32'hDDDDDDDD; 
        WriteData = 32'h44444444;
        #10; 
        
        SrcA = 32'h00000000; 
        WriteData = 32'h00000000;
        #20;

        $finish;
    end

endmodule