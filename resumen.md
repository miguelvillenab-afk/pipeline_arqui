Listo. Verifiqué y corregí las fases 0, 1 y 2, e implementé la fase 3 completa con simulaciones reales usando Icarus Verilog.

## Resumen de lo hecho

| Fase | Estado | Resultado |
|---|---|---|
| 0 — Contrato | ✅ Corregida | `contrato.md` actualizado |
| 1 — Fetch + IF/ID | ✅ Corregida y verificada | **TESTBENCH IF/ID: PASS** |
| 2 — Decode + ID/EX | ✅ Corregida y verificada | **TESTBENCH ID/EX: PASS** |
| 3 — Execute + EX/MEM | ✅ Implementada y verificada | **TESTBENCH EX/MEM: PASS** |
| 4 — MEM/WB | ⏳ Pendiente | Writeback provisional desde EX/MEM |
| 5 — Integración | ⏳ Pendiente | Falta MEM/WB y test con `riscvtest.dat` |
| 6 — Hazards | ⏳ Pendiente | Falta forwarding y load-use |

---

## Fase 0 — Contrato corregido

Actualicé `contrato.md` con lo que faltaba y con las reglas que el código anterior no respetaba:

- Se añadió **`ID_EX_PC`** al registro ID/EX. Era necesario porque el target de branch/jal debe calcularse como `ID_EX_PC + ID_EX_ImmExt`, no mezclando `IF_ID_PC` con `ex_ImmExt` como hacía el código anterior.
- Se documentó la prioridad: **`reset` > `flush` > `stall` > captura**.
- Se aclaró que el flush de IF/ID inserta un **NOP** (`addi x0, x0, 0`), no `32'h0`.
- Se documentó que **`PCSrc` se calcula en EX**, no en Decode.
- Se dejó claro que `EX_MEM_Zero` se pipelinea, pero la decisión actual del branch se toma en EX.
- Se documentó el writeback provisional de la Fase 3.

---

## Fase 1 — Fetch + IF/ID corregida

Archivo: `src files/ifid.v`

Correcciones:

- El reset y el flush ahora cargan un **NOP real**, no `0`. Antes, `32'h0` caía en el `default` de `maindec` y propagaba `x` por las señales de control.
- Se mantiene la prioridad `flush > stall`.
- Se conservan las salidas `IF_ID_Instr`, `IF_ID_PC` e `IF_ID_PC4`.

Testbench: `testbench/testbench_ifid.v`

Ahora es autocontenido y verifica:

- Reset → NOP / PC=0 / PC4=0.
- Captura normal.
- Stall mantiene el valor.
- Flush inserta NOP.
- Flush tiene prioridad sobre stall.

Resultado: **TESTBENCH IF/ID: PASS**.

---

## Fase 2 — Decode + ID/EX corregida

### `src files/idex.v`

Problemas corregidos:

- Antes usaba `flopr`, que no tiene enable ni clear: `stall_ID_EX` y `flush_ID_EX` eran señales muertas.
- Ahora usa `flopenrc`, un flip-flop con reset asíncrono, enable y clear síncronos.
- Se añadió `IF_ID_PC` / `ID_EX_PC`.
- Se mantienen todas las señales del contrato: operandos, `rs1`, `rs2`, `rd`, `PC4` y todos los controles.
- El ancho del registro quedó en **187 bits** (5×32 + 3×5 + 12).

Nuevo módulo: `src files/flopenrc.v`.

### Control en Decode

El control ya **no** se genera con la instrucción que sale de `imem`. En `src files/datapath_pipeline.v` se instancian `maindec` y `aludec` alimentados por `IF_ID_Instr`, que es la instrucción que realmente está en Decode.

Esto corrige el error de desfase de una etapa que tenía el diseño anterior.

### `src files/datapath.v` restaurado

Restauré `datapath.v` exactamente a su versión single-cycle original (`2e18873`). Así:

- `riscvsingle.v` y `top.v` vuelven a funcionar como referencia single-cycle.
- El pipeline vive en `datapath_pipeline.v`, respetando la regla de seguridad de no modificar el original.

Verificado: **Simulation succeeded** con `testbench/testbench.v`.

### Testbench ID/EX

`testbench/tb_index.v` fue reescrito y ahora verifica:

- Reset.
- Captura de `SrcA`, `WriteData`, `ImmExt`, `PC`, `PC4`, `rs1`, `rs2`, `rd`.
- Captura de todos los controles.
- Stall mantiene el valor.
- Flush limpia a burbuja.
- Flush gana sobre stall.

Resultado: **TESTBENCH ID/EX: PASS**.

---

## Fase 3 — Execute + EX/MEM implementada

### Nuevo: `src files/exmem.v`

Registro EX/MEM con las señales del contrato:

- `EX_MEM_ALUResult`
- `EX_MEM_Zero`
- `EX_MEM_WriteData`
- `EX_MEM_rd`
- `EX_MEM_PC4`
- `EX_MEM_PCTarget`
- `EX_MEM_MemWrite`
- `EX_MEM_RegWrite`
- `EX_MEM_ResultSrc`
- `EX_MEM_Branch`
- `EX_MEM_Jump`

Tiene reset asíncrono y no tiene stall/flush, porque la instrucción que está en EX debe continuar a MEM.

### `src files/datapath_pipeline.v`

Implementa la cadena:

```
IF → IF/ID → ID → ID/EX → EX → EX/MEM → MEM → WB
```

Incluye:

- ALU conectada a `ID_EX_SrcA` y al mux `ALUSrc`.
- Sumador de branch/jal correcto: `ID_EX_PC + ID_EX_ImmExt`.
- `PCSrc` calculado en EX:

```verilog
PCSrc = (ID_EX_Branch & Zero) | ID_EX_Jump;
```

- Flush de las dos instrucciones jóvenes cuando el branch/jal es tomado:
  - `flush_IF_ID = PCSrc`
  - `flush_ID_EX = PCSrc`
- `dmem` direccionada con `EX_MEM_ALUResult`, escrita con `EX_MEM_MemWrite` y `EX_MEM_WriteData`.
- Writeback provisional desde EX/MEM hasta que se implemente MEM/WB en la Fase 4.

### Nuevos tops

- `src files/riscvpipeline.v`: wrapper del procesador pipelineado, misma interfaz que `riscvsingle`.
- `src files/top_pipeline.v`: top con `imem` + `dmem`, misma interfaz que `top`.

Así no se rompe el single-cycle y se puede simular el pipeline por separado.

### Testbench EX/MEM

`testbench/testbench_exmem.v` verifica:

- Reset.
- ALU add: `10 + 5 = 15`, `Zero = 0`.
- ALU sub: `7 - 7 = 0`, `Zero = 1`.
- Captura de `WriteData`, `rd`, `PC4`, `PCTarget` y controles.
- `PCTarget = PC + ImmExt`.
- Caso `jal`.

Resultado: **TESTBENCH EX/MEM: PASS**.

### Verificación extra del pipeline

También simulé `top_pipeline` con dos programas sin hazards:

1. ALU + branch tomado + flush + store → **PIPELINE PASS**.
2. `lw` + `sw` + `jal` + escritura de PC+4 → **PIPELINE LOAD/JAL PASS**.

Esto confirma que la cadena IF/ID/EX/EX-MEM/MEM y el control de branch/jal funcionan.

---

## Verificación final

| Prueba | Resultado |
|---|---|
| Testbench IF/ID | **PASS** |
| Testbench ID/EX | **PASS** |
| Testbench EX/MEM | **PASS** |
| Single-cycle de referencia (`top`) | **Simulation succeeded** |
| Pipeline con branch tomado | **PASS** |
| Pipeline con `lw`/`sw`/`jal` | **PASS** |
| Pipeline con `riscvtest.dat` estándar | ⏳ Pendiente Fase 6 |

El `riscvtest.dat` estándar todavía **no pasa** en el pipeline porque contiene hazards RAW y un load-use inmediato. Eso corresponde a la Fase 6 (forwarding + detección de load-use). No es un fallo de la Fase 3.

---

## Archivos modificados

- `contrato.md`
- `FASES_DESARROLLO.md`
- `src files/datapath.v` — restaurado al single-cycle original
- `src files/flopr.v` — corregido a `output reg` para compatibilidad con simuladores
- `src files/ifid.v`
- `src files/idex.v`
- `testbench/testbench_ifid.v`
- `testbench/tb_index.v` — ahora testbench autocontenido de ID/EX

## Archivos nuevos

- `src files/flopenrc.v`
- `src files/exmem.v`
- `src files/datapath_pipeline.v`
- `src files/riscvpipeline.v`
- `src files/top_pipeline.v`
- `testbench/testbench_exmem.v`

No hice commit; los cambios están en el árbol de trabajo de la rama `IDEX`.

---

## Cómo reproducir las pruebas

```bash
# IF/ID
iverilog -g2012 -o sim_ifid "src files/ifid.v" testbench/testbench_ifid.v
vvp sim_ifid

# ID/EX
iverilog -g2012 -o sim_idex "src files/idex.v" "src files/flopenrc.v" testbench/tb_index.v
vvp sim_idex

# EX/MEM
iverilog -g2012 -o sim_exmem "src files/exmem.v" "src files/alu.v" "src files/mux2.v" "src files/adder.v" testbench/testbench_exmem.v
vvp sim_exmem

# Single-cycle de referencia
iverilog -g2012 -o sim_sc "src files"/*.v testbench/testbench.v
cd data && vvp ../sim_sc
```

---

## Siguiente paso

La Fase 4 consiste en:

1. Crear `src files/memwb.v`.
2. Mover el writeback de `EX_MEM_*` a `MEM_WB_*`.
3. Conectar `dmem.ReadData` a `MEM_WB_ReadData`.
4. Dejar el pipeline listo para la integración de Fase 5.

Después de eso, la Fase 6 (forwarding + load-use) es la que hará pasar el `riscvtest.dat` estándar.

¿Sigo con la Fase 4?