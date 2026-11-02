`timescale 1ns / 1ps

module hazard_unit (
    // Entradas desde el pipeline
    input [4:0] rs1_ID, rs2_ID,        // Registros fuente de la instrucción en ID
    input [4:0] rs1_EX, rs2_EX,        // Registros fuente de la instrucción en EX
    input [4:0] rd_EX, rd_MEM,         // Registros destino de las etapas EX y MEM
    
    // Señales de control para saber si la instrucción escribe en registro y de dónde trae el dato
    input       ResultSrc_EX,          // 1 si la instrucción en EX es un lw (espera dato de memoria)
    input       RegWrite_EX,           // 1 si la instrucción en EX va a escribir en el regfile
    input       RegWrite_MEM,          // 1 si la instrucción en MEM va a escribir en el regfile
    input       PCSrc_EX,              // 1 si se tomó un branch/jump en EX

    // Salidas hacia los registros y muxes
    output reg       stall_IF_ID,      // Congela IF/ID
    output reg       stall_ID_EX,      // Congela ID/EX
    output reg       flush_IF_ID,      // Limpia IF/ID
    output reg       flush_ID_EX,      // Limpia ID/EX
    output reg [1:0] ForwardA, ForwardB // Selección de muxes de forwarding
);

    // Lógica del Load-Use Hazard (Stall)
    // Un lw en EX genera un stall si la instrucción en ID necesita ese registro.
    // OJO: Si rd_EX es 0 (x0), no hay hazard, porque x0 nunca cambia.
    wire lw_stall = (ResultSrc_EX == 2'b01) && (rd_EX != 5'd0) && 
                    ((rd_EX == rs1_ID) || (rd_EX == rs2_ID));

    always @(*) begin
        // Por defecto, no hay stall ni flush
        stall_IF_ID = 0; 
        stall_ID_EX = 0; 
        flush_IF_ID = 0; 
        flush_ID_EX = 0;
        ForwardA = 2'b00; 
        ForwardB = 2'b00;
        
        // 1. Evaluar Load-Use Hazard (Stall + Burbuja)
        if (lw_stall) begin
            stall_IF_ID = 1;  // Congela Fetch (PC y la instrucción en IF/ID)
            stall_ID_EX = 1;  // Congela los datos que iban a pasar de ID a EX
            //flush_ID_EX = 1;  // Limpia el registro ID/EX para inyectar un NOP en EX
        end
        
        // 2. Evaluar Branch (si no hay stall). Si el salto se tomó, limpia las instrucciones erróneas.
        else if (PCSrc_EX) begin
            flush_IF_ID = 1;
            //flush_ID_EX = 1;
        end
        
        // 3. Forwarding desde EX/MEM (Prioridad alta)
        // Si la instrucción anterior (en EX) va a escribir y es el mismo registro...
        if (RegWrite_EX && (rd_EX != 5'd0) && (rd_EX == rs1_EX)) 
            ForwardA = 2'b10;
        if (RegWrite_EX && (rd_EX != 5'd0) && (rd_EX == rs2_EX)) 
            ForwardB = 2'b10;
        
        // 4. Forwarding desde MEM/WB (Prioridad baja, solo si no se resolvió en el paso 3)
        if (RegWrite_MEM && (rd_MEM != 5'd0) && (rd_MEM == rs1_EX) && !(RegWrite_EX && (rd_EX == rs1_EX))) 
            ForwardA = 2'b01;
        if (RegWrite_MEM && (rd_MEM != 5'd0) && (rd_MEM == rs2_EX) && !(RegWrite_EX && (rd_EX == rs2_EX))) 
            ForwardB = 2'b01;
    end

endmodule