`timescale 1ns / 1ps

module tb_dual_alu_indep_debug;
    // Señales del top-level
    reg clk;
    reg reset;
    wire [31:0] PC;
    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire MemWrite;

    // Señales internas para debug (acceso jerárquico)
    wire [31:0] Instr_A;
    wire [31:0] Instr_B;
    wire issue_B_comb;

    // Instancia del top dual
    // Nota: ReadData YA NO es un puerto aquí, es un wire interno de top_dual
    top_dual #(
        .MEMFILE("dual_alu_indep_debug.mem")
    ) uut (
        .clk(clk), 
        .reset(reset),
        .PC(PC),
        .WriteData(WriteData), 
        .DataAdr(DataAdr), 
        .MemWrite(MemWrite)
    );

    // Conectar señales internas para verlas en el waveform y consola
    assign Instr_A = uut.rvd.dp.Instr_A;
    assign Instr_B = uut.rvd.dp.Instr_B;
    assign issue_B_comb = uut.rvd.dp.issue_B_comb;

    // Generador de reloj (Periodo de 10ns)
    initial begin 
        clk = 0; 
        forever #5 clk = ~clk; 
    end

    initial begin
        reset = 1;
        #20 reset = 0;

        repeat(30) @(posedge clk);

        $display("x1=%0d (esp 12)  x4=%0d (esp 30)  x6=%0d (esp 23)  x8=%0d (esp 34)",
            uut.rvd.dp.rf.rf[1], uut.rvd.dp.rf.rf[4],
            uut.rvd.dp.rf.rf[6], uut.rvd.dp.rf.rf[8]);

        if (uut.rvd.dp.rf.rf[1]===12 && uut.rvd.dp.rf.rf[4]===30 &&
            uut.rvd.dp.rf.rf[6]===23 && uut.rvd.dp.rf.rf[8]===34)
            $display("[OK] Resultados correctos");
        else
            $display("[ERROR] Resultados incorrectos");
        $finish;
    end
endmodule