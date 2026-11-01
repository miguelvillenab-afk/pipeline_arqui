# Descripción general del pipeline de cinco etapas, datapath y unidad de control

## 1. Pipeline de cinco etapas

El *pipeline* de cinco etapas divide la ejecución de cada instrucción en cinco pasos que se realizan
en paralelo: mientras una instrucción está en la última etapa, otra acaba de entrar por la primera.
En un ciclo de reloj dado, el procesador tiene siempre cinco instrucciones "en vuelo",
cada una en una etapa distinta. Esto incrementa el número de instrucciones completadas por ciclo,
aunque cada instrucción individual tarde igual que en el diseño single-cycle.

| Etapa | Nombre | Qué hace |
|-------|--------|----------|
| **IF** | Fetch | Lee la instrucción de `imem` usando `PC` y calcula `PC+4`. |
| **ID** | Decode | Decodifica la instrucción, lee los registros fuente y genera el inmediato extendido. |
| **EX** | Execute | Calcula con la ALU el resultado, la dirección de memoria o el destino de un salto. |
| **MEM** | Memory | Lee o escribe la memoria de datos `dmem` (para `lw` y `sw`). |
| **WB** | Writeback | Escribe el resultado en el registro destino del `regfile`. |

Entre cada par de etapas hay un **registro de pipeline** (IF/ID, ID/EX, EX/MEM, MEM/WB).
En cada flanco de reloj, el registro toma los datos parciales de la instrucción que termina la
etapa anterior y los entrega a la etapa siguiente. De esta forma el estado de cada instrucción
viaja "empaquetado" a través del procesador.

En el proyecto, los registros se nombran según el contrato (`contrato.md`), que usa un prefijo
que indica de dónde nace cada señal: `IF_ID_*` (nace en Fetch, alimenta Decode), `ID_EX_*`
(nace en Decode, alimenta Execute) y `EX_MEM_*` (nace en Execute, alimenta Memory).
Por ejemplo, `ID_EX_SrcA` es el operando A que produce Decode y va a Execute.

## 2. Datapath (camino de datos)

El datapath es el conjunto de componentes que transportan y transforman los datos.
En la implementación se organiza por etapas:

1. **Fetch:** registro `PC`, memoria de instrucciones `imem` y sumador `PC+4`.
2. **Decode:** `regfile` con dos puertos de lectura, generador de inmediatos (`extend`) y unidad de control.
3. **Execute:** ALU, mux `ALUSrc` (elige entre el segundo registro o el inmediato) y sumador
   para el destino de branch/jal.
4. **Memory:** acceso a `dmem` (lectura para `lw`, escritura para `sw`).
5. **Writeback:** mux final que selecciona entre el resultado de la ALU, el dato leído de memoria
   o `PC+4` (para `jal`), y lo escribe en el `regfile`.

Cada instrucción avanza una etapa por ciclo de reloj y, en un momento dado, hay hasta
cinco instrucciones simultáneas: cada una con su propio estado y sus propias señales de control,
que viajan con ella por los registros de pipeline.

## 3. Unidad de control

La unidad de control es la parte del procesador que interpreta cada instrucción y decide qué
deben hacer los datos por el datapath. A partir del campo `opcode` (y, en algunos casos,
`funct3` y `funct7`), genera las señales que gobiernan muxes, memoria y ALU.

En el diseño se divide en dos bloques:

- **`maindec`:** decodifica el `opcode` y produce las señales de alto nivel:
  `RegWrite`, `ALUSrc`, `MemWrite`, `ResultSrc`, `Branch`, `Jump`, `ImmSrc` y `ALUOp`.
- **`aludec`:** a partir de `ALUOp` + `funct3`/`funct7`, determina la operación concreta
  de la ALU (`ALUControl`: add, sub, and, or, slt...).

En un diseño single-cycle, la unidad de control produce las señales una sola vez y éstas
se aplican inmediatamente. En un *pipeline* las señales no se pueden aplicar a la vez para todas
las instrucciones: se decodifican en la etapa ID y luego **viajan por los registros de pipeline
junto con la instrucción** a la que pertenecen (así, `ID_EX_MemWrite` describe la escritura de
memoria de esa instrucción concreta y no de otra que esté en otra etapa).

Señales clave que viajan por pipeline:

| Señal | Uso |
|-------|-----|
| `ALUSrc` | Elige la fuente del operando B de la ALU (registro o inmediato). |
| `ALUControl` | Define la operación de la ALU. |
| `RegWrite` | Habilita la escritura en el `regfile` (etapa WB). |
| `MemWrite` | Habilita la escritura en `dmem` (etapa MEM). |
| `ResultSrc` | Selecciona en WB entre resultado ALU, memoria o `PC+4`. |
| `Branch` / `Jump` | Indican que la instrucción puede modificar el flujo de PC. |
| `ImmSrc` | Define el formato de extensión del inmediato (I, S, B, J). |

## 4. Relación entre las tres partes

- El **datapath** mueve y transforma los datos (registros, ALU, memorias, muxes).
- La **unidad de control** dice qué debe hacer cada componente en cada etapa.
- Los **registros de pipeline** son los registros intermedios que separan las etapas y hacen
  que instrucciones distintas avancen a la vez: cada una viaja con su propio conjunto de datos
  y sus propias señales de control.

Con esto, el pipeline logra ejecutar más instrucciones por ciclo de reloj gracias a que la
etapa de inicio de una instrucción coincide con la etapa de cierre de otras cuatro.
La correcta organización de datapath + control + registros es la que permite que las
cinco instrucciones no se estorben entre sí.
