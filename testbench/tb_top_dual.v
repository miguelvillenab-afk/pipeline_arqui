`timescale 1ns / 1ps

// tb_top_dual: corre el programa del profesor (prueba_final.mem) en el
// procesador Dual-Issue. Misma estructura que tb_top_pipeline.
module tb_top_dual();

    reg clk;
    reg reset;

    wire [31:0] PC;
    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire        MemWrite;

    top_dual #(.MEMFILE("prueba_final.mem")) dut (
        .clk(clk),
        .reset(reset),
        .PC(PC),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );

    always #5 clk = ~clk;

    // ---- Memoria de datos para las capturas de ondas (direcciones 1536-1588) ----
    wire signed [31:0] M1536 = dut.dmem.RAM[384];
    wire signed [31:0] M1540 = dut.dmem.RAM[385];
    wire signed [31:0] M1544 = dut.dmem.RAM[386];
    wire signed [31:0] M1548 = dut.dmem.RAM[387];
    wire signed [31:0] M1552 = dut.dmem.RAM[388];
    wire signed [31:0] M1556 = dut.dmem.RAM[389];
    wire signed [31:0] M1560 = dut.dmem.RAM[390];
    wire signed [31:0] M1564 = dut.dmem.RAM[391];
    wire signed [31:0] M1568 = dut.dmem.RAM[392];
    wire signed [31:0] M1572 = dut.dmem.RAM[393];
    wire signed [31:0] M1576 = dut.dmem.RAM[394];
    wire signed [31:0] M1580 = dut.dmem.RAM[395];
    wire signed [31:0] M1584 = dut.dmem.RAM[396];
    wire signed [31:0] M1588 = dut.dmem.RAM[397];

    initial begin
        clk = 0;
        reset = 1;
        #20;
        reset = 0;

        #5000;
        $display("Simulación finalizada.");
        $finish;
    end

endmodule
