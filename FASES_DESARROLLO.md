# Plan de Desarrollo por Fases — Etapa 1 (Pipeline 5 etapas)

Este plan permite que 4 integrantes avancen de forma encadenada y segura: cada integrante termina su módulo antes de que el siguiente lo integre, minimizando riesgos de incompatibilidad.

---

## Fase 0 — Contrato de interfaz (Todos juntos, 1 sesión)

**Objetivo:** Acordar los nombres exactos de señales antes de escribir una sola línea de código.

**Acciones:**
1. Revisar el archivo `contrato.md` (ya creado).
2. Cada integrante confirma que entiende las señales de entrada y salida de su registro.
3. Firmar el contrato: nadie cambia un nombre sin avisar al grupo y actualizar `contrato.md`.
4. Decidir nombres de archivos (ejemplo: `if_stage.v`, `id_stage.v`, `ex_stage.v`, `mem_wb_stage.v`, o bloques dentro de `datapath.v`).

**Entrega de la fase:** `contrato.md` acordado por los 4.

---

## Fase 1 — Integrante 1: Fetch + Registro IF/ID

**Objetivo:** Construir la entrada del pipeline.

**Tareas:**
1. Copiar `datapath.v` a `datapath_pipeline.v` (no tocar el original hasta que funcione).
2. Implementar el registro IF/ID usando `flopr.v` como plantilla.
3. Conectar `imem`, `pcreg` (PC) y `pcadd4` (PCPlus4).
4. Exponer salidas: `IF_ID_Instr`, `IF_ID_PC`, `IF_ID_PC4`.
5. Crear un testbench sencillo que verifique que `IF_ID_Instr` se actualice cada ciclo con lo que lee `imem`.

**Condición de salida:** El integrante 1 entrega al equipo el archivo con las salidas `IF_ID_*` funcionando y simuladas.

---

## Fase 2 — Integrante 2: Decode + Registro ID/EX

**Objetivo:** Decodificar instrucciones y preparar operandos para EX.

**Pre-requisito:** Recibir las salidas `IF_ID_*` del Integrante 1.

**Tareas:**
1. Usar `IF_ID_Instr`, `IF_ID_PC`, `IF_ID_PC4` como entradas.
2. Conectar `regfile` (2 lecturas), `extend` y `controller` (`maindec` + `aludec`).
3. Implementar el registro ID/EX con las señales del contrato.
4. Exponer salidas: `ID_EX_SrcA`, `ID_EX_WriteData`, `ID_EX_ImmExt`, `ID_EX_PC4`, `ID_EX_rs1`, `ID_EX_rs2`, `ID_EX_rd`, y todas las señales de control.
5. Testbench sencillo: verificar que `ID_EX_SrcA` y `ID_EX_WriteData` reflejen los valores leídos de `regfile` desde `IF_ID_Instr`.

**Condición de salida:** El integrante 2 entrega al equipo el archivo con las salidas `ID_EX_*` funcionando y simuladas.

---

## Fase 3 — Integrante 3: Execute + Registro EX/MEM

**Objetivo:** Ejecutar operaciones ALU y calcular direcciones de salto.

**Pre-requisito:** Recibir las salidas `ID_EX_*` del Integrante 2.

**Tareas:**
1. Usar salidas `ID_EX_*` como entradas.
2. Conectar ALU, muxes de operandos (`ALUSrc`), sumador de branch (`pcaddbranch`).
3. Implementar el registro EX/MEM con las señales del contrato.
4. Exponer salidas: `EX_MEM_ALUResult`, `EX_MEM_Zero`, `EX_MEM_WriteData`, `EX_MEM_rd`, `EX_MEM_PC4`, `EX_MEM_PCTarget`, y señales de control de MEM/WB.
5. Testbench sencillo: verificar que `EX_MEM_ALUResult` sea correcto para una instrucción ALU y que `EX_MEM_Zero` refleje el resultado de la ALU.

**Condición de salida:** El integrante 3 entrega al equipo el archivo con las salidas `EX_MEM_*` funcionando y simuladas.

---

## Fase 4 — Integrante 4: Memory + Writeback + Registro MEM/WB

**Objetivo:** Acceder a memoria de datos y escribir resultado en el register file.

**Pre-requisito:** Recibir las salidas `EX_MEM_*` del Integrante 3.

**Tareas:**
1. Usar salidas `EX_MEM_*` como entradas.
2. Conectar `dmem` (lectura y escritura).
3. Implementar el registro MEM/WB con las señales del contrato.
4. Conectar `resultmux` (mux3) y escribir al `regfile` (`wd3`, `a3`, `we3`).
5. Testbench sencillo: verificar que `MEM_WB_rd` reciba el registro destino correcto y que `we3` se active solo cuando `MEM_WB_RegWrite = 1`.

**Condición de salida:** El integrante 4 entrega al equipo el archivo con las salidas a `regfile` funcionando y simuladas.

---

## Fase 5 — Integración completa (Todos)

**Objetivo:** Conectar las 4 etapas en cadena y verificar con el testbench original.

**Tareas:**
1. Conectar en `datapath.v` (o `riscvsingle.v`) la cadena:
   ```
   IF → IF/ID → ID → ID/EX → EX → EX/MEM → MEM → MEM/WB → WB
   ```
2. Instanciar `imem` y `dmem` en `top.v` (o mantener la estructura actual).
3. Usar el `testbench.v` existente y ejecutar `riscvtest.dat`.
4. Verificar que el procesador pipelineado produzca los mismos resultados que el single-cycle original.

**Condición de salida:** El pipeline de 5 etapas funciona correctamente con forwarding básico (sin stalls complejos todavía).

---

## Fase 6 — Forwarding, stalls y flushing (Todos)

**Objetivo:** Agregar detección de hazards y control de flujo.

**Tareas:**
1. Implementar forwarding entre EX/MEM y MEM/WB hacia las entradas de EX.
2. Detectar dependencias RAW (especialmente `lw` seguido de instrucción que usa el resultado).
3. Agregar señales `stall_IF_ID`, `stall_ID_EX`, `flush_IF_ID`, `flush_ID_EX`.
4. Manejar branches tomados: hacer flush de las instrucciones más jóvenes en el par.
5. Volver a ejecutar el testbench y los programas de prueba.

**Condición de salida:** Pipeline funcional con hazards resueltos.

---

## Reglas de seguridad para no romper nada

| Regla | Descripción |
|-------|-------------|
| 1 | Nunca borren `riscvsingle.v` ni `datapath.v` originales. Trabajen sobre copias. |
| 2 | Un solo integrante modifica un archivo a la vez. Si usan Git, usen branches separados. |
| 3 | Cada registro debe tener `clk` y `reset`. Sin reset, la simulación empieza con valores `x`. |
| 4 | Primero hagan que el pipeline funcione sin stalls. Luego agreguen hazard detection. |
| 5 | Cada integrante debe verificar su módulo con un testbench individual antes de integrar. |
| 6 | Si hay conflicto de nombres de señales, se arregla en `contrato.md` y se avisa al grupo. |

---

## Orden de ejecución recomendado

```
Fase 0 (todos) → Fase 1 (Int. 1) → Fase 2 (Int. 2) → Fase 3 (Int. 3) → Fase 4 (Int. 4) → Fase 5 (todos) → Fase 6 (todos)
```

Cada fase debe tener una "entrega" clara antes de que la siguiente comience.
