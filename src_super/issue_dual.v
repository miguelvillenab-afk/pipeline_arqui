`timescale 1ns / 1ps
// Decide si la instrucción B del par recién buscado se puede emitir junto con A.
// Se evalúa en la etapa IF porque el PC tiene que avanzar +8 o +4 en ese mismo
// ciclo; por eso no se puede decidir después, en ID.
//
// política:
//   - B solo puede ser ALU (R-type, I-type ALU) o LUI.
//   - A no puede ser branch ni jal.
//   - Sin RAW intra-par: si A escribe un registro que B lee, no se emite B.
//   - Sin WAW intra-par: si A y B escriben el mismo rd, no se emite B.

module issue_dual(
    input  [31:0] Instr_A,
    input  [31:0] Instr_B,
    output reg    issue_B
    );

    localparam [6:0] OP_LOAD   = 7'b0000011,
                     OP_STORE  = 7'b0100011,
                     OP_RTYPE  = 7'b0110011,
                     OP_BRANCH = 7'b1100011,
                     OP_ITYPE  = 7'b0010011,
                     OP_JAL    = 7'b1101111,
                     OP_LUI    = 7'b0110111;

    wire [6:0] op_A = Instr_A[6:0];
    wire [6:0] op_B = Instr_B[6:0];

    // A: qué tipo de instr es
    wire A_load   = (op_A == OP_LOAD);
    wire A_branch = (op_A == OP_BRANCH);
    wire A_jal    = (op_A == OP_JAL);
    wire A_writes = (op_A == OP_RTYPE) || (op_A == OP_ITYPE) ||
                    (op_A == OP_LUI)   || A_load || A_jal;

    // B: solo ALU / LUI
    wire B_alu    = (op_B == OP_RTYPE) || (op_B == OP_ITYPE) || (op_B == OP_LUI);
    wire B_writes = B_alu;

    wire [4:0] A_rd  = Instr_A[11:7],
               A_rs1 = Instr_A[19:15],
               A_rs2 = Instr_A[24:20];
    wire [4:0] B_rd  = Instr_B[11:7],
               B_rs1 = Instr_B[19:15],
               B_rs2 = Instr_B[24:20];

    wire raw = A_writes && (A_rd != 5'd0) &&
               ((A_rd == B_rs1) || (A_rd == B_rs2));

    wire waw = A_writes && B_writes && (A_rd != 5'd0) && (A_rd == B_rd);

    always @(*) begin
        issue_B = 1'b0;
        if (B_alu && !A_branch && !A_jal && !raw && !waw)
            issue_B = 1'b1;
    end

endmodule