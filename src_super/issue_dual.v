`timescale 1ns / 1ps
// Issue Unit Dual-Issue
// Decide si B (segunda instruccion del par) se emite junto con A.
// Se evalua en IF: el PC avanza +8 si issue_B=1, o +4 si B se reagrupa.
//
// B no se emite si:
//   - A y B acceden a memoria (un solo puerto de datos)
//   - A y B son branch/jump (un solo recurso de resolucion)
//   - A es branch/jump (B seria camino incorrecto si A salta)
//   - hay RAW o WAW entre A y B
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
                     OP_JALR   = 7'b1100111,
                     OP_LUI    = 7'b0110111;

    wire [6:0] op_A = Instr_A[6:0];
    wire [6:0] op_B = Instr_B[6:0];

    wire A_is_mem = (op_A == OP_LOAD) || (op_A == OP_STORE);
    wire B_is_mem = (op_B == OP_LOAD) || (op_B == OP_STORE);

    wire A_is_branch = (op_A == OP_BRANCH) || (op_A == OP_JAL) || (op_A == OP_JALR);
    wire B_is_branch = (op_B == OP_BRANCH) || (op_B == OP_JAL) || (op_B == OP_JALR);

    // Store y Branch no escriben registro
    wire A_writes_reg = (op_A == OP_RTYPE) || (op_A == OP_ITYPE) ||
                        (op_A == OP_LUI)   || (op_A == OP_LOAD)  ||
                        (op_A == OP_JAL)   || (op_A == OP_JALR);

    wire B_writes_reg = (op_B == OP_RTYPE) || (op_B == OP_ITYPE) ||
                        (op_B == OP_LUI)   || (op_B == OP_LOAD)  ||
                        (op_B == OP_JAL)   || (op_B == OP_JALR);

    wire [4:0] A_rd  = Instr_A[11:7];
    wire [4:0] B_rd  = Instr_B[11:7];
    wire [4:0] B_rs1 = Instr_B[19:15];
    wire [4:0] B_rs2 = Instr_B[24:20];

    wire mem_conflict    = A_is_mem && B_is_mem;
    wire branch_conflict = A_is_branch && B_is_branch;

    // RAW: A escribe un registro que B lee.
    // Nota: compara rs2 aunque B no lo use (I-type, LUI, JAL), lo que
    // genera falsos positivos y baja el IPC.
    wire raw = A_writes_reg && (A_rd != 5'd0) &&
               ((A_rd == B_rs1) || (A_rd == B_rs2));

    // WAW: A y B escriben el mismo registro
    wire waw = A_writes_reg && B_writes_reg && (A_rd != 5'd0) && (A_rd == B_rd);

    always @(*) begin
        issue_B = !mem_conflict && !branch_conflict && !raw && !waw && !A_is_branch;
    end

endmodule