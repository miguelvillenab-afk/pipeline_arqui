`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// tb_program5: prueba autoverificable del pipeline Single-Issue con
// programs/program5.mem.
//
// Cubre: xor, sll, srl, sra, sltu, slt y sus versiones inmediatas; lui con
// bits de rs1 distintos de cero; escritura a x0; beq, bne, blt, bge, bltu,
// bgeu (tomados y no tomados, hacia adelante y hacia atrás); jal y jalr
// (con bit 0 del destino en 1); forwarding desde MEM y WB, forwarding del
// dato de sw, load-use y bypass del Register File.
//
// Cada instrucción del camino incorrecto suma 1 a x31, así que x31 = 0
// significa que los flush funcionaron. Al terminar imprime PASS/FAIL, los
// ciclos y las instrucciones ejecutadas según el modelo de referencia.
//////////////////////////////////////////////////////////////////////////////////

module tb_program5();

    reg clk;
    reg reset;

    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire        MemWrite;

    top_pipeline #(.MEMFILE("program5.mem")) dut (
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );

    localparam [31:0] END_PC    = 32'h000000e8;  // beq x0, x0, END
    localparam integer N_INSTR  = 62;            // instrucciones ejecutadas (modelo de referencia)

    integer errors;
    integer cycles;

    task check_reg(input integer r, input [31:0] exp);
        begin
            if (dut.rvp.dp.rf.rf[r] !== exp) begin
                $display("FAIL x%0d = %h, esperado %h", r, dut.rvp.dp.rf.rf[r], exp);
                errors = errors + 1;
            end
        end
    endtask

    task check_mem(input integer w, input [31:0] exp);
        begin
            if (dut.dmem.RAM[w] !== exp) begin
                $display("FAIL mem[%0d] = %h, esperado %h", w*4, dut.dmem.RAM[w], exp);
                errors = errors + 1;
            end
        end
    endtask

    always #5 clk = ~clk;

    initial begin
        clk    = 0;
        reset  = 1;
        errors = 0;
        cycles = 0;
        #22;
        reset = 0;

        // Corre hasta que el beq final llega a EX (o hasta un límite).
        while (!(dut.rvp.dp.ID_EX_PC == END_PC && dut.rvp.dp.ID_EX_Branch) && cycles < 2000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        // Deja terminar MEM y WB de las instrucciones anteriores.
        repeat (3) @(posedge clk);
        #1;

        check_reg( 1, 32'h000000d0);
        check_reg( 2, 32'hfffffffd);
        check_reg( 3, 32'h1230a000);
        check_reg( 4, 32'h00000002);
        check_reg( 5, 32'hfffffffb);
        check_reg( 6, 32'hfffffff8);
        check_reg( 7, 32'h000000a0);
        check_reg( 8, 32'h07ffffff);
        check_reg( 9, 32'hffffffff);
        check_reg(10, 32'h00000001);
        check_reg(11, 32'h00000000);
        check_reg(12, 32'hfffffffb);
        check_reg(13, 32'hfffffff8);
        check_reg(14, 32'hfffff802);
        check_reg(15, 32'hffffffe8);
        check_reg(16, 32'h0000000f);
        check_reg(17, 32'hfffffffe);
        check_reg(18, 32'h00000001);
        check_reg(19, 32'h00000001);
        check_reg(20, 32'h000000f0);
        check_reg(21, 32'h00000106);
        check_reg(22, 32'h00000005);
        check_reg(23, 32'h0000000a);
        check_reg(24, 32'h00000000);
        check_reg(25, 32'h0000000a);
        check_reg(26, 32'h0000000b);
        check_reg(27, 32'h00000014);
        check_reg(28, 32'h000000d4);
        check_reg(29, 32'h000000e4);
        check_reg(30, 32'h000000dc);
        check_reg(31, 32'h00000000);
        check_mem( 0, 32'h0000000a);  // dirección 0
        check_mem( 2, 32'h0000000a);  // dirección 8
        check_mem( 3, 32'h0000000b);  // dirección 12
        check_mem( 4, 32'h000000dc);  // dirección 16

        if (cycles >= 2000)
            $display("FAIL: el programa no llegó al final (timeout)");
        if (errors == 0 && cycles < 2000)
            $display("PROGRAM5 PASS  ciclos hasta el beq final en EX = %0d, instrucciones ejecutadas = %0d", cycles, N_INSTR);
        else
            $display("PROGRAM5 FAIL  (%0d errores)", errors);
        $finish;
    end

endmodule
