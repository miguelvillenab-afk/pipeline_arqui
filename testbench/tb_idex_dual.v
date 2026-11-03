`timescale 1ns / 1ps

module tb_idex_dual;

    reg clk;
    reg reset;
    reg [31:0] Instr_A;
    reg [31:0] Instr_B;

    wire [31:0] PC;
    wire [31:0] IF_ID_Instr;
    wire [31:0] IF_ID_Instr_B;

    wire [31:0] ID_EX_B_SrcA;
    wire [31:0] ID_EX_B_WriteData;
    wire [31:0] ID_EX_B_ImmExt;
    wire [31:0] ID_EX_B_PC;
    wire [31:0] ID_EX_B_PC4;
    wire [4:0]  ID_EX_B_rs1;
    wire [4:0]  ID_EX_B_rs2;
    wire [4:0]  ID_EX_B_rd;
    wire        ID_EX_B_ALUSrc;
    wire [2:0]  ID_EX_B_ALUControl;
    wire        ID_EX_B_RegWrite;
    wire        ID_EX_B_MemWrite;
    wire [1:0]  ID_EX_B_ResultSrc;
    wire        ID_EX_B_Branch;
    wire        ID_EX_B_Jump;
    wire [1:0]  ID_EX_B_ImmSrc;

    integer errors;

    localparam [31:0] NOP       = 32'h0000_0013;
    localparam [31:0] ADDI_X2_20 = 32'h0140_0113; // addi x2, x0, 20
    localparam [31:0] BEQ_X0_X0  = 32'h0000_0063; // beq x0, x0, 0

    datapath_dual dut (
        .clk                 (clk),
        .reset               (reset),
        .PC                  (PC),
        .Instr_A             (Instr_A),
        .Instr_B             (Instr_B),
        .ReadData            (32'b0),
        .IF_ID_Instr         (IF_ID_Instr),
        .IF_ID_Instr_B       (IF_ID_Instr_B),
        .ID_EX_B_SrcA        (ID_EX_B_SrcA),
        .ID_EX_B_WriteData   (ID_EX_B_WriteData),
        .ID_EX_B_ImmExt      (ID_EX_B_ImmExt),
        .ID_EX_B_PC          (ID_EX_B_PC),
        .ID_EX_B_PC4         (ID_EX_B_PC4),
        .ID_EX_B_rs1         (ID_EX_B_rs1),
        .ID_EX_B_rs2         (ID_EX_B_rs2),
        .ID_EX_B_rd          (ID_EX_B_rd),
        .ID_EX_B_ALUSrc      (ID_EX_B_ALUSrc),
        .ID_EX_B_ALUControl  (ID_EX_B_ALUControl),
        .ID_EX_B_RegWrite    (ID_EX_B_RegWrite),
        .ID_EX_B_MemWrite    (ID_EX_B_MemWrite),
        .ID_EX_B_ResultSrc   (ID_EX_B_ResultSrc),
        .ID_EX_B_Branch      (ID_EX_B_Branch),
        .ID_EX_B_Jump        (ID_EX_B_Jump),
        .ID_EX_B_ImmSrc      (ID_EX_B_ImmSrc)
    );

    always #5 clk = ~clk;

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task check;
        input condition;
        input [8*100-1:0] message;
        begin
            if (condition)
                $display("PASS: %0s", message);
            else begin
                $display("FAIL: %0s", message);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        Instr_A = NOP;
        Instr_B = ADDI_X2_20;
        errors = 0;

        // Reset limpia el nuevo registro ID/EX de B.
        tick();
        check(ID_EX_B_RegWrite == 1'b0, "reset limpia RegWrite de B");
        check(ID_EX_B_rd == 5'd0, "reset limpia rd de B");
        check(ID_EX_B_PC == 32'd0, "reset limpia PC de B");

        // La pareja entra en IF/ID y luego B avanza a ID/EX.
        @(negedge clk);
        reset = 1'b0;
        tick();
        check(IF_ID_Instr_B == ADDI_X2_20, "IF/ID recibe addi de la vía B");
        tick();

        check(ID_EX_B_SrcA == 32'd0, "B captura SrcA leido desde x0");
        check(ID_EX_B_WriteData == 32'd0, "B captura el segundo operando de x20");
        check(ID_EX_B_ImmExt == 32'd20, "B captura el inmediato 20");
        check(ID_EX_B_PC == 32'd4, "B captura su PC (PC+4)");
        check(ID_EX_B_PC4 == 32'd8, "B captura su PC+4 (PC+8 del par)");
        check(ID_EX_B_rs1 == 5'd0, "B captura rs1");
        check(ID_EX_B_rd == 5'd2, "B captura rd=x2");
        check(ID_EX_B_ALUSrc == 1'b1, "B captura ALUSrc de addi");
        check(ID_EX_B_ALUControl == 3'b000, "B captura ALUControl de suma");
        check(ID_EX_B_RegWrite == 1'b1, "B captura RegWrite de addi");
        check(ID_EX_B_MemWrite == 1'b0, "B no activa MemWrite para addi");
        check(ID_EX_B_ResultSrc == 2'b00, "B selecciona resultado ALU");
        check(ID_EX_B_Branch == 1'b0 && ID_EX_B_Jump == 1'b0,
              "B no activa branch ni jump para addi");
        check(ID_EX_B_ImmSrc == 2'b00, "B captura ImmSrc de tipo I");

        // Un branch tomado por A debe limpiar la instrucción joven de B.
        @(negedge clk);
        Instr_A = BEQ_X0_X0;
        Instr_B = ADDI_X2_20;
        tick(); // branch y B llegan a IF/ID
        tick(); // branch llega a EX; B llega a ID/EX
        check(ID_EX_B_RegWrite == 1'b1, "B está en ID/EX antes del flush del branch");
        tick(); // PCSrc de A limpia ID/EX para ambas vías
        check(ID_EX_B_RegWrite == 1'b0, "branch tomado limpia RegWrite de B");
        check(ID_EX_B_rd == 5'd0, "branch tomado limpia rd de B");
        check(ID_EX_B_ImmExt == 32'd0, "branch tomado limpia el inmediato de B");

        if (errors == 0) begin
            $display("TESTBENCH ID/EX DUAL: PASS");
            $finish;
        end else begin
            $display("TESTBENCH ID/EX DUAL: FAIL (%0d errores)", errors);
            $fatal(1);
        end
    end

endmodule
