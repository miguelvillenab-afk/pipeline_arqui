`timescale 1ns / 1ps

// =====================================================================
//  tb_c_opt: metricas de la arquitectura C (Dual-Issue + BHT 2 bits)
//  Solo cambia MEMFILE. PC_FINAL y la memoria esperada se configuran solos.
// =====================================================================

`define DP_C    dut.rvd.dp
`define DMEM_C  dut.dmem.RAM
`define IMEM_C  dut.imem.RAM

module tb_c_opt();

    // ---------------- UNICA LINEA A CAMBIAR ----------------
    localparam MEMFILE = "programa_propio.mem";
    //   "programa_propio.mem"    programa propio
    //   "prueba_final.mem"       programa del profesor
    //   "programa_predictor.mem" programa corto del predictor
    // -------------------------------------------------------

    localparam ES_PROPIO = (MEMFILE == "programa_propio.mem");
    localparam ES_PROFE  = (MEMFILE == "prueba_final.mem");
    localparam ES_CORTO  = (MEMFILE == "programa_predictor.mem");
    localparam CHECK_MEM = ES_PROPIO | ES_PROFE | ES_CORTO;
    localparam MAX_TIME  = 20000;

    reg clk;
    reg reset;

    wire [31:0] PC;
    wire        MemWrite;
    wire [31:0] DataAdr;
    wire [31:0] WriteData;

    top_opt #(.MEMFILE(MEMFILE)) dut (
        .clk(clk),
        .reset(reset),
        .PC(PC),
        .MemWrite(MemWrite),
        .DataAdr(DataAdr),
        .WriteData(WriteData)
    );

    always #5 clk = ~clk;

    // PC del jal final: se busca en la memoria de instrucciones el primer
    // "jal x0, 0" (0x0000006F), que es el bucle final de los tres programas
    reg [31:0] PC_FINAL;
    integer k;
    initial begin
        PC_FINAL = 32'h0;
        #1;
        for (k = 255; k >= 0; k = k - 1)
            if (`IMEM_C[k] === 32'h0000006F) PC_FINAL = k * 4;
    end

    wire signed [31:0] M1536 = `DMEM_C[384];
    wire signed [31:0] M1540 = `DMEM_C[385];
    wire signed [31:0] M1544 = `DMEM_C[386];
    wire signed [31:0] M1548 = `DMEM_C[387];
    wire signed [31:0] M1552 = `DMEM_C[388];
    wire signed [31:0] M1556 = `DMEM_C[389];
    wire signed [31:0] M1560 = `DMEM_C[390];
    wire signed [31:0] M1564 = `DMEM_C[391];
    wire signed [31:0] M1568 = `DMEM_C[392];
    wire signed [31:0] M1572 = `DMEM_C[393];
    wire signed [31:0] M1576 = `DMEM_C[394];
    wire signed [31:0] M1580 = `DMEM_C[395];
    wire signed [31:0] M1584 = `DMEM_C[396];
    wire signed [31:0] M1588 = `DMEM_C[397];

    wire [31:0] pc4_w0 = `DP_C.MEM_WB_PC4;
    wire [31:0] pc4_w1 = `DP_C.MEM_WB_B_PC4;

    wire valid0 = (pc4_w0 !== 32'h0) && (^pc4_w0 !== 1'bx);
    wire valid1 = (pc4_w1 !== 32'h0) && (^pc4_w1 !== 1'bx);

    wire final_retire = (PC_FINAL != 32'h0) &&
                        ((valid0 && pc4_w0 == PC_FINAL + 4) ||
                         (valid1 && pc4_w1 == PC_FINAL + 4));

    wire ctrl_A = `DP_C.ID_EX_Branch   | `DP_C.ID_EX_Jump;
    wire ctrl_B = `DP_C.ID_EX_B_Branch | `DP_C.ID_EX_B_Jump;

    integer cycle_count, instr_count;
    integer dual_ret, single_ret, solo_B;
    integer stall_cnt, flush_cnt;
    integer br_total, br_taken, pred_taken, mispred;
    reg     done;
    real    CPI, IPC;

    always @(posedge clk) begin
        if (reset) begin
            cycle_count <= 0;  instr_count <= 0;
            dual_ret    <= 0;  single_ret  <= 0;  solo_B <= 0;
            stall_cnt   <= 0;  flush_cnt   <= 0;
            br_total    <= 0;  br_taken    <= 0;
            pred_taken  <= 0;  mispred     <= 0;
            done <= 0;  CPI <= 0.0;  IPC <= 0.0;
        end else if (!done) begin
            cycle_count <= cycle_count + 1;
            instr_count <= instr_count + valid0 + valid1;

            if (valid0 && valid1)     dual_ret   <= dual_ret + 1;
            else if (valid0 ^ valid1) single_ret <= single_ret + 1;
            if (!valid0 && valid1)    solo_B     <= solo_B + 1;

            if (`DP_C.stall_ifid_hz) stall_cnt <= stall_cnt + 1;
            if (`DP_C.flush_ifid_hz) flush_cnt <= flush_cnt + 1;

            br_total   <= br_total   + ctrl_A + ctrl_B;
            br_taken   <= br_taken   + (ctrl_A & `DP_C.ex_PCSrc) + (ctrl_B & `DP_C.ex_PCSrc_B);
            pred_taken <= pred_taken + (ctrl_A & `DP_C.ID_EX_predict_taken)
                                     + (ctrl_B & `DP_C.ID_EX_B_predict_taken);
            mispred    <= mispred    + `DP_C.mispred_A + `DP_C.mispred_B;

            if (instr_count > 0) begin
                CPI <= $itor(cycle_count) / $itor(instr_count);
                IPC <= $itor(instr_count) / $itor(cycle_count);
            end

            if (final_retire) done <= 1;
        end
    end

    // Memoria esperada (1536 a 1588) segun el programa
    reg signed [31:0] esperado [0:13];
    integer j;
    initial begin
        for (j = 0; j < 14; j = j + 1) esperado[j] = 0;

        if (ES_PROFE) begin
            esperado[0]  = 11;  esperado[1]  = 5;   esperado[2]  = 12;
            esperado[3]  = 7;   esperado[4]  = 16;  esperado[5]  = 23;
            esperado[6]  = 24;  esperado[7]  = 18;  esperado[8]  = 24;
            esperado[9]  = 74;  esperado[10] = 4;   esperado[11] = 0;
            esperado[12] = 1;   esperado[13] = 1;
        end else if (ES_PROPIO) begin
            esperado[0]  = 7;   esperado[1]  = -3;  esperado[2]  = 12;
            esperado[3]  = 7;   esperado[4]  = 0;   esperado[5]  = 25;
            esperado[6]  = 7;   esperado[7]  = -8;  esperado[8]  = 188;
            esperado[9]  = 25;  esperado[10] = 12;  esperado[11] = 213;
        end else if (ES_CORTO) begin
            esperado[0]  = 16;  esperado[1]  = 4;   esperado[2]  = 5;
        end
    end

    integer i, errores;

    initial begin
        clk = 0;
        reset = 1;
        #20;
        reset = 0;

        fork : esperar
            begin
                wait (done);
                repeat (3) @(posedge clk);
                disable esperar;
            end
            begin
                #MAX_TIME;
                $display("AVISO: no retiro la instruccion final. Resultados parciales.");
                disable esperar;
            end
        join

        errores = 0;
        if (CHECK_MEM)
            for (i = 0; i < 14; i = i + 1)
                if (`DMEM_C[384 + i] !== esperado[i]) begin
                    errores = errores + 1;
                    $display("  ERROR M%0d: obtenido=%0d esperado=%0d",
                             1536 + 4*i, $signed(`DMEM_C[384 + i]), esperado[i]);
                end

        $display("==============================================");
        $display(" Arquitectura           : C - DUAL-ISSUE + BHT 2 bits");
        $display(" Programa               : %0s", MEMFILE);
        $display(" PC final detectado     : 0x%0h", PC_FINAL);
        $display(" Instrucciones retiradas: %0d", instr_count);
        $display(" Ciclos                 : %0d", cycle_count);
        if (instr_count > 0 && cycle_count > 0) begin
            $display(" CPI                    : %0.4f", $itor(cycle_count) / $itor(instr_count));
            $display(" IPC                    : %0.4f", $itor(instr_count) / $itor(cycle_count));
        end
        $display(" Ciclos retiro doble    : %0d", dual_ret);
        $display(" Ciclos retiro simple   : %0d", single_ret);
        $display(" Ciclos solo via B      : %0d", solo_B);
        $display(" Stalls load-use        : %0d", stall_cnt);
        $display(" Flushes                : %0d", flush_cnt);
        $display(" Saltos resueltos       : %0d", br_total);
        $display(" Saltos tomados         : %0d", br_taken);
        $display(" Predichos tomados      : %0d", pred_taken);
        $display(" Aciertos               : %0d", br_total - mispred);
        $display(" Mispredicciones        : %0d", mispred);
        if (br_total > 0)
            $display(" Precision              : %0.2f %%",
                     100.0 * $itor(br_total - mispred) / $itor(br_total));
        if (!CHECK_MEM)
            $display(" Verificacion memoria   : no definida para este .mem");
        else if (errores == 0)
            $display(" Verificacion memoria   : PASS");
        else
            $display(" Verificacion memoria   : FAIL (%0d errores)", errores);
        $display("==============================================");
        $finish;
    end

endmodule