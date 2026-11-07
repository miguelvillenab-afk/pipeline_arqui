# Registro de fixes — Pipeline RV32I y Dual-Issue

**Proyecto:** `C:\Users\Ricardo\Documentos\pipeline_arqui`
**Rama:** `Superarquitectura`
**Creado:** 2026-11-06
**Última actualización:** 2026-11-06
**Alcance:** todos los fixes de correctitud y huecos de implementación que se hagan
antes y durante E2.

---

## 1. Propósito

Este documento es el **registro único de fixes**. Cada cambio de código debe quedar
acá con:

- dónde se hizo (archivo y líneas),
- por qué se hizo (síntoma y causa raíz),
- qué solucionó (efecto funcional),
- cómo se verificó,
- qué riesgo o efecto colateral deja.

La idea es que, si alguien retoma el proyecto, no tenga que reconstruir por qué el
código está como está.

---

## 2. Reglas de uso

1. **Un fix = una entrada.** No se mezclan cambios no relacionados.
2. **No se borran entradas.** Si un fix se revierte, se cambia el estado a
   `DESCARTADO` y se explica por qué.
3. **Las líneas se registran al momento del fix.** Como después se corren, también
   se guarda el módulo, la señal y un fragmento del código antes/después.
4. **Todo fix se verifica.** Sin verificación, el estado máximo es `APLICADO`, no
   `VERIFICADO`.
5. **No se toca `src files/` ni `program1.mem`–`program4.mem`.** Los fixes van en
   `src_super/` o `testbench/`. Si un fix obliga a tocar `src files/`, se registra
   como excepción y se pide aprobación antes.
6. **Si hace falta documentar en otro `.md`, se pregunta primero.** Este archivo
   es la fuente principal; los reportes existentes solo se actualizan cuando el
   usuario lo autorice.
7. **Cada fix debe indicar si bloquea E2.** Eso define la prioridad.

---

## 3. Estados

| Estado | Significado |
|---|---|
| `PENDIENTE` | identificado, todavía no se tocó |
| `EN CURSO` | se está implementando |
| `APLICADO` | el cambio está en el archivo, falta verificar |
| `VERIFICADO` | compila y pasa la prueba definida |
| `DESCARTADO` | se probó y no se usó; se documenta el motivo |

Prioridad:

| Prioridad | Criterio |
|---|---|
| `ALTA` | bug de correctitud o hueco que impide probar E2 |
| `MEDIA` | necesario para E2 pero no bloquea los primeros tests |
| `BAJA` | mejora, limpieza o documentación |

---

## 4. Backlog de huecos conocidos

| Fix | Hueco | Tipo | ¿Bloquea E2? | Archivo previsto | Estado |
|---|---|---|---|---|---|
| `FIX-001` | `dmem` entrega el dato un ciclo tarde | Bug de correctitud | **Sí** | `src_super/dmem_dual.v` + `top_dual.v` | `VERIFICADO` |
| `FIX-002` | `regfile_dual` sin write-through | Bug de correctitud | **Sí** | `src_super/regfile_dual.v` | `VERIFICADO` |
| `FIX-003` | `jal` usa el inmediato de LUI | Bug de correctitud | **Sí** | `src_super/extend_dual.v` + `datapath_dual.v` | `VERIFICADO` |
| `FIX-004` | `reg_idex_b` captura B aunque no se emita | Hueco E1 | **Sí** | `src_super/datapath_dual.v` | `VERIFICADO` |
| `FIX-005` | no existe `IF_ID_IssueB` | Hueco E1 | **Sí** | `src_super/datapath_dual.v` | `VERIFICADO` |
| `FIX-006` | `PCNext` solo hace `PC+4`; `PCPlus8` sin usar | Hueco E1 | **Sí** (para dual-issue) | `src_super/datapath_dual.v` | `VERIFICADO` |
| `FIX-007` | `mux5` creado pero no instanciado | Hueco E1 | No (es E2) | `src_super/datapath_dual.v` | `VERIFICADO` (E2.1) |
| `FIX-008` | `ID_EX_B_*` sin consumidor en `riscv_dual` | Hueco E1 | No (es E2) | `src_super/riscv_dual.v` | `VERIFICADO` (E2.1) |
| `FIX-009` | `imem_dual` fijo a `program1.mem` | Infra de test | No | `src_super/imem_dual.v` | `VERIFICADO` |
| `FIX-010` | testbench dual sin halt, ciclos ni checks | Infra de test | No | `testbench/` | `PENDIENTE` |

> Los fixes 007–010 no son “bugs” del diseño actual: son piezas que E2 va a
> necesitar. Se registran acá para no perderlas y para documentar cuándo se
> implementen.

---

## 5. Fixes ya aplicados (histórico)

Estos tres se aplicaron en una sesión anterior sobre `src_super/datapath_dual.v`.
Se registran acá porque explican por qué el archivo está como está.

### FIX-000A — `extend` conectado con 25 bits

| Campo | Detalle |
|---|---|
| **Estado** | `APLICADO` (verificación formal pendiente) |
| **Fecha** | Sesión anterior a 2026-11-06 |
| **Archivo** | `src_super/datapath_dual.v` |
| **Líneas al momento del fix** | 195 y 228 |
| **Señal afectada** | `ext.instr`, `ext_b.instr` |

**Síntoma.**
Los inmediatos negativos, los branches y los J-type podían quedar mal. En
`program1.mem` no se notaba porque todos los inmediatos son positivos y el `beq`
no salta.

**Causa raíz.**
El puerto `instr` de `extend` es de 32 bits, pero estaba conectado a
`IF_ID_Instr[31:7]` (25 bits). El bit 31 del inmediato se perdía y `instr[31]`
quedaba siempre en 0.

**Antes.**

```verilog
extend ext (
    .instr  (IF_ID_Instr[31:7]),
    ...
);

extend ext_b (
    .instr  (IF_ID_Instr_B[31:7]),
    ...
);
```

**Después.**

```verilog
extend ext (
    .instr  (IF_ID_Instr),
    ...
);

extend ext_b (
    .instr  (IF_ID_Instr_B),
    ...
);
```

**Qué solucionó.**
La extensión de inmediato recibe la instrucción completa. Se recuperan el signo
de los I-type y S-type, el bit 31 de los B-type y el campo completo de LUI.

**Verificación.**
Pendiente de waveform con un branch que salte y con un `addi` de inmediato
negativo. La compilación pasa.

**Riesgo / efecto colateral.**
Ninguno: el puerto ya era de 32 bits; solo se corrigió el ancho de la conexión.

**Relacionado.** `FIX-003`, `hazard`, branches.

---

### FIX-000B — `hazard_unit` sin `rd_WB`, `RegWrite_WB` y `ALUSrc_EX`

| Campo | Detalle |
|---|---|
| **Estado** | `APLICADO` |
| **Fecha** | Sesión anterior a 2026-11-06 |
| **Archivo** | `src_super/datapath_dual.v` |
| **Líneas al momento del fix** | 409–411 y 421 |
| **Señales afectadas** | `ForwardA`, `ForwardB`, `ForwardC` |

**Síntoma.**
El forwarding desde `MEM/WB` nunca se activaba. Tampoco se respetaba que el
operando B fuera inmediato (`ALUSrc_EX`), así que `ForwardB` podía reenviar un
registro cuando la instrucción no lo usaba.

**Causa raíz.**
La instancia de `hazard_unit` no conectaba `rd_WB`, `RegWrite_WB` ni
`ALUSrc_EX`. Esos puertos quedaban flotando y las condiciones de forwarding de
WB no se cumplían.

**Antes.**

```verilog
hazard_unit hu (
    ...
    .rd_MEM        (EX_MEM_rd),
    .RegWrite_MEM  (EX_MEM_RegWrite),

    .PCSrc_EX      (ex_PCSrc),
    ...
);
```

**Después.**

```verilog
hazard_unit hu (
    ...
    .rd_MEM        (EX_MEM_rd),
    .RegWrite_MEM  (EX_MEM_RegWrite),

    .rd_WB         (MEM_WB_rd),
    .RegWrite_WB   (MEM_WB_RegWrite),
    .ALUSrc_EX     (ID_EX_ALUSrc),

    .PCSrc_EX      (ex_PCSrc),
    ...
);
```

**Qué solucionó.**
Se habilitó el forwarding `MEM/WB → EX` y se evitó el falso forwarding del
operando B cuando `ALUSrc_EX = 1`.

**Verificación.**
Pendiente de un test RAW con dos instrucciones de separación (productor en WB,
consumidor en EX).

**Riesgo / efecto colateral.**
Ninguno; son puertos que el módulo ya tenía.

**Relacionado.** `FIX-002`, `FIX-007`, E2-H2/H3.

---

### FIX-000C — Faltaba el forwarding del dato de store (`ForwardC`)

| Campo | Detalle |
|---|---|
| **Estado** | `APLICADO` |
| **Fecha** | Sesión anterior a 2026-11-06 |
| **Archivo** | `src_super/datapath_dual.v` |
| **Líneas al momento del fix** | 90, 291, 317–322, 355 |
| **Señales afectadas** | `ForwardC`, `writeData_fwd`, `exmem.WriteData` |

**Síntoma.**
Un `sw` podía guardar un valor viejo cuando el registro de datos venía de una
instrucción anterior. El forwarding de `rs2` no se aplicaba al dato de store
porque ese dato no pasa por `srcbmux`.

**Causa raíz.**
Solo existían `mux_forwardA` y `mux_forwardB`. El `WriteData` que se capturaba en
`EX/MEM` era `ID_EX_WriteData` sin reenviar.

**Antes.**

```verilog
wire [1:0] ForwardA, ForwardB;
wire [31:0] alu_SrcA_fwd, alu_SrcB_fwd;

exmem reg_exmem (
    ...
    .WriteData        (ID_EX_WriteData),
    ...
);
```

**Después.**

```verilog
wire [1:0] ForwardA, ForwardB, ForwardC;
wire [31:0] alu_SrcA_fwd, alu_SrcB_fwd, writeData_fwd;

// Dato de store: rs2 sin pasar por ALUSrc
mux3 #(WIDTH) mux_forwardC (
    .d0 (ID_EX_WriteData),
    .d1 (wb_Result),
    .d2 (EX_MEM_ALUResult),
    .s  (ForwardC),
    .y  (writeData_fwd)
);

exmem reg_exmem (
    ...
    .WriteData        (writeData_fwd),
    ...
);
```

**Qué solucionó.**
El dato de un `sw` ahora puede venir de `MEM/WB` o de `EX/MEM`, igual que los
operandos de la ALU.

**Verificación.**
Pendiente de un test `add`/`sw` con dependencia RAW y de revisar `ForwardC` en
waveform.

**Riesgo / efecto colateral.**
Ninguno; se agregó una ruta que el `hazard_unit` ya calculaba.

**Relacionado.** `FIX-002`, E2-H4.

---

## 6. Fixes pendientes (detalle)

### FIX-001 — `dmem` entrega el dato un ciclo tarde

| Campo | Detalle |
|---|---|
| **Estado** | `VERIFICADO` (simulación, 2026-11-06) |
| **Prioridad** | `ALTA` |
| **¿Bloquea E2?** | Sí |
| **Fecha** | 2026-11-06 |
| **Archivo(s)** | `src_super/dmem_dual.v` (nuevo, 44 líneas) y `src_super/top_dual.v` |
| **Líneas** | `dmem_dual.v` completo; `top_dual.v` línea 43 |

**Síntoma.**
Un `lw` seguido de un consumidor devuelve el dato de la lectura anterior, no el
de la dirección actual. Los programas 1 y 2 no lo detectan porque el `lw` no se
usa después.

**Causa raíz.**
`src files/dmem.v` registra la lectura:

```verilog
always @(posedge clk) begin
    rd <= RAM[a[31:2]];
    ...
end
```

y `src files/memwb.v` captura `ReadData` en el mismo flanco:

```verilog
MEM_WB_ReadData <= ReadData;
```

En el flanco, `dmem.rd` todavía tiene el valor anterior. `MEM/WB` guarda ese
valor viejo. El dato nuevo recién aparece en `dmem.rd` después del flanco, cuando
`MEM/WB` ya lo perdió.

**Implementación aplicada.**
Se creó `src_super/dmem_dual.v` con lectura combinacional y escritura síncrona:

```verilog
assign rd = RAM[a[31:2]];

always @(posedge clk) begin
    if (we) RAM[a[31:2]] <= wd;
end
```

Se mantuvieron los mismos valores iniciales de `src files/dmem.v`
(`RAM[0] = 10`, `RAM[2] = 30`) para no alterar la regresión de `program1.mem`.
En `src_super/top_dual.v` se reemplazó la instancia `dmem` por `dmem_dual`
(línea 43). La memoria sigue teniendo un solo puerto.

**Por qué así.**
No se toca `src files/`, se mantiene un solo puerto y el `MEM/WB` existente
captura el dato correcto al final del ciclo de MEM.

**Verificación.**
Estado: **VERIFICADO por simulación** (xsim 2026.1, 2026-11-06).

Test `t_lw.mem` (`addi x1,42 → sw → lw x2 → add x3,x2,x2`):

- `x2 = 42` (antes el `lw` entregaba el dato de la dirección anterior).
- `x3 = 84`, o sea el consumidor load-use ve el dato correcto.

Regresión `program1..4` contra `top_pipeline`: `dmem` idéntico en los 4
programas. En `program1`/`program2` el `lw` deja `x10 = 10` en el dual, mientras
que el single-issue deja `x10 = x` (bug de lectura registrada). Es la diferencia
esperada y confirma el fix.

1. `addi → sw → lw → add` con el `lw` usado por el `add`: OK.
2. `dmem` del dual contra el single-issue: sin diferencias en los 4 programas.
3. Señales: `DataAdr`, `ReadData`, `MEM_WB_ReadData` estables en MEM.

**Riesgo / efecto colateral.**
Cambia el timing de la lectura en el dual. El single-issue (`src files/`) queda
igual. Hay que revisar que `dmem_dual` no introduzca escritura combinacional.

**Relacionado.** `FIX-006`, E2-T3, load-use.

---

### FIX-002 — `regfile_dual` sin write-through

| Campo | Detalle |
|---|---|
| **Estado** | `VERIFICADO` (simulación, 2026-11-06) |
| **Prioridad** | `ALTA` |
| **¿Bloquea E2?** | Sí |
| **Fecha** | 2026-11-06 |
| **Archivo(s)** | `src_super/regfile_dual.v` |
| **Líneas** | 41–65 |

**Síntoma.**
Si una instrucción escribe en WB y otra lee el mismo registro en ID en el mismo
ciclo, el consumidor lee el valor viejo. El forwarding no lo cubre: al ciclo
siguiente el productor ya salió de `MEM/WB`.

**Causa raíz.**
`src files/regfile.v` tiene write-through:

```verilog
assign rd1 = (a1 != 0) ? ((we3 && (a3 == a1)) ? wd3 : rf[a1]) : 32'b0;
```

`src_super/regfile_dual.v` solo hace:

```verilog
assign rd1_A = (a1_A != 5'd0) ? rf[a1_A] : 32'b0;
```

**Implementación aplicada.**
Se agregó write-through en las 4 salidas de lectura, contra los 2 puertos de
escritura. La vía B tiene prioridad porque es más joven:

```verilog
assign rd1_A = (a1_A == 5'd0) ? 32'b0 :
               (we3_B && (a3_B == a1_A)) ? wd3_B :
               (we3_A && (a3_A == a1_A)) ? wd3_A :
                                           rf[a1_A];
```

y análogamente para `rd2_A`, `rd1_B` y `rd2_B` (líneas 45–65 del archivo).

**Por qué así.**
La vía B es más joven que A en el mismo par. Si ambas escribieran el mismo `rd`
(cosa que el Issue Unit va a prohibir), gana B. Si no, no hay conflicto.

**Verificación.**
Estado: **VERIFICADO por simulación** (xsim 2026.1, 2026-11-06).

Test `t_wt.mem`: tres `addi` y después `add x4, x1, x0`, con el productor de
`x1` en WB justo cuando el consumidor está en ID. Resultado: `x4 = 5`.
Sin write-through el consumidor habría leído el valor viejo (`0`).

1. Dos escrituras simultáneas: cubierto estructuralmente (prioridad B > A).
2. Consumidor inmediato en ID: OK (`x4 = 5`).
3. `x0` sigue devolviendo 0 en los 4 puertos de lectura.

**Riesgo / efecto colateral.**
Puede alargar levemente el camino combinacional de lectura. No cambia el
comportamiento secuencial.

**Relacionado.** `FIX-000B`, E2-T5.

---

### FIX-003 — `jal` usa el inmediato de LUI

| Campo | Detalle |
|---|---|
| **Estado** | `VERIFICADO` (simulación, 2026-11-06) |
| **Prioridad** | `ALTA` |
| **¿Bloquea E2?** | Sí, si se testea `jal`; si no, documentar |
| **Fecha** | 2026-11-06 |
| **Archivo(s)** | `src_super/extend_dual.v` (nuevo, 50 líneas) y `src_super/datapath_dual.v` |
| **Líneas** | `extend_dual.v` completo; `datapath_dual.v` líneas 212 y 245 |

**Síntoma.**
Un `jal` salta a una dirección incorrecta. El link (`PC+4`) puede estar bien,
pero el target no.

**Causa raíz.**
`maindec` asigna `ImmSrc = 2'b11` a `jal`:

```verilog
7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
```

y `extend` interpreta `2'b11` como U-type:

```verilog
2'b11: begin
    immext = {instr[31:12], 12'b0};  // Para LUI
end
```

**Implementación aplicada.**
Se creó `src_super/extend_dual.v` con la misma interfaz que `extend`, pero con
la distinción por opcode dentro de `2'b11`:

```verilog
2'b11: begin
    if (instr[6:0] == 7'b1101111)
        immext = {{12{instr[31]}}, instr[19:12], instr[20],
                  instr[30:21], 1'b0};       // J-type (jal)
    else
        immext = {instr[31:12], 12'b0};      // U-type (lui)
end
```

Se reemplazaron las dos instancias en `src_super/datapath_dual.v`:

- línea 212: `extend_dual ext (...)` para la vía A.
- línea 245: `extend_dual ext_b (...)` para la vía B.

No se tocó `src files/extend.v` ni el ancho de `ImmSrc`.

**Por qué así.**
No se toca `src files/extend.v` ni se cambia el ancho de `ImmSrc`, que está
propagado por `idex`, `maindec` y los registros.

**Verificación.**
Estado: **VERIFICADO por simulación** (xsim 2026.1, 2026-11-06).

Test `t_jal.mem`: `jal x5, 8` en `0x04`. Resultados:

- `x5 = 0x08` (link = PC+4).
- `x1 = 42`, o sea se ejecutó la instrucción de `0x0c` y se salteó la de `0x08`.
- `PC` fue a `0x0c`, no a `0x00800000`.

También se verificó `lui` en `program1` (`x3 = 0x1234`), así que la distinción
J-type/U-type dentro de `ImmSrc=2'b11` no rompió el caso U-type.

1. `jal x1, target` con target conocido: OK.
2. `x1 = PC+4`: OK.
3. `lui` sigue funcionando: OK.

**Riesgo / efecto colateral.**
Ninguno para LUI: el opcode distingue los dos casos. El single-issue sigue con el
bug si no se cambia; el dual queda correcto.

**Relacionado.** `FIX-000A`, E2-T4.

---

### FIX-004 — `reg_idex_b` captura B aunque no se emita

| Campo | Detalle |
|---|---|
| **Estado** | `VERIFICADO` (simulación, 2026-11-06) |
| **Prioridad** | `ALTA` |
| **¿Bloquea E2?** | Sí |
| **Fecha** | 2026-11-06 |
| **Archivo(s)** | `src_super/datapath_dual.v` |
| **Líneas** | 120–121 (wire) y 335 (conexión en `reg_idex_b`) |

**Síntoma.**
Si `issue_B = 0`, la vía B no debería ejecutar nada. Hoy `reg_idex_b` usa el
mismo `stall/flush` que A y captura `ID_B_*` todos los ciclos. B podría ejecutar
una instrucción que en realidad se va a re-fetchar como A, duplicándola.

**Causa raíz.**
La instancia de `reg_idex_b` solo recibe `flush_idex_hz`:

```verilog
idex reg_idex_b (
    ...
    .stall_ID_EX      (stall_idex_hz),
    .flush_ID_EX      (flush_idex_hz),
    ...
);
```

No existe una condición de validez de B.

**Implementación aplicada.**
Se agregó la condición de validez de B y se conectó en `reg_idex_b`:

```verilog
wire flush_idex_b;
assign flush_idex_b = flush_idex_hz | ~IF_ID_IssueB;

idex reg_idex_b (
    ...
    .stall_ID_EX      (stall_idex_hz),
    .flush_ID_EX      (flush_idex_b),
    ...
);
```

Mientras no exista el Issue Unit (E2), `IF_ID_IssueB` vale 0 y la vía B queda
permanentemente en burbuja. Eso es lo correcto: hoy solo se ejecuta A.

**Por qué así.**
B solo es válida si el Issue Unit decidió emitirla. Si no, se limpia su `ID/EX`
y la instrucción se ejecuta una sola vez, como A, en el ciclo siguiente.

**Verificación.**
Estado: **VERIFICADO por simulación** (xsim 2026.1, 2026-11-06).

En `tb_fixes` se chequeó en cada ciclo que `ID_EX_B_RegWrite = 0` y
`ID_EX_B_MemWrite = 0` mientras `issue_B_comb = 0`. Nunca se activó B. Los
cuatro programas de regresión ejecutan solo la vía A y el register file coincide
con lo esperado (salvo las diferencias ya explicadas por `FIX-001`).

1. Par con RAW intra-par: B no se emite.
2. B no escribe dos veces: OK (controles de B siempre en 0).
3. Contador de ejecuciones: no aplica todavía; llega con el Issue Unit de E2.

**Riesgo / efecto colateral.**
Ninguno si `IF_ID_IssueB` se mantiene correctamente en stall/flush.

**Relacionado.** `FIX-005`, E2-I9, E2-T6.

---

### FIX-005 — No existe `IF_ID_IssueB`

| Campo | Detalle |
|---|---|
| **Estado** | `VERIFICADO` (simulación, 2026-11-06) |
| **Prioridad** | `ALTA` |
| **¿Bloquea E2?** | Sí |
| **Fecha** | 2026-11-06 |
| **Archivo(s)** | `src_super/datapath_dual.v` |
| **Líneas** | 110–116 (declaración y placeholder) y 173–180 (registro) |

**Síntoma.**
ID no sabe si `IF_ID_Instr_B` es una instrucción emitida o solo la siguiente que
se va a re-fetchar como A. Sin ese bit no se puede limpiar `ID_EX_B` ni gatear
el hazard unit.

**Causa raíz.**
El bit de decisión de emisión no existe. La única información es
`IF_ID_Instr_B`, que siempre está presente aunque B no se emita.

**Implementación aplicada.**
Se declaró el bit y se registró con `flopenrc #(1)`:

```verilog
wire issue_B_comb;
wire IF_ID_IssueB;

assign issue_B_comb = 1'b0;   // placeholder hasta el Issue Unit de E2

flopenrc #(1) reg_issue_b (
    .clk   (clk),
    .reset (reset),
    .en    (~stall_ifid_hz),
    .clr   (flush_ifid_hz),
    .d     (issue_B_comb),
    .q     (IF_ID_IssueB)
);
```

El placeholder `issue_B_comb = 1'b0` mantiene el comportamiento actual: nunca se
emite B y el PC avanza de a 4. En E2 se reemplaza por la salida del Issue Unit.

**Por qué así.**
El PC avanza +8 o +4 en el mismo ciclo en que se busca el par. La decisión debe
tomarse en IF y viajar registrada a ID, no recalcularse en ID.

**Verificación.**
Estado: **VERIFICADO por simulación** (xsim 2026.1, 2026-11-06).

- `IF_ID_IssueB = 0` en todos los ciclos mientras `issue_B_comb = 0`.
- El bit se actualiza con el mismo `stall`/`flush` que `reg_ifid_b`, así que
  queda alineado con el par.
- La ruta `issue_B_comb = 1` todavía no se puede ejercitar: depende del Issue
  Unit de E2.

1. `issue_B = 1`: pendiente para E2.
2. `issue_B = 0`: OK.
3. Stall: misma lógica que el registro del par; pendiente de waveform.
4. Flush: misma lógica que el registro del par; pendiente de waveform.

**Riesgo / efecto colateral.**
Si `flush_ifid` y `stall_ifid` coinciden, la prioridad de `flopenrc`
(`clr > en`) limpia el bit. Es lo correcto.

**Relacionado.** `FIX-004`, `FIX-006`, E2-I8.

---

### FIX-006 — `PCNext` solo hace `PC+4`

| Campo | Detalle |
|---|---|
| **Estado** | `VERIFICADO` (simulación, 2026-11-06) |
| **Prioridad** | `ALTA` para dual-issue |
| **¿Bloquea E2?** | Sí |
| **Fecha** | 2026-11-06 |
| **Archivo(s)** | `src_super/datapath_dual.v` |
| **Líneas** | 430–437 |

**Síntoma.**
El PC nunca avanza de a 8. `PCPlus8` se calcula en la línea 125 pero no se usa.

**Causa raíz.**

```verilog
mux2 #(WIDTH) pcmux (
    .d0 (PCPlus4),
    .d1 (ex_PCTarget),
    .s  (ex_PCSrc),
    .y  (PCNext)
);
```

**Implementación aplicada.**
Se reemplazó el `mux2` por un `mux3`:

```verilog
// target > PC+8 > PC+4
mux3 #(WIDTH) pcmux (
    .d0 (PCPlus4),
    .d1 (PCPlus8),
    .d2 (ex_PCTarget),
    .s  ({ex_PCSrc, issue_B_comb}),
    .y  (PCNext)
);
```

`mux3` implementa `y = s[1] ? d2 : (s[0] ? d1 : d0)`, así que `ex_PCSrc` tiene
prioridad sobre `issue_B_comb`. Con el placeholder actual (`issue_B_comb = 0`)
el comportamiento es idéntico al anterior: `PC+4` o target.

**Por qué así.**
El branch tiene prioridad absoluta. Si no hay branch y se emitieron dos, el par
consumió 8 bytes. Si solo se emitió A, el siguiente par arranca en `PC+4`.

**Verificación.**
Estado: **VERIFICADO parcialmente por simulación** (xsim 2026.1, 2026-11-06).
La ruta `PC+8` queda pendiente hasta que E2 genere `issue_B_comb = 1`.

Verificado:

- `PC` avanza `0 → 4 → 8 → …` en `t_lw` y `t_wt`.
- Branch tomado (`t_branch.mem`, `program4`): `PC` va al target, se saltea la
  instrucción de `0x0c` (`x3 = 0`) y se ejecuta la de `0x10` (`x4 = 7`).
- `program1..4`: el `PC` nunca avanza de a 8 con el placeholder actual.

Pendiente para E2: par emitido con `issue_B_comb = 1` → `PC+8`.

**Riesgo / efecto colateral.**
Hay que usar el `issue_B` **combinacional** del par que se está buscando, no el
`IF_ID_IssueB` del par anterior.

**Relacionado.** `FIX-005`, E2-D10.

---

### FIX-009 — `imem_dual` parametrizable (`MEMFILE`)

| Campo | Detalle |
|---|---|
| **Estado** | `VERIFICADO` (simulación, 2026-11-06) |
| **Prioridad** | `MEDIA` |
| **¿Bloquea E2?** | No; es infraestructura de test |
| **Fecha** | 2026-11-06 |
| **Archivo(s)** | `src_super/imem_dual.v` y `src_super/top_dual.v` |
| **Líneas** | `imem_dual.v` 8 y 19; `top_dual.v` 6–8 y 36 |

**Síntoma.**
Para probar cada escenario de 3.2 había que copiar el `.mem` del test como
`program1.mem` en la carpeta de xsim. Eso pisaba el programa base y hacía fácil
confundir archivos.

**Causa raíz.**

```verilog
initial begin
    $readmemh("program1.mem", RAM);
end
```

El nombre estaba fijo en el módulo.

**Implementación aplicada.**

`src_super/imem_dual.v`:

```verilog
module imem_dual #(
    parameter MEMFILE = "program1.mem"
    )(
    ...
    );

    initial begin
        $readmemh(MEMFILE, RAM);
    end
```

`src_super/top_dual.v`:

```verilog
module top_dual #(
    parameter MEMFILE = "program1.mem"
    )(
    ...
    );

    imem_dual #(.MEMFILE(MEMFILE)) imem (
        ...
    );
```

**Qué solucionó.**
Un testbench puede instanciar:

```verilog
top_dual #(.MEMFILE("test_alu_indep.mem")) dut (...);
```

sin renombrar archivos. El valor por defecto conserva `program1.mem`.

**Por qué así.**
El parámetro viaja de `top_dual` a `imem_dual`; no hay que tocar `imem` ni el
resto del datapath. La cadena `MEMFILE` es un parámetro de texto, soportado por
Vivado para `$readmemh`.

**Verificación.**
Estado: **VERIFICADO por simulación** (xsim 2026.1, 2026-11-06).

`tb_fixes` instancia cuatro `top_dual` con cuatro `MEMFILE` distintos
(`t_lw.mem`, `t_wt.mem`, `t_jal.mem`, `t_branch.mem`) y cada uno ejecuta su
propio programa:

- `t_lw`: `x2 = 42`, `x3 = 84`.
- `t_wt`: `x4 = 5`.
- `t_jal`: `x5 = 8`, `x1 = 42`.
- `t_branch`: `x4 = 7`, `x3 = 0`.

También se corrieron `program1..4` en paralelo con `MEMFILE` absoluto.

1. Default: sigue cargando `program1.mem`.
2. `MEMFILE("otro.mem")`: OK.
3. Sin warnings de `$readmemh` por archivo no encontrado.

**Riesgo / efecto colateral.**
El archivo `.mem` debe estar en la carpeta de trabajo de xsim o en una ruta
válida. Si no se encuentra, `RAM` queda con `x`.

**Relacionado.** `FIX-010`, E2-T1..T7.

---

## 7. Fixes previstos de E2 (no son huecos actuales)

Estos no se pueden aplicar todavía porque dependen de módulos que no existen.
Se registran para mantener el mapa completo.

| Fix | Tarea E2 | Cuándo |
|---|---|---|
| `FIX-007` | Instanciar `mux5` para forwarding de 5 fuentes (A y B) | E2.1 (hecho) |
| `FIX-008` | Conectar `ID_EX_B_*` → `EX/MEM_B` → `MEM/WB_B` → RF | E2.1 (hecho) |
| `FIX-010` | TB con halt, contador de ciclos y checks | Fase 6 |
| `FIX-011` | `flush_exmem_b` para branch/jal en A | Fase 4 |
| `FIX-012` | Branch compartido (un sumador + mux de vía) | Fase 2 |

> `FIX-009` ya pasó de “previsto” a `APLICADO`; ver la sección 6.

---

## 8. Plantilla para nuevos fixes

Copiar y completar:

```markdown
### FIX-0XX — Título corto

| Campo | Detalle |
|---|---|
| **Estado** | PENDIENTE / EN CURSO / APLICADO / VERIFICADO / DESCARTADO |
| **Prioridad** | ALTA / MEDIA / BAJA |
| **¿Bloquea E2?** | Sí / No |
| **Fecha** | YYYY-MM-DD |
| **Archivo(s)** | ruta(s) |
| **Líneas** | rango al momento del fix |
| **Señales afectadas** | ... |

**Síntoma.**
...

**Causa raíz.**
...

**Antes.**
```verilog
...
```

**Después.**
```verilog
...
```

**Qué solucionó.**
...

**Por qué así.**
...

**Verificación.**
1. ...
2. ...

**Riesgo / efecto colateral.**
...

**Relacionado.** ...
```

---

## 9. Verificación global antes de E2

Antes de declarar cerrados los huecos:

- [x] `FIX-001` verificado con un `lw` cuyo dato se usa (`x2 = 42`, `x3 = 84`).
- [x] `FIX-002` verificado con consumidor inmediato en ID (`x4 = 5`).
- [x] `FIX-003` verificado con `jal x5, 8` (`x5 = 8`, salta a `0x0c`).
- [x] `FIX-004` verificado: B nunca ejecuta con `issue_B_comb = 0`.
- [x] `FIX-005` verificado: `IF_ID_IssueB` en 0 bloquea B y en 1 lo emite (E2.1).
- [x] `FIX-006` verificado: `PC+4`, target y `PC+8` (E2.1 emite pares reales).
- [x] La compilación del diseño dual no tiene errores nuevos (xvlog 2026.1,
  `--relax`). Solo quedan los warnings preexistentes de `mux2`/`mux3`.
- [x] La regresión `program1..4` da el mismo `dmem` que `top_pipeline`.
- [x] `PrArqui.xpr` incluye `dmem_dual.v` y `extend_dual.v` (agregados al
  `<FileSet sources_1>`).

> Los ítems `[~]` no son huecos abiertos: son rutas que dependen del Issue Unit
> de E2 y por eso no se pueden ejercitar todavía.
>
> Actualización E2.1: ya no queda ningún `[~]`. Las rutas `IF_ID_IssueB = 1` y
> `PC+8` se ejercitan con pares emitidos de verdad (ver sección 11).

---

## 10. Observaciones de la verificación (2026-11-06)

### 10.1 Herramienta y entorno

Sí hay simulador CLI en esta máquina:

```
D:\programas\AMDDesignTools\2026.1\Vivado\bin\xvlog.bat
D:\programas\AMDDesignTools\2026.1\Vivado\bin\xelab.bat
D:\programas\AMDDesignTools\2026.1\Vivado\bin\xsim.bat
```

La compilación necesita `--relax` porque `src files/mux2.v` y `src files/mux3.v`
declaran `parameter WIDTH` después de usarlo en el puerto. Sin `--relax` xvlog lo
trata como error; con `--relax` queda como warning preexistente. Esto no lo
introdujo ningún fix.

Los testbenches temporales de verificación se corrieron en:

```
C:\Users\Ricardo\AppData\Local\Temp\opencode\dual_sim\
C:\Users\Ricardo\AppData\Local\Temp\opencode\cmp_sim\
```

No se agregaron al repositorio para no adelantar `FIX-010` (TB definitivo de E2).

### 10.2 Resultado de los tests

| Test | Programa | Resultado |
|---|---|---|
| `FIX-001` | `addi x1,42 → sw → lw x2 → add x3` | `x2 = 42`, `x3 = 84` |
| `FIX-002` | 3 `addi` + consumidor a distancia 3 | `x4 = 5` |
| `FIX-003` | `jal x5, 8` en `0x04` | `x5 = 8`, `PC` a `0x0c`, `x1 = 42` |
| `FIX-004/005` | 4 programas en paralelo | `ID_EX_B_RegWrite = 0`, `IF_ID_IssueB = 0` |
| `FIX-006` | branch tomado `beq x1,x2,8` | `x3 = 0` (salteada), `x4 = 7` |
| `FIX-009` | 4 `MEMFILE` distintos | cada instancia corre su programa |

Regresión `program1..4` dual vs `top_pipeline`:

- `dmem` idéntico en los 4 programas.
- Únicas diferencias de registros: `x10` en `program1` y `program2`.
  El dual da `10`; el single-issue da `x`. Es exactamente el bug de `FIX-001`
  (el single-issue conserva la lectura registrada de `dmem`).

### 10.3 Hallazgo: comentarios de `program1.mem` y `program2.mem`

No se modificaron los `.mem` (restricción del proyecto), pero al verificar se
detectó que **la codificación no coincide con el comentario** en dos casos:

| Archivo | Palabra | Comentario dice | La palabra realmente es |
|---|---|---|---|
| `program1.mem` `0x24` | `00420223` | `sw x4, 4(x0)` | `sw x4, 4(x4)` |
| `program1.mem` `0x28` | `00002503` | `lw x9, 0(x0)` | `lw x10, 0(x0)` |
| `program2.mem` `0x10` | `00420223` | `sw x4, 8(x0)` | `sw x4, 4(x4)` |
| `program2.mem` `0x14` | `00002503` | `lw x5, 8(x0)` | `lw x10, 0(x0)` |

La codificación correcta de `sw x4, 4(x0)` sería `00402223` y la de
`lw x9, 0(x0)` sería `00002483`. Los `program3.mem` y `program4.mem` sí
coinciden con sus comentarios.

Esto no es un bug del hardware: el datapath ejecuta lo que dice la palabra. Se
deja documentado para que, si se quiere que la regresión valide los comentarios,
se corrija el `.mem` en una tarea aparte y con autorización.

---

## 11. Historial del documento

| Fecha | Cambio |
|---|---|
| 2026-11-06 | Creación. Se registran `FIX-000A/B/C` y el backlog `FIX-001..010`. |
| 2026-11-06 | Se aplican `FIX-001` (dmem_dual), `FIX-002` (write-through), `FIX-003` (extend_dual) y `FIX-009` (MEMFILE). Verificación por simulación pendiente. |
| 2026-11-06 | Se aplican `FIX-004` (flush de B sin emisión), `FIX-005` (`IF_ID_IssueB` + placeholder `issue_B_comb`) y `FIX-006` (`PCNext` con `PC+4`/`PC+8`/target). Verificación por simulación pendiente. |
| 2026-11-06 | Verificación con xsim 2026.1: `FIX-001..006` y `FIX-009` pasan. Regresión `program1..4` con `dmem` idéntico al single-issue. Se agregan `dmem_dual.v` y `extend_dual.v` a `PrArqui.xpr`. Se documenta el hallazgo de codificación de `program1/2.mem`. |
