`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// tb_top_pipeline: testbench de cierre de la Etapa 1 (pipeline single-issue).
//
// Corre en paralelo los 4 programas de programs/ y riscvtest.dat. Para cada
// DUT compara, al final de un numero fijo de ciclos:
//   - los 32 registros del regfile,
//   - las 64 palabras de dmem.
// Los valores esperados se generaron con un modelo RV32I independiente.
//
// riscvtest.dat termina con "beq x2,x2,0" (halt por auto-branch), por eso
// ademas se verifica el criterio clasico: sw de 25 en la direccion 100.
//
// Los .mem/.dat deben estar en el directorio de simulacion. En Vivado se
// copian desde las fuentes del proyecto; en xsim por linea de comandos se
// ejecuta desde un directorio que los contenga.
////////////////////////////////////////////////////////////////////////////////

module tb_top_pipeline();

    localparam integer NCYCLES = 400;

    reg clk;
    reg reset;
    integer errors;
    integer i;

    wire [31:0] wd_1, da_1;
    wire [31:0] wd_2, da_2;
    wire [31:0] wd_3, da_3;
    wire [31:0] wd_4, da_4;
    wire [31:0] wd_R, da_R;
    wire mw_1, mw_2, mw_3, mw_4, mw_R;

    top_pipeline #(.MEMFILE("program1.mem")) dut1 (
        .clk(clk), .reset(reset),
        .WriteData(wd_1), .DataAdr(da_1), .MemWrite(mw_1));

    top_pipeline #(.MEMFILE("program2.mem")) dut2 (
        .clk(clk), .reset(reset),
        .WriteData(wd_2), .DataAdr(da_2), .MemWrite(mw_2));

    top_pipeline #(.MEMFILE("program3.mem")) dut3 (
        .clk(clk), .reset(reset),
        .WriteData(wd_3), .DataAdr(da_3), .MemWrite(mw_3));

    top_pipeline #(.MEMFILE("program4.mem")) dut4 (
        .clk(clk), .reset(reset),
        .WriteData(wd_4), .DataAdr(da_4), .MemWrite(mw_4));

    top_pipeline #(.MEMFILE("riscvtest.dat")) dutR (
        .clk(clk), .reset(reset),
        .WriteData(wd_R), .DataAdr(da_R), .MemWrite(mw_R));

    reg [31:0] exp_reg_1 [0:31];
    reg [31:0] exp_reg_2 [0:31];
    reg [31:0] exp_reg_3 [0:31];
    reg [31:0] exp_reg_4 [0:31];
    reg [31:0] exp_reg_R [0:31];

    reg [31:0] exp_mem_1 [0:63];
    reg [31:0] exp_mem_2 [0:63];
    reg [31:0] exp_mem_3 [0:63];
    reg [31:0] exp_mem_4 [0:63];
    reg [31:0] exp_mem_R [0:63];

    reg saw_store_25;

    always #5 clk = ~clk;

    // Criterio clasico de riscvtest: store de 25 en direccion 100.
    always @(negedge clk) begin
        if (dutR.MemWrite && (dutR.DataAdr == 32'd100) && (dutR.WriteData == 32'd25))
            saw_store_25 <= 1'b1;
    end

    task check_reg(input integer prog, input integer idx,
                   input [31:0] got, input [31:0] exp);
        begin
            if (got !== exp) begin
                $display("FAIL P%0d x%0d: got %h exp %h", prog, idx, got, exp);
                errors = errors + 1;
            end
        end
    endtask

    task check_mem(input integer prog, input integer idx,
                   input [31:0] got, input [31:0] exp);
        begin
            if (got !== exp) begin
                $display("FAIL P%0d mem[%0d]: got %h exp %h", prog, idx, got, exp);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // ---------------- tablas esperadas ----------------
        for (i = 0; i < 32; i = i + 1) begin
            exp_reg_1[i] = 32'd0; exp_reg_2[i] = 32'd0; exp_reg_3[i] = 32'd0;
            exp_reg_4[i] = 32'd0; exp_reg_R[i] = 32'd0;
        end
        for (i = 0; i < 64; i = i + 1) begin
            exp_mem_1[i] = 32'd0; exp_mem_2[i] = 32'd0; exp_mem_3[i] = 32'd0;
            exp_mem_4[i] = 32'd0; exp_mem_R[i] = 32'd0;
        end

        // programa 1
        exp_reg_1[1]  = 32'h0000000A; exp_reg_1[2]  = 32'h00000014;
        exp_reg_1[3]  = 32'h00001234; exp_reg_1[4]  = 32'h0000001E;
        exp_reg_1[5]  = 32'h0000000A; exp_reg_1[6]  = 32'h0000001E;
        exp_reg_1[7]  = 32'h0000001E; exp_reg_1[8]  = 32'h00000014;
        exp_reg_1[10] = 32'h0000000A; exp_reg_1[11] = 32'h00000063;
        exp_mem_1[0] = 32'h0000000A; exp_mem_1[2] = 32'h0000001E;
        exp_mem_1[8] = 32'h0000001E;

        // programa 2
        exp_reg_2[1]  = 32'h0000000A; exp_reg_2[2]  = 32'h00000014;
        exp_reg_2[3]  = 32'h0000000A; exp_reg_2[4]  = 32'h0000000F;
        exp_reg_2[10] = 32'h0000000A;
        exp_mem_2[0] = 32'h0000000A; exp_mem_2[2] = 32'h0000001E;
        exp_mem_2[4] = 32'h0000000F;

        // programa 3
        exp_reg_3[1] = 32'h0000000A; exp_reg_3[2] = 32'h00000014;
        exp_reg_3[3] = 32'h0000000A; exp_reg_3[4] = 32'h0000001E;
        exp_reg_3[6] = 32'h0000001E;
        exp_mem_3[0] = 32'h0000000A; exp_mem_3[2] = 32'h0000001E;

        // programa 4
        exp_reg_4[1] = 32'h00000005; exp_reg_4[2] = 32'h00000005;
        exp_reg_4[3] = 32'h0000000A; exp_reg_4[4] = 32'h00000014;
        exp_reg_4[5] = 32'h00000019; exp_reg_4[6] = 32'h00000064;
        exp_mem_4[0] = 32'h0000000A; exp_mem_4[2] = 32'h0000001E;

        // riscvtest.dat
        exp_reg_R[2] = 32'h00000019; exp_reg_R[3] = 32'h00000044;
        exp_reg_R[4] = 32'h00000001; exp_reg_R[5] = 32'h0000000B;
        exp_reg_R[7] = 32'h00000007; exp_reg_R[9] = 32'h00000012;
        exp_mem_R[0]  = 32'h0000000A; exp_mem_R[2]  = 32'h0000001E;
        exp_mem_R[24] = 32'h00000007; exp_mem_R[25] = 32'h00000019;

        // ---------------- estimulo ----------------
        errors = 0;
        saw_store_25 = 1'b0;
        clk = 1'b0;
        reset = 1'b1;
        #20;
        reset = 1'b0;

        repeat (NCYCLES) @(posedge clk);
        #1;

        // ---------------- checks ----------------
        for (i = 0; i < 32; i = i + 1) begin
            check_reg(1, i, dut1.rvp.dp.rf.rf[i], exp_reg_1[i]);
            check_reg(2, i, dut2.rvp.dp.rf.rf[i], exp_reg_2[i]);
            check_reg(3, i, dut3.rvp.dp.rf.rf[i], exp_reg_3[i]);
            check_reg(4, i, dut4.rvp.dp.rf.rf[i], exp_reg_4[i]);
            check_reg(9, i, dutR.rvp.dp.rf.rf[i], exp_reg_R[i]);
        end

        for (i = 0; i < 64; i = i + 1) begin
            check_mem(1, i, dut1.dmem.RAM[i], exp_mem_1[i]);
            check_mem(2, i, dut2.dmem.RAM[i], exp_mem_2[i]);
            check_mem(3, i, dut3.dmem.RAM[i], exp_mem_3[i]);
            check_mem(4, i, dut4.dmem.RAM[i], exp_mem_4[i]);
            check_mem(9, i, dutR.dmem.RAM[i], exp_mem_R[i]);
        end

        if (!saw_store_25) begin
            $display("FAIL riscvtest: no se observo sw de 25 en direccion 100");
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("RESULTADO ETAPA 1: PASS");
            $finish;
        end else begin
            $fatal(1, "RESULTADO ETAPA 1: FAIL (%0d errores)", errors);
        end
    end

endmodule
