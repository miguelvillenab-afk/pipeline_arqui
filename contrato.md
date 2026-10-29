# Contrato de Interfaz — Registros de Pipeline (Etapa 1)

Este documento define los nombres exactos de señales para los 4 registros de pipeline que se deben agregar al procesador RISC-V single-cycle existente en `src files/`.

**Regla:** ningún integrante cambia un nombre sin avisar al equipo y actualizar este archivo.

---

## Convención de nombres

Cada registro de pipeline usa un prefijo que indica su ubicación:

| Registro | Prefijo | Ubicación |
|----------|---------|-----------|
| IF/ID | `IF_ID_` | Entre Fetch y Decode |
| ID/EX | `ID_EX_` | Entre Decode y Execute |
| EX/MEM | `EX_MEM_` | Entre Execute y Memory |
| MEM/WB | `MEM_WB_` | Entre Memory y Writeback |

Señales globales de control de registros:
- `clk` — reloj
- `reset` — reset síncrono/asíncrono (según `flopr.v`)
- `stall_<registro>` — si es 1, el registro **no se actualiza** (hold)
- `flush_<registro>` — si es 1, el registro se limpia (nop)

---

## 1. Registro IF/ID (Fetch → Decode)

### Entradas (qué se mete al registro)

| Señal | Origen en el proyecto actual | Descripción |
|-------|------------------------------|-------------|
| `clk`, `reset` | top / testbench | Reloj y reset |
| `stall_IF_ID` | lógica de hazard | Mantiene el valor actual |
| `flush_IF_ID` | lógica de branch tomado | Limpia el registro |
| `Instr` | salida de `imem` | Instrucción de 32 bits |
| `PC` | salida de `pcreg` (PC actual) | Dirección actual |
| `PCPlus4` | salida de `pcadd4` | PC + 4 |

### Salidas (qué entrega a la etapa ID)

| Señal | Se conecta a | Descripción |
|-------|--------------|-------------|
| `IF_ID_Instr` | `regfile` (rs1, rs2, rd), `extend`, `controller` | Instrucción decodificada |
| `IF_ID_PC` | lógica de branch/jump | PC actual |
| `IF_ID_PC4` | Registro ID/EX | PC + 4 (para `jal`) |

---

## 2. Registro ID/EX (Decode → Execute)

### Entradas (qué se mete al registro)

| Señal | Origen en el proyecto actual | Descripción |
|-------|------------------------------|-------------|
| `clk`, `reset` | — | Reloj y reset |
| `stall_ID_EX` | lógica de hazard | Mantiene el valor actual |
| `flush_ID_EX` | lógica de branch tomado | Limpia señales de control |
| `SrcA` | `rd1` del `regfile` | Valor de registro rs1 |
| `WriteData` | `rd2` del `regfile` | Valor de registro rs2 |
| `ImmExt` | salida de `extend` | Inmediato extendido a 32 bits |
| `IF_ID_PC4` | de IF/ID | PC + 4 |
| `IF_ID_Instr[19:15]` | de IF/ID | Dirección rs1 |
| `IF_ID_Instr[24:20]` | de IF/ID | Dirección rs2 |
| `IF_ID_Instr[11:7]` | de IF/ID | Dirección rd |
| `ALUSrc` | salida de `controller` | Mux SrcB |
| `ALUControl` | salida de `aludec` | Operación ALU |
| `RegWrite` | salida de `controller` | Habilita escritura regfile |
| `MemWrite` | salida de `controller` | Habilita escritura dmem |
| `ResultSrc` | salida de `controller` | Mux resultado final |
| `Branch` | salida de `maindec` | Branch condicional |
| `Jump` | salida de `controller` | Salto incondicional |
| `ImmSrc` | salida de `maindec` | Tipo de inmediato |

### Salidas (qué entrega a la etapa EX)

| Señal | Se conecta a | Descripción |
|-------|--------------|-------------|
| `ID_EX_SrcA` | Operando A de ALU | — |
| `ID_EX_WriteData` | Operando B / dato para store | — |
| `ID_EX_ImmExt` | Operando B (si ALUSrc=1) | — |
| `ID_EX_PC4` | Cálculo de salto `jal` | — |
| `ID_EX_rs1` | Detección de hazards / forwarding | Dirección rs1 |
| `ID_EX_rs2` | Detección de hazards / forwarding | Dirección rs2 |
| `ID_EX_rd` | Escritura en WB | Dirección destino |
| `ID_EX_ALUSrc` | Control de ALU | — |
| `ID_EX_ALUControl` | Control de ALU | — |
| `ID_EX_RegWrite` | Control de WB | — |
| `ID_EX_MemWrite` | Control de MEM | — |
| `ID_EX_ResultSrc` | Control de WB | — |
| `ID_EX_Branch` | Control de PC | — |
| `ID_EX_Jump` | Control de PC | — |
| `ID_EX_ImmSrc` | Control de inmediato | — |

---

## 3. Registro EX/MEM (Execute → Memory)

### Entradas (qué se mete al registro)

| Señal | Origen en el proyecto actual | Descripción |
|-------|------------------------------|-------------|
| `clk`, `reset` | — | Reloj y reset |
| `ALUResult` | salida de `alu` | Resultado de la ALU |
| `Zero` | salida de `alu` | Bandera cero (branch) |
| `ID_EX_WriteData` | de ID/EX | Dato para store (`sw`) |
| `ID_EX_rd` | de ID/EX | Dirección destino |
| `ID_EX_PC4` | de ID/EX | PC + 4 |
| `ID_EX_MemWrite` | de ID/EX | `we` de `dmem` |
| `ID_EX_RegWrite` | de ID/EX | Habilita escritura regfile |
| `ID_EX_ResultSrc` | de ID/EX | Mux resultado final |
| `ID_EX_Branch` | de ID/EX | Branch condicional |
| `ID_EX_Jump` | de ID/EX | Salto incondicional |
| Dirección de branch/jump | `pcaddbranch` / cálculo `jal` | PC destino |

### Salidas (qué entrega a la etapa MEM)

| Señal | Se conecta a | Descripción |
|-------|--------------|-------------|
| `EX_MEM_ALUResult` | Dirección de memoria / resultado | — |
| `EX_MEM_Zero` | Decisión de branch tomado | — |
| `EX_MEM_WriteData` | Dato a escribir en `dmem` | — |
| `EX_MEM_rd` | Registro destino para WB | — |
| `EX_MEM_PC4` | Para escribir PC+4 en rd (`jal`) | — |
| `EX_MEM_MemWrite` | `we` de `dmem` | — |
| `EX_MEM_RegWrite` | Control de WB | — |
| `EX_MEM_ResultSrc` | Control de WB | — |
| `EX_MEM_Branch` | Control de PC | — |
| `EX_MEM_Jump` | Control de PC | — |
| `EX_MEM_PCTarget` | Dirección de salto calculada | — |

---

## 4. Registro MEM/WB (Memory → Writeback)

### Entradas (qué se mete al registro)

| Señal | Origen en el proyecto actual | Descripción |
|-------|------------------------------|-------------|
| `clk`, `reset` | — | Reloj y reset |
| `ReadData` | salida de `dmem` | Dato leído de memoria |
| `EX_MEM_ALUResult` | de EX/MEM | Resultado ALU o dirección |
| `EX_MEM_PC4` | de EX/MEM | PC + 4 |
| `EX_MEM_rd` | de EX/MEM | Dirección destino |
| `EX_MEM_RegWrite` | de EX/MEM | Habilita escritura regfile |
| `EX_MEM_ResultSrc` | de EX/MEM | Mux resultado final |

### Salidas (qué entrega a la etapa WB)

| Señal | Se conecta a | Descripción |
|-------|--------------|-------------|
| `MEM_WB_ReadData` | input `d1` del `resultmux` | — |
| `MEM_WB_ALUResult` | input `d0` del `resultmux` | — |
| `MEM_WB_PC4` | input `d2` del `resultmux` | — |
| `MEM_WB_rd` | `a3` del `regfile` (write port) | — |
| `MEM_WB_RegWrite` | `we3` del `regfile` | — |
| `MEM_WB_ResultSrc` | selector `s` del `resultmux` | — |

---

## 5. Señales finales de Writeback (al Register File)

| Señal | Destino en el proyecto actual |
|-------|------------------------------|
| `MEM_WB_ResultSrc` | selector `s` del `resultmux` |
| `MEM_WB_ALUResult` | input `d0` del `resultmux` |
| `MEM_WB_ReadData` | input `d1` del `resultmux` |
| `MEM_WB_PC4` | input `d2` del `resultmux` |
| `resultmux.y` | `wd3` del `regfile` |
| `MEM_WB_rd` | `a3` del `regfile` |
| `MEM_WB_RegWrite` | `we3` del `regfile` |

---

## 6. Ejemplo de declaración (SystemVerilog/Verilog)

```systemverilog
// Registro IF/ID
logic [31:0] IF_ID_Instr, IF_ID_PC, IF_ID_PC4;

// Registro ID/EX
logic [31:0] ID_EX_SrcA, ID_EX_WriteData, ID_EX_ImmExt, ID_EX_PC4;
logic [4:0]  ID_EX_rs1, ID_EX_rs2, ID_EX_rd;
logic        ID_EX_ALUSrc, ID_EX_RegWrite, ID_EX_MemWrite;
logic        ID_EX_Branch, ID_EX_Jump;
logic [1:0]  ID_EX_ResultSrc, ID_EX_ImmSrc;
logic [2:0]  ID_EX_ALUControl;

// Registro EX/MEM
logic [31:0] EX_MEM_ALUResult, EX_MEM_WriteData, EX_MEM_PC4, EX_MEM_PCTarget;
logic [4:0]  EX_MEM_rd;
logic        EX_MEM_Zero, EX_MEM_MemWrite, EX_MEM_RegWrite;
logic        EX_MEM_Branch, EX_MEM_Jump;
logic [1:0]  EX_MEM_ResultSrc;

// Registro MEM/WB
logic [31:0] MEM_WB_ReadData, MEM_WB_ALUResult, MEM_WB_PC4;
logic [4:0]  MEM_WB_rd;
logic        MEM_WB_RegWrite;
logic [1:0]  MEM_WB_ResultSrc;
```
