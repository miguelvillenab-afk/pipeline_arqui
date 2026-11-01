# Fase 4 — Memory, Writeback y registro MEM/WB

**Proyecto:** pipeline RISC-V de 5 etapas (`pipeline_arqui`)
**Rama:** `mod-miguel`
**Fecha:** 2026-11-01
**Estado:** ✅ Implementada y verificada con Icarus Verilog

---

## 1. Objetivo

En la Fase 3 el writeback era **provisional**: el `regfile` se escribía todavía desde
`EX_MEM_*`, es decir, al final de la etapa MEM. La Fase 4 cierra el pipeline de cinco etapas:

1. Crear el registro **MEM/WB**.
2. Mover el writeback a `MEM_WB_*`.
3. Mantener la lógica de memoria (`dmem`, `MemWrite`, `DataAdr`, `WriteData`) en la etapa MEM.
4. Verificar que las fases anteriores y el single-cycle de referencia sigan funcionando.

Con esto la cadena queda completa:

```
IF → IF/ID → ID → ID/EX → EX → EX/MEM → MEM → MEM/WB → WB
```

---

## 2. Archivos de la Fase 4

| Archivo | Tipo | Cambio |
|---------|------|--------|
| `src files/memwb.v` | **Nuevo** | Registro MEM/WB con reset asíncrono. |
| `src files/datapath_pipeline.v` | Modificado | Instancia `memwb`, expone `MEM_WB_*`, writeback real desde `MEM_WB_*`. |
| `src files/riscvpipeline.v` | Modificado | Conecta las nuevas salidas de observabilidad `MEM_WB_*`. |
| `testbench/testbench_memwb.v` | **Nuevo** | Testbench unitario del registro y del mux de writeback. |
| `doc/diagrama_datapath_single_issue.drawio` | **Nuevo** | Diagrama Draw.io del datapath de 5 etapas. |
| `FASES_DESARROLLO.md` | Modificado | Fase 4 marcada como completada. |
| `contrato.md` | Modificado | La nota 7 deja de decir “writeback provisional”. |

---

## 3. Registro MEM/WB (`src files/memwb.v`)

### 3.1 Interfaz

| Puerto | Ancho | Origen / destino |
|--------|-------|------------------|
| `clk` | 1 | Reloj global |
| `reset` | 1 | Reset asíncrono |
| `ReadData` | 32 | Salida `rd` de `dmem` |
| `ALUResult` | 32 | `EX_MEM_ALUResult` |
| `PC4` | 32 | `EX_MEM_PC4` |
| `rd` | 5 | `EX_MEM_rd` |
| `RegWrite` | 1 | `EX_MEM_RegWrite` |
| `ResultSrc` | 2 | `EX_MEM_ResultSrc` |
| `MEM_WB_ReadData` | 32 | Entrada `d1` del `resultmux` |
| `MEM_WB_ALUResult` | 32 | Entrada `d0` del `resultmux` |
| `MEM_WB_PC4` | 32 | Entrada `d2` del `resultmux` |
| `MEM_WB_rd` | 5 | `a3` del `regfile` |
| `MEM_WB_RegWrite` | 1 | `we3` del `regfile` |
| `MEM_WB_ResultSrc` | 2 | Selector `s` del `resultmux` |

### 3.2 Comportamiento

```verilog
always @(posedge clk or posedge reset) begin
    if (reset) begin
        MEM_WB_ReadData  <= 32'b0;
        MEM_WB_ALUResult <= 32'b0;
        MEM_WB_PC4       <= 32'b0;
        MEM_WB_rd        <= 5'b0;
        MEM_WB_RegWrite  <= 1'b0;
        MEM_WB_ResultSrc <= 2'b0;
    end else begin
        MEM_WB_ReadData  <= ReadData;
        MEM_WB_ALUResult <= ALUResult;
        MEM_WB_PC4       <= PC4;
        MEM_WB_rd        <= rd;
        MEM_WB_RegWrite  <= RegWrite;
        MEM_WB_ResultSrc <= ResultSrc;
    end
end
```

### 3.3 ¿Por qué MEM/WB no tiene `stall` ni `flush`?

Porque las instrucciones que llegan a MEM **deben completar su recorrido**:

- Si se congelara MEM/WB, una instrucción quedaría atrapada entre MEM y WB y el `regfile`
  nunca recibiría su escritura.
- Las burbujas se insertan **antes**, limpiando `ID/EX` (`RegWrite=0`, `MemWrite=0`, `Branch=0`,
  `Jump=0`). Una burbuja atraviesa EX/MEM y MEM/WB con `RegWrite=0`, por lo que no altera
  ningún registro.
- El `flush` de branch ocurre en EX y limpia IF/ID e ID/EX; nunca es necesario limpiar MEM/WB.

Esto coincide con `contrato.md`: MEM/WB solo tiene `clk` y `reset`.

---

## 4. Integración en `datapath_pipeline.v`

### 4.1 Instanciación

```verilog
memwb reg_memwb (
    .clk               (clk),
    .reset             (reset),
    .ReadData          (ReadData),          // de dmem
    .ALUResult         (EX_MEM_ALUResult),
    .PC4               (EX_MEM_PC4),
    .rd                (EX_MEM_rd),
    .RegWrite          (EX_MEM_RegWrite),
    .ResultSrc         (EX_MEM_ResultSrc),
    .MEM_WB_ReadData   (MEM_WB_ReadData),
    .MEM_WB_ALUResult  (MEM_WB_ALUResult),
    .MEM_WB_PC4        (MEM_WB_PC4),
    .MEM_WB_rd         (MEM_WB_rd),
    .MEM_WB_RegWrite   (MEM_WB_RegWrite),
    .MEM_WB_ResultSrc  (MEM_WB_ResultSrc)
);
```

### 4.2 Etapa MEM (sin cambios de responsabilidad)

La memoria sigue gobernada por `EX_MEM_*`, que es lo correcto: `sw`, `lw` y las direcciones
pertenecen a la etapa MEM.

```verilog
assign DataAdr   = EX_MEM_ALUResult;
assign MemWrite  = EX_MEM_MemWrite;
assign WriteData = EX_MEM_WriteData;
```

### 4.3 Writeback real

```verilog
assign wb_Result = (MEM_WB_ResultSrc == 2'b01) ? MEM_WB_ReadData :
                   (MEM_WB_ResultSrc == 2'b10) ? MEM_WB_PC4 :
                                                 MEM_WB_ALUResult;
```

Y el `regfile` ahora se escribe con las señales de MEM/WB:

```verilog
regfile rf (
    .clk (clk),
    .we3 (MEM_WB_RegWrite),
    .a1  (IF_ID_Instr[19:15]),
    .a2  (IF_ID_Instr[24:20]),
    .a3  (MEM_WB_rd),
    .wd3 (wb_Result),
    .rd1 (id_SrcA),
    .rd2 (id_WriteData)
);
```

### 4.4 Verdad del mux de writeback

| `MEM_WB_ResultSrc` | Resultado escrito en `regfile` | Instrucción típica |
|--------------------|--------------------------------|--------------------|
| `00` | `MEM_WB_ALUResult` | `add`, `addi`, `and`, `or`, `slt`, direcciones |
| `01` | `MEM_WB_ReadData` | `lw` |
| `10` | `MEM_WB_PC4` | `jal` / `jalr` (link) |

El valor `11` no se usa; el `mux3` lo resuelve como `d2` por el bit alto, pero `maindec`
no lo genera.

### 4.5 Observabilidad en el wrapper

`riscvpipeline.v` expone ahora:

```verilog
.MEM_WB_ReadData  (),
.MEM_WB_ALUResult (),
.MEM_WB_PC4       (),
.MEM_WB_rd        (),
.MEM_WB_RegWrite  (),
.MEM_WB_ResultSrc ()
```

Estas salidas permiten inspeccionar la etapa WB desde un testbench sin cambiar la interfaz
de `top_pipeline`.

---

## 5. Consecuencia temporal: dependencias y NOPs

Al añadir la quinta etapa, la escritura del `regfile` ocurre **un ciclo más tarde** que en la
Fase 3. Sin forwarding (Fase 6), una instrucción que consume un registro debe estar al menos
**4 instrucciones después** del productor (3 NOPs de separación). Antes de la Fase 4 bastaban
3 instrucciones (2 NOPs).

Ejemplo:

```asm
addi x1, x0, 5
nop
nop
nop
add  x3, x1, x2   # x1 ya está escrito en WB
```

Esta separación **no es un defecto**: es la consecuencia normal de tener writeback real en la
5ª etapa. La Fase 6 (forwarding y load-use) elimina la restricción.

---

## 6. Verificación

Herramientas: **Icarus Verilog** (`iverilog` + `vvp`).

### 6.1 Testbench unitario MEM/WB

```bash
iverilog -o sim_memwb \
  "src files/memwb.v" "src files/mux3.v" "src files/regfile.v" \
  testbench/testbench_memwb.v
vvp sim_memwb
```

Resultado:

```text
PASS reset ReadData
PASS reset ALUResult
PASS reset PC4
PASS reset rd
PASS reset RegWrite
PASS reset ResultSrc
PASS captura ReadData (lw)
PASS captura ALUResult (lw)
PASS captura PC4 (lw)
PASS captura rd (lw)
PASS captura RegWrite (lw)
PASS captura ResultSrc (lw)
PASS mux WB selecciona ReadData
PASS regfile x5 = ReadData (lw)
PASS captura ALUResult
PASS mux WB selecciona ALU
PASS regfile x6 = ALUResult
PASS captura PC4 (jal)
PASS captura ResultSrc (jal)
PASS mux WB selecciona PC4
PASS regfile x7 = PC4 (jal)
PASS regfile x8 escrito una vez
PASS burbuja: RegWrite=0
PASS burbuja: wb_Result existe pero we3=0
PASS regfile x8 no cambia con RegWrite=0
PASS reset final ReadData
PASS reset final ALUResult
PASS reset final RegWrite
TESTBENCH MEM/WB: PASS
```

Qué cubre:

- Reset asíncrono de las seis salidas.
- Captura de `ReadData`, `ALUResult`, `PC4`, `rd`, `RegWrite` y `ResultSrc`.
- Selección correcta del mux para `lw` (`01`), ALU (`00`) y `jal` (`10`).
- Escritura efectiva en `regfile` (`x5`, `x6`, `x7`).
- Una burbuja con `RegWrite=0` **no** modifica el registro (`x8` conserva su valor).

### 6.2 Regresión de las fases anteriores

| Prueba | Resultado |
|--------|-----------|
| IF/ID (`testbench_ifid.v`) | **TESTBENCH IF/ID: PASS** |
| ID/EX (`tb_index.v`) | **TESTBENCH ID/EX: PASS** |
| EX/MEM (`testbench_exmem.v`) | **TESTBENCH EX/MEM: PASS** |
| Single-cycle de referencia (`testbench.v` + `top`) | **Simulation succeeded** |

### 6.3 Integración del pipeline (programas sin hazards)

Se ejecutaron dos programas sin dependencias cercanas, re-espaciados para la nueva etapa WB.

**Programa A — ALU + branch tomado + flush:**

```asm
addi x1, x0, 5
nop
nop
nop
addi x2, x0, 10
nop
nop
nop
add  x3, x1, x2      # x3 = 15
nop
nop
nop
sw   x3, 0(x0)       # mem[0] = 15
nop
nop
beq  x1, x1, +12     # tomado: salta addi x4 y sw x4
addi x4, x0, 99      # no debe ejecutarse
sw   x4, 8(x0)       # no debe ejecutarse
addi x5, x0, 42
nop
nop
nop
sw   x5, 4(x0)       # mem[4] = 42
nop
nop
jal  x0, 0
```

Resultado:

```text
STORE addr=0 data=15 cycle=17
STORE addr=4 data=42 cycle=27
PIPELINE PASS
```

**Programa B — `lw`, `sw` y `jal`:**

```asm
addi x1, x0, 5
nop
nop
nop
sw   x1, 0(x0)       # mem[0] = 5
nop
nop
nop
lw   x2, 0(x0)       # x2 = 5
nop
nop
nop
sw   x2, 4(x0)       # mem[4] = 5
nop
nop
nop
jal  x3, +12         # x3 = PC+4 = 68
addi x4, x0, 99      # no debe ejecutarse
nop                  # no debe ejecutarse
nop                  # destino del jal
nop
nop
nop
sw   x3, 8(x0)       # mem[8] = 68
nop
nop
jal  x0, 0
```

Resultado:

```text
STORE addr=0 data=5 cycle=9
STORE addr=4 data=5 cycle=17
STORE addr=8 data=68 cycle=28
PIPELINE LOAD/JAL PASS
```

Esto confirma que:

- `lw` escribe el dato leído en el `regfile` a través de MEM/WB.
- `sw` usa `EX_MEM_ALUResult` como dirección y `EX_MEM_WriteData` como dato.
- `jal` escribe `PC+4` en `rd` mediante `MEM_WB_PC4` (`ResultSrc=10`).
- El flush de branch sigue descartando las instrucciones jóvenes.
- El `regfile` ya no se escribe desde EX/MEM.

### 6.4 `riscvtest.dat` estándar

El programa estándar **todavía no pasa** en el pipeline:

- Contiene dependencias RAW y un caso load-use (`lw` seguido de `add`).
- Sin forwarding ni detección de load-use, el pipeline lee valores viejos y no alcanza
  `mem[100] = 25` (`Simulation succeeded`).
- El single-cycle de referencia sí pasa, porque no tiene etapas.

Esto es **esperado** y corresponde a la Fase 6, no a un fallo de la Fase 4.

---

## 7. Diagrama Draw.io

Archivo: `doc/diagrama_datapath_single_issue.drawio`

Contenido:

- Las cinco etapas y los cuatro registros de pipeline, incluido **MEM/WB**.
- La ruta de datos completa: PC → imem → IF/ID → ID → ID/EX → EX → EX/MEM → MEM → MEM/WB → WB.
- El lazo de realimentación `PCNext` desde el mux de PC.
- El flush de branch en naranja (`flush_IF_ID`, `flush_ID_EX`) — implementado en Fase 3.
- En rojo punteado, los bloques pendientes de Fase 6:
  - **Hazard Unit** (load-use + `stall_IF_ID` / `stall_ID_EX`).
  - **Forwarding Unit** (EX/MEM → EX y MEM/WB → EX).
- Leyenda de colores.

Para abrirlo: [app.diagrams.net](https://app.diagrams.net) → *File → Open* → seleccionar el
`.drawio`, o usar la extensión Draw.io de VS Code.

---

## 8. Lo que queda para la Fase 6

| Elemento | Estado |
|----------|--------|
| Registro MEM/WB | ✅ Fase 4 |
| Writeback desde `MEM_WB_*` | ✅ Fase 4 |
| Forwarding EX/MEM → EX | ❌ Fase 6 |
| Forwarding MEM/WB → EX | ❌ Fase 6 |
| Detección de load-use | ❌ Fase 6 |
| `stall_IF_ID` / `stall_ID_EX` reales | ❌ Hoy a `1'b0` |
| Flush de branch/jal | ✅ Fase 3 |
| `riscvtest.dat` en pipeline | ❌ Requiere Fase 6 |

Cuando se implemente el forwarding, el multiplexor de la ALU tendrá tres fuentes por operando
(`ID_EX`, `EX_MEM`, `MEM_WB`) y la unidad de hazards generará los stalls de load-use.

---

## 9. Checklist de la Fase 4

- [x] `src files/memwb.v` creado con reset asíncrono.
- [x] `datapath_pipeline.v` instancia MEM/WB.
- [x] Writeback movido de `EX_MEM_*` a `MEM_WB_*`.
- [x] `regfile.we3` y `regfile.a3` usan `MEM_WB_RegWrite` y `MEM_WB_rd`.
- [x] `resultmux` usa `MEM_WB_ResultSrc`, `MEM_WB_ALUResult`, `MEM_WB_ReadData`, `MEM_WB_PC4`.
- [x] `riscvpipeline.v` expone las nuevas salidas.
- [x] Testbench unitario MEM/WB: **PASS**.
- [x] IF/ID, ID/EX y EX/MEM siguen pasando.
- [x] Single-cycle de referencia sigue pasando.
- [x] Pipeline sin hazards pasa con branch, `lw`, `sw` y `jal`.
- [x] Diagrama Draw.io generado.
- [x] `FASES_DESARROLLO.md` y `contrato.md` actualizados.
- [ ] `riscvtest.dat` completo (pendiente de Fase 6: forwarding + load-use).
