`timescale 1ns / 1ps
// Issue Unit Dual-Issue
// Decide si la instrucción B del par recién buscado se puede emitir junto con A.
// Se evalúa en la etapa IF porque el PC tiene que avanzar +8 o +4 en ese mismo ciclo.
//
// Política actualizada (E2):
//   - B puede ser ALU, LUI, Load, Store, Branch o JAL/JALR.
//   - A puede ser cualquier instrucción, pero si A es Branch/JAL, B no se emite 
//     (porque si A se toma, B es camino incorrecto).
//   - Conflictos estructurales: No se pueden emitir dos Mem Ops ni dos Branches juntos.
//   - Dependencias: Sin RAW ni WAW intra-par.
module issue_dual(
    input  [31:0] Instr_A,
    input  [31:0] Instr_B,
    output reg    issue_B
);

    // DECLARACIÓN DE OP-CODES (Aquí estaba el error, faltaba OP_JALR)
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

    // ---------------------------------------------------------
    // Sub-tarea 1.1 y 1.2: Detectar tipo de instrucción en A y B
    // ---------------------------------------------------------
    
    // ¿Es operación de memoria?
    wire A_is_mem = (op_A == OP_LOAD) || (op_A == OP_STORE);
    wire B_is_mem = (op_B == OP_LOAD) || (op_B == OP_STORE);

    // ¿Es instrucción de control (Branch/Jump)?
    wire A_is_branch = (op_A == OP_BRANCH) || (op_A == OP_JAL) || (op_A == OP_JALR);
    wire B_is_branch = (op_B == OP_BRANCH) || (op_B == OP_JAL) || (op_B == OP_JALR);

    // ¿Escribe en un registro? (Load, R-type, I-type ALU, LUI, JAL, JALR escriben. Store NO).
    wire A_writes_reg = (op_A == OP_RTYPE) || (op_A == OP_ITYPE) || 
                        (op_A == OP_LUI) || (op_A == OP_LOAD) || 
                        (op_A == OP_JAL) || (op_A == OP_JALR);
                        
    wire B_writes_reg = (op_B == OP_RTYPE) || (op_B == OP_ITYPE) || 
                        (op_B == OP_LUI) || (op_B == OP_LOAD) || 
                        (op_B == OP_JAL) || (op_B == OP_JALR);

    // Campos de registros
    wire [4:0] A_rd  = Instr_A[11:7],  A_rs1 = Instr_A[19:15], A_rs2 = Instr_A[24:20];
    wire [4:0] B_rd  = Instr_B[11:7],  B_rs1 = Instr_B[19:15], B_rs2 = Instr_B[24:20];

    // ---------------------------------------------------------
    // Sub-tarea 1.3: Detectar conflictos estructurales
    // ---------------------------------------------------------
    
    // Conflicto de puerto de memoria (solo hay 1 puerto de datos)
    wire mem_conflict = A_is_mem && B_is_mem;
    
    // Conflicto de unidad de branches (solo hay 1 recurso de resolución)
    wire branch_conflict = A_is_branch && B_is_branch;

    // ---------------------------------------------------------
    // Sub-tarea 1.4: Detectar dependencias intra-par (RAW y WAW)
    // ---------------------------------------------------------
    
    // RAW: A escribe en un registro que B necesita leer
    wire raw = A_writes_reg && (A_rd != 5'd0) && 
               ((A_rd == B_rs1) || (A_rd == B_rs2));
               
    // WAW: A y B escriben en el mismo registro (distinto de x0)
    wire waw = A_writes_reg && B_writes_reg && (A_rd != 5'd0) && (A_rd == B_rd);

    // ---------------------------------------------------------
    // Sub-tarea 1.5: Lógica de emisión completa
    // ---------------------------------------------------------
    always @(*) begin
        issue_B = 1'b0; // Por defecto no se emite B
        
        // B se emite si se cumplen TODAS estas condiciones:
        // 1. No hay conflicto de memoria.
        // 2. No hay conflicto de branch.
        // 3. No hay dependencia RAW intra-par.
        // 4. No hay dependencia WAW intra-par.
        // 5. A no es una instrucción de control (si A es branch/jal, B es camino incorrecto).
        if (!mem_conflict && !branch_conflict && !raw && !waw && !A_is_branch) begin
            issue_B = 1'b1;
        end
    end

endmodule