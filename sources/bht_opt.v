`timescale 1ns / 1ps
module bht_opt(
    input clk,
    input reset,
    // Puerto de lectura A
    input [31:0] pc_A,
    output predict_taken_A,
    // Puerto de lectura B
    input [31:0] pc_B,
    output predict_taken_B,
    // Puerto de actualización A
    input update_en_A,
    input [31:0] update_pc_A,
    input actual_taken_A,
    // Puerto de actualización B
    input update_en_B,
    input [31:0] update_pc_B,
    input actual_taken_B
);

    // 64 entradas de 2 bits
    reg [1:0] bht_table [0:63];
    integer i;

    // Índices usando los bits 7 a 2 del PC
    wire [5:0] read_idx_A  = pc_A[7:2];
    wire [5:0] read_idx_B  = pc_B[7:2];
    wire [5:0] write_idx_A = update_pc_A[7:2];
    wire [5:0] write_idx_B = update_pc_B[7:2];

    // Inicialización: Weakly Not Taken (01)
    initial begin
        for(i = 0; i < 64; i = i + 1) bht_table[i] = 2'b01;
    end

    // Lógica de Predicción (Lectura)
    assign predict_taken_A = bht_table[read_idx_A][1];
    assign predict_taken_B = bht_table[read_idx_B][1];

    // Lógica de Actualización (Escritura)
    always @(posedge clk) begin
        if (reset) begin
            for(i = 0; i < 64; i = i + 1) bht_table[i] <= 2'b01;
        end else begin
            if (update_en_A) begin
                case(bht_table[write_idx_A])
                    2'b00: bht_table[write_idx_A] <= actual_taken_A ? 2'b01 : 2'b00;
                    2'b01: bht_table[write_idx_A] <= actual_taken_A ? 2'b10 : 2'b00;
                    2'b10: bht_table[write_idx_A] <= actual_taken_A ? 2'b11 : 2'b01;
                    2'b11: bht_table[write_idx_A] <= actual_taken_A ? 2'b11 : 2'b10;
                endcase
            end
            if (update_en_B) begin
                case(bht_table[write_idx_B])
                    2'b00: bht_table[write_idx_B] <= actual_taken_B ? 2'b01 : 2'b00;
                    2'b01: bht_table[write_idx_B] <= actual_taken_B ? 2'b10 : 2'b00;
                    2'b10: bht_table[write_idx_B] <= actual_taken_B ? 2'b11 : 2'b01;
                    2'b11: bht_table[write_idx_B] <= actual_taken_B ? 2'b11 : 2'b10;
                endcase
            end
        end
    end
endmodule